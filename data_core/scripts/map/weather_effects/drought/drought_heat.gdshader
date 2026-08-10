shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float distortion_strength : hint_range(0.0, 0.02) = 0.006;
uniform float distortion_speed : hint_range(0.0, 5.0) = 1.0;
uniform float distortion_scale : hint_range(1.0, 30.0) = 9.0;
uniform float distortion_vertical : hint_range(0.0, 2.0) = 0.7;

uniform vec4 heat_color : source_color = vec4(0.95, 0.68, 0.28, 1.0);
uniform float heat_alpha : hint_range(0.0, 1.0) = 0.12;


void fragment()
{
	float time = TIME * distortion_speed;

	vec2 uv = SCREEN_UV;


	// -------------------------------------------------------
	// ONDAS DE AIRE CALIENTE
	// -------------------------------------------------------

	float onda_1 = sin(
		uv.y * distortion_scale
		+ time
	);

	float onda_2 = sin(
		uv.y * distortion_scale * 1.73
		- time * 0.71
	);

	float onda_3 = sin(
		uv.x * distortion_scale * 0.43
		+ time * 1.31
	);

	float onda_4 = sin(
		uv.y * distortion_scale * 3.1
		+ time * 0.47
	);


	float onda = (
		onda_1 * 0.40
		+ onda_2 * 0.25
		+ onda_3 * 0.15
		+ onda_4 * 0.20
	);


	// -------------------------------------------------------
	// DISTORSIÓN
	// -------------------------------------------------------

	vec2 desplazamiento = vec2(
		onda * distortion_strength,
		onda * distortion_strength
		* distortion_vertical
	);


	// La distorsión es más visible cerca de la parte inferior.

	float factor_altura = smoothstep(
		0.0,
		1.0,
		1.0 - uv.y
	);


	desplazamiento *= mix(
		0.30,
		1.0,
		factor_altura
	);


	vec2 uv_distorsionada = (
		uv + desplazamiento
	);


	// -------------------------------------------------------
	// IMAGEN DE LA PANTALLA
	// -------------------------------------------------------

	vec4 pantalla = texture(
		SCREEN_TEXTURE,
		uv_distorsionada
	);


	// -------------------------------------------------------
	// TINTE DE CALOR
	// -------------------------------------------------------

	vec3 calor = pantalla.rgb;


	// Aumentamos ligeramente el rojo.

	calor.r += (
		heat_color.r
		* heat_alpha
		* 0.35
	);


	// Aumentamos ligeramente el verde.

	calor.g += (
		heat_color.g
		* heat_alpha
		* 0.18
	);


	// Reducimos ligeramente el azul.

	calor.b -= (
		heat_alpha
		* 0.08
	);


	pantalla.rgb = clamp(
		calor,
		vec3(0.0),
		vec3(1.0)
	);


	// -------------------------------------------------------
	// RESULTADO FINAL
	// -------------------------------------------------------

	COLOR = pantalla;
}