Shader "MS4VRC/SimpleBlur" {
    Properties {
        _Blur("Blur Size",Range(1,10)) = 1
    }
    SubShader {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent+999" }
        LOD 100

        GrabPass{ "_BlurTexture" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float4 scrPos : TEXCOORD0;
            };

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeScreenPos(o.vertex);
                return o;
            }

            uniform float _Blur;
            sampler2D _BlurTexture;
            float4 _BlurTexture_TexelSize;

            fixed4 frag (v2f i) : SV_Target {
                float2 screenUV = i.scrPos.xy / i.scrPos.w; 
                float2 texcelSize = _BlurTexture_TexelSize.xy * _Blur;
                float4 bgcolor = tex2D(_BlurTexture,  screenUV);

                bgcolor += tex2D(_BlurTexture, screenUV + float2(texcelSize.x, 0));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(-texcelSize.x, 0));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(0, texcelSize.y));
                bgcolor += tex2D(_BlurTexture, screenUV + float2(0, -texcelSize.y));
                bgcolor += tex2D(_BlurTexture, screenUV + 0.7*float2(texcelSize.x, texcelSize.y));
                bgcolor += tex2D(_BlurTexture, screenUV + 0.7*float2(texcelSize.x, -texcelSize.y));
                bgcolor += tex2D(_BlurTexture, screenUV + 0.7*float2(-texcelSize.x, texcelSize.y));
                bgcolor += tex2D(_BlurTexture, screenUV + 0.7*float2(-texcelSize.x, -texcelSize.y));
                bgcolor /= 9;
                return bgcolor;
            }
            ENDCG
        }
    }
}
