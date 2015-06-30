MagTracking Demo README
Date: January 30, 2003
Author: Cory Sharp <cssharp@eecs.berkeley.edu>

$Id: README.MagTrackingDemo.txt,v 1.2 2003/01/31 21:20:50 cssharp Exp $


--------------------------
"QUICK" START INSTRUCTIONS
--------------------------

1. TinyOS 1.0 must be installed and functional.

2. Set the TOSDIR environment variable.  TOSDIR points to the base directory of
TinyOS; that is, the full path to tinyos-1.x/tos/.

    EXAMPLE: export TOSDIR=$HOME/tinyos-1.x/tos

3. The UCB NestArch requires perl as a part of the build process.  Ensure a
recent version of perl is installed.

4. The magnetometer sensor mote code is in the directory MagTrackingSensor/.

  4.a. The magnetometer motes lay on a grid of arbitrary, even spacing.  There
  may be at most 16 motes in one direction, allowing for grid sizes from 1x1 to
  16x16, or anything in between.  The network id (TOS_LOCAL_ADDRESS) of each
  mote specifies its location in "mote units".  For instance, the network id's
  and corresponding positions for a 4x3 grid of motes look like this

	       0x202  0x212  0x222  0x232
	       (0,2)  (1,2)  (2,2)  (3,2)

	    ^  0x201  0x211  0x221  0x231
	    |  (0,1)  (1,1)  (2,1)  (3,1)
	    |
	       0x200  0x210  0x220  0x230
       Y-axis  (0,0)  (1,0)  (2,0)  (3,0)

	    .  X-axis -->
  
  4.b.  Build the MagTrackingSensor code with "make mica" from inside the
  MagTrackingSensor/ directory.

  4.c.  Install the MagTrackingSensor code with "make mica reinstall.0x2XY", on
  as many motes as desired.

  4.d.  Place the motes on a grid as shown above.

5. The camera pointer code is in the directory CameraPointer/.

  5.a. The camera code controls a Sony EVI-D30 camera.  This is a pan-tilt-zoom
  camera commonly used for teleconferencing, and should be easy to acquire if
  one is not readily available near your lab.

  5.b. The camera may be placed anywhere in the world relative to mote (0,0),
  providing you can fully specify the position and rotation of the base of the
  camera in 3-space.  The position may be specified in whatever units you favor
  (inches, centimeters, meters, furlongs, light-seconds, etc) relative to the
  mote axes.  A conversion factor must be supplied that transforms mote units
  to your particular camera units.  The camera base rotations are given in
  degrees.

  The default camera base position, rotation, and world scale are

    pos.x =  90 inches,   pos.y = -20 inches,   pos.z = 60 inches
    rot.x = -45 degrees,  rot.y =   0 degrees,  rot.z =  0 degrees
    world_scale = 22.5 inches / mote_unit

  which specifies 22.5 inches between each mote, and places the camera base 20
  inches directly behind mote (4,0), 5 feet in the air, pointing in the
  direction of the Y-axis, tilted down at a 45 degree angle.

  To change these defaults, edit CameraPointerM.nc and edit the lines near the
  top of the file that begin with "//!! Config".

  5.c. The camera mote MUST have network id 0x300.

  5.d. Build and install the CameraPointer code with "make mica install.0x300".

6. Run the demo

  6.a. Slowly turn on the MagTrackingSensor motes.

  6.b. Place and power the camera.  Attach the CameraPointer mote to a
  programming board.  Attach that programming board to the "Visca In" port of
  the Sony EVI-D30 camera using a null modem cable.  Due to the current
  initialization procedure, the CameraPointer mote must be turned on only after
  it has been attached to the camera.

  6.c. Excite a varying magnetic field within the mote grid, possibly with a
  large magnet velcro-ed to a remote control car.

  6.d. Observe the camera video.

  6.e. Enjoy.

7. See tools/README for instructions on running the corresponding Matlab
visualization.

