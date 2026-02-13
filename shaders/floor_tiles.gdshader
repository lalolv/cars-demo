shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.31, 0.34, 0.38, 1.0);
uniform vec4 alt_tile_color : source_color = vec4(0.34, 0.37, 0.42, 1.0);
uniform vec4 line_color : source_color = vec4(0.45, 0.48, 0.53, 1.0);
uniform float tile_size : hint_range(0.3, 4.0) = 1.25;
uniform float line_width : hint_range(0.005, 0.15) = 0.02;
uniform float line_softness : hint_range(0.0, 0.03) = 0.01;
uniform float checker_strength : hint_range(0.0, 1.0) = 0.55;
uniform bool use_albedo_texture = false;
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float texture_tile_size : hint_range(0.2, 8.0) = 1.4;
uniform vec2 texture_uv_offset = vec2(0.0, 0.0);
uniform float texture_blend : hint_range(0.0, 1.0) = 1.0;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.08;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.44;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 grid_uv = world_pos.xz / max(tile_size, 0.001);
	vec2 cell = floor(grid_uv);
	float parity = mod(cell.x + cell.y, 2.0);
	vec3 procedural_tile_color = mix(base_color.rgb, alt_tile_color.rgb, parity * checker_strength);
	vec3 tile_color = procedural_tile_color;
	if (use_albedo_texture) {
		vec2 tex_uv = world_pos.xz / max(texture_tile_size, 0.001) + texture_uv_offset;
		vec3 texture_color = texture(albedo_texture, tex_uv).rgb;
		tile_color = mix(procedural_tile_color, texture_color, texture_blend);
	}

	vec2 frac_uv = fract(grid_uv);
	vec2 to_line = min(frac_uv, 1.0 - frac_uv);
	float line_dist = min(to_line.x, to_line.y);
	float grid_mask = 1.0 - smoothstep(line_width, line_width + line_softness, line_dist);

	float top_face = smoothstep(0.35, 0.75, world_normal.y);
	ALBEDO = mix(tile_color, line_color.rgb, grid_mask * top_face);
	METALLIC = metallic_value;
	ROUGHNESS = roughness_value;
}
