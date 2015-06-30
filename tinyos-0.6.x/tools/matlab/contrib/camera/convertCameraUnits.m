function newVal = convertCameraUnits(valueInType, valueIn, convertTo)
%convertCameraUnits -- convert between camera units and pan/tilt/zoom
%  newVal = convertCameraUnits(valueInType, valueIn, convertTo) uses the
% following conventions for its input/output parameters:
%
%   valueInType specifies what kind of value valueIn is, and must be one
%     of the following: 'pan', 'tilt', 'zoom'.
%
%   valueIn is the value to be converted.
%
%   convertTo specifies whether, the value is to be converted to camera
%     hexidecimal units (use convertTo = 'camera') or "real-world" values (such
%     as degrees or no units for zoom) (use convertTo = 'real').
%
%NOTE: defineCameraEnvironment must be called prior to using this function.

% Shawn Schaffert, 2002-06-27

global CAMERA_PARAMS


convertTo = lower(convertTo);
switch lower(valueInType)
    
case 'pan'

    panSlope = (CAMERA_PARAMS.maxPanCam - CAMERA_PARAMS.minPanCam) / (CAMERA_PARAMS.maxPanDegrees - CAMERA_PARAMS.minPanDegrees);
    if strcmp(convertTo, 'real')
        panCam = hex2dec(valueIn);
        if panCam > CAMERA_PARAMS.maxPanCam
            panCam = panCam - 2^16;
        end
        panDegrees = (panCam - CAMERA_PARAMS.minPanCam) / panSlope + CAMERA_PARAMS.minPanDegrees;
        newVal = clip(panDegrees, CAMERA_PARAMS.minPanDegrees, CAMERA_PARAMS.maxPanDegrees);
    elseif strcmp(convertTo, 'camera')
        panCam = panSlope * ( valueIn - CAMERA_PARAMS.minPanDegrees ) + CAMERA_PARAMS.minPanCam; 
        panCam = clip(panCam, CAMERA_PARAMS.minPanCam, CAMERA_PARAMS.maxPanCam);
        if panCam >= 0, newVal = dec2hex(panCam,4);
        else, newVal = dec2hex((2^16 + panCam),4); end
    else
        disp('ERROR (in convertCameraUnits): conversion type not supported');
    end
    
    
case 'tilt'
    
    tiltSlope = (CAMERA_PARAMS.maxTiltCam - CAMERA_PARAMS.minTiltCam) / (CAMERA_PARAMS.maxTiltDegrees - CAMERA_PARAMS.minTiltDegrees);
    if strcmp(convertTo, 'real')
        tiltCam = hex2dec(valueIn);
        if tiltCam > CAMERA_PARAMS.maxTiltCam
            tiltCam = tiltCam - 2^16;
        end
        tiltDegrees = (tiltCam - CAMERA_PARAMS.minTiltCam) / tiltSlope + CAMERA_PARAMS.minTiltDegrees;
        newVal = clip(tiltDegrees, CAMERA_PARAMS.minTiltDegrees, CAMERA_PARAMS.maxTiltDegrees);
        
    elseif strcmp(convertTo, 'camera')
        tiltCam = tiltSlope * ( valueIn - CAMERA_PARAMS.minTiltDegrees ) + CAMERA_PARAMS.minTiltCam; 
        tiltCam = clip(tiltCam, CAMERA_PARAMS.minTiltCam, CAMERA_PARAMS.maxTiltCam);
        if tiltCam >= 0, newVal = dec2hex(tiltCam,4);
        else, newVal = dec2hex((2^16 + tiltCam),4); end
    else
        disp('ERROR (in convertCameraUnits): conversion type not supported');
    end
    
    
case 'zoom'
    if strcmp(convertTo, 'real')
        newVal = hex2dec(valueIn);
    elseif strcmp(convertTo, 'camera')
        zoomCam = clip(valueIn, CAMERA_PARAMS.minZoomCam, CAMERA_PARAMS.maxZoomCam);
        newVal = dec2hex(zoomCam,4);
    else
        disp('ERROR (in convertCameraUnits): conversion type not supported');
    end
    
otherwise
    disp('ERROR (in convertCameraUnits): input type not supported');
end
