function y = movingAverage(x,numpoints)
% y = movingAverage(x,numpoints)
%
% The moving average filter averages over x for the number
% of points given and saves this data in y

x0 = x(1);
for i=1:length(x)
    if i <= numpoints
        sum = 0;
        for j=1:i
            sum = sum + x(i-j+1);
        end
        y(i) = sum/i;
    else
        sum = 0;
        for j=1:numpoints
            sum = sum + x(i-j+1);
        end
        y(i) = sum/numpoints;
    end
end

y = y';