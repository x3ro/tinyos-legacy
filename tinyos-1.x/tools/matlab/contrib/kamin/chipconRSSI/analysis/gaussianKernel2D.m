function height = gaussianKernel2D(x,y,data,sigma)
%height = gaussianKernel2D(x,y,data,sigma)
%
%This function finds the height of the gaussian kernel at (x,y) given the
%data and the value of sigma.

height = 0;
for i = 1:size(data,1)
    height = height + normpdf(sqrt( (x-data(i,1))^2 + (y-data(i,2))^2), 0, sigma);
end
