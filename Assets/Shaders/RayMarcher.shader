Shader "Hidden/Ray-marcher"
{
    Properties
    {
    }

    CGINCLUDE
    #pragma target 4.0

    #define UNITY_SHOULD_SAMPLE_SH 1
    #define UNITY_SAMPLE_FULL_SH_PER_PIXEL 1

    #include "UnityCG.cginc"
    #include "UnityGlobalIllumination.cginc"

    struct Input
    {
        float4 vertex : POSITION;
    };

    struct Varyings
    {
        float4 vertex : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    Varyings vertex(Input input)
    {
        Varyings output;

        output.vertex = input.vertex;
        output.uv = input.vertex;

        return output;
    }

    float4 _MainTex_TexelSize;

    int _MaximumIterationCount;
    float _Epsilon;

    float grain(float seed)
    {
        return frac(sin(seed) * 423145.92642);
    }

    float query(float3 position)
    {
        return length(position - float3(-1.5, 0., 0.)) - .5;
    }

    float intersect(in float3 origin, in float3 direction, out float depth)
    {
        float sample = _ProjectionParams.z;
        depth = _ProjectionParams.y;

        float3 position = origin;

        int i = 0;
        for (; i < _MaximumIterationCount; ++i)
        {
            position = origin + direction * depth;
            sample = query(position);

            if (sample < _Epsilon)
            {
                break;
            }

            depth += max(_Epsilon, sample) + _Epsilon * (.5 + .5 * grain(position.z));

            if (depth >= (_ProjectionParams.z - _ProjectionParams.y))
            {
                break;
            }
        }

        if (i == _MaximumIterationCount)
            depth = 1.;

        return sample;
    }

    float3 calculateNormal(float3 position)
    {
        return normalize(
            float3(query(position + float3(_Epsilon, 0., 0.)) -
                query(position - float3(_Epsilon, 0., 0.)),

                query(position + float3(0., _Epsilon, 0.)) -
                    query(position - float3(0., _Epsilon, 0.)),

                query(position + float3(0., 0., _Epsilon)) -
                    query(position - float3(0., 0., _Epsilon))
            )
        );
    }

    float3 calculateApproximateNormal(float3 position, float d)
    {
        return normalize(
            float3(query(position + float3(_Epsilon, 0., 0.)),
                query(position + float3(0., _Epsilon, 0.)),
                query(position + float3(0., 0., _Epsilon))
            ) - d
        );
    }

    float calculateAOFactor(float3 p, float3 n)
    {
        float sum = 0.;
        float t = 0.;
        float amp = 1.0;

        for(int i = 0; i < 10; i++)
        {
            t += .1;
            sum += amp * (t - query(p + n * t));
            amp *= 0.7;
        }

        return max(0., 1. - .7 * sum);
    }

    float calculateDepth(float4 clipSpacePosition)
    {
        #if defined (UNITY_UV_STARTS_AT_TOP)
            return clipSpacePosition.z / clipSpacePosition.w;
        #else
            return ((clipSpacePosition.z / clipSpacePosition.w) + 1.) * .5;
        #endif
    }

    struct GBuffer
    {
        half4 diffuse : SV_Target0;
        half4 specularSmoothness : SV_Target1;
        half4 normal : SV_Target2;
        half4 emission : SV_Target3;

        float depth : SV_Depth;
    };

    GBuffer fragment(Varyings input)
    {
        GBuffer output;

        float2 coordinates = input.uv;
        coordinates.x *= _ScreenParams.x / _ScreenParams.y;

        float3 origin = _WorldSpaceCameraPos;
        float3 direction = normalize(float3(UNITY_MATRIX_V[0].xyz * coordinates.x +
            UNITY_MATRIX_V[1].xyz * coordinates.y - UNITY_MATRIX_V[2].xyz * abs(UNITY_MATRIX_P[1][1])));

        float depth = 0.;
        float sample = intersect(origin, direction, depth);

        float3 position = origin;
        float3 normal = 0.;

        output.diffuse = float4(0., 0., 0., 1.);

        if (sample < _Epsilon)
        {
            position = origin + direction * depth;
            normal = calculateApproximateNormal(position, sample);

            output.diffuse = float4(1., 1., 1., 1.);
            output.depth = calculateDepth(mul(UNITY_MATRIX_VP, float4(position, 1.)));
        }
        else
        {
            discard;
        }

        output.specularSmoothness = float4(0., 0., 0., 0.);
        output.normal = float4(normal * .5 + .5, 1.);

        // Emission + lighting + lightmaps + reflection probes buffer.
        half3 ambient = ShadeSHPerPixel(normal, float3(0, 0, 0), position) * calculateAOFactor(position, normal);
        output.emission = float4(ambient, 0.);

        return output;
    }
    ENDCG

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Cull Off

        Pass
        {
            Tags { "LightMode" = "Deferred" }

            Stencil
            {
                Comp Always
                Pass Replace
                Ref 128
            }

            CGPROGRAM
            #pragma vertex vertex
            #pragma fragment fragment
            ENDCG
        }
    }
}
