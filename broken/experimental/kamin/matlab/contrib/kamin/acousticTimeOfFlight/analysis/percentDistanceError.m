function error=percentDistanceError(estimate, true)
%this function will calculate the percent error for a bunch of distance estimates

if length(estimate)~=length(true)
    error('parameters must be the same length')
end

error=0;
for i=1:length(estimate)
    if true(i)~=0
        error = error + abs((estimate(i)-true(i))/true(i));
    end
end
error=error/length(estimate);