vec3 calcNormalFog(vec3 color, vec3 fragpos){
float fog = length(fragpos)/far*1.5;
fog = 1.0-exp(-6.0*fog*fog*fog);
return mix(color,nether_c*0.005,min(fog,1.0));
}