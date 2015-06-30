function [outputPoints, t, error] = linearConformalTransform(inputPoints, basePoints)
%t = linearConformalTransform(inputPoints, basePoints)
%
%This function derives a linear conformal coordinate transform from the
%inputPoints coordinate system to the basePoints coordinate system.
%
%inputPoints and basePoints are both m x 2 vectors of x, y coords and must
%have m>=2.

error=0;
t=[1 0; 0 1; 0 0];
if isempty(basePoints) 
    outputPoints = inputPoints;
    
    return
end
if size(inputPoints)~=size(basePoints) error('input matrices must be same size'); end
if any(size(inputPoints,1)==1) inputPoints=basePoints; end
if any(size(inputPoints,1)==0) error('must enter points'); end

a = [inputPoints ones(size(inputPoints,1),1) zeros(size(inputPoints,1),1)];
a2 = [a(:,2) -a(:,1) a(:,4) a(:,3)];
a=[a; a2];
b = basePoints(:);
[x,flag,error]=lsqr(a,b);
t(1:3,1) = x(1:3);
t(1,2)=-x(2);
t(2,2)=x(1);
t(3,2)=x(4);
outputPoints = [inputPoints ones(size(inputPoints,1),1)]*t;
%error = findLocationError(inputPoints, outputPoints);