// #version 450
// most uniforms and attributes are already provided by ThreeJS
// see docs at https://threejs.org/docs/#api/en/renderers/webgl/WebGLProgram
// more code at https://threejs.org/docs/index.html?q=shader#api/en/materials/ShaderMaterial

// https://www.physicsforums.com/threads/equations-for-computing-null-geodesics-in-schwarzschild-spacetime.969057/

uniform vec3 meshPos;
uniform vec2 meshDim;
uniform sampler2D skyTxt;
uniform sampler2D diskTxt;
uniform float uTime;
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


vec2 get_ea(float L, vec2 ep) { // Returns the second derivative of s
  float ep_len = length(ep);
  float c = -1.5 * (L * L) / pow(ep_len, 5.);
  return vec2(c) * ep;
}


vec3 tracer(Ray currentRay) {
  // Initialize constants, ehat0, ehat1 ep, ev
  int N = 750;
  float dt = .05;
  vec2 ep = vec2(length(currentRay.origin), 0.);
  vec3 ehat0 = currentRay.origin / ep.x;
  vec3 ehat1 = normalize(currentRay.dir - dot(currentRay.dir, ehat0) * ehat0);
  vec2 ev = vec2(dot(currentRay.dir, ehat0), dot(currentRay.dir, ehat1));
  float L = ep.x * ev.y;
  float DISK_SLOPE = -ehat0.y / ehat1.y;

  for (int i = 0; i < N; ++i) {
    // Classic Runge-Kutta method
    // vec2 k1ep, k2ep, k3ep, k4ep;
    // vec2 k1ev, k2ev, k3ev, k4ev;

    // k1ep = ev;
    // k1ev = get_ea(L, ep);
    // k2ep = ev + dt * k1ev / 2.;
    // k2ev = get_ea(L, ep + dt * k1ep / 2.);
    // k3ep = ev + dt * k2ev / 2.;
    // k3ev = get_ea(L, ep + dt * k2ep / 2.);
    // k4ep = ev + dt * k3ev;
    // k4ev = get_ea(L, ep + dt * k3ep);
    // vec2 step_ep = dt / 6. * (k1ep + 2. * k2ep + 2. * k3ep + k4ep);
    // vec2 step_ev = dt / 6. * (k1ev + 2. * k2ev + 2. * k3ev + k4ev);

    // Euler's method
    vec2 step_ep = ev * dt;
    vec2 step_ev = get_ea(L, ep) * dt;

    // Update variables
    vec2 old_ep = ep;
    ep += step_ep;
    ev += step_ev;

    // Photon entered event horizon, return black
    if (length(ep) < 1.) {
      return vec3(0.);
    }
    
    // Photon hit accretion disk
    if (ep.x * DISK_SLOPE < ep.y != old_ep.x * DISK_SLOPE < old_ep.y) {
      float current_m = (ep.y - old_ep.y) / (ep.x - old_ep.x);
      float current_b = old_ep.y - current_m * old_ep.x;
      float cross_e0 = -current_b / (DISK_SLOPE - current_m);
      float cross_e1 = DISK_SLOPE * cross_e0;
      vec3 finalPos = cross_e0 * ehat0 + cross_e1 * ehat1;
      float final_len2 = cross_e0 * cross_e0 + cross_e1 * cross_e1;

      if (final_len2 > 9. && final_len2 < 36.) {
        return finalPos;
      }
    }
  }
  
  vec2 finalep = ep + vec2(1000.) * ev;
  vec3 finalPos = finalep.x * ehat0 + finalep.y * ehat1;

  return finalPos; // Assume photon is far enough away from black hole to travel in straight line
}


// Returns theta and phi of the spherical coordinates corresponding to the cartesian coordinates
vec2 get_angles(vec3 cart) {
  float th = 3.141592 - atan(sqrt(cart.x * cart.x + cart.z * cart.z), cart.y);
  float phi;
  if (cart.x == 0.0) {
    if (cart.z == 0.0) {
      phi = 0.0;
    } else if (cart.z > 0.0) {
      phi = 3.141592 / 2.;
    } else {
      phi = -1.0 * 3.141592 / 2.;
    }
  } else if (cart.x > 0.0) {
    phi = atan(cart.z / cart.x);
  } else if (cart.x < 0.0) {
    if (cart.z >= 0.0) {
      phi = atan(cart.z / cart.x) + 3.141592;
    } else {
      phi = atan(cart.z / cart.x) + 3.141592;
    }
  }
  return vec2(th, phi + 3.141592 / 2.);
}


void main () {
  Ray currentRay = create_screen_ray();
  vec3 finalPos = tracer(currentRay);

  // gl_FragColor = vec4(final, 1.);

  // access sky texture with spherical coords
  if (length(finalPos) > 100.) { // if photon didn't hit disk
    // if (abs(finalPos.z) < .4) finalPos.z = .4;
    vec2 sph = get_angles(finalPos);
    float ftheta01 = sph.x / 3.141592;
    float fphi01 = sph.y / 3.141592 / 2.;
    gl_FragColor = texture2D(skyTxt, vec2(fphi01, ftheta01));
    // gl_FragColor = texture2D(skyTxt, vec2(fract(vUv.x + .5), fract(vUv.y + vUv.x)));
    // gl_FragColor = vec4(fphi01, 0., 0., 1.); 
  } else if (length(finalPos) > 2.9) {
    float fphi = sign(finalPos.z) * acos(finalPos.x / sqrt(finalPos.x * finalPos.x + finalPos.z * finalPos.z)) + 3.141592;
    float r01 = (length(finalPos) - 3.) / 3.;
    float fphi01 = fract((fphi + uTime) / 3.141592 / 2.);
    vec3 rawColor = texture2D(diskTxt, vec2(fphi01, r01)).xyz;
    gl_FragColor = vec4(rawColor.x, rawColor.y, rawColor.z * .8, 1.);
  } else {
    gl_FragColor = vec4(0., 0., 0., 1.);
  }
}