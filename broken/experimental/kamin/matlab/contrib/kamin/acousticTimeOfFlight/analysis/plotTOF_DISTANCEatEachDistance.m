groupTOF_DISTANCEbyDistance

for i=1:length(distanceData)
    pairs = distanceData{i};
    if ishold
        figure
    end
    co=get(gca, 'colorOrder');
    lso='-:.o*-:.o*-:.o*-:.o*';
    leg={};
    for j = 2:length(pairs)
        TOF=[];
        DIST=[];
        data = [TOF_DISTANCE.onsetTOF{pairs{j}(1), pairs{j}(2)}];
        TOF = data*.25;
        DIST= (TOF-100)*.0347;

        %minimum within certain range of median
        distEstimate=[];
        for k = 1:length(data)
            window = timeWindow(DIST(1:k), 30); %windowSize=30
            medn = median(window);
            range=.0007*medn^2+.025*medn+30;
            window = removeOutsideOf(window, medn-range, medn);
            m = min(window);
            distEstimate(k) = m;%m-0.0006*m^2 -.2505*m+1.1741;
        end
        
        plot(DIST, 'color', [co(mod(j-2, length(co))+1,:)], 'lineStyle', lso(floor((j-1)/length(co))+1))%'.')
        hold on
        plot(distEstimate, 'color', [co(mod(j-2, length(co))+1,:)], 'lineStyle', lso(floor((j-1)/length(co))+1))
        leg{end+1} = num2str(pairs{j});
        leg{end+1} = [num2str(pairs{j}) ' filtered'];
    end
    plot(0:250,0:250,'-b')
    hold off
    title(['distance = ' num2str(pairs{1})])
    legend(leg);
    pause
end
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        x = 1:length(data);
		hold off
		plot(x,DIST,'.')
		hold on
		plot(x,minWindow)
		hold off
		axis([0 500 -10 400]);
		xlabel('time')
		ylabel('DIST')
		title(['Distance = ' num2str(distance) '; min in std'])
		%    legend('5','10','15','20','25','30','35','40','45','50')
		legend('DIST, w=1','w=10','w=30','w=50')
		beep
		pause
		beep
		clear minWindow
