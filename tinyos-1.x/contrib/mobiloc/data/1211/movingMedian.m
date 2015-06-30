function y = movingMedian(x,numpoints)
% y = movingMedian(x,numpoints)
%
% The moving median filter takes the median of x for the number
% of points given and saves this data in y

for i=1:length(x)
    if i <= numpoints
        y(i) = median(x(1:i));
    else
        y(i) = median(x(i-numpoints:i));
    end
end

y = y';