Shader "DepthLiquid/Translucent/FakeRefraction"
{
    Properties {
        _Color("Color", Color) = (1, 1, 1, 1)
        _Refraction("Refraction", Range (0, 1)) = 0.2
    }
    SubShader {
        Tags { "RenderType" = "Transparent"  "Queue" = "Transparent+997" }
        LOD 100
        GrabPass
        {
            "_RefractionTexture"
        }
        Pass { //outside
            Cull Back
            ZWrite Off
            //ZTest Always

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float4 grabPos : TEXCOORD0;
                float2 refractVec : TEXCOORD1;
                float refractStr : TEXCOORD2;
            };

            uniform float4 _Color;
            uniform float _Refraction;
            sampler2D _RefractionTexture;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos( v.vertex );
                o.grabPos = ComputeGrabScreenPos( o.vertex );

                float3 worldNorm = UnityObjectToWorldNormal(v.normal);
                float3 viewNorm = mul((float3x3)UNITY_MATRIX_V, worldNorm);
                float3 viewPos = UnityObjectToViewPos(v.vertex);
                float3 viewDir = normalize(viewPos);
                float3 viewCross = cross(viewDir, viewNorm);
                viewNorm = float3(-viewCross.y, viewCross.x, 0.0);
                o.refractVec = viewNorm.xy;
                o.refractStr = length(viewNorm.xy);
                return o;
            }

            float4 frag (v2f i) : SV_Target {
                float refractStr = (1 - clamp(i.refractStr, 0, 1)) * _Refraction;
                i.grabPos.x -= i.refractVec.x * refractStr;
                i.grabPos.y -= i.refractVec.y * refractStr;
                float4 bgcolor = tex2Dproj(_RefractionTexture, i.grabPos);

                return  bgcolor *_Color;
            }
            ENDCG
        }


    }
    FallBack "Diffuse"
}
