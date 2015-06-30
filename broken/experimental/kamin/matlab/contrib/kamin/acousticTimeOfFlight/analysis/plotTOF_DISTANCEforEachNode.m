[r c] = size(TOF_DISTANCE.onsetTOF);
lstyle = {'.k','+k','*k','ok','xk','.b','+b','*b','ob','xb','.g','+g','*g','og','xg','.r','+r','*r','or','xr','.c','+c','*c','oc','xc','.m','+m','*m','om','xm','.y','+y','*y','oy','xy'};

if ishold
    figure
end
leg={};
for k=1:32
    leg{k}=num2str(k);
end

%first do it for the reception of each node
for i=1:c
	for k=1:32
        plot(0,0,lstyle{k})
    	hold on
	end
    
    %for each transmitter
    for j = 1:c
        if length(TOF_DISTANCE.onsetTOF{i,j})>5
            [xi, yi, zi] = getLocation(i);
            [xj, yj, zj] = getLocation(j);
            dist= sqrt( (xi-xj)^2 + (yi-yj)^2 + (zi-zj)^2 );

            TOF=[];
            DIST=[];
            data = [TOF_DISTANCE.onsetTOF{i,j}];
            TOF = data*.25;
            DIST= (TOF-100)*.0347;
	
            %find minimum within certain range of median
            distEstimate=[];
            for k = 1:length(DIST)
                window = timeWindow(DIST(1:k), 30); %windowSize=30
                medn = median(window);
                range=.0007*medn^2+.025*medn+30;
                window = removeOutsideOf(window, medn-range, medn);
                m = min(window);
                distEstimate(k) = m;%m-0.0006*m^2 -.2505*m+1.1741;
            end
            
            %and plot the mode
            errorbar(dist, mode(max(1, round(distEstimate))), std(distEstimate), lstyle{j})%'.')
        end
	end
	plot(0:250,0:250,'-')
	hold off
	title([num2str(i) 'receiving'])
	if ~isempty(leg)
        legend(leg);
	end
    pause
% 		if ~isempty(input('K?>>'))
%          keyboard
% 		end
end    


if ishold
    figure
end
leg={};
for k=1:32
    leg{k}=num2str(k);
end

%then do it for the transmission of each node
for i=1:c
	for k=1:32
        plot(0,0,lstyle{k})
    	hold on
	end

 
    %for each receiver
    for j = 1:r
        if length(TOF_DISTANCE.onsetTOF{j,i})>5
            [xi, yi, zi] = getLocation(i);
            [xj, yj, zj] = getLocation(j);
            dist= sqrt( (xi-xj)^2 + (yi-yj)^2 + (zi-zj)^2 );

            TOF=[];
            DIST=[];
            data = [TOF_DISTANCE.onsetTOF{j,i}];
            TOF = data*.25;
            DIST= (TOF-100)*.0347;
	
            %find minimum within certain range of median
            distEstimate=[];
            for k = 1:length(DIST)
                window = timeWindow(DIST(1:k), 30); %windowSize=30
                medn = median(window);
                range=.0007*medn^2+.025*medn+30;
                window = removeOutsideOf(window, medn-range, medn);
                m = min(window);
                distEstimate(k) = m;%m-0.0006*m^2 -.2505*m+1.1741;
            end
            
            %and plot the mode
            errorbar(dist, mode(max(1, round(distEstimate))), std(distEstimate), lstyle{j})%'.')
        end
	end
	plot(0:250,0:250,'-')
	hold off
	title([num2str(i) 'transmitting'])
	if ~isempty(leg)
        legend(leg);
	end
    pause
% 		if ~isempty(input('K?>>'))
%          keyboard
% 		end
end