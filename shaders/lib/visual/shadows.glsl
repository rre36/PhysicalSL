uniform sampler2DShadow shadowtex0;
#ifdef ShadowColor
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
#endif

/*
uniform sampler2D shadowtex0;
#ifdef ShadowColor
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
#endif
*/

vec2 shadowoffsets[8] = vec2[8](    vec2( 0.0, 1.0),
                                    vec2( 0.7, 0.7),
                                    vec2( 1.0, 0.0),
                                    vec2( 0.7,-0.7),
                                    vec2( 0.0,-1.0),
                                    vec2(-0.7,-0.7),
                                    vec2(-1.0, 0.0),
                                    vec2(-0.7, 0.7));

/*
float texture2DShadow(sampler2D shadowtex, vec3 shadowpos){
    float shadow = texture2D(shadowtex,shadowpos.st).x;
    shadow = clamp((shadow-shadowpos.z)*65536.0,0.0,1.0);
    return shadow;
}
*/

vec2 offsetDist(float x, int s){
	float n = fract(x*1.414)*3.1415;
    return vec2(cos(n),sin(n))*1.4*x/s;
}

vec3 getBasicShadow(vec3 shadowpos){
    float shadow0 = shadow2D(shadowtex0,vec3(shadowpos.st, shadowpos.z)).x;
    //float shadow = texture2DShadow(shadowtex0,vec3(shadowpos.st, shadowpos.z));

    vec3 shadowcol = vec3(0.0);
    #ifdef ShadowColor
    float shadow1 = shadow2D(shadowtex1,vec3(shadowpos.st, shadowpos.z)).x;
    //float shadow1 = texture2DShadow(shadowtex1,vec3(shadowpos.st, shadowpos.z));
    if (shadow0 < 1.0 && shadow1 > 0.0) shadowcol = texture2D(shadowcolor0,shadowpos.st).rgb * shadow1;
    #endif

    return shadowcol * (1.0-shadow0) + shadow0;
}

vec3 getFilteredShadow(vec3 shadowpos, float step){
    vec3 shadow = getBasicShadow(vec3(shadowpos.st, shadowpos.z))*2.0;

    for(int i = 0; i < 8; i++){
        shadow+= getBasicShadow(vec3(step * shadowoffsets[i] + shadowpos.st, shadowpos.z));
    }

    return shadow * 0.1;
}

vec3 getTAAFilteredShadow(vec3 shadowpos, float step){
    float noise = gradNoise();

    vec3 shadow = vec3(0.0);

    for(int i = 0; i < 2; i++){
        vec2 offset = offsetDist(noise+i,2)*step;
        shadow += getBasicShadow(vec3(shadowpos.st+offset, shadowpos.z));
        shadow += getBasicShadow(vec3(shadowpos.st-offset, shadowpos.z));
    }
    
    return shadow * 0.25;
}

vec3 getShadow(vec3 shadowpos, float step){
    #ifdef ShadowFilter
    #if AA == 2
    vec3 shadow = getTAAFilteredShadow(shadowpos, step);
    #else
    vec3 shadow = getFilteredShadow(shadowpos, step);
    #endif
    #else
    vec3 shadow = getBasicShadow(shadowpos);
    #endif

    return shadow;
}