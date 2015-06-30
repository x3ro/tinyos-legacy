function renderAxes( axHand , filename )


if nargin < 2, filename = ''; end

if isempty( filename ), filename = 'map_tracks.jpg'; end


dest = [ './public_html/' filename ];
tmpFilename = [ './public_html/TMP.' filename ];

[X,cMap] = frame2im( getframe( axHand ) );
if ~isempty( cMap )
    imwrite( X , cMap , filename , 'jpg' , 'Quality' , 70 );
else
    imwrite( X , tmpFilename , 'jpg' , 'Quality' , 70 );
end
copyfile( tmpFilename , dest , 'f' );


%w = 400/72;
%h = 300/72;
%set( f , 'PaperSize' , [w h] );
%set( f , 'PaperPosition' , [0 0 w h] );
%get( f )
%print -dpng -r72 map_tracks.png