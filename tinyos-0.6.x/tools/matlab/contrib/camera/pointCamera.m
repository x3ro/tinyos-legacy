function pointCamera(p)
%pointCamera -- point the camera at a given point
%  pointCamera(p) points the camera at the three-dimension point p where
%  p is in global coordinates

% Shawn Schaffert, 2002-06-27

global CAMERA_PARAMS

%convert position to look at into pan/tilt degrees
c = CAMERA_PARAMS.cameraPosition;  %precalculated camera position
d = p - c;   %direction camera needs to point
tmp = convertCameraCoords(d,'degrees');
pan = tmp(1);
tilt = tmp(2);

%determine amount of zoom
distance = sqrt(sum(d.^2));  %distance between camera focus and object to look at
zoom = CAMERA_PARAMS.zoomFactor * distance;

%convert everything to hex camera units
panCamHex = convertCameraUnits('pan', pan, 'camera');
tiltCamHex = convertCameraUnits('tilt', tilt, 'camera');
zoomCamHex = convertCameraUnits('zoom', zoom, 'camera');

%send pan, tilt, zoom to camera
if strcmp( get( CAMERA_PARAMS.camSerialPort, 'status' ), 'open' )

    %constants
    header = '81';  %from controller (address 0) to the only camera (address 1)
    terminator = 'ff';  %end of packet
    
    %zoom packet
    packet = {};
    packet{1} = [header ; '01' ; '04' ; '47' ; '0' zoomCamHex(1) ; '0' zoomCamHex(2) ; '0' zoomCamHex(3) ; '0' zoomCamHex(4) ; terminator];
    
    %pan/tilt packet
    panSpeed = '18';
    tiltSpeed = '14';
    packet{2} = [header ; '01' ; '06' ; '02' ; panSpeed ; tiltSpeed ; ...
            '0' panCamHex(1) ; '0' panCamHex(2) ; '0' panCamHex(3) ; '0' panCamHex(4) ; ...
            '0' tiltCamHex(1) ; '0' tiltCamHex(2) ; '0' tiltCamHex(3) ; '0' tiltCamHex(4) ; terminator];
    
    %inject packet
    if CAMERA_PARAMS.debug
        disp('Sending Camera Packet...');
        disp(['Desired:     Pan, Tilt, Zoom: ' num2str(pan) ' , ' num2str(tilt) ' , ' num2str(zoom)]);
        disp(['Sent(hex):   Pan, Tilt, Zoom: ' num2str(panCamHex) ' , ' num2str(tiltCamHex) ' , ' num2str(zoomCamHex)]);
    end
    for i = 1:2
        fwrite(CAMERA_PARAMS.camSerialPort, hex2dec(packet{i}), 'uchar', 'sync');
        displayText = [];
        for j = 1:size(packet{i},1)
            displayText = [displayText ' ' packet{i}(j,:) ];
        end
        if CAMERA_PARAMS.debug, disp(displayText); end
    end
    if CAMERA_PARAMS.debug, disp('....done'); end
else
    disp('ERROR (in pointCamera): Camera Serial Port Not Open');
end
