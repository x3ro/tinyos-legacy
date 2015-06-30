function defineCameraEnvironment(serialPortString, positionInches, baseRotationDegrees, descentAngleDegrees, zoomFactor)
%defineCameraEnvironment  --  one time setup of camera
%  defineCameraEnvironment(serialPortString, positionInches, baseRotationDegrees, ...
%  descentAngleDegrees, zoomFactor) sets up a serial communication channel
%  with the camera and defines where the camera is with respect to the global coordinate
%  system.  Here are units are in inches or degrees (zoomFactor is a unitless zoom
%  multiplier).  The function inputs are as follows:
%    serialPortString is the name of the COM port the camera is connected to (ex: 'COM1')
%    positionInches = [x ; y ; z] is the position of the *camera* (not tripod) base in global coordinate system
%    descentAngleDegrees is the descent angle that the camera base makes with horizon
%    zoomFactor is a multiplicative factor that determines how much zoom is needed for objects farther away

% Shawn Schaffert, 2002-06-27

%note that using the global command makes these as empty objects if they don't exist
global CAMERA_PARAMS
global ROOT

%one time init
if isempty(CAMERA_PARAMS)
    CAMERA_PARAMS.cameraPathDone = 0;
    CAMERA_PARAMS.camSerialPortOpen = 0;
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CAMERA_PARAMS.debug = 0;

%conversions
rho = descentAngleDegrees * pi / 180;
phi = baseRotationDegrees * pi / 180;
s = positionInches;

%repackage
CAMERA_PARAMS.zoomFactor = zoomFactor;

%physical hard-coded parameters camera params 
CAMERA_PARAMS.cameraBaseHeight = 2.5;  %distance (inches) from tripod base to focus of camera
CAMERA_PARAMS.minPanDegrees = -100;  %in degrees
CAMERA_PARAMS.maxPanDegrees = 100;
CAMERA_PARAMS.minTiltDegrees = -25;
CAMERA_PARAMS.maxTiltDegrees = 25;

%software hard-coded camera params -- these are the min/max values that you can send in a packet to camera
CAMERA_PARAMS.minTiltCam = -360;
CAMERA_PARAMS.maxTiltCam = 360;
CAMERA_PARAMS.minPanCam = -1440;
CAMERA_PARAMS.maxPanCam = 1440;
CAMERA_PARAMS.minZoomCam = 0;
CAMERA_PARAMS.maxZoomCam = 28672;

%derived params
w = CAMERA_PARAMS.cameraBaseHeight;
baseRotationMatrix = [ cos(phi) -sin(phi) 0 ; sin(phi) cos(phi) 0 ; 0 0 1];  %account for tripod rotation
cameraTiltMatrix = [ 1 0 0 ; 0 cos(rho) sin(rho) ; 0 -sin(rho) cos(rho) ]; %account for camera base tilting downward
CAMERA_PARAMS.T = cameraTiltMatrix * baseRotationMatrix;  %columns are camera coord basis wrt global frame
CAMERA_PARAMS.cameraPosition = s + CAMERA_PARAMS.T * [0 ; 0 ; w]; %focus of camera in global coordinates



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ONE-TIME SETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%setup path if it hasn't been done yet
setNewPath = 0;
if ~isempty(ROOT) & ~CAMERA_PARAMS.cameraPathDone
    addpath([ROOT '/contrib/camera'])
    CAMERA_PARAMS.cameraPathDone = 1;        
end

%open serial port to camera if it hasn't been done yet
if ~CAMERA_PARAMS.camSerialPortOpen

    %specify a serial port object for the camera
    s = serial(serialPortString);
    s.InputBufferSize = 128;
    s.OutputBufferSize = 128;
    s.BaudRate = 9600;
    s.DataBits = 8;
    s.StopBit = 1;
    s.Parity = 'none';
    s.ByteOrder = 'bigEndian';  %MSB first
    s.FlowControl = 'none';  %neither XON/XOFF (software) or RTS/CTS (hardware) flow ctrl is supported
    s.ReadAsyncMode = 'manual';  %this means, I will manually call readasync() periodically to prevent data loss
    s.Timeout = 1; 
    
    %open the serial port
    fopen(s);
    CAMERA_PARAMS.camSerialPort = s;
    CAMERA_PARAMS.camSerialPortOpen = 1;

    %set the camera's address
    fwrite(CAMERA_PARAMS.camSerialPort, hex2dec([ '88' ; '30' ; '01' ; 'ff' ]), 'uchar', 'sync');
    
    %clear command buffer
    fwrite(CAMERA_PARAMS.camSerialPort, hex2dec([ '81' ; '01' ; '00' ; '01' ; 'ff' ]), 'uchar', 'sync');
    
end
