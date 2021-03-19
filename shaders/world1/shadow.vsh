#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#define WavingCrops
#define WavingFire
#define WavingPlant
#define WavingGrass
#define WavingLava
#define WavingLeaves
#define WavingLilypad
#define WavingTallPlant
#define WavingVines

#include "/global.glsl"
 
const float shadowMapBias = 1.0-25.6/shadowDistance;

varying float mat;
varying vec2 texcoord;
varying vec4 color;

attribute vec4 mc_midTexCoord;
attribute vec4 mc_Entity;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

#ifdef WorldTimeAnimation
float frametime = float(worldTime)/20.0*AnimationSpeed;
#else
float frametime = frameTimeCounter*AnimationSpeed;
#endif

#include "/lib/vertex/waving.glsl"

void main(){
	texcoord = gl_MultiTexCoord0.xy;
	
	mat = 0.0;

	float istopv = 0.0;
	if (gl_MultiTexCoord0.t < mc_midTexCoord.t) istopv = 1.0;

	vec4 position = shadowModelViewInverse * shadowProjectionInverse * ftransform();
	position.xyz += wavingBlocks(position.xyz,istopv);
	
	if (mc_Entity.x == 79) mat = 1.0;
	if (mc_Entity.x == 8) mat = 2.0;
	if (mc_Entity.x == 51) mat = 3.0;
	
	gl_Position = shadowProjection *  shadowModelView * position;

	float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	float distortFactor = (1.0f - shadowMapBias) + dist * shadowMapBias;
	
	gl_Position.xy *= (1.0f / distortFactor);
	gl_Position.z = gl_Position.z*0.2;
	
	color = gl_Color;
}
