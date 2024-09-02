// #version 450
// most uniforms and attributes are already provided by ThreeJS
// see docs at https://threejs.org/docs/#api/en/renderers/webgl/WebGLProgram
// more code at https://threejs.org/docs/index.html?q=shader#api/en/materials/ShaderMaterial

// https://www.physicsforums.com/threads/equations-for-computing-null-geodesics-in-schwarzschild-spacetime.969057/

uniform vec3 meshPos;
uniform vec2 meshDim;
varying vec2 vUv;


struct Ray {
  vec3 origin;
  vec3 dir;
};


Ray create_screen_ray() {
  Ray outRay;
  vec3 camRight = vec3(viewMatrix[0][0], viewMatrix[1][0], viewMatrix[2][0]);
  vec3 camUp = vec3(viewMatrix[0][1], viewMatrix[1][1], viewMatrix[2][1]);
  vec3 upTrans = camUp * (vUv.y - .5) * meshDim.y;
  vec3 rightTrans = camRight * (vUv.x - .5) * meshDim.x;
  outRay.origin = meshPos + upTrans + rightTrans;
  outRay.dir = normalize(outRay.origin - cameraPosition);
  return outRay;
}


vec3 get_infinity_pos(Ray r) {
  float far = 10000.;

  // solve parameterized equation for sphere collision https://viclw17.github.io/2018/07/16/raytracing-ray-sphere-intersection
  vec3 originDiff = r.origin;
  float b = 2. * dot(r.dir, originDiff);
  float c = dot(originDiff, originDiff) - far * far;
  float disc = b * b - 4. * c;

  if (disc > 0.) {
    float sqrtDisc = sqrt(disc);
    float distFarIntersect = (-b + sqrtDisc) / 2.;

    if (distFarIntersect >= 0.)
      return r.origin + r.dir * vec3(distFarIntersect);
  }

  return vec3(0.);
}


// float get_impact_param(Ray r) {
//   float l = get_L(r);
//   return abs(l / 1.);
// }


float f1(float t, float y, float G, float M, float L) {
  float result = (3. * G*G * M*M / (L*L) * y*y - y + 1.);
  return result;
}

float f2(float t, float y) {
  float result = y;
  return result;
}



// vec3 tracer(Ray currentRay) {
//   int N;
//   float G, M, L, E, uh0, u0, phi0, dphi;
//   N = 1000;     // Number of steps
//   G = 1.0;        // Gravitational constant
//   M = 0.2;        // Mass of gravitating object
//   L = length(vec3(
//     currentRay.origin.y * currentRay.dir.z - currentRay.origin.z * currentRay.dir.y,
//     currentRay.origin.z * currentRay.dir.x - currentRay.origin.x * currentRay.dir.z,
//     currentRay.origin.x * currentRay.dir.y - currentRay.origin.y * currentRay.dir.x
//   ));             // Angular momentum of orbiting object
//   E = 1.0;        // Energy of orbiting object

//   u0 = 1. / length(currentRay.origin);                       // Initial inverse radius test particle
//   uh0 = -dot(currentRay.origin, currentRay.dir) * (u0 * u0);       // Initial derivative inverse radius wrt phi
//   phi0 = 0.;                                         // Initial angle test particle
//   dphi = 0.005;                                     // Step size

//   /* Start calculations */
//   float phi = phi0;
//   float u = u0;
//   float uh = uh0;
//   float r = L*L / (G * M * u);
//   float rs = 2. * G * M / (1. * 1.);
//   float x = r * cos(phi);
//   float y = r * sin(phi);
//   float t = 0.;

//   /* Evolve orbit */
//   for(int i = 0; i < N; ++i) {
//     /* Advance step */
//     float u_o = u;
//     float uh_o = uh;
//     float h = dphi;

//     /* Integration using the method of Heun */
//     float uh_hat = uh_o + h * f1(phi, u_o, G, M, L);
//     u = u_o + 0.5 * h * (f2(phi, uh_o) + f2(phi, uh_hat));

//     float u_hat = u_o + h*f2(phi, uh_o);
//     uh = uh_o + 0.5 * h * (f1(phi, u_o, G, M, L) + f1(phi, u_hat, G, M, L));

//     /* Compute radial coordinate */
//     r = L * L / (G * M * u);

//     if (r < rs) {
//       return vec3(0.);
//     }

//     /* Compute time coordinate */
//     float d_tau = r * r * dphi / L;
//     float dt = E * d_tau / (1. - 2. * G * M / r);

//     t = t + dt;

//     /* Compute Cartesian coordinates */
//     x = r * cos(phi);
//     y = r * sin(phi);

//     /* Update angle */
//     phi = phi + dphi;
//   }

//   vec3 e0 = x * normalize(currentRay.origin);
//   vec3 e1 = y * normalize(currentRay.dir);

//   return e0 + e1;
// }


vec3 get_ds2(float L, vec3 s) { // Returns the second derivative of s
  return -1.5 * (L * L) * normalize(s) / pow(length(s), 4.);
}


vec3 tracer(Ray currentRay) {
  int N;
  float L, t, dt;
  vec3 s, ds;
  N = 1500;       // Number of steps
  L = length(vec3(
    currentRay.origin.y * currentRay.dir.z - currentRay.origin.z * currentRay.dir.y,
    currentRay.origin.z * currentRay.dir.x - currentRay.origin.x * currentRay.dir.z, // Angular momentum of photon
    currentRay.origin.x * currentRay.dir.y - currentRay.origin.y * currentRay.dir.x
  ));
  
  s = currentRay.origin;
  ds = currentRay.dir;
  t = 0.;
  dt = .025;

  for (int i = 0; i < N; ++i) { // using classic Runge-Kutta method for second order ODE numeric integration
    // Calculate partial steps
    vec3 k1s, k2s, k3s, k4s;
    vec3 k1ds, k2ds, k3ds, k4ds;

    // k1s = ds;
    // k1ds = get_ds2(L, s);
    // k2s = ds + dt * k1ds / 2.;
    // k2ds = get_ds2(L, s + dt * k1s / 2.);
    // k3s = ds + dt * k2ds / 2.;
    // k3ds = get_ds2(L, s + dt * k2s / 2.);
    // k4s = ds + dt * k3ds;
    // k4ds = get_ds2(L, s + dt * k3s);

    // // Combine partial steps
    // vec3 step_s = s + dt / 6. * (k1s + 2. * k2s + 2. * k3s + k4s);
    // vec3 step_ds = ds + dt / 6. * (k1ds + 2. * k2ds + 2. * k3ds + k4ds);

    // // Temp code
    vec3 step_s = ds * dt;
    vec3 step_ds = get_ds2(L, s) * dt;


    // Update variables
    s += step_s;
    ds += step_ds;
    t += dt;

    // Check for escape condition
    if (length(s) < 1.) { // Photon entered event horizon, return black
      return vec3(0.);
    }
    if (abs(s.y) < .025 && length(s) < 6. && length(s) > 3.) {
      return vec3(1.,(length(s) - 1.5) / 3.5,.4);
    }
  }
  
  return s + 1000. * ds; // Assume photon is far enough away from black hole to travel in straight line
}


void main () {
  Ray r = create_screen_ray();
  vec3 final = tracer(r);

  // float ip = get_impact_param(r);
  // vec3 infPos = get_infinity_pos(r);
  // float ip_threshold = 3. * 1.73205080 *1. * .2 / (1. * 1.);
  // if (ip > ip_threshold)
  //   gl_FragColor = vec4(infPos, 1.);
  // else
  //   gl_FragColor = vec4(0., 0., 0., 1.);

  gl_FragColor = vec4(final, 1.);
}