#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#include "/global.glsl"
 
varying float mat;
varying float recolor;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 normal;
varying vec3 upVec;
varying vec3 sunVec;

varying vec4 color;

#ifdef RPSupport
varying float dist;
varying vec3 binormal;
varying vec3 tangent;
varying vec3 viewVector;
varying vec4 vtexcoordam;
varying vec4 vtexcoord;
attribute vec4 at_tangent;
#endif

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform int worldTime;

uniform float frameTimeCounter;
uniform float nightVision;
uniform float rainStrength;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;


#ifdef WorldTimeAnimation
float frametime = float(worldTime)/20.0*AnimationSpeed;
#else
float frametime = frameTimeCounter*AnimationSpeed;
#endif

#include "/lib/vertex/waving.glsl"

#if AA == 2
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
#include "/lib/util/jitter.glsl"
#endif

void main(){
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
	
	mat = 0.0;
	recolor = 0.0;
	
	float istopv = 0.0;
	if (gl_MultiTexCoord0.t < mc_midTexCoord.t) istopv = 1.0;
	
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	position.xyz += wavingBlocks(position.xyz,istopv);
	
	//Foliage
	if (mc_Entity.x == 31 || mc_Entity.x == 6 || mc_Entity.x == 59 || mc_Entity.x == 175 || mc_Entity.x == 176 || mc_Entity.x == 18 || mc_Entity.x == 106 || mc_Entity.x == 111 || mc_Entity.x == 83 || mc_Entity.x == 104)
	mat = 1.0;
	//Emissive
	if (mc_Entity.x == 55 || mc_Entity.x == 213 || mc_Entity.x == 76 || mc_Entity.x == 50 || mc_Entity.x == 91 || mc_Entity.x == 89 || mc_Entity.x == 51) mat = 2.0;
	//Lava
	if (mc_Entity.x == 10) mat = 3.0;
	//Metals	
	if (mc_Entity.x == 42) mat = 4.0;
	//Recolor
	if (mc_Entity.x == 213 || mc_Entity.x == 89 || mc_Entity.x == 138.0) recolor = 1.0;
	
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	
	#if AA == 2
	gl_Position.xy = taaJitter(gl_Position.xy,gl_Position.w);
	#endif
	
	color = gl_Color;
	//Lectern Fix
	if (mc_Entity.x == 300) color.a = 1;
	
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = clamp((lmcoord - 0.03125) * 1.06667, 0.0, 1.0);
	
	//Fix Lightmap
	if (mc_Entity.x == 91 || mc_Entity.x == 89 || mc_Entity.x == 10 || mc_Entity.x == 51) lmcoord.x = 1.0;
	if (mc_Entity.x == 62) lmcoord.x -= 0.0667;

	normal = normalize(gl_NormalMatrix * gl_Normal);
	//Sun position fix from Builderb0y
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = 0.0;
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	
	upVec = normalize(gbufferModelView[1].xyz);
	//sunVec = normalize(sunPosition);
	
	#ifdef RPSupport
	vec2 midcoord = (gl_TextureMatrix[0] *  mc_midTexCoord).st;
	vec2 texcoordminusmid = texcoord-midcoord;
	vtexcoordam.pq  = abs(texcoordminusmid)*2;
	vtexcoordam.st  = min(texcoord,midcoord-texcoordminusmid);
	vtexcoord.xy    = sign(texcoordminusmid)*0.5+0.5;
	
	tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
						  tangent.y, binormal.y, normal.y,
						  tangent.z, binormal.z, normal.z);
								  
	viewVector = ( gl_ModelViewMatrix * gl_Vertex).xyz;
	viewVector = (tbnMatrix * viewVector);
	
	dist = length(gl_ModelViewMatrix * gl_Vertex);
	#endif
}