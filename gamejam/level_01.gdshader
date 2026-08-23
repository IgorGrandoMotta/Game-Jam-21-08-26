shader_type canvas_item;

uniform float player_y = 0.0;

varying float world_y;

void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).y;
}

void fragment() {
	vec4 wall_color = texture(TEXTURE, UV);

	// Na camada da frente, mostra somente paredes abaixo do Player.
	if (world_y <= player_y) {
		discard;
	}

	COLOR = wall_color;
}
