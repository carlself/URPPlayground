Shader "Playground/Jellyfish"
{
    Properties
    {
        _Color1("Color1", Color) = (0.1, 0.4, 0.3, 1)
        _Color2("Color2", Color) = (0.3, 0.2, 0.5, 1)
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "RenderPipeline"="UniversalRenderPipeline"
            "Queue"="Transparent"
        }

        Pass
        {
            Tags {
                "LightMode"="UniversalForward"
            }


            Blend One One

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex JellyfishVertex
            #pragma fragment JellyfishFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../ShaderLibrary/Math.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _Color1;
                float4 _Color2;
            CBUFFER_END

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : NORMAL;
                float3 color : COLOR;
            };

            Varyings JellyfishVertex(Attributes IN)
            {
                float y = IN.positionOS.y;
                float mask = clamp(abs(3.6 - y), 1,3);
                float scale = 0.2 * sin(_TimeParameters.x * 3.0 + y * 3.0) * mask+1;
                
                float3 positionOS = IN.positionOS.xyz * float3(scale, 1, scale);
                float3 rotationAroundY = sin(_TimeParameters.x + y);
                Unity_RotateAboutAxis_Radians_float(positionOS, float3(0,1,0),rotationAroundY , positionOS);

                Varyings OUT;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(positionOS);
                OUT.positionCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS;

                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS);
                float3 normalWS = normalInputs.normalWS;
                Unity_RotateAboutAxis_Radians_float(normalWS, float3(0, 1,0),rotationAroundY, normalWS);
                OUT.normalWS = normalWS;

                OUT.color = lerp(_Color1, _Color2, saturate(y/3.6));
                return OUT;
            }

            float FresnelEffect(float3 normal, float3 viewDir, float power)
            {
                return pow(1.0 - saturate(dot(normal, viewDir)), power);
            }

            float4 JellyfishFragment(Varyings IN) : SV_Target
            {
                float3 viewDir = GetWorldSpaceViewDir(IN.positionWS);
                float fresnel = FresnelEffect(IN.normalWS, viewDir, 1.5) + 0.2;
                float3 color = IN.color * fresnel;
                return float4(color,1);
            }

            ENDHLSL
        }
    }
}
