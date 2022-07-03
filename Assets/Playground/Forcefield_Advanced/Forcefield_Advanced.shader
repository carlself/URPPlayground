Shader "Playground/Forcefield_Advanced"
{
    Properties {
        _Color ("Color", Color) = (0.2, 0.3, 0.6,1)
        _ColorStrength("Color Strength", float) = 0.1
        _DistortionStrength("Distortion Strength", float) = 0.01
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

            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex ForcefieldVertex
            #pragma fragment ForcefieldFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"
            #include "../ShaderLibrary/Noise.hlsl"

            
            CBUFFER_START(UnityPerMaterial)
                float3 _Color;
                float _ColorStrength;
                float _DistortionStrength;
            CBUFFER_END

            struct Attributes {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float4 positionNDC : TEXCOORD1;
                float3 positionVS : TEXCOORD2;
                float3 normalWS : NORMAL;
            };

            Varyings ForcefieldVertex(Attributes IN)
            {
                Varyings OUT;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS;
                OUT.positionNDC = positionInputs.positionNDC;
                OUT.positionVS = positionInputs.positionVS;

                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS);
                OUT.normalWS = normalInputs.normalWS;

                return OUT;
            }

            float FresnelEffect(float3 normal, float3 viewDir, float power)
            {
                return pow((1.0 - saturate(dot(normalize(normal), normalize(viewDir)))), power);
            }


            uniform float _Points[6*4];

            void Ripple(float3 position, out float3 direction, out float strength)
            {
                float3 directionOutput = 0;
                float strengthOutput = 0;

                [unroll]
                for(int i = 0; i < 6*4; i += 4)
                {
                    float3 p = float3(_Points[i], _Points[i+1], _Points[i+2]);

                    float t = _Points[i+3]; // liftime

                    // ripple shape
                    float rippleSize = 1;
                    float gradient = smoothstep(t/3, t, distance(position, p)/rippleSize);

                    float ripple =  saturate(sin(5*gradient));//gradient* 0.2;// 

                    float3 rippleDirection = normalize(position - p);

                    float lifetimeFade = saturate(1-t);
                    float rippleStrength = lifetimeFade*ripple;

                    directionOutput += rippleDirection*rippleStrength * 0.2;
                    strengthOutput += rippleStrength;
                }

                direction = directionOutput;
                strength = strengthOutput;
            }

            float4 ForcefieldFragment(Varyings IN) : SV_Target
            {
                float2 ndc = IN.positionNDC.xy/IN.positionNDC.w;
                float3 viewDirWS = GetWorldSpaceViewDir(IN.positionWS);

                // noise
                float2 distortedVS = _TimeParameters.x * 0.1 + IN.positionVS.xy;
                float noise;
                Unity_GradientNoise_float(distortedVS, 25,  noise);
                noise = (noise - 0.5) * _DistortionStrength;
                
                // ripple
                float3 rippleDir;
                float rippleStrength;
                Ripple(IN.positionWS, rippleDir, rippleStrength);

                float3 rippleDirVS = TransformWorldToViewDir(rippleDir);
                float3 distortion = rippleDirVS + noise;
                float2 distortedUV = distortion.xy + ndc;

                // calculate world pos form scene depth
                float fragDepth = IN.positionNDC.w; 
                float sceneDepth = LinearEyeDepth(SampleSceneDepth(distortedUV), _ZBufferParams);
                float3 scenePos =  GetCameraPositionWS() - viewDirWS/fragDepth * sceneDepth;

                // fresnel effect
                float3 normalWS = normalize(IN.normalWS);
                float fresnel = FresnelEffect(normalWS, viewDirWS, 8) * 2;

                // intersection effect
                float3 objectPos = GetObjectToWorldMatrix()._m03_m13_m23;
                float dis = distance(scenePos, objectPos);
                float sphereRadius = 1;
                float intersection = pow(saturate(1 -  abs(dis - sphereRadius)), 15);

                float3 highlightColor = (intersection + fresnel + rippleStrength * 0.4) * _Color;


                float3 sceneColor = SampleSceneColor(distortedUV);
                float3 color =  lerp( sceneColor,_Color , _ColorStrength);
                color = color + highlightColor;

                return float4(color, 1);

            }
            ENDHLSL
        }
    }
}