// satin: light down a fold of cloth. one noise-warped field, run through a cyclic ramp of black,
// teal, cream and plum, then grained per pixel. after a piece by strano
// (x.com/5tr4n0/status/2103247586815873535): the ramp, the band spacing, the tilt and the grain
// are measured off a frame of it, the construction is mine.

// the seed picks all of these; any you `--set` is pinned instead
// `--set bands=3.6`: cycles of the ramp across the screen's height, before the warp (seeded 2.2..4.5)
// `--set warp=1.0`: how far the noise pushes the bands out of straight (seeded 0.6..1.5)
// `--set grain=1.0`: the per-pixel jitter of the ramp lookup, 0 for smooth (seeded 0.5..1.3)
// `--set hue=0`: turns of the whole ramp around grey, 0..1 (seeded anywhere; 0 is the reference)
// `--set tilt=34`: degrees the bands fall by (seeded -60..60)
// `--set flip=0`: 1 mirrors the ramp, so the sharp edge is on the other side of each fold (seeded)

// one cycle of the ramp, sampled along a line across the reference's bands. the black holds for
// a third of the cycle, the edge up into teal is sharp, and everything after that is gradual:
// that asymmetry is what makes a band read as a fold catching light rather than a stripe
constant int st_count = 12;
constant float st_pos[st_count] = { 0.00, 0.30, 0.34, 0.40, 0.48, 0.56, 0.62, 0.70, 0.78, 0.86, 0.93, 1.00 };
constant float3 st_col[st_count] = {
  float3(0x05, 0x02, 0x0a) / 255.0,
  float3(0x0a, 0x0a, 0x18) / 255.0,
  float3(0x19, 0x3f, 0x4d) / 255.0,
  float3(0x30, 0x6c, 0x6a) / 255.0,
  float3(0x93, 0xa0, 0x76) / 255.0,
  float3(0xcb, 0xca, 0xa2) / 255.0,
  float3(0xf3, 0xec, 0xdf) / 255.0,
  float3(0xd1, 0xb9, 0x9d) / 255.0,
  float3(0xb8, 0x88, 0x6e) / 255.0,
  float3(0x60, 0x34, 0x4a) / 255.0,
  float3(0x3a, 0x10, 0x30) / 255.0,
  float3(0x05, 0x02, 0x0a) / 255.0,
};

inline float3 st_ramp(float t) {
  t = fract(t);
  for (int i = 1; i < st_count; i++) {
    if (t < st_pos[i]) return mix(st_col[i - 1], st_col[i], (t - st_pos[i - 1]) / (st_pos[i] - st_pos[i - 1]));
  }
  return st_col[st_count - 1];
}

float4 wp_main(float2 uv, constant Uniforms& u) {
  float aspect = u.res.x / u.res.y;
  float2 p = (uv - 0.5) * float2(aspect, 1.0);

  // the seed only ever goes through hash11; `+ n` picks the nth independent value
  float2 seed = float2(hash11(u.seed + 1.0), hash11(u.seed + 2.0)) * 64.0;
#ifdef WP_PARAM_tilt
  float tilt = WP_PARAM_tilt * 0.0174533;
#else
  float tilt = (hash11(u.seed + 3.0) - 0.5) * 120.0 * 0.0174533;
#endif
#ifdef WP_PARAM_bands
  float bands = WP_PARAM_bands;
#else
  float bands = mix(2.2, 4.5, hash11(u.seed + 4.0));
#endif
#ifdef WP_PARAM_warp
  float warp = WP_PARAM_warp;
#else
  float warp = mix(0.6, 1.5, hash11(u.seed + 5.0));
#endif
#ifdef WP_PARAM_grain
  float grain = WP_PARAM_grain;
#else
  float grain = mix(0.5, 1.3, hash11(u.seed + 6.0));
#endif
#ifdef WP_PARAM_hue
  float hue = WP_PARAM_hue;
#else
  float hue = hash11(u.seed + 7.0);
#endif
#ifdef WP_PARAM_flip
  float flip = WP_PARAM_flip > 0.5 ? -1.0 : 1.0;
#else
  float flip = hash11(u.seed + 8.0) < 0.5 ? -1.0 : 1.0;
#endif
  float t = u.time;

  // frame turned so the bands run along x: q.y is the distance across them
  float2 q = float2(cos(tilt) * p.x - sin(tilt) * p.y, sin(tilt) * p.x + cos(tilt) * p.y);

  // the warp. a straight gradient plus noise is a stripe pattern with a wobble; what the
  // reference does is pinch, fork and pool, and that takes warping the domain twice: one noise
  // field displaces the point the next one is read at. stretched along the bands so the folds
  // stay long. the slow drift is for `wpr stream`; at time 0 it is still
  float2 wq = q * float2(0.55, 1.1) + seed + float2(t * 0.012, t * 0.02);
  float2 w1 = float2(fbm(wq, 4), fbm(wq + float2(5.2, 1.3), 4)) - 0.5;
  float2 w2 = float2(fbm(wq + 2.4 * w1 + float2(1.7, 9.2), 4), fbm(wq + 2.4 * w1 + float2(8.3, 2.8), 4)) - 0.5;
  float v = q.y * bands + t * 0.02;
  v += (w2.y * 3.2 + w1.y * 1.2) * warp;
  // the hair on the edges: fast across the bands, slow along them
  float fine = vnoise(q * float2(9.0, 70.0) + seed * 1.7 + t * 0.03) - 0.5;
  v += fine * 0.10 * warp;

  // the grain: every pixel looks the ramp up a little off its neighbours, which is what frizzes
  // the sharp black edge and gives the smooth stretches their tooth
  v += (hash21(uv * u.res + fract(t) * 7.1) - 0.5) * 0.16 * grain;

  // the ramp was sampled in srgb and wpr shows exactly what we return, so no gamma step. the
  // hue turn is a rotation about the grey axis, taken in proportion to how saturated the stop
  // is: the teal and plum flanks turn all the way, the cream highlight and the black hold
  // barely at all. a full turn on the cream made it lavender, and lavender satin is a
  // different fabric
  float3 col = st_ramp(v * flip);
  float3 k = float3(0.57735);
  float cs = cos(hue * 6.28318), sn = sin(hue * 6.28318);
  float3 turned = clamp(col * cs + cross(k, col) * sn + k * dot(k, col) * (1.0 - cs), 0.0, 1.0);
  float sat = (max3(col.r, col.g, col.b) - min3(col.r, col.g, col.b)) / max(max3(col.r, col.g, col.b), 1e-4);
  col = mix(col, turned, smoothstep(0.08, 0.35, sat));
  return float4(col, 1.0);
}
