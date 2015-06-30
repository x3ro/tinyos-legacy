expdecay_make = fn (bits) vector(bits, 0);
expdecay_get = fn (s, val)
  s[1] = s[1] - (s[1] >> s[0]) + (val >> s[0]);

