shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0.0, 4.0) = 1.0;

uniform vec2 region_uv_min = vec2(0.0);
uniform vec2 region_uv_max = vec2(1.0);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * outline_width;

	float a = col.a;
	float max_a = 0.0;

	// Derecha
	vec2 uv_r = UV + vec2(px.x, 0.0);
	if (uv_r.x >= region_uv_min.x && uv_r.x <= region_uv_max.x
	&& uv_r.y >= region_uv_min.y && uv_r.y <= region_uv_max.y) {
		max_a = max(max_a, texture(TEXTURE, uv_r).a);
	}

	// Izquierda
	vec2 uv_l = UV + vec2(-px.x, 0.0);
	if (uv_l.x >= region_uv_min.x && uv_l.x <= region_uv_max.x
	&& uv_l.y >= region_uv_min.y && uv_l.y <= region_uv_max.y) {
		max_a = max(max_a, texture(TEXTURE, uv_l).a);
	}

	// Abajo
	vec2 uv_d = UV + vec2(0.0, px.y);
	if (uv_d.x >= region_uv_min.x && uv_d.x <= region_uv_max.x
	&& uv_d.y >= region_uv_min.y && uv_d.y <= region_uv_max.y) {
		max_a = max(max_a, texture(TEXTURE, uv_d).a);
	}

	// Arriba
	vec2 uv_u = UV + vec2(0.0, -px.y);
	if (uv_u.x >= region_uv_min.x && uv_u.x <= region_uv_max.x
	&& uv_u.y >= region_uv_min.y && uv_u.y <= region_uv_max.y) {
		max_a = max(max_a, texture(TEXTURE, uv_u).a);
	}

	// Sin contorno en el borde del lienzo del frame
	float edge_mask = 1.0;
	edge_mask *= step(region_uv_min.x + px.x, UV.x);
	edge_mask *= step(UV.x, region_uv_max.x - px.x);
	edge_mask *= step(region_uv_min.y + px.y, UV.y);
	edge_mask *= step(UV.y, region_uv_max.y - px.y);

	float outline = max_a * step(a, 0.01) * edge_mask;

	vec3 rgb = mix(outline_color.rgb, col.rgb, step(0.01, a));
	float out_a = max(a, outline * outline_color.a);

	COLOR = vec4(rgb, out_a);
}