function displayTracksCallback( track )

% assume tracks are given in "RFS GPS" coordinates
% assume the imported map is align with North at the top of the image
% assume the fire hydrant is (0,0) where x is East and y is North

global G_displayTracks

if isempty( G_displayTracks )
    error('Do not call this function directly (instead call startDisplayTracks or stopDisplayTracks)');
    error('No connection has been establish');
end


% continuously read tracks and display them
% assume each track is described as a matrix in the following
% form (NOTE that trackID is repeated to fill out the matrix):
% row 1 : trackID   trackID   ...
% row 2 : x1        x2        ...
% row 3 : y1        y2        ...
%

% get the new track
%[ conn , track ] = recv( conn );
if G_displayTracks.debug
    sprintf( 'receiving the following new/updated track:' );
    track
end
trackId = track(1,1);
G_displayTracks.tracks{ trackId } = track(2:3,:);

% draw the RFS map
axes( G_displayTracks.axHand );
hold off;
image( G_displayTracks.xx.*G_displayTracks.sx , G_displayTracks.yy.*G_displayTracks.sy , G_displayTracks.mapImage );
axis equal;
hold on;

% draw each track
colors = [ 'r' 'g' 'b' 'k' 'w' ];
for k = 1:length( G_displayTracks.tracks )
    track = G_displayTracks.tracks{k};
    if k <= length( colors )
	color = colors(k);
    else
	color = 'w';
    end
    if ~isempty( track )
	tmp = plot( track(1,:) , track(2,:) , color );
	set( tmp , 'LineWidth' , 2 );
    end
end
    
if G_displayTracks.render
    renderAxes( G_displayTracks.axHand , '' );
end
