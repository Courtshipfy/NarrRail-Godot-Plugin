# NarrRail-Godot-Plugin

NarrRail 在 Godot 的运行时插件：支持 `.nrstory` 导入与执行，提供对话状态机、分支选择、变量/条件计算和调试能力，面向 AVG/视觉小说工作流。

## 开发目录建议（插件与示例项目隔离）

建议把插件源码放在仓库根目录独立文件夹，再通过目录联接（Junction）挂到 Godot 项目 `addons/`：

```text
NarrRail-Godot-Plugin/
  narrrail-plugin/                 # 插件真实源码（单一维护）
  narr-rail-host-project/          # Godot 示例宿主项目
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
- 宿主项目目录：`narr-rail-host-project`
- 创建链接到：`narr-rail-host-project/addons/narrrail`

可选参数：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-dev-link.ps1 \
  -PluginSource "narrrail-plugin" \
  -HostProject "narr-rail-host-project" \
  -LinkRelative "addons/narrrail"
```

> 注意：脚本要求插件目录下存在 `plugin.cfg`（用于验证插件根结构）。

## 在 Godot 中启用

1. 打开 `narr-rail-host-project`
2. 进入 `Project > Project Settings > Plugins`
3. 找到 `narrrail` 插件并启用

## 相关文档

- `Docs/SCRIPT_FORMAT.md` - `.nrstory` 格式规范
- `Docs/SPEC_SYNC.md` - 规范同步策略
- `Docs/TASK_PLAN.md` - 任务拆解与里程碑
