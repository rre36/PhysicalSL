#define LightmapDirStrength 1.0 //[2.0 1.4 1.0 0.7 0.5]

float directionalLightmap(float lm, float lmcoord, vec3 normal, mat3 lmTBN){
    if (lm < 0.001) return lm;

    vec2 deriv = vec2(dFdx(lmcoord),dFdy(lmcoord))*256.0;
    vec3 dir = normalize(vec3(deriv.x * lmTBN[0] + 0.0005 * lmTBN[2] + deriv.y * lmTBN[1]));
    
    float pwr = clamp(dot(normal,dir),-1.0,1.0);
    if (abs(pwr) > 0) pwr = pow(abs(pwr),LightmapDirStrength)*sign(pwr)*lm;
    if (length(deriv) > 0.001) lm = pow(lm,1.0-pwr);

	return lm;
}