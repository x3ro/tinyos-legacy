function [xpred,ypred,vx,vy] = predictPosition(Tdelay,Xreadings,Yreadings,timeStamp)

% INPUT:
%       Tdelay : time delay of measurament. could be the time in seconds if timestamps 
%                are available for measurament, or # of steps if assumed that readings 
%                are equally spaced in time
%       Xreading: column vector (Nreadings,1) of past x-measuraments
%       Yreading: column vector (Nreadings,1) of past y-measuraments
%       timeStamp: column vecotr (Nreadings,1) of timestamps corresponds to (X,Y)readings
%                   if not given, timestamps is created virtually assuming (X,Y)readings are
%                   equally spaced in time
%       METHOD: 'linear' interpolate a rect using LSQ, 'cubic' interpolate a parabola to the data
%
% OUTPUT:
%        xpred-ypred: x-y position estimation at present
%        vx,vy: x-y velocity estimation at present




global METHOD

%METHOD = 'linear';

Nreadings = length(Xreadings);

%take care of case of single point at beginning
if Nreadings <= 2
    xpred = Xreadings(Nreadings,1);
    ypred = Yreadings(Nreadings,1);
    vx = 0;
    vy = 0;
    return;
end

if nargin<4
    timeStamp = (1:1:Nreadings)';   %created virtually if not given
    timePrediction = Nreadings + Tdelay;    %virtual time of desired prediction
else
    timePrediction = timeStamp(end) + Tdelay;
end

switch METHOD
    case 'linear'
        A = [ timeStamp ones(Nreadings,1) ];

        pseudoA = inv(A'*A)*A';
        Cx = pseudoA*Xreadings;
        Cy = pseudoA*Yreadings;

        xpred = [timePrediction 1]*Cx;
        ypred = [timePrediction 1]*Cy;
        vx = Cx(:,1);
        vy = Cy(:,1);
        %figure(30)
        %plot(timeStamp,Xreadings,'*r');hold on;
        %plot(timeStamp,A*Cx,'ok'); hold off; %pause;%hold off;
            
    case 'cubic'


        A = [ timeStamp.^2 timeStamp ones(Nreadings,1) ];

        pseudoA = inv(A'*A)*A';
        Cx = pseudoA*Xreadings;
        Cy = pseudoA*Yreadings;

        xpred = [timePrediction^2 timePrediction 1]*Cx;
        ypred = [timePrediction^2 timePrediction 1]*Cy;
        vx = [2*timePrediction 1]*Cx(1:2,1);
        vy = [2*timePrediction 1]*Cy(1:2,1);        
 end
    