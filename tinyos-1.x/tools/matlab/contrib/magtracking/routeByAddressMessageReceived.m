function routeByAddressMessageReceived(address, message)
global MAG_TRACKING


MAG_TRACKING.xCameraPositions(end+1)=message.get_xEstimate/256;
MAG_TRACKING.yCameraPositions(end+1)=message.get_yEstimate/256;
MAG_TRACKING.CameraPositionTimes(end+1)=cputime;
