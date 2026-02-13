shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.84, 0.86, 0.89, 1.0);
uniform vec4 ring_color : source_color = vec4(0.63, 0.66, 0.71, 1.0);
uniform float ring_radius : hint_range(0.1, 8.0) = 2.12;
uniform float ring_width : hint_range(0.002, 0.2) = 0.02;
uniform float ring_softness : hint_range(0.0, 0.05) = 0.01;
uniform float side_darkening : hint_range(0.0, 0.4) = 0.08;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.1;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.3;
uniform float clearcoat_value : hint_range(0.0, 1.0) = 0.45;
uniform float clearcoat_roughness_value : hint_range(0.0, 1.0) = 0.12;

varying vec3 world_normal;
varying vec3 local_pos;

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	local_pos = VERTEX;
}

void fragment() {
	float top_face = smoothstep(0.4, 0.8, world_normal.y);
	float ring_distance = abs(length(local_pos.xz) - ring_radius);
	float ring_mask = 1.0 - smoothstep(ring_width, ring_width + ring_softness, ring_distance);

	vec3 top_color = mix(base_color.rgb, ring_color.rgb, ring_mask * top_face);
	vec3 side_color = base_color.rgb * (1.0 - side_darkening);
	ALBEDO = mix(side_color, top_color, top_face);

	METALLIC = metallic_value;
	ROUGHNESS = roughness_value;
	CLEARCOAT = clearcoat_value;
	CLEARCOAT_ROUGHNESS = clearcoat_roughness_value;
}
