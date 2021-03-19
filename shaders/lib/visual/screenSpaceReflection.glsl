const int maxf = 4;				//number of refinements
const float stp = 1.0;			//size of one step for raytracing algorithm
const float ref = 0.1;			//refinement multiplier
const float inc = 2.0;			//increasement factor at each step

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}

vec4 raytrace(sampler2D colortex, sampler2D depthtex, vec3 fragpos, vec3 normal, float dither) {
    vec4 color = vec4(0.0);
	#if AA == 2
	dither = fract(dither + frameTimeCounter);
	#endif

    vec3 start = fragpos;
    vec3 vector = stp * reflect(normalize(fragpos), normalize(normal));
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
	float border = 0.0;
	vec3 pos = vec3(0.0);

    for(int i=0;i<30;i++){
        pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
		if (pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1) break;
		vec3 rfragpos = vec3(pos.xy, texture2D(depthtex,pos.xy).r);
        rfragpos = nvec3(gbufferProjectionInverse * nvec4(rfragpos * 2.0 - 1.0));
        float err = length(fragpos - rfragpos);
		float cor = pow(length(vector) * pow(length(tvector), 0.1), 1.1) * 1.5;
		if (err < cor){
                sr++;
                if (sr >= maxf) break;
				tvector -=vector;
                vector *=ref;
		}
        vector *= inc;
        tvector += vector * (dither * 0.05 + 0.975);
		fragpos = start + tvector;
    }
	
	border = clamp(1.0 - pow(cdist(pos.st), 50.0), 0.0, 1.0);
	
	if (pos.z <1.0-1e-5){
		#ifdef ReflectPrevious
		//Previous frame reprojection from Chocapic13
		vec4 fragpositionPrev = gbufferProjectionInverse * vec4(pos*2.0-1.0,1.);
		fragpositionPrev /= fragpositionPrev.w;
		
		fragpositionPrev = gbufferModelViewInverse * fragpositionPrev;

		vec4 previousPosition = fragpositionPrev + vec4(cameraPosition-previousCameraPosition,0.0);
		previousPosition = gbufferPreviousModelView * previousPosition;
		previousPosition = gbufferPreviousProjection * previousPosition;
		pos.xy = previousPosition.xy/previousPosition.w*0.5+0.5;
		#endif

		color.a = getReflectionAlpha(colortex, depthtex, pos.st);
		if (color.a > 0.5) color.rgb = texture2D(colortex, pos.st).rgb;
		
		color.a *= border;
	}
	
    return color;
}

vec4 raytraceRough(sampler2D colortex, sampler2D depthtex, vec3 fragpos, vec3 normal, float dither, float r, vec2 noisecoord){
	vec4 color = vec4(0.0);
	int steps = 1 + int(4 * r);
	r *= r;

	for(int i = 0; i < steps; i++){
		vec3 noise = vec3(texture2D(noisetex, vec2(0.19,0.17) * i + noisecoord).xy * 2.0 - 1.0, 0.0);
		noise.xy *= 0.7*r;
		noise.z = 1.0 - (noise.x * noise.x + noise.y * noise.y);

		vec3 tangent = normalize(cross(gbufferModelView[1].xyz, normal));
		mat3 tbnMatrix = mat3(tangent, cross(normal, tangent), normal);

		vec3 rnormal = normalize(tbnMatrix * noise);
		
		color += raytrace(colortex, depthtex, fragpos, rnormal, dither);
	}
	color /= steps;
	
	return color;
}