shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.153, 0.176, 0.227, 1.0);
uniform sampler2D reflection_texture : hint_default_black, filter_linear;
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.7;
uniform float fresnel_power : hint_range(0.5, 10.0) = 3.0;
uniform float platform_radius : hint_range(0.1, 10.0) = 2.2;
uniform float edge_softness : hint_range(0.0, 1.0) = 0.15;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.65;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.18;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// For a horizontal planar mirror the screen-space position of any point
	// on the mirror surface is identical for main camera and mirror camera
	// (mathematical property of reflection), so SCREEN_UV maps directly to
	// the correct texel in the mirror SubViewport.
	vec3 refl_col = texture(reflection_texture, SCREEN_UV).rgb;

	// Fresnel: stronger reflection at grazing angles
	vec3 V = normalize(CAMERA_POSITION_WORLD - world_pos);
	float NdotV = max(dot(vec3(0.0, 1.0, 0.0), V), 0.0);
	float fresnel = mix(0.15, 1.0, pow(1.0 - NdotV, fresnel_power));

	// Circular edge fade-out
	float dist = length(world_pos.xz);
	float circle_mask = 1.0 - smoothstep(platform_radius - edge_softness, platform_radius, dist);

	// Top-face only
	float top_face = smoothstep(0.3, 0.7, world_normal.y);

	// Combine
	float factor = reflection_strength * fresnel * circle_mask * top_face;
	ALBEDO = mix(base_color.rgb, refl_col, factor);
	METALLIC = metallic_value;
	ROUGHNESS = roughness_value;
}
