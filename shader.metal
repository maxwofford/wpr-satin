// the wpr-template starter: replace it with your own!

// `--set blobs=3`: how many
#ifndef WP_PARAM_blobs
#define WP_PARAM_blobs 6
#endif

float4 wp_main(float2 uv, constant Uniforms& u) {
  // the frame is 1.0 tall and `aspect` wide, centered. a blob 0.3 across here is a third of
  // the screen height on every display, portrait or wide
  float aspect = u.res.x / u.res.y;
  float2 p = (uv - 0.5) * float2(aspect, 1.0);

  // the seed only ever goes through hash11; `+ n` picks the nth independent value
  float hue = hash11(u.seed + 1.0);
  float3 ground = hsv2rgb(float3(hue, 0.5, 0.05));
  float3 inkA = hsv2rgb(float3(hue, 0.7, 1.0));
  float3 inkB = hsv2rgb(float3(fract(hue + 0.1 + 0.25 * hash11(u.seed + 2.0)), 0.6, 1.0));

  float3 color = ground;
  for (int i = 0; i < WP_PARAM_blobs; i++) {
    float k = float(i) * 7.0;
    float2 center = (float2(hash11(u.seed + 10.0 + k), hash11(u.seed + 11.0 + k)) - 0.5) * float2(aspect, 0.9);
    float radius = mix(0.15, 0.35, hash11(u.seed + 12.0 + k));
    float2 d = p - center;
    float glow = exp(-dot(d, d) / (radius * radius));
    color += mix(inkA, inkB, hash11(u.seed + 13.0 + k)) * glow * 0.4;
  }

  // squash the bright overlaps so they glow instead of clipping to white, then gamma-correct:
  // wpr shows exactly the numbers you return
  color = 1.0 - exp(-color);
  color = pow(color, float3(1.0 / 2.2));
  return float4(color, 1.0);
}
