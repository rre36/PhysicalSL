vec3 calcNormalFog(vec3 color, vec3 fragpos){
float fog = length(fragpos)/(16.0*FogRange);
fog = 1.0-exp(-0.8*fog*fog);
return mix(color,end_c*0.025,fog);
}