#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_OtherColor;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
in float displacement;
in float time;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float bias(float b, float t) {
    return pow(t, log(b) / log(0.5f));
}

float gain(float g, float t) {
    if (t < 0.5f) 
        return bias(1. - g, 2.*t) / 2.;
    else 
        return 1. - bias(1.-g, 2. - 2.*t) / 2.;
}

//float smoothstep(float edge0, float edge1, float x) {
//    x = clamp((x - edge0)/(edge1 - edge0), 0.0, 1.0);
//    return x*x(3 - 2*x);
//}

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.
        
        //lightIntensity += 1.f;
        //lightIntensity /= 2.f;
        // diffuseColor *= clamp(sin(time) + 1.f, 0.5, 0.7);
        
        //vec4 otherColor = vec4(1.f - diffuseColor.rgb, 1.f);
        vec4 otherColor = u_OtherColor;
        //vec4 otherColor = vec4(1.f);

        //float offset = displacement + 0.25f;
        //float offset = displacement * 0.9f + (sin(time / 500.) + 1.) / 2.f;
        // offset /= 2.f;
        // offset += 0.25f;
        //float offset = (50.f * sin(displacement) + 1.f) / 2.f;
        //float offset = (50.f * sin(20. * displacement) + 1.f) / 2.f;
        float offset = ((20. * displacement) + 1.f + sin(time / 200.f)) / 2.f;
        //offset = clamp(offset, 0.0, 1.0);
        offset = clamp(bias(0.1, offset), 0.0, 1.0);
        // Compute final shaded color
        // out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
        // out_Col = vec4(otherColor.rgb * offset, diffuseColor.a);
        vec4 col = vec4(bias(0.99, mix(diffuseColor.r, otherColor.r, offset)), diffuseColor.gb, 1.f);
        out_Col = vec4(mix(diffuseColor.rgb, otherColor.rgb, offset), diffuseColor.a);
        float gainValue = 0.9;
        vec4 newCol = vec4(gain(gainValue, mix(diffuseColor.r, otherColor.r, offset)), 
                           gain(gainValue, mix(diffuseColor.g, otherColor.g, offset)), 
                           gain(gainValue, mix(diffuseColor.b, otherColor.b, offset)), 1.f);
        out_Col = newCol;
        // out_Col = vec4(mix(diffuseColor.rgb, otherColor.rgb, offset), diffuseColor.a);
        // out_Col = vec4(mix(diffuseColor.rgb, otherColor.rgb, offset) * (sin(time / 50.) + 1.f), diffuseColor.a); //flashing colors
        // out_Col = vec4(col.rgb * offset, diffuseColor.a);
}
