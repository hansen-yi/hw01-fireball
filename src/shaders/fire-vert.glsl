#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time;
uniform int u_Octaves;
uniform float u_Amplitude;
uniform float u_Frequency;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;
out float displacement;
out float time;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

vec3 hash3(vec3 p) {
    return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 191.999)),
                          dot(p,vec3(269.5, 183.3, 423.891)),
                          dot(p, vec3(420.6, 631.2, 119.02))
                    )) * 43758.5453);
}

float surflet(vec3 p, vec3 gridPoint) {
    // Compute the distance between p and the grid point along each axis, and warp it with a
    // quintic function so we can smooth our cells
    vec3 t2 = abs(p - gridPoint);
    // vec3 t = vec3(1.f) - 6.f * pow(t2, 5.f) + 15.f * pow(t2, 4.f) - 10.f * pow(t2, 3.f);
    vec3 t = vec3(1.f) - 6.f * (t2 * t2 * t2 * t2 * t2) + 15.f * (t2 * t2 * t2 * t2) - 10.f * (t2 * t2 * t2);
    // Get the random vector for the grid point (assume we wrote a function random2
    // that returns a vec2 in the range [0, 1])
    vec3 gradient = hash3(gridPoint) * 2. - vec3(1., 1., 1.);
    // Get the vector from the grid point to P
    vec3 diff = p - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * t.x * t.y * t.z;
}

float perlinNoise3D(vec3 p) {
	float surfletSum = 0.f;
	// Iterate over the four integer corners surrounding uv
	for(int dx = 0; dx <= 1; ++dx) {
		for(int dy = 0; dy <= 1; ++dy) {
			for(int dz = 0; dz <= 1; ++dz) {
				surfletSum += surflet(p, floor(p) + vec3(dx, dy, dz));
			}
		}
	}
	return surfletSum;
}

float bias(float b, float t) {
    return pow(t, log(b) / log(0.5f));
}

float gain(float g, float t) {
    if (t < 0.5f) 
        return bias(1. - g, 2.*t) / 2.;
    else 
        return 1. - bias(1.-g, 2. - 2.*t) / 2.;
}
float sawtooth_wave(float x, float freq, float amplitude) {
    return (x * freq - floor(x * freq)) * amplitude;
}
float impulse(float k, float x) {
    float h = k*x;
    return h*exp(1.0f-h);
}
float displace(float x, float y, float z) {
    float noise = perlinNoise3D(vs_Pos.xyz);
    float newX = noise * 3.f * clamp(sawtooth_wave(sin(123.f * x), 200.f, 5.f), 0.0, 1.0);
    float newY = impulse(0.9, noise) * 5.f * sin(230.f * y);
    float newZ = gain(0.2, 0.5f) * sin(noise * cos(309.f * z));
    // return vec4(newX, newY, newZ, 0);
    return (newX + newY + newZ) / 10.f;
}

float fbm(float x, float y, float z, float f, float a) {
    float total = 0.f;
    float persistence = 0.5f;
    //if (o == -1) {
    //    o = 8;
    //}
    if (a == -1.) {
        a = 0.5;
    }
    int octaves = 8;
    float freq = f;
    float amp = a;
    for(int i = 1; i <= octaves; i++) {
        total += impulse(0.8, displace(x * freq, y * freq, z * freq) * amp);
        freq *= 2.f;
        amp *= persistence;
    }
    return total;
}




void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.


    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below
    // float posIdentity = vs_Pos.x + vs_Pos.y + vs_Pos.z;
    // float posIdentity = vs_Nor.x + vs_Nor.y + vs_Nor.z;
    // modelposition += 10.f * sin(100.f + posIdentity);
    // modelposition *= 10.f * sin(100.f + posIdentity);
    // modelposition += abs(100.f * sin(cos(10.f * posIdentity / 2.f)));
    // modelposition += vec4((1000.f * sin(posIdentity / 200.f) * vs_Nor.xyz), 0.f);
    // vec3 posNormalized = normalize(vec3(vs_Pos));
    // float posNormalizedIdentity = posNormalized.x + posNormalized.y + posNormalized.z;
    // modelposition += vec4(sin(6.28 * posIdentity) * vs_Nor.xyz, 0.f);
    // modelposition += fbm(vs_Pos.x, vs_Pos.y, vs_Pos.z, 0.5) / 10.f;
    
    float d = 3.f * fbm(vs_Pos.x * sin(u_Time / 200.f), vs_Pos.y, vs_Pos.z * sin(u_Time / 500.f), u_Frequency, u_Amplitude) / (10.f * sin(u_Time / 500.f));
    // float d = fbm(vs_Pos.x * sin(u_Time / 200.f), vs_Pos.y + sin(u_Time / 100.f), vs_Pos.z * sin(u_Time / 500.f), u_Frequency, u_Amplitude) / (10.f * sin(u_Time / 500.f));
    // d = impulse(0.99, d);
    // d = clamp(gain(0.9, d), -1.0, 0.0); //cool
    // d = gain(0.9, d); //very cool
    float e = gain(0.9, d);
    //d = smoothstep(d, e, 0.9);
    displacement = d;
    //displacement = fbm(vs_Pos.x + 40. * sin(u_Time / 1000.f), vs_Pos.y + 700. * cos(u_Time / 2000.f), vs_Pos.z + 450. * sin(u_Time / 3000.f), u_Frequency * u_Time, u_Amplitude * u_Time) / 3000.f;
    time = u_Time;
    modelposition += d * vs_Nor;
    //modelposition +=  5.0 * vs_Nor;
    fs_Pos = modelposition;
    // modelposition += 0.75 * displace(vs_Pos.x, vs_Pos.y, vs_Pos.z) / 10.f;

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
