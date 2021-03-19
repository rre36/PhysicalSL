vec2 blackoutlineoffset[12] = vec2[12](vec2(-2.0,2.0),vec2(-1.0,2.0),vec2(0.0,2.0),vec2(1.0,2.0),vec2(2.0,2.0),vec2(-2.0,1.0),vec2(-1.0,1.0),vec2(0.0,1.0),vec2(1.0,1.0),vec2(2.0,1.0),vec2(1.0,0.0),vec2(2.0,0.0));

vec3 blackoutline(sampler2D depth, vec3 color, float wfogmult){
	float ph = 1.0/1080.0;
	float pw = ph/aspectRatio;

	float outline = 1.0;
	float z = ld(texture2D(depth,texcoord.xy).r)*far*2.0;
	float minz = 1.0;
	float sampleza = 0.0;
	float samplezb = 0.0;

	for (int i = 0; i < 12; i++){
		sampleza = texture2D(depth,texcoord.xy+vec2(pw,ph)*blackoutlineoffset[i]).r;
		samplezb = texture2D(depth,texcoord.xy-vec2(pw,ph)*blackoutlineoffset[i]).r;
		outline *= clamp(1.0-(z-(ld(sampleza)+ld(samplezb))*far)*0.5,0.0,1.0);
		minz = min(minz,min(sampleza,samplezb));
	}
	
	vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord.x, texcoord.y, minz, 1.0) * 2.0 - 1.0);
	fragpos /= fragpos.w;

	vec3 fog = vec3(0.0);
	if(outline < 1.0){
		fog = calcFog(vec3(0.0),fragpos.xyz,blindness);
		
		if(isEyeInWater == 1.0){
			float b = clamp(blindness*2.0-1.0,0.0,1.0);
			b = 1.0-b*b;
			
			fog = calcWaterFog(fog, fragpos.xyz, water_c*b, cmult, wfogrange*wfogmult);
		}
	}

	return mix(fog,color,outline);
}

float blackoutlinemask(sampler2D depth0, sampler2D depth1){
	float ph = 1.0/540.0;
	float pw = ph/aspectRatio;

	float mask = 0.0;
	for (int i = 0; i < 12; i++){
		mask += float(texture2D(depth0,texcoord.xy+vec2(pw,ph)*blackoutlineoffset[i]).r < texture2D(depth1,texcoord.xy+vec2(pw,ph)*blackoutlineoffset[i]).r);
		mask += float(texture2D(depth0,texcoord.xy-vec2(pw,ph)*blackoutlineoffset[i]).r < texture2D(depth1,texcoord.xy-vec2(pw,ph)*blackoutlineoffset[i]).r);
	}

	return clamp(mask,0.0,1.0);
}