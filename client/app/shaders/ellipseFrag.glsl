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

void main() {
    /*
    u = 2M/r
    alpha = 2ME/L

    A (scatter) 0 < a < 2 / (sqrt(27))
    B (plunge) a > 2 / (sqrt(27))
    */
    Ray r = create_screen_ray();
    float L = length(vec3(
        r.origin.y * r.dir.z - r.origin.z * r.dir.y,
        r.origin.z * r.dir.x - r.origin.x * r.dir.z, // Angular momentum of photon
        r.origin.x * r.dir.y - r.origin.y * r.dir.x
    ));
    float u = 2. * .2 / length(r.origin);
    float a = 2. * .2 * 1. / L;

    gl_FragColor = vec4(vec3(0. < a && a < (2./sqrt(27.))), 1.);
}