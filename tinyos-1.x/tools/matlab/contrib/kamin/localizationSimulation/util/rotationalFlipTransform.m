function [outputPoints, transform, error] = rotionalFlipTransform(inputPoints, basePoints)
%[outputPoints, transform, error] = rotionalFlipTransform(inputPoints, basePoints)
%
%This function derives a linear conformal coordinate transform from the
%inputPoints coordinate system to the basePoints coordinate system.
%It also flips the coordinate system if that improves results
%
%inputPoints and basePoints are both m x 2 vectors of x, y coords and must
%have m>=2.

[outputPoints, transform, error] = linearConformalTransform(inputPoints, basePoints);

inputPoints2 = [inputPoints(:,1) -inputPoints(:,2)];
[outputPoints2, transform2, error2] = linearConformalTransform(inputPoints2, basePoints);
if error2<error
    outputPoints = outputPoints2;
    transform = transform2;
    error = error2;
end