vec3 getFogColor(vec3 fragpos){
vec3 fog_col = fog_c;
vec3 nfragpos = normalize(fragpos);
float lfragpos = length(fragpos)/64.0;
lfragpos = 1.0-exp(-lfragpos*lfragpos);

float NdotU = clamp(dot(nfragpos,upVec),0.0,1.0);
float NdotS = dot(nfragpos,sunVec)*0.5+0.5;

float lightmix = NdotS*NdotS*(1-NdotU)*(pow(1.0-timeBrightness,3.0)*0.9+0.1)*(1.0-rainStrength)*lfragpos*eBS;

fog_col = mix(fog_col*(1.0-sqrt(lightmix)),light*sqrt(light),lightmix) * sunVisibility + (light_n*light_n*0.4);
fog_col = mix(fog_col,weather*weather*luma(ambient/(weather*weather))*0.9,rainStrength)*0.3;

return pow(fog_col,vec3(1.125));
}

vec3 calcNormalFog(vec3 color, vec3 fragpos){
float fog = length(fragpos)/(FogRange*50.0*(sunVisibility*0.5+1.5))*(1.5*rainStrength+1.0)*eBS;
fog = 1.0-exp(-2.0*fog*mix(sqrt(fog),1.0,rainStrength));
return mix(color,getFogColor(fragpos),fog);
}