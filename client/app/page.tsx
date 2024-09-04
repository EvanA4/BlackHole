// @ts-nocheck
'use client'
import React, { useEffect, useRef, useState } from 'react'
import { Canvas, useFrame, useLoader, useThree } from '@react-three/fiber'
import * as THREE from 'three'
import { OrbitControls, PerspectiveCamera } from '@react-three/drei'
import { EXRLoader } from 'three/examples/jsm/loaders/EXRLoader'


// Import normal shader
// import tracerVert from './shaders/cartesianVert.glsl'
// import tracerFrag from './shaders/cartesianFrag.glsl'

// Import schwarzschild shader
// import tracerVert from './shaders/schwarzVert.glsl'
// import tracerFrag from './shaders/schwarzFrag.glsl'

// Import elliptical solution
import tracerVert from './shaders/fastVert.glsl'
import tracerFrag from './shaders/fastFrag.glsl'


function BlackHoleMesh() {
  return (
    <>
      <mesh>
        <meshStandardMaterial/>
        <sphereGeometry args={[1, 32, 32]}/>
      </mesh>
      <mesh rotation={[Math.PI / 2, 0, 0]}>
        <meshStandardMaterial side={THREE.DoubleSide}/>
        <ringGeometry args={[1.3, 3, 32, 1]}/>
      </mesh>
    </>
  )
}


function ShaderRec() {
  const { scene, camera, size } = useThree()
  const meshRef = useRef(null!)
  const rectRef = useRef(null!)
  const shMatRef = useRef(null!)
  const meshPos = useRef(new THREE.Vector3())
  const meshDim = useRef(new THREE.Vector2())

  useEffect(() => {
    const exrLoader = new EXRLoader();
    exrLoader.setDataType(THREE.FloatType)
    exrLoader.load('/final.exr', (texture) => {
      shMatRef.current.uniforms.lightTxt.value = texture
      // console.log(texture.image.data)
    })
  }, [])

  useFrame((state) => {
    // match post-processing mesh to camera
    let cameraDir = new THREE.Vector3()
    camera.getWorldDirection(cameraDir)
    let cameraLength = Math.sqrt(Math.pow(cameraDir.x, 2) + Math.pow(cameraDir.y, 2) +  Math.pow(cameraDir.z, 2))
    let cameraNorm = [cameraDir.x / cameraLength, cameraDir.y / cameraLength, cameraDir.z / cameraLength]
    meshRef.current.position.set(camera.position.x + cameraNorm[0] * .1, camera.position.y + cameraNorm[1] * .1, camera.position.z + cameraNorm[2] * .1)
    meshRef.current.rotation.set(camera.rotation.x, camera.rotation.y, camera.rotation.z)

    meshPos.current.copy(meshRef.current.position)
    meshDim.current.set(rectRef.current.parameters.width, rectRef.current.parameters.height)
  })

  return (
    <>
      <mesh ref={meshRef}>
        <shaderMaterial
          ref={shMatRef}
          uniforms={{
            meshPos: { value: meshPos.current },
            meshDim: { value: meshDim.current },
            lightTxt: { value: null }
          }}
          vertexShader={tracerVert}
          fragmentShader={tracerFrag}
        />
        <planeGeometry ref={rectRef} args={[size.width * .1/(size.height * 1.072), size.height * .1/(size.height * 1.072)]}/>
      </mesh>
    </>
  )
}


export default function Home() {
  return (
    <main className="bg-gray-700 h-[100vh]">
      <Canvas resize={{scroll: false}}>
        <PerspectiveCamera position={[10, 3, 0]} makeDefault fov={50}/>
        {/* <spotLight position={[10, 10, 10]} intensity={1000}/> */}
        {/* <BlackHoleMesh/> */}
        <ShaderRec/>
        <OrbitControls/>
      </Canvas>
    </main>
  );
}
