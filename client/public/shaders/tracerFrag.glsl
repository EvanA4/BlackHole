// most uniforms and attributes are already provided by ThreeJS
// see docs at https://threejs.org/docs/#api/en/renderers/webgl/WebGLProgram
// more code at https://threejs.org/docs/index.html?q=shader#api/en/materials/ShaderMaterial

varying vec2 vUv;

void main () {
    gl_FragColor = vec4(vUv, 0., 1.);
}