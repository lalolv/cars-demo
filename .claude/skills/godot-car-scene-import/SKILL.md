---
name: godot-car-scene-import
description: Convert newly added car .glb models in assets/models into switchable standalone scenes under scenes/cars, register them in CarManager (main.tscn), and apply stable placement + physics defaults. Use when user adds new vehicle models or reports cars not visible/falling after switching.
---

# Godot Car Scene Import Skill

## Goal
Standardize how new car models are integrated so they can be switched from UI and behave consistently on stage.

## Repository Conventions
- Engine: Godot 4.x
- Main scene: `scenes/main.tscn`
- Car scene folder: `scenes/cars/`
- Model folder: `assets/models/<car_name>/<car_name>.glb`
- Car switch logic:
  - `scripts/car_manager.gd`
  - `scripts/rotating_stage.gd`

## Step-by-Step Workflow

### 0) Fast path (recommended)
Use bundled script to scaffold and register cars:

```bash
python3 .claude/skills/godot-car-scene-import/scripts/register_cars.py 1962_ferrari_250_gto 1985_toyota_sprinter_trueno_ae86
```

What it does:
- Verifies each model exists at `assets/models/<car_name>/<car_name>.glb`
- Creates missing `scenes/cars/<car_name>.tscn` using the standard structure
- Updates `scenes/main.tscn`:
  - appends missing `ext_resource` entries
  - appends matching entries to `car_scenes` and `car_names`

Then run the validation section below.

### 1) Create one scene per model
For each new model, create `scenes/cars/<car_name>.tscn` with this structure:

```tscn
[gd_scene format=3]

[ext_resource type="PackedScene" path="res://assets/models/<car_name>/<car_name>.glb" id="1_model"]

[node name="CarBody" type="RigidBody3D"]

[node name="Model" parent="." instance=ExtResource("1_model")]

[editable path="Model"]
```

Why this structure:
- `RigidBody3D` keeps gravity/physics behavior aligned with existing car behavior.
- Model as child avoids scaling the rigid body directly (more stable collision behavior).

### 2) Register new car scenes in main scene
Update `scenes/main.tscn`:
- Add `ext_resource` entries for each new car scene.
- In `CarManager` node, append to:
  - `car_scenes`
  - `car_names`

Keep both arrays the same length and same order.

### 3) Keep stage fitting + physics fallback
Do not remove current fitting pipeline in `scripts/rotating_stage.gd`:
- `_fit_car_to_stage()` for auto scale/centering
- `_ensure_collision_shape()` fallback for missing collision shapes

Important rule:
- Never scale `RigidBody3D` root for imported cars.
- Scale and offset model child node instead.

### 4) Validate in editor/runtime
Run and verify:
- Switch between all cars from UI selector.
- New cars remain visible on stage (no out-of-view spawn).
- New cars do not flash then disappear (fall-through).
- Existing registered cars still switch correctly.

## Troubleshooting

### Symptom: car flashes then disappears
Likely falling through due to collision mismatch.
- Ensure root is `RigidBody3D` and model is child.
- Ensure collision shape exists (scene-defined or auto fallback).
- Ensure rigid body root is not scaled.

### Symptom: no model visible but no error
Likely transform/size issue.
- Confirm `_fit_car_to_stage()` is still called after `add_child(new_car)`.
- Confirm model scene exists at `res://assets/models/<car_name>/<car_name>.glb`.
- Reimport `.glb` once in editor.

### Symptom: selector can switch but wrong names/order
Check `car_scenes` and `car_names` ordering in `scenes/main.tscn`.

## Quick Checklist
- Optional fast path script executed
- Added `scenes/cars/<car_name>.tscn`
- Root node is `RigidBody3D` (`CarBody`)
- Model is child instance from `.glb`
- Added `ext_resource` in `scenes/main.tscn`
- Added matching entries in `car_scenes` and `car_names`
- Runtime switch verified for visibility + gravity
