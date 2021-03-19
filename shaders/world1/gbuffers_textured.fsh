#version 120

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

/*
Note : gbuffers_basic, gbuffers_entities, gbuffers_hand, gbuffers_terrain, gbuffers_textured, and gbuffers_water contains mostly the same code. If you edited one of these files, you need to do the same thing for the rest of the file listed.
*/

#include "/global.glsl"
 
const float shadowMapBias = 1.0-25.6/shadowDistance;

varying float glz;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 normal;
varying vec3 upVec;
varying vec3 sunVec;

varying vec4 color;

uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float frameTimeCounter;
uniform float nightVision;
uniform float rainStrength;
uniform float screenBrightness; 
uniform float viewWidth;
uniform float viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

#ifdef SoftParticle
uniform float far;
uniform float near;
#endif

uniform sampler2D texture;

#ifdef SoftParticle
uniform sampler2D depthtex0;
#endif

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float gradNoise(){
	return fract(52.9829189*fract(0.06711056*gl_FragCoord.x + 0.00583715*gl_FragCoord.y)+frameCounter/8.0);
}

#ifdef SoftParticle
float ld(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

float lgd(float depth){
	return -(2.0 * near / depth - (far + near)) / (far - near);
}
#endif

#include "/lib/color/endColor.glsl"
#include "/lib/color/torchColor.glsl"
#include "/lib/visual/shadows.glsl"
#include "/lib/util/spaceConversion.glsl"

#if AA == 2
#include "/lib/util/jitter.glsl"
#endif

#ifdef SoftParticle
#include "/lib/util/dither.glsl"
#endif

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord) * color;
	
	if (albedo.a > 0.0){
		//NDC Coordinate
		#if AA == 2
		vec3 fragpos = toNDC(vec3(taaJitter(gl_FragCoord.xy/vec2(viewWidth,viewHeight),-0.5),glz*0.5+0.5));
		#else
		vec3 fragpos = toNDC(vec3(gl_FragCoord.xy/vec2(viewWidth,viewHeight),glz*0.5+0.5));
		#endif
		
		//World Space Coordinate
		vec3 worldpos = toWorld(fragpos);
		
		//Convert to linear color space
		albedo.rgb = pow(albedo.rgb, vec3(2.2));
		
		#ifdef DisableTexture
		albedo.rgb = vec3(0.5);
		#endif
		
		//Lightmap
		#ifdef LightmapBanding
		float torchmap = clamp(floor(lmcoord.x*14.999) / 14, 0.0, 1.0);
		#else
		float torchmap = clamp(lmcoord.x, 0.0, 1.0);
		#endif
		
		//Shadows
		vec3 shadow = vec3(0.0);
		
		float NdotL = 1.0;
		
		//Apply diffuse (uncomment)
		//NdotL = clamp(dot(normal,sunVec)*1.01-0.01,0.0,1.0);
		
		worldpos = toShadow(worldpos);
		
		float distb = sqrt(worldpos.x * worldpos.x + worldpos.y * worldpos.y);
		float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
		
		worldpos.xy /= distortFactor;
		worldpos.z *= 0.2;
		worldpos = worldpos*0.5+0.5;
		
			float diffthresh = 0.00004;
			float step = 1.0/shadowMapResolution;

			worldpos.z -= diffthresh;
			
			shadow = getShadow(worldpos, step);

		
		vec3 fullshading = shadow * NdotL;
		
		//Lighting Calculation
		vec3 scenelight = mix(end_c*0.025, end_c*0.1, fullshading);
		float newtorchmap = pow(torchmap,10.0)*(EmissiveBrightness+0.5)+(torchmap*0.7);
		
		vec3 blocklight = (newtorchmap * newtorchmap) * torch_c;
		float minlight = (0.009*screenBrightness + 0.001);
		
		vec3 finallight = scenelight + blocklight + nightVision + minlight;
		albedo.rgb *= finallight;
		
		//Desaturation
		#ifdef Desaturation
		float desat = clamp(sqrt(torchmap), DesaturationFactor * 0.4, 1.0);
		vec3 desat_c = end_c*0.125*(1.0-desat);
		albedo.rgb = mix(luma(albedo.rgb)*desat_c*10.0,albedo.rgb,desat);
		#endif
	}

	//Soft Particles
	#ifdef SoftParticle
	float z = ld(gl_FragCoord.z) * (far - near);
	float bz = ld(texture2D(depthtex0, gl_FragCoord.xy / vec2(viewWidth, viewHeight)).r) * (far - near);
	float dz = clamp(bz - z,0.0,1.0);
	dz = dz * dz * (3.0 - 2.0 * dz);

	if(albedo.a > 0.999) albedo.a *= float(dz > fract(bayer64(gl_FragCoord.xy) + frameTimeCounter * 8.0));
	else albedo.a *= dz;
	#endif
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
	#ifdef RPSupport
	#ifdef ReflectSpecular
/* DRAWBUFFERS:0367 */
	gl_FragData[1] = vec4(0.0,0.0,0.0,1.0);
	gl_FragData[2] = vec4(0.0,0.0,0.0,1.0);
	gl_FragData[3] = vec4(0.0,0.0,0.0,1.0);
	#endif
	#endif
}