any expdecay_make(bits) vector(bits, 0);
any expdecay_get(s, val)
  s[1] = s[1] - (s[1] >> s[0]) + (val >> s[0]);

