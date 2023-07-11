Shader "SotosShaders/MyLit" {
	//Los subshaders te permiten diferentes comportamientos y opciones para diferentes pipelines y plataformas
	Properties{
		[Header(Surface options] // Creo un texto de cabezera
		[MainTexture] _ColorMap("Texture", 2D) = "red" {}
		[MainColor]_ColorTint("Tint", Color) = (1,1,1,1)
		_Smoothness("Smoothness", Float) = 0
		
		[HideInInspector] _SourceBlend("Source blend", Float) = 0
		[HideInInspector] _DestBlend("Destination blend", Float) = 0
		[HideInInspector] _ZWrite("ZWrite", Float) = 0
		[HideInInspector] _SurfaceType("Surface type", Float) = 0
	}
	SubShader{

		//estos tags se comparten por todos los pases en este subshaders
		Tags{"RenderPipeline" = "UniversalPipeline""RenderType" = "Transparent""Queue" = "Transparent"}

		//Cada pase tiene sus propias funciones de vertex y fragment además de diferentes palabras clave de shader
		Pass{
			Name"ForwardLit" //For debugging
			Tags{"LightMode" = "UniversalForward"} // Universal forward le dice a Unity que este será el pase principal para la luz de este shader

			Blend[_SourceBlend][_DestBlend]
			ZWrite[_ZWrite]
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			HLSLPROGRAM

			#define _SPECULAR_COLOR

			#if UNITY_VERSION >= 202120
				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
			#else
				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
				#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#endif
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			//Registro las funciones programables
			#pragma vertex Vertex
			#pragma fragment Fragment

			
			//Incluyo mi codigo hlsl
			#include "MyLitForwardLitPass.hlsl"

			ENDHLSL
		}  
		Pass{
			Name "ShadowCaster"
			Tags{"LightMode" = "ShadowCaster"}

			ColorMask 0

			HLSLPROGRAM
			#pragma vertex ShadowVertex
			#pragma fragment ShadowFragment
			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW


			#include "MylitShadowCasterPass.hlsl"
			ENDHLSL

		}
	}
}