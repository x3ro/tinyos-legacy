function t = changeRangingRadius(t, radius)
%
%this function make all ranging estimates perfect when below the given
%radius

for i=1:length(t)
    t(i).connectivityMatrix = t(i).distanceMatrix<radius;
    t(i).kd = -ones(size(t(i).distanceMatrix));
    t(i).kd(t(i).connectivityMatrix) = t(i).distanceMatrix(t(i).connectivityMatrix);
end