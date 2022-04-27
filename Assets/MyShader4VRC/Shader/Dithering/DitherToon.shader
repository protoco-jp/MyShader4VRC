/* DONE
SHADE
DITHER
*/

/* TODO
MATCAP
cginc/EDITOR
FORWARDBASE
METALIC
FORWARDADD
CAST SHADOW
RECEIVE SHADOW?
GEOMETRY
VAT
*/

Shader "MS4VRC/Dither/DitherToon" {
    Properties {
        [Header(Shader Variant)]
        [KeywordEnum(NONE, HARD, SOFT)]_SHADOW("Shadow Type", Int) = 0
        [Toggle] _Saturate("Saturate Light", Float) = 0
        [KeywordEnum(NONE, TEX, IGN, WHITE)]_NOISE("Noise Pattern", Int) = 0
        [KeywordEnum(PARAM, MUL, MASK)]_ALPHA("Alpha type", Int) = 0

        [Header(Color Properties)]
        [HDR] _Color ("Color", Color) = (1,1,1,1)
        _Unlit("Unlit",Range(0,1)) = 0.5
        _Shade("Shade Str",Range(-1,1)) = 0.5
        _ShadeMaskStr("Shade Mask Str",Range(-1,1)) = 0.5
        _ShadeStep("Shade Step",Range(1,-1)) = 0
        _MainTex ("MainTexture", 2D) = "white" {}
        _AlphaMask ("AlphaMask", 2D) = "white" {}

        [Header(Discard Properties)]
        _Density("Density", Range(0,1)) = 1
        _OffsetX("Dither Offset X", Range(0,1)) = 0
        _OffsetY("Dither Offset Y", Range(0,1)) = 0
        [NoScaleOffset] _BayerTex ("Dither Texture", 2D) = "white" {}
    }
    SubShader {
        Tags { "Queue"="AlphaTest" }

        Pass {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #pragma multi_compile_fog

            #pragma shader_feature _SHADOW_NONE _SHADOW_HARD _SHADOW_SOFT
            #pragma shader_feature _NOISE_NONE _NOISE_TEX _NOISE_WHITE _NOISE_IGN
            #pragma shader_feature _ALPHA_PARAM _ALPHA_MUL _ALPHA_MASK
            #pragma shader_feature _ _SATURATE_ON
            // make fog work


            #include "UnityCG.cginc" 
            #include "UnityLightingCommon.cginc"
            #include "Lighting.cginc" 
            #include "AutoLight.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float3 ambient : COLOR0;
                float2 uv : TEXCOORD0;
                float4 scrPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                UNITY_FOG_COORDS(3)
                SHADOW_COORDS(4)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            uniform float4 _Color;
            sampler2D _MainTex;
            sampler2D _AlphaMask;
            uniform float4 _MainTex_ST;
            uniform float _Shade;
            uniform float _ShadeMaskStr;
            uniform float _Unlit;
            uniform float _ShadeStep;

            sampler2D _BayerTex;
            uniform float4 _BayerTex_TexelSize;
            uniform float _Density;
            uniform float _OffsetX;
            uniform float _OffsetY;

            v2f vert (appdata v) {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.scrPos = ComputeNonStereoScreenPos(o.pos);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.ambient = ShadeSH9(float4(o.normal,1));
                UNITY_TRANSFER_FOG(o,o.pos)
                TRANSFER_SHADOW(o)
                return o;
            }

            float3 frag (v2f i) : SV_Target {
                float4 col = tex2D(_MainTex, i.uv) * _Color;

                #ifdef _NOISE_TEX //texture based
                    float2 screenUV = (i.scrPos.xy / i.scrPos.w) * ((_ScreenParams.xy) / _BayerTex_TexelSize.zw) + float2(_OffsetX, _OffsetY);
                    float threshold = clamp(tex2D( _BayerTex, screenUV ).r, 0.001, 0.999);
                #elif _NOISE_WHITE //white noise
                    float2 screenUV = (i.scrPos.xy / i.scrPos.w) * _ScreenParams.xy;
                    float threshold = frac(sin(dot(screenUV, fixed2(12.9898,78.233))) * 43758.5453);
                #elif _NOISE_IGN //Interleaved Gradient Noise (CoD Dither)
                    float2 screenUV = (i.scrPos.xy / i.scrPos.w) * _ScreenParams.xy;
                    float3 magic = float3(0.06711056,0.00583715,52.9829189);
                    float threshold = frac(magic.z * frac(dot(screenUV,magic.xy)));
                #endif
                #ifndef _NOISE_NONE
                    #ifdef _ALPHA_MASK
                        clip(_Density * tex2D(_AlphaMask, i.uv) - threshold);
                    #elif _ALPHA_MUL
                        clip(_Density * col.a - threshold);
                    #elif _ALPHA_PARAM
                        clip(_Density - threshold);
                    #endif
                #endif

                #ifdef _SATURATE_ON
                    col *= saturate(_LightColor0) * (1 - _Unlit) +  _Unlit;
                #else
                    col *= _LightColor0 * (1 - _Unlit) +  _Unlit;
                #endif

                #ifndef _SHADOW_NONE
                    float3 dLight = normalize( _WorldSpaceLightPos0.xyz);
                    float3 normal = normalize(i.normal);
                    fixed4 diffuse = dot(dLight, normal);
                    float ambient = i.ambient.r * 0.298912 + i.ambient.g * 0.586611 + i.ambient.b * 0.114478; 
                    float4 shadowMask = diffuse * (1 - _ShadeMaskStr) +  _ShadeMaskStr;
                    #ifdef _SHADOW_HARD
                        diffuse = step(_ShadeStep, diffuse);
                    #endif
                    float4 shadow = shadowMask * SHADOW_ATTENUATION(i) + (1 - shadowMask);
                    float4 adjustedShadow = diffuse * shadow * (1 - _Shade) +  _Shade;
                    col *= adjustedShadow;//max(adjustedShadow, ambient);
                    col += float4(i.ambient.xyz,0);
                #endif

                UNITY_APPLY_FOG(i.fogCoord, col);

                return  shadow.rgb;
            }
            ENDCG
        }
        Pass {
            Stencil {
                Ref 128
                Pass Replace
            }
            ColorMask 0
            ZWrite Off
        }

        Pass {
          Tags {"LightMode"="ShadowCaster"}

          CGPROGRAM
          #pragma vertex vert
          #pragma fragment frag
          #pragma multi_compile_shadowcaster
          #include "UnityCG.cginc"

          struct v2f {
            V2F_SHADOW_CASTER;
          };

          v2f vert(appdata_base v) {
            v2f o;
            TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
            return o;
          }

          float4 frag(v2f i) : SV_Target {
            SHADOW_CASTER_FRAGMENT(i)
          }
          ENDCG
        }
    }
}
