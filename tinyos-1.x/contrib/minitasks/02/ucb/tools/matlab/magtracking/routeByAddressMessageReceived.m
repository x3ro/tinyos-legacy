function routeByAddressMessageReceived(address, message)
%This function receives all routeByAddress Messages.  In the mag tracking
%demo, these messages are only sent to the camera, so I take the position
%that the camera is being directed to and store it, along with it's time
%stamp


global MAG_TRACKING


MAG_TRACKING.xCameraPositions=message.get_xEstimate;
MAG_TRACKING.yCameraPositions=message.get_yEstimate;
MAG_TRACKING.CameraPositionTimes=cputime;
