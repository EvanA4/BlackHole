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

    float rayDist = length(r.origin);

    // compute ehat0 and ehat1
    vec3 ehat0 = r.origin / rayDist;
    vec3 ehat1 = normalize(r.dir - (dot(r.dir, r.origin) / (rayDist * rayDist) * r.origin));

    // compute psi, r0
    float r0 = rayDist;
    float psi = atan(dot(r.dir, ehat1), dot(r.dir, ehat0));

    // compute appropriate pixel sizes
    const float MAXR = 10000.;
    vec2 access = vec2(
      psi / 3.141592,
      sqrt(MAXR * MAXR - (MAXR - r0) * (MAXR - r0)) / MAXR
    );

    vec2 phi_r1 = texture2D(lightTxt, access).xy;
    float phi = phi_r1.x;
    float r1 = phi_r1.y;

    // get multiples of ehat0 and ehat1
    float finale0 = r1 * cos(phi);
    float finale1 = r1 * sin(phi);

    // get final position of photon
    vec3 finalPos = vec3(finale0) * ehat0 + vec3(finale1) * ehat1;

    // gl_FragColor = vec4(vec3(phi / 3.141592), 1.);
    // gl_FragColor = vec4(finalPos, 1.);
    gl_FragColor = vec4(finalPos, 1.);
}