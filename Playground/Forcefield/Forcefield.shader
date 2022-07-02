Shader "Playground/Forcefield" {
    Properties {
        [MainColor]_Color ("Main Color", Color) = (1,1,1,1)
        _Power ("Power", Float) = 3
        _IntersectionPower("Intersection Power", Float) = 15
    }

    SubShader {
        Tags {
            "RenderType"="Transparent"
            "RenderPipeline"="UniversalRenderPipeline"
            "Queue"="Transparent"
        }

        Pass {
            Tags {
                "LightMode"="UniversalForward"
            }

            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex ForcefieldVertex
            #pragma fragment ForcefieldFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float _Power;
                float _IntersectionPower;
            CBUFFER_END

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };


            struct Varyings {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float4 positionNDC : TEXCOORD1;
                float3 normalWS : NORMAL;
            };

            Varyings ForcefieldVertex(Attributes IN) {
                Varyings OUT;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS;
                OUT.positionNDC = positionInputs.positionNDC;

                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS);
                OUT.normalWS = normalInputs.normalWS;

                return OUT;
            }

            float FresnelEffect(float3 normal, float3 viewDir, float power)
            {
                return pow(1.0 - saturate(dot(normal, viewDir)), power);
            }


            float4 ForcefieldFragment(Varyings IN, half facing : VFACE) : SV_TARGET{
                // fresnel
                float3 viewDir = GetWorldSpaceViewDir(IN.positionWS);
                float fresnel = FresnelEffect(IN.normalWS, viewDir, _Power);
                float alpha;
                if (facing > 0)
                {
                    alpha = fresnel * 2 + 0.02;
                }
                else
                {
                    alpha = 0;
                }

                // depth intersection effect
                float fragDepth = IN.positionNDC.w;
                float2 screenUV = IN.positionNDC.xy / IN.positionNDC.w; 
                float sceneDepth = LinearEyeDepth(SampleSceneDepth(screenUV), _ZBufferParams);

                float intersection = pow(1 - saturate(sceneDepth - fragDepth), _IntersectionPower);
                alpha = alpha + intersection;

                float3 color = _Color.rgb;
                return float4(color.rgb, alpha);
            }
            ENDHLSL
        }
    }
}