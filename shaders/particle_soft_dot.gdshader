// 粒子软圆点着色器
// 原理：高斯衰减（软边）+ 中心亮核，模拟真实光晕/星点效果。
// 颜色和透明度由 GPUParticles3D 的 color_ramp 通过顶点色（COLOR）传入。
// Billboard 朝向由 GPUParticles3D.transform_align = Z_BILLBOARD 处理，此处无需 vertex 矩阵。
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_add;

void fragment() {
	// UV 中心化为 (-0.5, 0.5)，边缘距离平方
	vec2 uv = UV - vec2(0.5);
	float d2 = dot(uv, uv) * 4.0;  // 圆心=0，圆盘边缘≈1

	// 高斯软边：让粒子从中心平滑消散到边缘，corners 几乎为 0
	float soft = exp(-d2 * 3.2);

	// 亮白核心：叠加一个更紧的高斯，使中心更耀眼
	float core = exp(-d2 * 18.0);

	// COLOR 来自 color_ramp（随生命周期变色 + 淡出）
	ALBEDO = COLOR.rgb * (1.0 + core * 2.2);
	ALPHA  = COLOR.a * soft;
}
