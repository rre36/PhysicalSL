#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#include "/global.glsl"
 
varying float glz;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 normal;
varying vec3 upVec;

varying vec4 color;

uniform int worldTime;

uniform mat4 gbufferModelView;

#ifdef SoftParticle
uniform float far;
uniform float near;
#endif

#if AA == 2
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
#include "/lib/util/jitter.glsl"
#endif

#ifdef SoftParticle
float ld(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

float lgd(float depth){
	return -(2.0 * near / depth - (far + near)) / (far - near);
}
#endif

void main(){
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
	
	gl_Position = ftransform();
	
	glz = gl_Position.z/gl_Position.w;
	
	#ifdef SoftParticle
	gl_Position.z = ld(gl_Position.z/gl_Position.w) * (far - near);
	gl_Position.z -= 0.25;
	gl_Position.z = lgd(gl_Position.z / (far - near))*gl_Position.w;
	#endif
	
	#if AA == 2
	gl_Position.xy = taaJitter(gl_Position.xy,gl_Position.w);
	#endif
	
	color = gl_Color;
	
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = clamp((lmcoord - 0.03125) * 1.06667, 0.0, 1.0);

	normal = normalize(gl_NormalMatrix * gl_Normal);
	upVec = normalize(gbufferModelView[1].xyz);
}