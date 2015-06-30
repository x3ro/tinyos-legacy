function calibrateCameraManual(comPortString)
%calibrateCameraManual -- manually adjust the calibration constants of the camera
%  calibrateCameraManual(comPortString) is a stand-alone function used to
%  manually calibrate the camera on COM port comPortString (ex: comPortString = 'COM1').
%  This function iteratively asks the user for the calibration constants and then
%  provides feedback by pointing at all four corners of the grid.  The calibration
%  constants are:
%    camera base location (3 dimensional point in global coordinate frame, inches)
%    camera base descent angle (in degrees)
%    camera tripod base rotation (in degrees)

% Shawn Schaffert, 2002-06-27

global CAMERA_PARAMS

%default calibration parameters
xInches = 24;
yInches = -24;
zInches = 52.5;
baseRotationDegrees = 0;
descentAngleDegrees = 45;
zoomFactor = 80;

%field size
fieldInchesX0 = 0;
fieldInchesX1 = 96;
fieldInchesY0 = 0;
fieldInchesY1 = 96;

%initialize camera
defineCameraEnvironment(comPortString, [xInches;yInches;zInches], baseRotationDegrees, ...
    descentAngleDegrees, zoomFactor);

%get zoomFactor and fieldInches
zoomFactor = inputDefault('Camera zoom factor', zoomFactor);
fieldInchesX0 = inputDefault('Field Size in Inches, x0', fieldInchesX0);
fieldInchesX1 = inputDefault('Field Size in Inches, x1', fieldInchesX1);
fieldInchesY0 = inputDefault('Field Size in Inches, y0', fieldInchesY0);
fieldInchesY1 = inputDefault('Field Size in Inches, y1', fieldInchesY1);
fieldInches = [fieldInchesX0 fieldInchesX1 fieldInchesY0 fieldInchesY1];

done = 0;
while ~done

    %let user try out new parameters
    xInches = inputDefault('Camera Position in Inches, x', xInches);
    yInches = inputDefault('Camera Position in Inches, y', yInches);
    zInches = inputDefault('Camera Position in Inches, z', zInches);
    baseRotationDegrees = inputDefault('Camera Base Rotation in Degrees', baseRotationDegrees);
    descentAngleDegrees = inputDefault('Camera Base Descent Angle in Degrees', descentAngleDegrees);

    %setup camera with new parameters
    defineCameraEnvironment(comPortString, [xInches;yInches;zInches], baseRotationDegrees, ...
        descentAngleDegrees, zoomFactor);
    
    %try the new setup by pointing at the four corners
    pointCamera([fieldInchesX0 ; fieldInchesY0 ; 0]);
    pause;
    pointCamera([fieldInchesX1 ; fieldInchesY0 ; 0]);
    pause;
    pointCamera([fieldInchesX1 ; fieldInchesY1 ; 0]);
    pause;
    pointCamera([fieldInchesX0 ; fieldInchesY1 ; 0]);
    pause;
    pointCamera([fieldInchesX0 ; fieldInchesY0 ; 0]);
    pause;
    
    %quit?
    askDone = lower( input('Quit? (y/n) [default n]','s') );
    if ~isempty(askDone)
        if strcmp(askDone, 'y'), done = 1; end
    end
    
end

%cleanup
releaseCameraEnvironment;

