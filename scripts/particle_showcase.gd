class_name ParticleShowcase
extends Node3D

# Phase 1：CarRevealBurst（换车爆发）+ StageRing（舞台环形轨迹）
# 全部节点在 _ready() 中动态创建，无需 .tscn 手动编辑。
# main.gd 通过 trigger_car_reveal() 和 set_stage_mode() 驱动。

var _car_reveal_burst: GPUParticles3D
var _stage_ring: GPUParticles3D


func _ready() -> void:
	_create_stage_ring()
	_create_car_reveal_burst()


# 由 main.gd 在 _on_car_changed() 中调用
func trigger_car_reveal() -> void:
	if _car_reveal_burst and is_instance_valid(_car_reveal_burst):
		_car_reveal_burst.restart()


# 由 main.gd 在 _set_ui_mode() 中调用
func set_stage_mode(active: bool) -> void:
	if not (_stage_ring and is_instance_valid(_stage_ring)):
		return
	if active and not _stage_ring.emitting:
		_stage_ring.restart()
	_stage_ring.emitting = active


# ─── 换车地面漫射粒子 ─────────────────────────────────────────────────────────
# 从整个平台圆盘面缓缓向上飘散，one-shot，像舞台通电 / 星光从脚下升起

func _create_car_reveal_burst() -> void:
	_car_reveal_burst = GPUParticles3D.new()
	_car_reveal_burst.name = "CarRevealBurst"
	_car_reveal_burst.position = Vector3(0, 0.01, 0)  # 平台顶面高度
	_car_reveal_burst.amount = 160
	_car_reveal_burst.lifetime = 2.5
	_car_reveal_burst.one_shot = true
	_car_reveal_burst.explosiveness = 0.35  # 部分瞬发 + 持续涌出约 0.5 秒
	_car_reveal_burst.randomness = 0.5
	_car_reveal_burst.emitting = false
	_car_reveal_burst.visibility_aabb = AABB(Vector3(-4.0, -0.5, -4.0), Vector3(8.0, 8.0, 8.0))

	var mat := ParticleProcessMaterial.new()
	# 用 Ring 形状将 inner_radius 设为 0，形成完整圆盘面发射
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_radius = 2.2        # 与平台 top_radius 一致
	mat.emission_ring_inner_radius = 0.0  # 0 = 填满整个圆盘
	mat.emission_ring_height = 0.02       # 极薄，贴紧地面
	mat.emission_ring_axis = Vector3(0.0, 1.0, 0.0)  # 水平圆盘
	mat.direction = Vector3(0.0, 1.0, 0.0)
	mat.spread = 22.0                     # 主体垂直向上，轻微散射
	mat.gravity = Vector3(0.0, -0.25, 0.0)  # 极弱重力，让粒子缓缓上浮
	mat.set_param_min(ParticleProcessMaterial.PARAM_INITIAL_LINEAR_VELOCITY, 0.3)
	mat.set_param_max(ParticleProcessMaterial.PARAM_INITIAL_LINEAR_VELOCITY, 1.8)
	mat.set_param_min(ParticleProcessMaterial.PARAM_SCALE, 0.02)
	mat.set_param_max(ParticleProcessMaterial.PARAM_SCALE, 0.06)

	# 颜色渐变：冷白 → 暖白 → 金 → 透明（像星光从地面升起）
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.92, 0.97, 1.0, 0.9),
		Color(1.0, 0.96, 0.80, 0.7),
		Color(1.0, 0.82, 0.35, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = gradient
	mat.color_ramp = color_tex

	_car_reveal_burst.process_material = mat
	_car_reveal_burst.transform_align = GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD

	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 1.0)  # 标准单位quad；实际大小由 PARAM_SCALE 控制
	mesh.material = _make_soft_dot_material()

	_car_reveal_burst.draw_passes = 1
	_car_reveal_burst.draw_pass_1 = mesh

	add_child(_car_reveal_burst)


# ─── 舞台环形轨迹粒子 ──────────────────────────────────────────────────────────
# 青色粒子从平台边缘向上飘散，STAGE 模式时持续循环

func _create_stage_ring() -> void:
	_stage_ring = GPUParticles3D.new()
	_stage_ring.name = "StageRing"
	_stage_ring.position = Vector3(0, -0.02, 0)  # 紧贴平台顶面
	_stage_ring.amount = 160
	_stage_ring.lifetime = 2.4
	_stage_ring.one_shot = false
	_stage_ring.explosiveness = 0.0
	_stage_ring.randomness = 0.6
	_stage_ring.emitting = false
	_stage_ring.preprocess = 1.5  # 进入 STAGE 模式时环形立即呈现，无冷启动延迟
	_stage_ring.visibility_aabb = AABB(Vector3(-4.0, -1.0, -4.0), Vector3(8.0, 6.0, 8.0))

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_radius = 2.2   # 与 Platform top_radius 一致
	mat.emission_ring_inner_radius = 1.85
	mat.emission_ring_height = 0.04
	mat.emission_ring_axis = Vector3(0.0, 1.0, 0.0)  # 水平环（XZ 平面）
	mat.direction = Vector3(0.0, 1.0, 0.0)
	mat.spread = 10.0  # 几乎垂直向上，轻微散射
	mat.gravity = Vector3(0.0, 0.0, 0.0)  # 无重力，缓缓上升
	mat.set_param_min(ParticleProcessMaterial.PARAM_INITIAL_LINEAR_VELOCITY, 0.25)
	mat.set_param_max(ParticleProcessMaterial.PARAM_INITIAL_LINEAR_VELOCITY, 0.75)
	mat.set_param_min(ParticleProcessMaterial.PARAM_SCALE, 0.015)
	mat.set_param_max(ParticleProcessMaterial.PARAM_SCALE, 0.04)

	# 颜色渐变：青蓝不透明 → 浅青半透 → 完全透明
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.0, 0.92, 1.0, 0.9),
		Color(0.3, 0.95, 1.0, 0.45),
		Color(0.0, 0.82, 1.0, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = gradient
	mat.color_ramp = color_tex

	_stage_ring.process_material = mat
	_stage_ring.transform_align = GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD

	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 1.0)
	mesh.material = _make_soft_dot_material()

	_stage_ring.draw_passes = 1
	_stage_ring.draw_pass_1 = mesh

	add_child(_stage_ring)


# ─── 共用辅助 ──────────────────────────────────────────────────────────────────

func _make_soft_dot_material() -> ShaderMaterial:
	var shader := load("res://shaders/particle_soft_dot.gdshader") as Shader
	if not shader:
		push_warning("ParticleShowcase: 找不到 particle_soft_dot.gdshader，粒子将显示为方块。")
		return null
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat
