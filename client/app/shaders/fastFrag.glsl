uniform vec3 meshPos;
uniform vec2 meshDim;
uniform sampler2D lightTxt;
uniform sampler2D skyTxt;
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
    const float MAXR = 1000.;
    vec2 access = vec2(
      psi / 3.141592,
      r0 / MAXR
    );

    vec2 phi_r1 = texture2D(lightTxt, access).xy;
    float phi = phi_r1.x;
    float r1 = phi_r1.y;

    // get multiples of ehat0 and ehat1
    float finale0 = r1 * cos(phi);
    float finale1 = r1 * sin(phi);

    // get final position of photon
    vec3 finalPos = vec3(finale0) * ehat0 + vec3(finale1) * ehat1;

    // get spherical coordinates of final position
    float ftheta = 3.141592 - acos(finalPos.y / length(finalPos));
    float fphi = sign(finalPos.z) * acos(finalPos.x / sqrt(finalPos.x * finalPos.x + finalPos.z * finalPos.z)) + 3.141592;

    // access sky texture with spherical coords
    gl_FragColor = texture2D(skyTxt, vec2(fphi / 3.141592 / 2., ftheta / 3.141592));
    if (abs(fphi) < 0.004)
      gl_FragColor = texture2D(skyTxt, vec2(.002, ftheta / 3.141592));
}