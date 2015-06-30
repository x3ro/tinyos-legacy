function valOut = convertCameraCoords(valIn, convertTo)
% convertCameraCoords -- convert to/from a vector in camera coordinates to pan,tilt in degrees
%   valOut = convertCameraCoords(valIn, convertTo) operates in two conversion modes:
%   if convertTo = 'camera' then,
%     valIn = [ pan ; tilt ] in degrees and valOut = [ x ; y ; z ] is a unit vector in
%     camera coordinates that points from the camera focus in the direction of the given
%     pan and tilt
%   if convertTo = 'degrees' then,
%     valIn = [ x ; y ; z ] is a vector in camera coordinates and valOut = [ pan ; tilt ] is
%     the pan and tilt required by the camera to look along this vector
%
%  NOTE:  requires a previous call to defineCameraEnvironment to function properly

% Shawn Schaffert, 2002-06-27

global CAMERA_PARAMS

switch lower(convertTo)
    
case 'camera'
    
    pan = valIn(1);
    tilt = valIn(2);
    
    %assume y = 1; since we will make a unit vector it doesn't matter
    y = 1;
    x = tan( pi / 180 * pan );
    diag = sqrt( sum( [x;y].^2 ) );
    z = diag * tan( pi / 180 * tilt );
        
    v = [x ; y ; z];
    valOut = v / norm(v);
    
case 'degrees'

    d = valIn;   %direction camera needs to point
    d_cam = inv( CAMERA_PARAMS.T ) * d; %convert direction camera needs to point to camera coordinate frame
    
    %determine pan,tilt in degrees
    x = d_cam(1);
    y = d_cam(2);
    z = d_cam(3);
    pan = 180 / pi * atan2( x , y );
    tilt = 180 / pi * atan2( z , sqrt( sum( [x;y].^2 ) ) );
    
    valOut = [pan ; tilt];
    
otherwise
    disp('In covertCameraCoords: ERROR, conversion type not supported');
end
