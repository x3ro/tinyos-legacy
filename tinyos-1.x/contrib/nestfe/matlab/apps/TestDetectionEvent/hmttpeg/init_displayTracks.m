global G_displayTracks

% TO USE:
%   call init_displayTracks
%   create a figure, turn on double-buffering, and get an axesHandle (called axHand )
%   for every new track, check if G_displayTracks.render == true, then call displayTracks( axHand , track , trackNum )
%
% How to turn on double-buffering:
% figHand = figure;
% set( figHand , 'DoubleBuffer' , 'on' );
%
% drop 0's

G_displayTracks = [];
G_displayTracks.fhPixel = [ 653 876 ];

% scale factor (meter/pixel)
G_displayTracks.sx = 0.45;
G_displayTracks.sy = 0.45;

G_displayTracks.mapImage = [];
G_displayTracks.cMap = [];
G_displayTracks.tracks = {};

% setup the RFS map
[ G_displayTracks.mapImage , G_displayTracks.cMap ] = imread( 'rfs.jpg' , 'jpeg' );
%G_displayTracks.mapImage = imread( 'rfs.bmp' , 'bmp' );
%tmp = imfinfo( 'rfs.bmp' );
%tmp = imfinfo( 'rfs.jpg' );
%G_displayTracks.cMap = tmp.Colormap;
%colormap( G_displayTracks.cMap );
%G_displayTracks.xx = (1:size( G_displayTracks.mapImage , 2 )) - G_displayTracks.fhPixel(1);
%G_displayTracks.yy = (1:size( G_displayTracks.mapImage , 1 )) - G_displayTracks.fhPixel(2);


%G_displayTracks.xx = (1:size( G_displayTracks.mapImage , 2 )) - G_displayTracks.fhPixel(1);
%G_displayTracks.yy = (1:size( G_displayTracks.mapImage , 1 )) - G_displayTracks.fhPixel(2);

% the bounds (in GPS coords) of the image file
%xMin = 85.8521222302;
%yMin = -12.0747874918;
%xMax = 43.090329561;
%yMax = -107.255657566;
xMin = -10;
yMin = -10;
xMax = 100;
yMax = -100;
G_displayTracks.xx = xMin:(xMax-xMin)/size( G_displayTracks.mapImage , 2 ):xMax;
G_displayTracks.yy = yMax:-(yMax-yMin)/size( G_displayTracks.mapImage , 1 ):yMin;
%G_displayTracks.xx = (1:size( G_displayTracks.mapImage , 2 )) - 50;
%G_displayTracks.yy = -(1:size( G_displayTracks.mapImage , 1 )) + 500;

% display debugging info
G_displayTracks.debug = false;

% render the axes to a jpeg for the PDAs
G_displayTracks.render = true;

% add the RFS background image
G_displayTracks.addBackground = true;

% state whether the tracks are in gps coords or "grid coords"
G_displayTracks.gpsCoords = true;

% grid coords to GPS coords transformation
G_displayTracks.G = [1 0 0 0;
                     0 1 0 0;
                     0 0 1 0;
                     0 0 0 1];

