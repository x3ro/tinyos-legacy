[r c] = size(TOF_DISTANCE.onsetTOF);
if ishold
    figure
end
%    co=get(gca, 'colorOrder');
%     co='ymcrgbk';
%     lso='*ox.*ox.*ox.*ox.*ox.';
lstyle = {'.k','+k','*k','ok','xk','.b','+b','*b','ob','xb','.g','+g','*g','og','xg','.r','+r','*r','or','xr','.c','+c','*c','oc','xc','.m','+m','*m','om','xm','.y','+y','*y','oy','xy'};

if ishold
    figure
end
hold on
leg={};
for k=1:32
    plot(0,0,lstyle{k})
    leg{k}=num2str(k);
end

for i=1:r

    %first do it for the receiving of this node
    index=0;
    for j = 1:c
        if length(TOF_DISTANCE.onsetTOF{j,i})>5
            [xi, yi, zi] = getLocation(i);
            [xj, yj, zj] = getLocation(j);
            dist= sqrt( (xi-xj)^2 + (yi-yj)^2 + (zi-zj)^2 );

            TOF=[];
            DIST=[];
            data = [TOF_DISTANCE.onsetTOF{j,i}];
            TOF = data*.25;
            DIST= (TOF-100)*.0347;
	
            %minimum within certain range of median
            distEstimate=[];
            for k = 1:length(DIST)
                window = timeWindow(DIST(1:k), 30); %windowSize=30
                medn = median(window);
                range=.0007*medn^2+.025*medn+30;
                window = removeOutsideOf(window, medn-range, medn);
                m = min(window);
                distEstimate(k) = m;%m-0.0006*m^2 -.2505*m+1.1741;
            end
            
   %         plot(dist, mode(max(1, round(distEstimate))), 'color', [co(mod(index-1, length(co))+1,:)], 'lineStyle', lso(floor((index)/length(co))+1))%'.')
%            errorbar(dist, mode(max(1, round(distEstimate))), std(distEstimate), lstyle{j})%'.')
            plot(dist, mode(max(1, round(distEstimate))), lstyle{j})%'.')
%            hold on
%            plot(distEstimate, 'color', [co(mod(index-1, length(co))+1,:)], 'lineStyle', lso(floor((index)/length(co))+1))
%             leg{end+1} = num2str(j);
%             leg{end+1} = [num2str(j) ' error'];
 %           leg{end+1} = [num2str(i) ' ' num2str(j) ' filtered'];
%            index = index + 1;
        end
    end
%     plot(0:250,0:250,'-')
%     hold off
%     title([num2str(i) 'receiving'])
%     if ~isempty(leg)
%         legend(leg);
%     end
% %    pause
%      if ~isempty(input('K?>>'))
%          keyboard
%      end
    
    
%     %now do the same thing for the transmissions of this node
%     leg={};
% 
%     index=0;
%     for j = 1:c
%         if ~isempty(TOF_DISTANCE.onsetTOF{j, i})
%             [xi, yi, zi] = getLocation(i);
%             [xj, yj, zj] = getLocation(j);
%             dist= sqrt( (xi-xj)^2 + (yi-yj)^2 + (zi-zj)^2 );
% 
%             TOF=[];
%             DIST=[];
%             data = [TOF_DISTANCE.onsetTOF{j, i}];
%             TOF = data*.25;
%             DIST= (TOF-100)*.0347;
% 	
%             %minimum within certain range of median
%             distEstimate=[];
%             for k = 1:length(DIST)
%                 window = timeWindow(DIST(1:k), 30); %windowSize=30
%                 medn = median(window);
%                 range=.0007*medn^2+.025*medn+30;
%                 window = removeOutsideOf(window, medn-range, medn);
%                 m = min(window);
%                 distEstimate(k) = m;%m-0.0006*m^2 -.2505*m+1.1741;
%             end
%             
% %            plot(dist, mode(max(1, round(distEstimate))), 'color', [co(mod(index-1, length(co))+1,:)], 'lineStyle', lso(floor((index)/length(co))+1))%'.')
%             errorbar(dist, mode(max(1, round(distEstimate))), std(distEstimate), lstyle{j})%'.')
%             hold on
% %            plot(distEstimate, 'color', [co(mod(index-1, length(co))+1,:)], 'lineStyle', lso(floor((index)/length(co))+1))
% %            leg{end+1} = num2str(j);
% %            leg{end+1} = [num2str(j) ' error'];
%  %           leg{end+1} = [num2str(i) ' ' num2str(j) ' filtered'];
%             index = index + 1;
%         end
%     end
%     plot(0:250,0:250,'-')
%     hold off
%     title([num2str(i) 'transmitting'])
%     if ~isempty(leg)
%         legend(leg);
%     end
%     pause
%     if ~isempty(input('K?>>'))
%         keyboard
%     end
end
        
plot(0:250,0:250,'-')
hold off
title('receiving')
if ~isempty(leg)
    legend(leg);
end
        