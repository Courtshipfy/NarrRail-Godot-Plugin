# NarrRail Godot Plugin v0.1.0

这是 NarrRail Godot 运行时插件的第一个公开预览版本。

## 安装

1. 下载 `narrrail-godot-plugin-v0.1.0.zip`。
2. 解压 zip。
3. 将其中的 `narrrail/` 文件夹复制到你的 Godot 项目：

```text
your-project/addons/narrrail/
```

4. 打开 Godot，并启用插件：

```text
Project > Project Settings > Plugins > NarrRail
```

插件目录必须是 `addons/narrrail`，否则内部脚本路径无法正确加载。

## 主要功能

- 将 `.nrstory` 导入为 Godot Resource。
- 从外部 NarrRail 故事仓库同步脚本，生成 `.tres` 资源。
- 支持 `Dialogue`、`MultiDialogue`、`Choice`、`Jump`、`SetVariable`、`Condition`、`EmitEvent` 和 `End`。
- 支持变量默认值、条件判断、进入/退出动作和运行时事件。
- 通过 `NarrRailSession` 运行故事流程。
- 通过信号接入 UI：`line_changed`、`choices_changed`、`ended`、`error_raised`、`variable_changed`、`event_emitted`。
- 提供存档/读档快照 API：`create_save_snapshot()` / `restore_save_snapshot(story_data, snapshot)`。
- 提供可选 trace logging，便于调试运行时流程。
- 示例项目包含基础调试 UI、VN 播放器、存档/读档示例和 Debug 面板。

## 使用方式

启用插件后，可以：

- 直接将 `.nrstory` 放入 Godot 项目并导入。
- 通过菜单执行：

```text
Project > Tools > NarrRail Sync Stories
```

从外部故事仓库同步 `.nrstory`。

## 验证情况

本版本使用 Godot `4.6.3` 验证，通过了：

- 语义一致性测试：`[NarrRail][Conformance] PASS`
- 示例 UI 存档/读档冒烟测试：`[NarrRail][SaveLoadSmoke] PASS`
- 性能基线测试：`[NarrRail][PerformanceBaseline] PASS`
- 外部故事仓库同步测试：`[NarrRail][SyncRepository] PASS`
- 宿主项目 headless 启动检查
- release zip 解压后复制到临时 Godot 项目的独立插件检查

## 预览版说明

这是 `0.1.0` 预览版。插件已经可以用于集成和试用，但在 `1.0.0` 前，公共 API 和 `.nrstory` 兼容细节仍可能调整。

建议在生产项目前先用自己的故事仓库跑一遍同步、导入、运行和存档流程。
