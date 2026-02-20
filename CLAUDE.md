# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

CarsDemo 是一个 Godot 4.6 交互式汽车展厅演示，使用 GDScript 开发，目标平台为移动端（Mobile 渲染器）。展厅内支持多车切换、轨道相机、旋转舞台、幻灯片背景墙、音乐播放和灯光预设。

## 开发命令

```bash
godot --path . --editor   # 打开 Godot 编辑器
godot --path .            # 直接运行游戏
```

无测试框架、Lint 工具或 CI 配置。

## 核心架构

### 主场景与入口

主场景为 `scenes/main.tscn`，根节点 `Main (Node3D)` 挂载 `scripts/main.gd`，是整个应用的调度中心。

### FocusMode 系统（核心设计模式）

`main.gd` 定义了四种焦点模式，控制相机位置、UI 面板显示和用户交互：

```
DEFAULT  → 自由轨道相机浏览展厅
STAGE    → 相机对准旋转舞台，显示汽车选择 UI
GUIDE    → 相机对准导游机器人，显示聊天 UI
SWEEPER  → 相机跟随扫地机器人
```

切换焦点时，`Main` 使用 Tween 平滑移动相机到预设点（`CameraPoints/` 子节点），并启用/禁用 `OrbitCamera` 自由旋转。

### 组件通信（信号驱动）

```
CarManager.car_changed(name)  →  Main._on_car_changed()  →  更新 UI 高亮
MusicPlayer.music_changed(name)  →  Main._on_music_changed()  →  更新 UI 选项
UI 按钮 pressed  →  Main 方法  →  调用 CarManager / MusicPlayer / 切换焦点
```

### 汽车切换流程

```
用户点击汽车按钮
→ Main._on_car_selected(index)
→ CarManager.switch_to_car(index)  # 卸载旧车，实例化新车
→ RotatingStage.set_car(scene)     # 计算 AABB，自适应缩放，播放动画
→ CarManager.car_changed.emit()    # 通知 UI 更新高亮
```

### 灯光系统

灯光按组管理（`base`、`car`、`ambient`），`Main` 提供三种预设模式，动态调整各组能量值。相机聚焦于不同区域时灯光能量也随之变化。

### 关键脚本职责

| 脚本 | 职责 |
|------|------|
| `scripts/main.gd` | 全局调度：焦点切换、UI 响应、灯光、相机 Tween |
| `scripts/car_manager.gd` | 汽车场景列表、加载/卸载/切换车辆 |
| `scripts/rotating_stage.gd` | 舞台旋转、汽车自适应缩放、动画播放 |
| `scripts/orbit_camera.gd` | 单指旋转、双指缩放的触控相机 |
| `scripts/music_player.gd` | 音乐列表、播放/暂停、淡入淡出 |
| `scripts/audio_visualizer.gd` | 频谱分析驱动舞台环形灯光着色器参数 |
| `scripts/screen_slideshow.gd` | 自动扫描目录、淡入淡出播放图片 |
| `scripts/autonomous_robot_sweeper.gd` | NavigationAgent3D 自主漫游、轮子/刷子动画 |
| `scripts/guide_robot.gd` | 导游机器人动画播放与朝向控制 |

### 添加新汽车

1. 将 `.glb` 模型放入 `assets/models/<car_name>/`
2. 在 `scenes/cars/` 下创建对应 `.tscn` 场景
3. 在 `scripts/car_manager.gd` 的 `car_scenes` 列表中注册场景路径
4. 在 `scenes/main.tscn` 的 CarManager 节点中更新导出属性

## 代码规范

- 缩进：Tab
- 命名：`snake_case` 变量/函数，`PascalCase` 节点/类，`SCREAMING_SNAKE_CASE` 常量
- 私有成员：`_` 前缀
- 节点引用：`@onready var`；对外暴露配置：`@export var`
- 脚本结构顺序：`class_name/extends` → `signal` → `const` → `@export` → `@onready` → 成员变量 → `_ready/_process/_input` → 公共方法 → `_私有方法`

## 资源约定

- 音乐：`assets/music/`（`.ogg` 格式）
- 幻灯片图片：`assets/slides/`（自动扫描目录）
- 着色器：`shaders/`（舞台边缘光、地板、镜面反射）
- 所有资源路径使用 `res://` 前缀，避免硬编码绝对路径
- `.tscn` / `.tres` 优先由 Godot 编辑器生成，避免手动编辑导致 UID 冲突
- 避免提交 `.godot/` 缓存目录
