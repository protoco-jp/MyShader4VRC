Shader "MS4VRC/Transparent/DepthLiquid"
{
    Properties {
        _Color("Color", Color) = (0.5,0.5,0.5,1)
        _Fade("Fade", Float) = 0.5
    }
    SubShader {
        Tags { "RenderType" = "Transparent"  "Queue" = "Transparent" }
        LOD 100

        Pass {
            Cull Back
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float4 projPos : TEXCOORD1;
            };

            uniform float4 _Color;
            uniform float _Fade;

            UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos( v.vertex );
                o.projPos = ComputeScreenPos (o.vertex);
                COMPUTE_EYEDEPTH(o.projPos.z);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
                float pixelZ = i.projPos.z;
                float4 color = _Color;
                color.a = clamp(_Fade * (sceneZ - pixelZ), 0.3, 1);
                color = float4(sceneZ,sceneZ,sceneZ,1.0);
                return color;
            }
            ENDCG
        }

    }
    FallBack "Diffuse"
}
