shader_type canvas_item;

uniform sampler2D mascara : filter_nearest, repeat_disable;
uniform vec2 mascara_origen = vec2(0.0);
uniform vec2 mascara_tamano = vec2(1.0);
uniform float tile_size = 16.0;

uniform sampler2D fondo : hint_screen_texture, filter_nearest;
uniform float umbral_azul : hint_range(-1.0, 1.0) = 0.0;

// Color actual del CanvasModulate (DnsManager)
uniform vec3 modulate_color = vec3(1.0);

uniform vec4 tinte : source_color = vec4(0.55, 0.7, 0.95, 1.0);
uniform float fuerza_tinte : hint_range(0.0, 1.0) = 0.35;
uniform float opacidad : hint_range(0.0, 1.0) = 0.5;

uniform float amplitud_px : hint_range(0.0, 4.0, 1.0) = 0.0;
uniform float filas_por_onda = 16.0;
uniform float velocidad = 2.0;

varying vec2 posicion_mundo;

void vertex() {
	posicion_mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float fila = floor(UV.y / TEXTURE_PIXEL_SIZE.y);
	float onda = round(sin(fila * 6.28318 / filas_por_onda + TIME * velocidad) * amplitud_px);
	vec4 color = texture(TEXTURE, UV + vec2(onda * TEXTURE_PIXEL_SIZE.x, 0.0));

	vec2 casilla = floor((posicion_mundo - mascara_origen) / tile_size);
	float agua = 0.0;
	if (all(greaterThanEqual(casilla, vec2(0.0))) && all(lessThan(casilla, mascara_tamano))) {
		agua = texture(mascara, (casilla + 0.5) / mascara_tamano).r;
	}

	vec3 debajo = texture(fondo, SCREEN_UV).rgb;

	// Quitar el tinte del DNS para medir azul como de día
	vec3 mod_safe = max(modulate_color, vec3(0.001));
	vec3 debajo_raw = debajo / mod_safe;

	float es_agua = step(umbral_azul, debajo_raw.b - debajo_raw.r);

	vec3 rgb = mix(color.rgb, tinte.rgb, fuerza_tinte);
	COLOR = vec4(mix(debajo, rgb, opacidad), step(0.5, color.a) * step(0.5, agua) * es_agua);
}