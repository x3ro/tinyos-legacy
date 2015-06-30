function x = clip(x, xMin, xMax)

x = round(x);
if x > xMax, x = xMax; end
if x < xMin, x = xMin; end
