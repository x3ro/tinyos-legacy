function service_renderTracks( mode , test )


if nargin < 2, test = []; end
if nargin < 1, mode = []; end

if isempty( test ), test = false; end
if isempty( mode ), mode = 'start'; end


global G_renderTracks

mode = lower( mode );
switch mode


 case 'start'

  G_renderTracks = [];
  G_renderTracks.renderTracks = true;


 case 'stop'

  G_renderTracks.renderTracks = false;




 otherwise
  error( 'invalid mode' );
end


%f = figure;
%m = magic(10);
%pcolor(m);
%w = 400/72;
%h = 300/72;
%set( f , 'PaperSize' , [w h] );
%set( f , 'PaperPosition' , [0 0 w h] );
%get( f )
%print -dpng -r72 map_tracks.png