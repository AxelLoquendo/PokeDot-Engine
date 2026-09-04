shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 pantalla_size = vec2(320.0, 180.0);
uniform float tamano_bloque : hint_range(2.0, 64.0) = 16.0;
uniform vec4 color_bloque : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 pixel_pos = UV * pantalla_size;
	vec2 bloque = floor(pixel_pos / tamano_bloque);
	vec2 bloques_totales = ceil(pantalla_size / tamano_bloque);

	// Esquina inferior derecha, en unidades de bloque.
	vec2 esquina = bloques_totales;

	float distancia = length(esquina - bloque);
	float distancia_maxima = length(bloques_totales);

	// Margen extra para que el último bloque también quede tapado.
	float umbral = progress * distancia_maxima * 1.2;

	if (distancia <= umbral) {
		COLOR = color_bloque;
	} else {
		discard;
	}
}