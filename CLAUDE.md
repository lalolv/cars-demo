# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个 Godot 4.5 游戏项目 (CarsDemo)，使用 GDScript 开发，目标平台为移动端 (Mobile 渲染器)。

## 开发命令

运行项目：
```bash
godot --path . --editor  # 打开编辑器
godot --path .           # 直接运行游戏
```

## 项目结构

- `project.godot` - 项目配置文件
- `node_3d.tscn` - 主场景 (GameScene)，包含世界环境、光照、地面和玩家
- `player.gd` - 玩家控制脚本，附加到 CharacterBody3D 节点
- `assets/` - 资源目录
- `scripts/` - 脚本目录

## 输入映射

项目定义了以下自定义输入动作：
- `left` (A键) - 左移
- `right` (D键) - 右移
- `forward` (W键) - 前进
- `backward` (S键) - 后退
- `ui_accept` (空格键) - 跳跃

## 技术要点

- 使用 Godot 4.5 的 Mobile 渲染器
- 玩家使用 CharacterBody3D 实现 3D 物理移动
- 场景使用 ProceduralSkyMaterial 程序化天空
