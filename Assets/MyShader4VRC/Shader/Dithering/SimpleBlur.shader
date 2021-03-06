Shader "MS4VRC/Dither/Blur" {
    Properties {
        [KeywordEnum(BOX_2X2, BOX_3X3, BOX_4X4)]_BLUR("Box Size", Int) = 0
        _Blur_Edge("ON/OFF",Range(0,1)) = 0
    }
    SubShader {
        Tags { "RenderType"="Transparent" "Queue"="Transparent+998" "VRCFallback"="Hidden" }
        LOD 100
        Cull Front
        Ztest Always

        GrabPass{ "_BlurTexture" }

        Pass {
            Stencil {
                Ref 128
                Comp Equal
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _BLUR_BOX_2X2 _BLUR_BOX_3X3 _BLUR_BOX_4X4

            #include "UnityCG.cginc"

            #define ADD_OFFSET_BGCOLOR(x,y) bgcolor += tex2D(_BlurTexture, screenUV + float2(x, y))

            struct appdata {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float4 scrPos : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata v) {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeScreenPos(o.vertex);
                return o;
            }

            sampler2D _BlurTexture;
            float4 _BlurTexture_TexelSize;
            float _Blur_Edge;

            fixed4 frag (v2f i) : SV_Target {
                float2 screenUV = i.scrPos.xy / i.scrPos.w; 
                float2 texcelSize = _BlurTexture_TexelSize.xy;

                float4 bgcolor = tex2D(_BlurTexture, screenUV);
                #ifdef _BLUR_BOX_2X2
                ADD_OFFSET_BGCOLOR(texcelSize.x, texcelSize.y);
                ADD_OFFSET_BGCOLOR(texcelSize.x, 0);
                ADD_OFFSET_BGCOLOR(0, texcelSize.y);
                bgcolor /= 4;
                #elif _BLUR_BOX_3X3
                ADD_OFFSET_BGCOLOR(texcelSize.x, texcelSize.y);
                ADD_OFFSET_BGCOLOR(texcelSize.x, 0);
                ADD_OFFSET_BGCOLOR(texcelSize.x, -texcelSize.y);

                ADD_OFFSET_BGCOLOR(0, texcelSize.y);
                ADD_OFFSET_BGCOLOR(0, -texcelSize.y);

                ADD_OFFSET_BGCOLOR(-texcelSize.x, texcelSize.y);
                ADD_OFFSET_BGCOLOR(-texcelSize.x, 0);
                ADD_OFFSET_BGCOLOR(-texcelSize.x, -texcelSize.y);

                bgcolor /= 9;
                #elif _BLUR_BOX_4X4
                ADD_OFFSET_BGCOLOR(texcelSize.x, texcelSize.y);
                ADD_OFFSET_BGCOLOR(texcelSize.x, 0);
                ADD_OFFSET_BGCOLOR(texcelSize.x, -texcelSize.y);
                ADD_OFFSET_BGCOLOR(texcelSize.x, -2*texcelSize.y);

                ADD_OFFSET_BGCOLOR(0, texcelSize.y);
                ADD_OFFSET_BGCOLOR(0, -texcelSize.y);
                ADD_OFFSET_BGCOLOR(0, -2*texcelSize.y);

                ADD_OFFSET_BGCOLOR(-texcelSize.x, texcelSize.y);
                ADD_OFFSET_BGCOLOR(-texcelSize.x, 0);
                ADD_OFFSET_BGCOLOR(-texcelSize.x, -texcelSize.y);
                ADD_OFFSET_BGCOLOR(-texcelSize.x, -2*texcelSize.y);

                ADD_OFFSET_BGCOLOR(-2*texcelSize.x, texcelSize.y);
                ADD_OFFSET_BGCOLOR(-2*texcelSize.x, 0);
                ADD_OFFSET_BGCOLOR(-2*texcelSize.x, -texcelSize.y);
                ADD_OFFSET_BGCOLOR(-2*texcelSize.x, -2*texcelSize.y);

                bgcolor /= 16;
                #endif

                return bgcolor * (1 - _Blur_Edge) + tex2D(_BlurTexture, screenUV) * _Blur_Edge;
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
