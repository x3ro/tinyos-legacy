% demoCamera.m  -- a sample script that demonstrates how to use the matlab camera environment

% Shawn Schaffert, 2002-07-01

serialPortString = 'COM4';  %the camera is on COM1
positionInches = [ 24 ; -24 ; 52.5 ];  %location of the camera base in the global coord frame
baseRotationDegrees = 0;  %rotation of the tripod relative to the global coord frame
descentAngleDegrees = 45;  %tilt down of the camera base
zoomFactor = 80;

defineCameraEnvironment(serialPortString, positionInches, baseRotationDegrees, descentAngleDegrees, zoomFactor);

done = 0;
while ~done
    x = inputDefault('Enter x position', 0);
    y = inputDefault('Enter y position', 0);
    z = inputDefault('Enter z position', 0);
    
    vec = [ x ; y ; z];
    pointCamera(vec);
    
    %quit?
    askDone = lower( input('Quit? (y/n) [default n]','s') );
    if ~isempty(askDone)
        if strcmp(askDone, 'y'), done = 1; end
    end
end

%clean up
releaseCameraEnvironment;
