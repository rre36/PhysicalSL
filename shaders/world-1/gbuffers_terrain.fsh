#version 120
#extension GL_ARB_shader_texture_lod : enable

/*
BSL Shaders by Capt Tatsu
https://www.bitslablab.com
*/

/*
Note : gbuffers_basic, gbuffers_entities, gbuffers_hand, gbuffers_terrain, gbuffers_textured, and gbuffers_water contains mostly the same code. If you edited one of these files, you need to do the same thing for the rest of the file listed.
*/

#include "/global.glsl"
 
varying float mat;
varying float recolor;

varying vec2 lmcoord;
varying vec2 texcoord;

varying vec3 normal;
varying vec3 upVec;

varying vec4 color;

#ifdef RPSupport
varying float dist;
varying vec3 binormal;
varying vec3 tangent;
varying vec3 viewVector;
varying vec4 vtexcoordam;
varying vec4 vtexcoord;
#endif

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

uniform sampler2D texture;

#ifdef RPSupport
uniform sampler2D specular;
uniform sampler2D normals;
#endif

#ifdef RPSupport
vec2 dcdx = dFdx(texcoord.xy);
vec2 dcdy = dFdy(texcoord.xy);
#endif

float luma(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

#include "/lib/color/netherColor.glsl"
#include "/lib/color/torchColor.glsl"
#include "/lib/util/spaceConversion.glsl"

#ifdef RPSupport
#include "/lib/rps/directionalLightmap.glsl"
#include "/lib/rps/parallax.glsl"
#endif

#if AA == 2
#include "/lib/util/jitter.glsl"
#endif

void main(){
	//Texture
	vec4 albedo = texture2D(texture, texcoord) * vec4(color.rgb,1.0);
	vec3 newnormal = normal;
	
	#ifdef RPSupport
	float pomfade = clamp((dist-POMDistance)/32.0,0.0,1.0);
	vec2 newcoord = vtexcoord.st*vtexcoordam.pq+vtexcoordam.st;
	
	#ifdef RPSPOM
	newcoord = getParallaxCoord(pomfade);
	if (mat < 2.98 || mat > 3.02) albedo = texture2DGradARB(texture, newcoord, dcdx, dcdy) * vec4(color.rgb,1.0);
	#endif
	
	float smoothness = 0.0;
	float f0 = 0.0;
	vec3 rawalbedo = vec3(0.0);
	#endif
	
	if (albedo.a > 0.0){
		//NDC Coordinate
		#if AA == 2
		vec3 fragpos = toNDC(vec3(taaJitter(gl_FragCoord.xy/vec2(viewWidth,viewHeight),-0.5),gl_FragCoord.z));
		#else
		vec3 fragpos = toNDC(vec3(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z));
		#endif
		
		//World Space Coordinate
		vec3 worldpos = toWorld(fragpos);
		
		#ifdef EmissiveRecolor
		vec3 rawtorch_c = Torch*Torch/TorchS;
		if (recolor > 0.9){
			float ec = length(albedo.rgb);
			albedo.rgb = clamp(ec*rawtorch_c*0.3+ec*0.3,vec3(0.0),vec3(2.2));
		}
		if (mat > 2.98 && mat < 3.02){
			float ec = clamp(pow(length(albedo.rgb),1.4),0,2.2);
			albedo.rgb = clamp(ec*rawtorch_c+ec*0.025,vec3(0),vec3(2.2));
		}
		#else
		if (recolor > 0.9) albedo.rgb *=  0.7;
		#endif
		
		//Specular & Normal Mapping
		#ifdef RPSupport
		vec4 specularmap = texture2DGradARB(specular, newcoord.xy, dcdx, dcdy);
		vec3 normalmap = texture2DGradARB(normals, newcoord.xy, dcdx, dcdy).xyz*2.0-1.0;

		#if SpecularFormat == 0	//labPBR
		smoothness = specularmap.r;
		f0 = specularmap.g;
		if (f0 < 0.9) f0 *= f0;
		#endif
		#if SpecularFormat == 1	//Old PBR
		smoothness = specularmap.r;
		if (specularmap.g >= 0.9) f0 = 1.0;
		else f0 = specularmap.g * 0.78 + 0.02;
		#endif
		#if SpecularFormat == 2	//Grayscale
		smoothness = specularmap.r;
		f0 = float(mat > 3.98 && mat < 4.02) * 0.98 + 0.02;
		#endif

		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							  tangent.y, binormal.y, normal.y,
							  tangent.z, binormal.z, normal.z);
		float normalcheck = normalmap.x + normalmap.y + normalmap.z;

		if (normalcheck > -2.999) newnormal = normalize(normalmap * tbnMatrix);
		#endif
		
		//Convert to linear color space
		albedo.rgb = pow(albedo.rgb, vec3(2.2));
		
		#ifdef DisableTexture
		albedo.rgb = vec3(0.5);
		#endif

		#ifdef RPSupport
		rawalbedo = albedo.rgb;
		#ifdef ReflectSpecular
		if (f0 >= 0.9) albedo.rgb *= (1.0 - smoothness) * (1.0 - smoothness);
		#endif
		#endif
		
		//Lightmap
		#ifdef LightmapBanding
		float torchmap = clamp(floor(lmcoord.x*14.999 * (0.75 + 0.25 * color.a)) / 14, 0.0, 1.0);
		#else
		float torchmap = clamp(lmcoord.x, 0.0, 1.0);
		#endif

		//Directional Lightmap
		#ifdef RPSupport
		#ifdef RPSLightmap
		mat3 lmTBN = mat3(normalize(dFdx(fragpos)),normalize(dFdy(fragpos)),vec3(0.0));
		lmTBN[2] = cross(lmTBN[0], lmTBN[1]);

		torchmap = directionalLightmap(torchmap,lmcoord.x,newnormal,lmTBN);
		#endif
		#endif
		
		//Material Flag
		float foliage = float(mat > 0.98 && mat < 1.02);
		float emissive = float(mat > 1.98 && mat < 2.02) * EmissiveBrightness;
		float lava = float(mat > 2.98 && mat < 3.02);
		
		#ifdef RPSupport
		#if SpecularFormat == 0
		if (specularmap.a < 1.0) emissive = specularmap.a * EmissiveBrightness;
		else emissive = 0.0;
		#endif
		#endif
		
		//Shadows
		float quarterNdotU = clamp(0.25 * dot(normal, upVec) + 0.75,0.5,1.0);
		quarterNdotU *= quarterNdotU;
		if (foliage > 0.5) quarterNdotU *= 1.8;
		
		//Lighting Calculation
		vec3 scenelight = nether_c*0.1;
		float newtorchmap = pow(torchmap,10.0)*(EmissiveBrightness+0.5)+(torchmap*0.7);
		
		vec3 blocklight = (newtorchmap * newtorchmap) * torch_c;
		#ifdef LightmapBanding
		scenelight *= floor(color.a*4.0+0.8)/4.0;
		float minlight = (0.009*screenBrightness + 0.001)*floor(color.a*4.0+0.8)/4.0;
		float sl = 1.0;
		#else
		float minlight = (0.009*screenBrightness + 0.001);
		float sl = color.a * color.a;
		#endif

		vec3 emissivelight = albedo.rgb * luma(albedo.rgb) * ((emissive + lava) * 4.0 / quarterNdotU);
		
		vec3 finallight = (scenelight + blocklight + emissivelight + nightVision + minlight) * sl;
		albedo.rgb *= finallight * quarterNdotU;

		//Material AO
		#ifdef RPSupport
		#if SpecularFormat == 0
		float ao = clamp(length(normalmap), 0.0, 1.0);
		albedo.rgb *= ao * ao;
		#endif
		#endif
		
		//Desaturation
		#ifdef Desaturation
		float desat = clamp(sqrt(torchmap + emissive), DesaturationFactor * 0.4, 1.0);
		vec3 desat_c = nether_c*0.2*(1.0-desat);
		albedo.rgb = mix(luma(albedo.rgb)*desat_c*10.0,albedo.rgb,desat);
		#endif
	}
	
/* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
	#if defined RPSupport && defined ReflectSpecular
/* DRAWBUFFERS:0367 */
	gl_FragData[1] = vec4(smoothness,f0,0.0,1.0);
	gl_FragData[2] = vec4(newnormal*0.5+0.5,1.0);
	gl_FragData[3] = vec4(rawalbedo,1.0);
	#endif
}