function testParams(a,b,e)
% testParams - tests the parameters for our sensor and radio models
% testParams(a,b,e)

global plotState;

% Parameters: [alpha; beta; eta] columns
testVec = [2   2
           20 20
           0.8 0.6];
n = size(testVec,2);
xplotSize = 10;

figure(plotState.TestParamsfignum);

if (nargin > 0)
    fplot(@(x)b/(b+x^a),[0 xplotSize]);
    title(sprintf('alpha: %d, beta %d',a,b));
    axis([0 xplotSize 0 1]);
    r = (b*(1-e)/e)^(1/a);
    disp(sprintf('The effective radius for (%.2f,%.2f,%.2f)is: %.2f',...
        a,b,e,r));
else
    for i =1:n
        a = testVec(1,i);
        b = testVec(2,i);
        e = testVec(3,i);
        subplot(n,1,i);
        fplot(@(x)b/(b+x^a),[0 xplotSize]);
        title(sprintf('alpha: %d, beta %d',a,b));
        axis([0 xplotSize 0 1]);
        r = (b*(1-e)/e)^(1/a);
        disp(sprintf('The effective radius for (%.2f,%.2f,%.2f)is: %.2f',...
            a,b,e,r));
    end
end