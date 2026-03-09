shader_type canvas_item;

uniform float speed = 3.0;
uniform vec4 tint_color : source_color = vec4(1.0);

void fragment() {
	vec2 uv = UV;
	uv.x += TIME * -speed;
	vec4 tex = texture(TEXTURE, uv);
	COLOR = tex * tint_color;
}
