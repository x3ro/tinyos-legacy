function service_displayTracks( mode , test , debug , render )


if nargin < 4, render = []; end
if nargin < 3, debug = []; end
if nargin < 2, test = []; end
if nargin < 1, mode = []; end

if isempty( render ), render = false; end
if isempty( debug ), debug = false; end
if isempty( test ), test = false; end
if isempty( mode ), mode = 'start'; end


global G_displayTracks

mode = lower(mode);
switch mode

 case 'start'
  
  if ~isempty( G_displayTracks ) && isfield( G_displayTracks , 'conn' ) && ~isempty( G_displayTracks.conn )
      error('The display tracks service is already started');
  end
  
  if test
      host = '';
  else
      host = '';
  end

  G_displayTracks = [];
  G_displayTracks.debug = debug;
  G_displayTracks.render = render;

  % pixel location of fire hydrant
  G_displayTracks.fhPixel = [ 653 876 ];

  % scale factor (meter/pixel)
  G_displayTracks.sx = 0.45;
  G_displayTracks.sy = 0.45;

  G_displayTracks.figHand = figure;
  set( G_displayTracks.figHand , 'DoubleBuffer' , 'on' );
  G_displayTracks.axHand = axes;
  G_displayTracks.mapImage = [];
  G_displayTracks.tracks = {};

  % setup the RFS map
  [ G_displayTracks.mapImage , G_displayTracks.cMap ] = imread( 'rfs.jpg' , 'jpeg' );
  %G_displayTracks.mapImage = imread( 'rfs.bmp' , 'bmp' );
  %tmp = imfinfo( 'rfs.bmp' );
  %tmp = imfinfo( 'rfs.jpg' );
  %G_displayTracks.cMap = tmp.Colormap;
  colormap( G_displayTracks.cMap );
  G_displayTracks.xx = (1:size( G_displayTracks.mapImage , 2 )) - G_displayTracks.fhPixel(1);
  G_displayTracks.yy = (1:size( G_displayTracks.mapImage , 1 )) - G_displayTracks.fhPixel(2);

  G_displayTracks.displayTracks = true;
  G_displayTracks.conn = Connection( host , 7000 , 7001 , [] , @displayTracksCallback );
  if G_displayTracks.debug
      G_displayTracks.conn
  end


 case 'stop'

  if isempty( G_displayTracks ) || ~isfield( G_displayTracks , 'conn' ) || isempty(G_displayTracks.conn)
      error('The display tracks service is not started');
  end

  G_displayTracks.displayTracks = false;
  G_displayTracks.conn = close( G_displayTracks.conn );
  G_displayTracks.conn = [];






 otherwise
  error('invalid mode');
end