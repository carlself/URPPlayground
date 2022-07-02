Shader "Playground/Water"
{
    Properties
    {
        _WaterColor ("Water Color", Color) = (0.2,0.3, 0.6, 1)
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
            Name "WaterPass"
            Tags {
                "LightMode"="UniversalForward"
            }



            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex WaterPassVertex
            #pragma fragment WaterPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "../ShaderLibrary/Noise.hlsl"
            #include "../ShaderLibrary/Math.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _WaterColor;
            CBUFFER_END

            struct Attributes {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 positionNDC : TEXCOORD1; // to get the real normalied screen space coordinate, divide by w in fragment shader 
                float3 positionWS : TEXCOORD2;
            };

            Varyings WaterPassVertex(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = positionInputs.positionCS;
                OUT.positionNDC = positionInputs.positionNDC;
                OUT.positionWS = positionInputs.positionWS;
                OUT.uv = IN.texcoord;

                return OUT;
            }

            float4 WaterPassFragment(Varyings IN):SV_TARGET 
            {
                float2 ndc = IN.positionNDC.xy/IN.positionNDC.w;
                float noise =  Unity_SimpleNoise(_TimeParameters.x * 0.1 + IN.uv, 100);
                noise = Remap(noise, 0, 1, -1, 1) * 0.02;
                // float3 sceneColor = SampleSceneColor(ndc + noise);
                float2 distortedUV = ndc + noise;
                float surfaceDepth = IN.positionNDC.w;
                float sceneDepth = LinearEyeDepth(SampleSceneDepth(distortedUV), _ZBufferParams);
                
                float2 uv = ndc;
                if(surfaceDepth < sceneDepth)
                {
                    uv = distortedUV;
                    // sceneColor = SampleSceneColor(ndc); 
                }
                float3 sceneColor = SampleSceneColor(uv);

                // caustic effect
                
                // screen texel world space
                float3 viewDir = GetWorldSpaceViewDir(IN.positionWS);
                float3 screenTexPos = viewDir/surfaceDepth * sceneDepth - GetCameraPositionWS();

                float angleOffset = _TimeParameters.x * 4;
                float voronoi;
                float cells;
                Unity_Voronoi_float(screenTexPos.xz, angleOffset, 1, voronoi, cells);
                voronoi = pow(voronoi, 5) * 0.5;
                sceneColor = sceneColor + voronoi;
                float3 color = lerp(sceneColor, _WaterColor.rgb, 0.5);
                return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}
