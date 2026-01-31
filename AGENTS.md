# AGENTS.md
# 面向自动化/多代理编码助手的仓库指南

## 项目概览
- 引擎: Godot 4.x (project.godot 显示 features: 4.6, Mobile)
- 语言: GDScript
- 目标: 移动端渲染器 (Mobile)
- 主场景: `scenes/main.tscn`

## 规则来源与补充
- 已存在的规则文件: `CLAUDE.md`
- Cursor 规则: 未发现 `.cursor/rules/` 或 `.cursorrules`
- Copilot 规则: 未发现 `.github/copilot-instructions.md`
- 若后续新增规则文件, 以其为准并更新本文件

## 运行 / 构建 / 测试 / Lint
- 运行编辑器: `godot --path . --editor`
- 直接运行: `godot --path .`
- 构建导出: 未发现 `export_presets.cfg` 或导出脚本
- Lint: 未配置专用 Lint 工具
- 测试框架: 未发现 GUT/WAT 等测试框架

## 单测/单场景运行
- 单测: 当前无单测框架, 无单测命令可用
- 单场景: 在编辑器中打开 `scenes/main.tscn` 并运行
- 若添加测试框架, 请在此补充 “单测试用例” 命令

## 代码风格 (GDScript)
- 缩进: 使用 Tab (当前脚本均为 Tab 缩进)
- 文件命名: `snake_case.gd`
- 变量/函数: `snake_case`
- 类/节点名: `PascalCase` (与场景中的节点保持一致)
- 常量: `SCREAMING_SNAKE_CASE`
- 私有成员: 以 `_` 前缀 (如 `_yaw`)
- 类型标注: 尽量为变量与函数返回值标注类型
- 导出属性: 使用 `@export var` 便于编辑器可配
- 节点引用: 使用 `@onready var` 获取场景节点
- 资源加载: 使用 `preload()` 或 `load()` 并放在脚本顶部
- 函数顺序建议: `_ready`/`_input` 等生命周期函数在前

## 导入与依赖
- 常用资源引用: `const SOME_SCENE := preload("res://...")`
- 动态加载: 仅在必要场景使用 `load()`
- 避免在热路径中重复 `load()`/`preload()`
- 资源路径统一使用 `res://` 前缀

## 脚本组织建议
- 顺序: `class_name`/`extends` -> `signal` -> `const` -> `@export` -> `@onready` -> 成员变量
- 生命周期函数: `_ready`、`_input`、`_process` 放在前部
- 公共 API: 放在生命周期函数之后
- 私有方法: 以 `_` 前缀, 放在文件后部

## 类型与集合
- 常用节点类型显式标注 (如 `Node3D`, `Camera3D`)
- PackedScene/Resource 明确类型 (如 `var car_scene: PackedScene`)
- 容器尽量使用类型化集合 (如 `Array[Node3D]`)
- Dictionary 内容较复杂时注明键值含义

## 错误处理与日志
- 依赖节点为空时, 在 `_ready()` 早退或 `push_error()`
- `queue_free()` 前先判断实例有效性
- 避免在热路径中大量 `print()`
- 调试信息优先用 `print_debug()` 或 `push_warning()`

## 注释与可读性
- 只在逻辑不直观时添加注释
- 行内注释避免冗余, 让代码表达意图
- 参数/返回类型能表达含义时不追加注释

## 格式与编辑器习惯
- 统一字符集: UTF-8 (见 `.editorconfig`)
- GDScript 排版: 与现有脚本一致, 不强制对齐运算符
- 避免手动编辑 `.godot/` 缓存文件
- 场景改动优先使用 Godot 编辑器, 降低合并冲突

## 场景与节点组织
- 主场景: `scenes/main.tscn`
- 节点命名: `PascalCase`, 语义清晰 (如 `OrbitCamera`, `CarMount`)
- 子节点引用: 用 `@onready` 与 NodePath, 避免硬编码路径变更
- 资源引用: 使用 `res://` 相对路径

## 场景与资源编辑细节
- `.tscn`/`.tres` 建议由编辑器生成, 减少 UID 冲突
- 若需手工编辑, 保持节点顺序与现有字段风格
- 不随意重排节点或删除 `uid://` 引用
- 新增节点前先确认命名与层级是否符合场景语义
- 资源移动/重命名后, 让编辑器更新引用路径
- 在脚本中避免硬编码 `.tscn` 节点层级路径
- 对外暴露节点引用时优先 `@export`/`@onready`
- 场景合并冲突时, 先用编辑器打开并修复

## 输入与交互
- 输入映射 (project.godot):
- `left` (A) / `right` (D) / `forward` (W) / `backward` (S)
- `touch_rotate` / `touch_zoom` (触控手势)
- 若新增输入动作, 需更新 `project.godot` 并同步说明

## 性能与运行时
- 避免在 `_process` 中频繁分配临时数组/字典
- 缓存常用节点引用, 避免重复 `get_node()`
- 高频逻辑尽量复用对象, 减少 GC 压力
- 触控手势处理保持轻量, 仅在需要时更新状态
- 使用 `@export` 配置数值, 避免运行时魔法数字
- 优先使用 Godot 内置数学函数, 避免自建昂贵计算

## UI 与交互层
- UI 节点放在 `CanvasLayer` 下管理
- Control 布局优先使用锚点与容器, 避免硬编码像素
- 交互脚本与 3D 逻辑解耦, 保持职责清晰
- 触控 UI 与手势输入避免冲突, 必要时做事件吞噬

## 物体生命周期与错误处理
- 节点存在性检查: 使用 `if node:` 或 `is_instance_valid(node)`
- 释放节点: 优先 `queue_free()` 并避免重复释放
- 防御式编程: 对可能为空的 `@export` 引用做早退
- 输入处理: 在 `_input` 中识别事件类型并做最小分支

## 移动端渲染注意事项
- Mobile 渲染器性能敏感, 避免高复杂度后处理
- 材质/光照调整优先在场景中完成, 保持脚本简洁
- 若添加特效, 关注帧率与内存占用

## 文件与目录
- `project.godot`: 项目配置, 避免手工改动未知字段
- `scenes/`: 场景资源 (文本格式可读)
- `scripts/`: GDScript 脚本目录
- `assets/`: 资源目录 (若新增资源请按类型分类)

## 现有脚本约定 (观察自仓库)
- `scripts/orbit_camera.gd`:
- 触控旋转与缩放逻辑集中, 使用 `_touch_positions` 跟踪
- `scripts/rotating_stage.gd`:
- 通过 `auto_rotate` 控制舞台旋转, 支持切换车辆

## 提交与变更建议
- 改动场景和脚本尽量分开提交 (如果需要提交)
- 避免提交 `.godot/` 目录下的缓存文件
- 若新增规则文件, 记得同步更新 `AGENTS.md`

## 快速命令速查
- 打开编辑器: `godot --path . --editor`
- 运行游戏: `godot --path .`
- 查看主场景: `scenes/main.tscn`
- 脚本目录: `scripts/`

## 需要补充的内容
- 导出预设 (export presets) 未配置
- Lint/Test 工具未配置
- 若引入 CI 或测试框架, 请补全命令与约定
