uniform vec3 meshPos;
uniform vec2 meshDim;
uniform sampler2D lightTxt;
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
    Ray r = create_screen_ray();
    // compute psi, r0
    // compute appropriate pixel sizes
    // get phi, r1
    // get ehat0 and ehat1
    // get multiples of ehat0 and ehat1
    // get final position of photon

    gl_FragColor = texture2D(lightTxt, vUv);
}