# 更新日志

## v0.1.0 - 2026-06-14

NarrRail Godot 插件的第一个公开预览版本。

### 新增

- 将 `.nrstory` 导入为 Godot Resource。
- 从外部故事仓库同步 `.nrstory`，生成 `.tres` 资源。
- 运行时支持 `Dialogue`、`MultiDialogue`、`Choice`、`Jump`、`SetVariable`、`Condition`、`EmitEvent` 和 `End`。
- 支持 `Bool`、`Int`、`Float`、`String` 变量默认值。
- 支持 `All` 条件逻辑和比较运算符。
- 支持 `enterActions` / `exitActions` 中的 `Set`、`Add`、`Subtract` 和 `EmitEvent`。
- 提供存档/读档快照 API：`create_save_snapshot()` / `restore_save_snapshot(story_data, snapshot)`。
- 提供 line、choice、end、error、variable、event 和 trace 相关运行时信号。
- 提供可选 runtime trace logging。
- `vn_player` 示例提供可选 Debug 面板。
- 同步故事资源支持合并同仓库 `GlobalConfig` 变量。
- 提供 headless 语义一致性、同步、存档/读档冒烟和性能基线测试 runner。

### 说明

- 已使用 Godot `4.6.3` 验证。
- 公共 API 已可用，但仍处于预览阶段；`1.0.0` 前可能发生破坏性调整。
