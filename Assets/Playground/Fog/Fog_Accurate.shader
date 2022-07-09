Shader "Playground/Fog_Accurate"
{
	Properties
	{
		_FogColor("Fog Color", Color) = (1,1,1,1)
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

			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex FogVertex
			#pragma fragment FogFragment

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

			CBUFFER_START(UnityPerMaterial)
			float4 _FogColor;
			CBUFFER_END
			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				float4 positionNDC : TEXCOORD1;
				float3 normalOS : NORMAL;
			};

			Varyings FogVertex(Attributes IN)
			{
				Varyings OUT;
				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.positionCS = positionInputs.positionCS;
				OUT.positionWS = positionInputs.positionWS;
				OUT.positionNDC = positionInputs.positionNDC;
				OUT.normalOS = IN.normalOS;

				return OUT;
			}

			float4 FogFragment(Varyings IN) : SV_TARGET
			{
				float sceneDepth = LinearEyeDepth(SampleSceneDepth(IN.positionNDC.xy / IN.positionNDC.w), _ZBufferParams);
				float3 viewDirWS = GetWorldSpaceViewDir(IN.positionWS);
				float3 scenePosWS = GetCameraPositionWS() - viewDirWS / IN.positionNDC.w * sceneDepth;
				float3 scenePosOS = TransformWorldToObject(scenePosWS);
				float alpha = saturate(-dot(scenePosOS, IN.normalOS));

				return float4(_FogColor.rgb, alpha);
			}
			ENDHLSL
		}
	}
}