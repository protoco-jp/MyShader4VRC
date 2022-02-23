﻿Shader "Dither/Dither" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR] _Color ("Color", Color) = (1,1,1,1)
        [KeywordEnum(NONE, BAYER, IGN, WHITE)]_NOISE("Noise Keyword", Float) = 0
        _BayerTex ("Texture", 2D) = "white" {}
        _Offset("Noise Offset", Range(0,1)) = 0.5
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _NOISE_NONE _NOISE_BAYER _NOISE_WHITE _NOISE_IGN
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 scrPos : TEXCOORD1;
            };

            uniform float4 _Color;
            uniform float _Offset;
            sampler2D _BayerTex;
            float4 _BayerTex_TexelSize;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.scrPos = ComputeScreenPos(o.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float3 frag (v2f i) : SV_Target {
                float4 col = tex2D(_MainTex, i.uv) * _Color;
                #ifdef _NOISE_BAYER //bayer matrix
                    float2 screenUV = (i.scrPos.xy / i.scrPos.w) * (_ScreenParams.xy / _BayerTex_TexelSize.zw) + _Offset;
                    float threshold = clamp(tex2D( _BayerTex, screenUV ).r, 0.001, 0.999);
                #elif _NOISE_WHITE //white noise
                    float2 screenUV = (i.scrPos.xy / i.scrPos.w) * _ScreenParams.xy;
                    float threshold = frac(sin(dot(screenUV, fixed2(12.9898,78.233))) * 43758.5453);
                #elif _NOISE_IGN //Interleaved Gradient Noise (CoD Dither)
                    float2 screenUV = (i.scrPos.xy / i.scrPos.w) * _ScreenParams.xy + _Offset;
                    float3 magic = float3(0.06711056,0.00583715,52.9829189);
                    float threshold = frac(magic.z * frac(dot(screenUV,magic.xy)));
                #endif
                #ifndef _NOISE_NONE
                    clip(_Color.a - threshold);
                #endif

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col.rgb;
            }
            ENDCG
        }
    }
}
