function localizationRefresh(varargin)
%localizationRefresh(varargin)
%
%this function uses the distance information in LOCALIZATION.distances
%and tries to plot the locations of all the nodes.

global LOCALIZATION
global TOF_DISTANCE
global MAX_NETWORK_DIMENSION

global alpha;

if length(varargin)>=1
    moteIDs = varargin{1};
else
    moteIDs = LOCALIZATION.moteIDs;
end

%use mass springs to reposition the desired motes
for iter=1:10
    locations = LOCALIZATION.locations;
    xForce=zeros(max(LOCALIZATION.moteIDs),1);
    yForce=zeros(max(LOCALIZATION.moteIDs),1);
    xForceCount=zeros(max(LOCALIZATION.moteIDs),1);
    yForceCount=zeros(max(LOCALIZATION.moteIDs),1);
    for i=1:length(moteIDs)
        mote = moteIDs(i);
        if sum((mote == LOCALIZATION.fixed) == 1)<1
            for j=1:length(LOCALIZATION.moteIDs)
                neighbor = LOCALIZATION.moteIDs(j);
                if i==8 | j==8
                    hi=1;
                end
                if mote~=neighbor & LOCALIZATION.distances(mote,neighbor) > 0
                    estDist = LOCALIZATION.distances(mote,neighbor);
                    xDist = locations(mote,1)-locations(neighbor,1);
                    yDist = locations(mote,2)-locations(neighbor,2);
                    curDist = sqrt(xDist^2+yDist^2);
                    deltaDist = estDist-curDist;
                    xF=xDist*deltaDist/curDist;
                    yF=yDist*deltaDist/curDist;
                     if sum((neighbor == LOCALIZATION.fixed) == 1)>=1
                        xForce(mote) = xForce(mote) + xF;
                        yForce(mote) = yForce(mote) + yF;
                        xForceCount(mote) = xForceCount(mote) + 1;
                        yForceCount(mote) = yForceCount(mote) + 1;
                    else
                        xForce(neighbor) = xForce(neighbor) - .5*xF;
                        yForce(neighbor) = yForce(neighbor) - .5*yF;
                        xForce(mote) = xForce(mote) + .5*xF;
                        yForce(mote) = yForce(mote) + .5*yF;
                        xForceCount(neighbor) = xForceCount(neighbor) + 1;
                        yForceCount(neighbor) = yForceCount(neighbor) + 1;
                        xForceCount(mote) = xForceCount(mote) + 1;
                        yForceCount(mote) = yForceCount(mote) + 1;
                    end
                end
            end
        end
    end
    for i=1:length(LOCALIZATION.moteIDs)
        moteID = LOCALIZATION.moteIDs(i);
        if sum((moteID == LOCALIZATION.fixed) == 1)<1
            LOCALIZATION.locations(moteID,1) = locations(moteID,1) + alpha*xForce(moteID)/xForceCount(moteID) + rand*(2-1)*.01*MAX_NETWORK_DIMENSION;
            LOCALIZATION.locations(moteID,2) = locations(moteID,2) + alpha*yForce(moteID)/yForceCount(moteID) + rand*(2-1)*.01*MAX_NETWORK_DIMENSION;
        end
    end
end

%and plot them
hold off
scatter(LOCALIZATION.locations(:,1),LOCALIZATION.locations(:,2))
hold on
for i=1:length(LOCALIZATION.moteIDs)
    text(LOCALIZATION.locations(LOCALIZATION.moteIDs(i),1)+2*.01*MAX_NETWORK_DIMENSION,LOCALIZATION.locations(LOCALIZATION.moteIDs(i),2)+2*.01*MAX_NETWORK_DIMENSION,num2str(LOCALIZATION.moteIDs(i)))
    [x,y]=getLocation(LOCALIZATION.moteIDs(i));
    if sum((LOCALIZATION.moteIDs(i) == LOCALIZATION.fixed) == 1)<1
        plot(x,y,'.r')
    else
        plot(x,y,'.g')
    end
end
hold off
