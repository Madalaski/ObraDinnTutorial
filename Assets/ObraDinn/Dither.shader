Shader "Effects/Dither"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Dither("Dither", 2D) = "white" {}
        _Noise("Noise", 2D) = "white" {}
        _ColorRamp("Color Ramp", 2D) = "white" {}
        _TL("Direction", Vector) = (0.0, 0.0, 0.0, 0.0)
        _BL("Direction", Vector) = (0.0, 0.0, 0.0, 0.0)
        _TR("Direction", Vector) = (0.0, 0.0, 0.0, 0.0)
        _BR("Direction", Vector) = (0.0, 0.0, 0.0, 0.0)
        _Tiling("Tiling", Float) = 192.0
        _Threshold("Threshold", Float) = 0.1
    }
        SubShader
{
    // No culling or depth
    Cull Off ZWrite Off ZTest Always

    Pass
    {
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };

        v2f vert(appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv;
            return o;
        }

        sampler2D _MainTex;
        float4 _MainTex_TexelSize;

        sampler2D _Dither;
        float4 _Dither_TexelSize;

        sampler2D _Noise;
        float4 _Noise_TexelSize;

        sampler2D _ColorRamp;

        float4 _BL;
        float4 _TL;
        float4 _TR;
        float4 _BR;

        float _Tiling;
        float _Threshold;

        float cylinderProject(sampler2D tex, float2 texel, float3 dir) {
            float u = 0.5 + (atan2(dir.x, -dir.z) / 3.14159265);
            return tex2D(tex, texel * _Tiling * float2(u, 0.5f + dir.y)).r;
        }

        float uvSphereProject(sampler2D tex, float2 texel, float3 dir) {
            float u = 0.5 + 0.5 * (atan2(dir.x, -dir.z) / 3.14159265);
            float v = 0.5 - (acos(dir.y) / 3.14159265);
            return tex2D(tex, _Tiling * float2(u,v)).r;

        }

        float cubeProject(sampler2D tex, float2 texel, float3 dir) {
            float3x3 rotDirMatrix = {0.9473740, -0.1985178,  0.2511438,
                                    0.2511438,  0.9473740, -0.1985178,
                                    -0.1985178,  0.2511438,  0.9473740};

            dir = mul(rotDirMatrix, dir);
            float2 uvCoords;
            if ((abs(dir.x) > abs(dir.y)) && (abs(dir.x) > abs(dir.z))) {
                uvCoords = dir.yz; // X axis

            }
            else if ((abs(dir.z) > abs(dir.x)) && (abs(dir.z) > abs(dir.y))) {
                uvCoords = dir.xy; // Z axis

            }
            else {
                uvCoords = dir.xz; // Y axis
            }

            return tex2D(tex, texel * _Tiling * uvCoords).r;
        }

        float2 edge(float2 uv, float2 delta)
{
            float3 up = tex2D(_MainTex, uv + float2(0.0, 1.0) * delta);
            float3 down = tex2D(_MainTex, uv + float2(0.0, -1.0) * delta);
            float3 left = tex2D(_MainTex, uv + float2(1.0, 0.0) * delta);
            float3 right = tex2D(_MainTex, uv + float2(-1.0, 0.0) * delta);
            float3 centre = tex2D(_MainTex, uv);

            return float2(min(up.b, min(min(down.b, left.b), min(right.b, centre.b))),
                max(max(distance(centre.rg, up.rg), distance(centre.rg, down.rg)),
                max(distance(centre.rg, left.rg), distance(centre.rg, right.rg))));
        }

        float4 frag(v2f i) : SV_Target
        {
            fixed4 col = tex2D(_MainTex, i.uv);

            float3 dir = normalize(lerp(lerp(_BL, _TL, i.uv.y), lerp(_BR, _TR, i.uv.y), i.uv.x));

            //float lum = dot(col, float3(0.299f, 0.587f, 0.114f));
            float lum = col.b;

            float2 ditherCoords = i.uv * _Dither_TexelSize.xy * _MainTex_TexelSize.zw;

            //float ditherLum = tex2D(_Dither, ditherCoords);
            //float ditherLum = cylinderProject(_Dither, _Dither_TexelSize.xy, dir);       
            //float ditherLum = uvSphereProject(_Dither, _Dither_TexelSize.xy, dir);

            //float ditherLum = cubeProject(_Dither, _Dither_TexelSize.xy, dir);
            float ditherLum = (col.a < 0.5) ? cubeProject(_Noise, _Noise_TexelSize.xy, dir) :
                cubeProject(_Dither, _Dither_TexelSize.xy, dir);

            float2 edgeData = edge(i.uv.xy, _MainTex_TexelSize.xy * 2.0f);

            lum = (edgeData.y < _Threshold) ? lum : ((edgeData.x < 0.1f) ? 1.0f : 0.0f);

            float ramp = (lum <= clamp(ditherLum, 0.1f, 0.9f)) ? 0.1f : 0.9f;
            //float3 output = tex2D(_ColorRamp, float2(ramp, 0.5f));
            float3 output = float4(1,1,1,1) * ramp;

            //return col;
            return float4(output, 1.0f);
        }
        ENDCG
    }
}
}
