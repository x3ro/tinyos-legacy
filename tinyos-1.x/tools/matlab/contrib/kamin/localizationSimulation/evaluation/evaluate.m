function [results,message] = evaluate(t, algorithm, drawboard)

%if isempty(t) load('testSuite/testsuite'); end
if isempty(algorithm) algorithm='composition'; end
if isempty(drawboard) drawboard= 0; end
    
% Load the testsuite which contains the coordinates for the centers 
%  of each circle in the m-by-n-by-2 matrix gm where m is the number 
%  of boards, and n is the number of points on a board.


for k = 1:length(t)
   
    npts = size(t(k).kd,1);
    
    % Run the algorithm and time it    
    time0 = cputime;
    eval(['t(k) = ' algorithm '(t(k));']);
    timeElapsed = cputime-time0;

    % Check the solution
    
    % Check for the correct number of points
    if size(t(k).xyEstimate,1) ~= npts
        error('incorrect number of points returned')
    end
    if size(t(k).xyEstimate,2) ~= 2
        error('should be two columns for xy')
    end
    
    % Check against box bounds
    if min(t(k).xyEstimate(:,1)) < t(k).bx(1)
        warning('Evalute: x too low')
    end
    if min(t(k).xyEstimate(:,2)) < t(k).bx(3)
        warning('Evalute: y too low')
    end
    if max(t(k).xyEstimate(:,1)) > t(k).bx(2)
        warning('Evalute: x too high')
    end
    if max(t(k).xyEstimate(:,2)) > t(k).bx(4)
        warning('Evalute: y too high')
    end

    % Calculate distance matrix
    x=t(k).xyEstimate(:,1);
    y=t(k).xyEstimate(:,2);
    [XY1,XY2] = meshgrid(x,y);
    dist = sqrt((XY1 - XY1').^2 + (XY2 - XY2').^2); 
    
    % Calculate strain matrix
    strainMatrix = dist - t(k).kd;
    strainMatrix(t(k).kd < 0) = 0;
        
    [results(k,1), locationErrors{k}] = findLocationError(t(k));
    results(k,2) = sum(abs(strainMatrix(:)))/(sum(t(k).kd(:)>=0)-npts);
    results(k,3) = timeElapsed;
    fprintf('Average Error = %0.03f (cm);   ', results(k,1));
    fprintf('Average Strain = %0.03f (cm);   ', sum(results(k,2)));
    fprintf('Time Elapsed   = %0.03f (sec)\n', results(k,3));
    
    % plot
    if drawboard
        subplot('Position',[.1 .825 .8 .1])
        [f,xi] = ksdensity(locationErrors{k});
        plot(xi/max(max(t(k).distanceMatrix.*t(k).connectivityMatrix)),f/sum(f),'lineWidth',2,'color',[0 0 1]);
        title('Empirical Probability of Error (kernel smoothing)')
        xlabel('Error (relative to maximum range)')
        ylabel('Probability')
        subplot('Position',[.1 .075 .8 .55])
        plotXY(t(k), strainMatrix);
        title(algorithm)
        axis off
        pause
    end
end

figure
[f,xi] = ksdensity([locationErrors{:}]);
plot(xi/max(max(t(k).kd)),f/sum(f),'lineWidth',2,'color',[0 0 1]);

message=sprintf('Average strain = %0.03f', sum(results(:,1))/size(results,1));
