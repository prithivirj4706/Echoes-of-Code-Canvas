// crt_digital.gdshader
// Subtle CRT look for the Digital World: scanlines, chromatic aberration and a
// vignette. Applied to a full-screen ColorRect that samples the rendered frame.
// Kept gentle so gameplay stays readable.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;
uniform float scan_intensity : hint_range(0.0, 0.5) = 0.10;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float aberration : hint_range(0.0, 3.0) = 0.7;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;

	// Chromatic aberration — split R/B horizontally a touch.
	vec3 col;
	col.r = texture(screen_tex, uv + vec2(px.x * aberration, 0.0)).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - vec2(px.x * aberration, 0.0)).b;

	// Scanlines, one dark band per virtual pixel row.
	float row = uv.y / px.y;
	float line = 0.5 + 0.5 * sin(row * 3.14159265);
	col *= 1.0 - scan_intensity * line;

	// Vignette toward the corners.
	float vig = smoothstep(0.85, 0.35, length(uv - vec2(0.5)));
	col *= mix(1.0, vig, vignette_strength);

	COLOR = vec4(col, 1.0);
}
