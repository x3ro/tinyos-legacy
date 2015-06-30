This is for use with the Sony EVI-D100 Camera (possibly the EVI-D30).

To initialize the camera communication and let the camera know its
location and orientation, call defineCameraEnvironment(...).  After
this, to point the camera call pointCamera([x;y;z]).  Finally, when 
you are done with the camera, call releaseCameraEnvironment to close
the camera communication.  Look at demoCamera.m for a quick functional
demo.


