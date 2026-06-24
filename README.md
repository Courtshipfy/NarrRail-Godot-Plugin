# NarrRail Godot Plugin

NarrRail 的 Godot 运行时插件，面向 AVG/视觉小说工作流。插件支持 `.nrstory` 导入、`.nroutline` 剧情总纲、外部故事仓库同步、对话状态机执行、分支选择、变量/条件计算和基础运行时事件。

## Features

- 导入 `.nrstory` 为 Godot Resource
- 导入 `.nroutline` 剧情总纲为 Godot Resource，并兼容旧 `.nrrail`
- 从外部故事仓库同步 `.nrstory` / `.nroutline` / `.nrrail`，生成 `.tres` 资源
- 支持 `Dialogue` / `MultiDialogue` / `Choice` / `Jump` / `SetVariable` / `Condition` / `EmitEvent` / `End`
- 支持 `Bool` / `Int` / `Float` / `String` 变量默认值初始化
- 支持 `All` 条件逻辑和 `==` / `!=` / `>` / `>=` / `<` / `<=`
- 支持 `enterActions` / `exitActions` 中的 `Set` / `Add` / `Subtract` / `EmitEvent`
- 提供运行时信号：`line_changed` / `choices_changed` / `ended` / `error_raised` / `variable_changed` / `event_emitted`
- 提供 `NarrRailEventRouter`，可将结构化 `eventType` 映射到 Godot 自定义行为
- 提供通用 `pause()` / `resume()` 运行时控制，示例项目用它实现 `delay` 事件
- 提供 `NarrRailOutlineRunner`，可按总纲串联多个 `.nrstory` 并执行 Branch 路由
- 提供运行时存档快照 API：`create_save_snapshot()` / `restore_save_snapshot(story_data, snapshot)`
- 提供可选运行时 trace logging：`trace_logged` / `get_trace_records()`
- 示例工程支持保存/读取 `user://narrrail_demo_save.json`

## Project Layout

当前仓库采用插件源码和 Godot 宿主项目分离的配置：

```text
NarrRail-Godot-Plugin/
  narrrail/                        # 插件源码，可直接复制到其他项目的 addons/narrrail
  narrrail-host-project/           # Godot 示例/宿主项目
    addons/
      narrrail -> ../../narrrail
```

Godot 实际从 `res://addons/narrrail` 加载插件代码；开发时直接修改 `narrrail/`。

## Install From Release

下载 release zip 后，将其中的 `narrrail/` 文件夹复制到你的 Godot 项目：

```text
your-godot-project/
  addons/
    narrrail/
      plugin.cfg
      plugin.gd
      runtime/
      importer/
      editor/
```

然后启用插件：

1. 用 Godot 打开你的项目
2. 进入 `Project > Project Settings > Plugins`
3. 找到 `NarrRail` 并启用

插件路径必须是 `res://addons/narrrail`。如果目录名不同，插件内部脚本路径将无法加载。

## Development Setup

如果本地缺少 `narrrail-host-project/addons/narrrail`，在仓库根目录创建 symlink：

```sh
mkdir -p narrrail-host-project/addons
ln -s ../../narrrail narrrail-host-project/addons/narrrail
```

然后启用插件：

1. 用 Godot 打开 `narrrail-host-project`
2. 进入 `Project > Project Settings > Plugins`
3. 找到 `narrrail` 并启用

## Package a Release

从仓库根目录运行：

```sh
bash tools/package_release.sh 0.1.0
```

输出文件：

```text
dist/narrrail-godot-plugin-v0.1.0.zip
```

zip 中包含可复制到项目中的 `narrrail/` 插件目录，以及 `README.md`、`LICENSE`、`CHANGELOG.md` 和 release notes。

## Run a Local Story

可以把自己的 `.nrstory` 放到示例项目内直接试运行：

1. 把 `.nrstory` 文件放到 `narrrail-host-project/sample/stories/`
2. 打开 `narrrail-host-project`
3. 运行主场景 `sample/scenes/demo_ui.tscn`
4. 在顶部下拉框选择脚本，或在路径输入框填写 `res://...` 路径
5. 点击 `Load` 重新开始当前脚本；新增文件后点击 `Refresh`

## Sync an External Story Repository

启用插件后，可以从右侧 `NarrRail` Dock 点击 `Sync Stories`。

也可以从 Godot 编辑器顶部菜单执行：

```text
Project > Tools > NarrRail Sync Stories
```

首次同步会要求选择外部故事仓库目录。插件会递归扫描该目录下的 `.nrstory`、`.nroutline` 和 legacy `.nrrail` 文件，并在 Godot 项目中生成 `.tres` 资源。

同步行为：

- 默认生成位置：`res://narrrail_stories/<repo_name>/...`
- 源 `.nrstory` 不会被复制进 Godot 项目
- 生成资源会记录原始 `source_path`
- 普通故事文件会生成 `NarrRailStoryResource`
- `meta.configType: GlobalConfig` 文件会生成 `NarrRailGlobalConfigResource`
- `.nroutline` / `.nrrail` 总纲文件会生成 `NarrRailOutlineResource`
- 同名 `.nroutline` 和 `.nrrail` 同时存在时优先同步 `.nroutline`
- 同步生成的总纲资源使用 `_outline.tres` 后缀，避免与同名故事资源碰撞
- 加载同步故事资产时，会自动合并同仓库 `GlobalConfig` 中的变量定义
- 再次同步会更新已有资源
- 同步确认后会删除目标目录下已经失去源文件的旧生成资源

可在 `Project > Project Settings` 中搜索 `narrrail/` 调整配置：

| Setting | Default | Description |
| --- | --- | --- |
| `narrrail/story_repository_path` | `""` | 外部 `.nrstory` 仓库路径 |
| `narrrail/pull_git_before_sync` | `true` | 如果目录是 Git 仓库，同步前执行 `git pull --ff-only` |
| `narrrail/story_resource_root` | `res://narrrail_stories` | 生成 `.tres` 资源的根目录 |

## Testing

运行语义一致性测试：

```sh
godot --headless --path narrrail-host-project --script res://tests/conformance/conformance_runner.gd
```

运行外部故事仓库同步测试：

```sh
godot --headless --path narrrail-host-project --script res://tests/sync_repository_runner.gd
```

运行示例 UI 存档/读档冒烟测试：

```sh
godot --headless --path narrrail-host-project --script res://tests/save_load_smoke_runner.gd
```

运行性能基线测试：

```sh
godot --headless --path narrrail-host-project --script res://tests/performance_baseline_runner.gd
```

启动宿主项目检查：

```sh
godot --headless --path narrrail-host-project --quit-after 1
```

发布前建议完整运行以上所有测试命令。

## Documentation

- `Docs/02_runtime/SCRIPT_FORMAT.md` - `.nrstory` 格式规范
- `Docs/02_runtime/SPEC_SYNC.md` - 规范同步策略
- `Docs/02_runtime/PERFORMANCE_BASELINE.md` - 性能基线
- `Docs/03_api/RUNTIME_API.md` - 运行时 API
- `Docs/03_api/UI_INTEGRATION_GUIDE.md` - UI 集成指南
- `Docs/01_architecture/TASK_PLAN.md` - 任务拆解与里程碑

## License

MIT License. See `LICENSE`.
