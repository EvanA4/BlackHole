// #version 450
// most uniforms and attributes are already provided by ThreeJS
// see docs at https://threejs.org/docs/#api/en/renderers/webgl/WebGLProgram
// more code at https://threejs.org/docs/index.html?q=shader#api/en/materials/ShaderMaterial


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


vec2 check_sphere(Ray r) {
  float b = 2. * dot(r.dir, r.origin);
  float c = dot(r.origin, r.origin) - 1.;
  float disc = b * b - 4. * c;

  if (disc > 0.) {
    float sqrtDisc = sqrt(disc);
    float distNearIntersect = max(0., (-b - sqrtDisc) / 2.); // max for in case camera is inside sphere
    float distFarIntersect = (-b + sqrtDisc) / 2.;
    float rawAtmDepth = distFarIntersect - distNearIntersect;

    if (distFarIntersect >= 0.)
      return vec2(distNearIntersect, rawAtmDepth );
  }

  return vec2(3.402823466e+38, 0.);
}


vec3 intersectPlane(Ray r) {
    vec3 pOrigin = vec3(0., 0., 0.);
    vec3 pDir = vec3(0., 1., 0.);

    float denom = dot(pDir, r.dir);
    if (denom > .00001 || denom < -.00001) {
        vec3 p0l0 = pOrigin - r.origin;
        float t = dot(p0l0, pDir) / denom;
        if (t >= 0.)
            return r.origin + r.dir * vec3(t);
    }

    // float a = 0.;
    // float b = 1.;
    // float c = 0.;
    // vec3 rectb = vec3(0., 0., 0.);
    // float t = (a * (rectb.x - r.origin.x) + b * (rectb.y - r.origin.y) + c * (rectb.x - r.origin.z)) / (a * r.dir.x + b * r.dir.y + c * r.dir.z);
    // return vec3(r.origin + r.dir * vec3(t));

    return vec3(0., 0., 0.);
}


void main () {
    Ray r = create_screen_ray();
    vec2 sphereData = check_sphere(r);
    float planePR = length(intersectPlane(r));
    vec3 final = vec3(0.);
    if (planePR > 1.3 && planePR < 3.)
        final.r = 1.;
    if (sphereData[1] > 0.) {
        final.g = 1.;
    }
    gl_FragColor = vec4(final, 1.);
}