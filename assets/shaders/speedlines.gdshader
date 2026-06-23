shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 bg_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float speed : hint_range(0.0, 10.0) = 4.0;
uniform float line_density : hint_range(0.0, 1.0) = 0.35;
uniform float line_falloff : hint_range(0.0, 1.0) = 0.2;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    // Center UV and convert to polar coordinates (angle and radius)
    vec2 centered_uv = UV - vec2(0.5);
    float angle = atan(centered_uv.y, centered_uv.x);
    float radius = length(centered_uv);
    
    // Create rays based on angle
    float ray = random(vec2(angle, 0.0));
    
    // Animate the rays moving outward
    float time_offset = TIME * speed;
    float noise = random(vec2(angle, floor(radius * 10.0 - time_offset)));
    
    // Calculate final line intensity
    float line_alpha = step(1.0 - line_density, noise) * smoothstep(line_falloff, 1.0, radius * 2.0);
    
    COLOR = mix(bg_color, line_color, line_alpha * line_color.a);
}