#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

#include "/global.glsl"

varying vec2 texcoord;

uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float aspectRatio;
uniform float blindness;
uniform float far;
uniform float frameTimeCounter;
uniform float near;
uniform float nightVision;
uniform float rainStrength;
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;

#ifdef RPSupport
uniform vec3 previousCameraPosition;

uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
#endif

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D noisetex;

#ifdef RPSupport
#ifdef ReflectSpecular
uniform sampler2D colortex3;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
#endif
#endif

#ifdef WorldTimeAnimation
float frametime = float(worldTime)/20.0*AnimationSpeed;
#else
float frametime = frameTimeCounter*AnimationSpeed;
#endif

float ld(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

#ifdef RPSupport
float getReflectionAlpha(sampler2D colortex, sampler2D depthtex, vec2 pos){
	return float(texture2D(depthtex, pos).r < 1.0);
}
#endif

#include "/lib/color/netherColor.glsl"
#include "/lib/color/torchColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/visual/ambientOcclusion.glsl"
#include "/lib/fog/netherFog.glsl"
#include "/lib/fog/commonFog.glsl"
#include "/lib/visual/promoOutline.glsl"

#ifdef BlackOutline
#include "/lib/fog/waterFog.glsl"
#include "/lib/visual/blackOutline.glsl"
#endif

#ifdef RPSupport
#include "/lib/rps/labMetal.glsl"
#include "/lib/visual/screenSpaceReflection.glsl"
#endif

void main(){
	vec4 color = texture2D(colortex0,texcoord.xy);
	float z = texture2D(depthtex0,texcoord.xy).r;
	
	//Dither
	#if defined AO || defined Clouds
	float dither = bayer64(gl_FragCoord.xy);
	#endif
	
	//NDC Coordinate
	vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, z, 1.0) * 2.0 - 1.0);
	fragpos /= fragpos.w;
	
	if (z < 1.0){
		//Specular Reflection
		#if defined RPSupport && defined ReflectSpecular
		float smoothness = texture2D(colortex3,texcoord.xy).r;
		float smoothness2 = smoothness * smoothness;
		float f0 = texture2D(colortex3,texcoord.xy).g;	
		vec3 normal = texture2D(colortex6,texcoord.xy).xyz*2.0-1.0;
		
		float fresnel = pow(clamp(1.0 + dot(normal, normalize(fragpos.xyz)),0.0,1.0),5.0);
		vec3 fresnel3 = vec3(mix(f0, 1.0, fresnel));
		#if SpecularFormat == 0
		if (f0 >= 0.9 && f0 < 1.0) fresnel3 = complexFresnel(fresnel, f0);
		#endif
		fresnel3 *= smoothness2;
		
		#ifdef ReflectRough
		vec2 noisecoord = texcoord.xy*vec2(viewWidth,viewHeight)/512.0;
		#if AA == 2
		noisecoord += fract(frameCounter*vec2(0.4,0.25));
		#endif
		#endif
		
		if (length(fresnel3) > 0.05 * length(color.rgb)){
			vec4 reflection = vec4(0.0);
			vec3 skyRef = nether_c*0.005;

			#ifdef ReflectPrevious
			#define colortexR colortex5
			#else
			#define colortexR colortex0
			#endif

			#ifdef ReflectRough
			if (smoothness >= 0.9) reflection = raytrace(colortexR,depthtex0,fragpos.xyz,normal,dither);
			else reflection = raytraceRough(colortexR,depthtex0,fragpos.xyz,normal,dither,1.0-smoothness,noisecoord);
			#else
			reflection = raytrace(colortexR,depthtex0,fragpos.xyz,normal,dither);
			#endif

			#ifdef ReflectPrevious
			reflection.rgb = pow(reflection.rgb*2.0,vec3(8.0));
			#endif
			
			reflection.rgb = mix(skyRef,reflection.rgb,reflection.a);
			
			vec3 spec = texture2D(colortex7,texcoord.xy).rgb;
			if (f0 >= 0.9){
				if (f0 == 1.0) fresnel3 = mix(spec * 0.8, vec3(1.0), fresnel) * smoothness2;
				color.rgb += reflection.rgb * fresnel3;
			}else{
				color.rgb = mix(color.rgb, reflection.rgb, fresnel3);
			}
		}
		#endif
		
		//Ambient Occlusion
		#ifdef AO
		color.rgb *= dbao(depthtex0, dither);
		#endif
		
		//Promo Art Outline
		#ifdef PromoOutline
		color.rgb = promooutline(color.rgb, depthtex0);
		#endif
		
		//Fog
		#ifdef Fog
		color.rgb = calcFog(color.rgb,fragpos.xyz, blindness);
		#endif
	}else{
		//Replace sky
		color.rgb = nether_c * 0.005;

		//Lava Fog
		if (isEyeInWater == 2){
			#ifdef EmissiveRecolor
			color.rgb = pow(Torch/TorchS,vec3(4.0))*2.0;
			#else
			color.rgb = vec3(1.0,0.3,0.01);
			#endif
		}
		
		//Blindness
		float b = clamp(blindness*2.0-1.0,0.0,1.0);
		b = b*b;
		if (blindness > 0.0) color.rgb *= 1.0-b;
	}
	
	//Black Outline
	#ifdef BlackOutline
	color.rgb = blackoutline(depthtex0, color.rgb, 1.0);
	#endif
	
/*DRAWBUFFERS:0*/
	gl_FragData[0] = color;
	#ifndef ReflectPrevious
/*DRAWBUFFERS:05*/
	gl_FragData[1] = vec4(pow(color.rgb,vec3(0.125)) * 0.5, float(z < 1.0));
	#endif
}
