// Trae las funciones de la biblioteca URP y nuestras propias funciones comunes
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

float4 _ColorTint;

TEXTURE2D(_ColorMap); SAMPLER(sampler_ColorMap); // RGB = albedo, A = alpha

float4 _ColorMap_ST; // This is automatically set by Unity. Used in TRANSFORM_TEX to apply UV tiling
float _Smoothness;

// Esta estructura de atributos recibe datos sobre la malla que estamos renderizando actualmente
// Los datos se colocan automáticamente en los campos según su semántica
struct Attributes {
	float3 positionOS : POSITION; // Posicion en object space
	float2 uv : TEXCOORD0;
	float3 normalOS : NORMAL;
};

// This struct is output by the vertex function and input to the fragment function.
// Note that fields will be transformed by the intermediary rasterization stage
struct Interpolators {
	// This value should contain the position in clip space (which is similar to a position on screen)
	// when output from the vertex function. It will be transformed into pixel position of the current
	// fragment on the screen when read from the fragment function
	float4 positionCS : SV_POSITION;
	float2 uv : TEXCOORD0; //material texture uvs
	float3 positionWS: TEXCOORD1;
	float3 normalWS : TEXCOORD2;
};

// The vertex function. This runs for each vertex on the mesh.
// It must output the position on the screen each vertex should appear at,
// as well as any data the fragment function will need
Interpolators Vertex(Attributes input) {
	Interpolators output;

	// These helper functions, found in URP/ShaderLib/ShaderVariablesFunctions.hlsl
	// transform object space values into world and clip space
	VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
	VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS);

	// Pass position and orientation data to the fragment function
	output.positionCS = posnInputs.positionCS;
	output.uv = TRANSFORM_TEX(input.uv, _ColorMap);
	output.positionWS = posnInputs.positionWS;
	output.normalWS = normInputs.normalWS;

	return output;
}

// The fragment function. This runs once per fragment, which you can think of as a pixel on the screen
// It must output the final color of this pixel
float4 Fragment(Interpolators input) : SV_TARGET{
	float2 uv = input.uv;

	float4 colorSample = SAMPLE_TEXTURE2D(_ColorMap, sampler_ColorMap, uv);

	InputData lightingInput = (InputData)0;
	lightingInput.positionWS = input.positionWS;
	lightingInput.normalWS = normalize(input.normalWS);
	lightingInput.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
	lightingInput.shadowCoord = TransformWorldToShadowCoord(input.positionWS);

	SurfaceData surfaceInput = (SurfaceData)0;
	surfaceInput.albedo = colorSample.rgb * _ColorTint.rgb;
	surfaceInput.alpha = colorSample.a * _ColorTint.a;
	surfaceInput.specular = 1;
	surfaceInput.smoothness = _Smoothness;

	#if UNITY_VERSION >= 202120 
		return UniversalFragmentBlinnPhong(lightingInput, surfaceInput);
	#else
		return UniversalFragmentBlinnPhong(lightingInput, surfaceInput.albedo, float4(surfaceInput.specular, 1), surfaceInput.smoothness, surfaceInput.emission, surfaceInput.alpha);
	#endif	
}