Shader "Playground/Fog_Simple"
{
	Properties
	{
		_FogColor("Fog Color", Color) = (1,1,1,1)
		_FogDensity("Fog Density", float) = 0.5
	}

		SubShader

	{
		Tags
		{
			"RenderPipeline" = "UniversalRenderpipeline"
			"Queue" = "Transparent"
			"RenderType" = "Transparent"
		}

		Pass
		{
			Tags {"LightMode" = "UniversalForward"}

			ZWrite Off
			ZTest LEqual
			Blend SrcAlpha OneMinusSrcAlpha

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex FogVertex
			#pragma fragment FogFragment
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float4 _FogColor;
			float _FogDensity;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS : POSITION;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float4 positionNDC : TEXCOORD0;
			};

			Varyings FogVertex(Attributes IN)
			{
				Varyings OUT;
				
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.positionNDC = positionInputs.positionNDC;

				return OUT;
			}

			float4 FogFragment(Varyings IN) : SV_TARGET
			{
				float sceneDepth = LinearEyeDepth(SampleSceneDepth(IN.positionNDC.xy / IN.positionNDC.w), _ZBufferParams);
				float fragDepth = IN.positionNDC.w;

				float alpha = saturate((sceneDepth - fragDepth) * _FogDensity);

				return float4(_FogColor.rgb, alpha);
			}
			
			ENDHLSL
			

		}
	}
}