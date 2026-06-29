// hit_flash.gdshader
// Reusable white/colour flash for sprite hit feedback. Drive `flash_amount`
// from 1.0 -> 0.0 on impact (see enemy_drone.gd). Respects the sprite's alpha
// so only the visible silhouette flashes.
shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(mix(tex.rgb, flash_color.rgb, flash_amount * tex.a), tex.a);
}
