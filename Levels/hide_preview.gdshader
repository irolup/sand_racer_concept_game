shader_type spatial;

uniform vec3 brush_position;
uniform float brush_radius : hint_range(0.0, 100.0);
uniform int brush_mode : hint_enum("OFF, DIG") = 0;

void fragment() {
    vec3 world_pos = (WORLD_MATRIX[0].xyz * VERTEX.x) + (WORLD_MATRIX[1].xyz * VERTEX.y) + (WORLD_MATRIX[2].xyz * VERTEX.z) + WORLD_MATRIX[3].xyz;;

    if (brush_mode == 1) { // DIG mode
        float dist = distance(world_pos, brush_position);
        if (dist <= brush_radius) {
            discard;
        }
    }

    ALBEDO = vec3(0.5, 0.7, 0.3);
}