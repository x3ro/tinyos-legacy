function releaseCameraEnvironment()
%releaseCameraEnvironment -- free resources used by the camera
%  releaseCameraEnvironment closes the serial port used by the camera, but
%  does not remove the global variable CAMERA_PARAMS used by the camera functions

% Shawn Schaffert, 2002-06-27

global CAMERA_PARAMS

fclose(CAMERA_PARAMS.camSerialPort);
delete(CAMERA_PARAMS.camSerialPort);
CAMERA_PARAMS.camSerialPortOpen = 0;
