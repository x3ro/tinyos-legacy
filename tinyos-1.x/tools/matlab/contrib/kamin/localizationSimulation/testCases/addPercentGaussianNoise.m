function t = addPercentGaussianNoise(t, percent)
%
%this function adds gaussian noise to all distance estimates in a test
%Suite.  The argument indicates what percent of the range value should be
%noise.  This value is used as the sigma^2 for a gaussian noise generator.


for i=1:length(t)
    t(i).kd(t(i).connectivityMatrix) = t(i).distanceMatrix(t(i).connectivityMatrix) + normrnd(0, t(i).distanceMatrix(t(i).connectivityMatrix)*percent/2);
end