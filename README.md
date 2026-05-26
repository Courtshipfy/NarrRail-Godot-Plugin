# NarrRail-Godot-Plugin

NarrRail 在 Godot 的运行时插件：支持 `.nrstory` 导入与执行，提供对话状态机、分支选择、变量/条件计算和调试能力，面向 AVG/视觉小说工作流。

## 开发目录建议（插件与示例项目隔离）

建议把插件源码放在仓库根目录独立文件夹，再通过目录联接（Junction）挂到 Godot 项目 `addons/`：

```text
NarrRail-Godot-Plugin/
  narrrail-plugin/                 # 插件真实源码（单一维护）
  narrrail-host-project/           # Godot 示例宿主项目
    addons/
      narrrail -> Junction 到 ../../narrrail-plugin
```

## 一键建立开发链接（Windows）

已提供脚本：`scripts/setup-dev-link.ps1`

在仓库根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-dev-link.ps1
```

默认行为：
- 插件源码目录：`narrrail-plugin`
- 宿主项目目录：`narrrail-host-project`
- 创建链接到：`narrrail-host-project/addons/narrrail`

可选参数：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-dev-link.ps1 \
  -PluginSource "narrrail-plugin" \
  -HostProject "narrrail-host-project" \
  -LinkRelative "addons/narrrail"
```

> 注意：脚本要求插件目录下存在 `plugin.cfg`（用于验证插件根结构）。

## 在 Godot 中启用

1. 打开 `narrrail-host-project`
2. 进入 `Project > Project Settings > Plugins`
3. 找到 `narrrail` 插件并启用

## 当前运行时支持范围

当前插件可直接加载并运行简单 `.nrstory`：

- 节点：`Dialogue` / `MultiDialogue` / `Choice` / `Jump` / `End`
- 变量：`Bool` / `Int` / `Float` / `String` 默认值初始化
- 条件：`All` + `==` / `!=` / `>` / `>=` / `<` / `<=`
- 动作：节点 `enterActions` / `exitActions` 中的 `Set` / `Add` / `Subtract` / `EmitEvent`
- 运行时信号：`line_changed` / `choices_changed` / `ended` / `error_raised` / `variable_changed` / `event_emitted`

尚未支持：`SetVariable` 节点、`EmitEvent` 节点、Save/Load。

Headless conformance validation:

```sh
godot --headless --path narrrail-host-project --script res://tests/conformance/conformance_runner.gd
```

## 试运行自己的 `.nrstory`

1. 把 `.nrstory` 文件放到 `narrrail-host-project/sample/stories/`
2. 打开 `narrrail-host-project`
3. 运行主场景 `sample/scenes/demo_ui.tscn`
4. 在顶部下拉框选择脚本，或在路径输入框填写 `res://...` 路径
5. 点击 `Load` 重新开始当前脚本；新增文件后点击 `Refresh`

## 相关文档

- `Docs/02_runtime/SCRIPT_FORMAT.md` - `.nrstory` 格式规范
- `Docs/02_runtime/SPEC_SYNC.md` - 规范同步策略
- `Docs/01_architecture/TASK_PLAN.md` - 任务拆解与里程碑
