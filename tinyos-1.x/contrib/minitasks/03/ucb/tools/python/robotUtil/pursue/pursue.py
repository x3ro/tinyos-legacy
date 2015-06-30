#!/usr/bin/python
#cmd line: ./pursue HOST PORT
# where (HOST,PORT) are where to read mag and rssi packets from
# ie, a pointer to SerialForwarder.java


#--------------------------------------------------#
# Notes
#--------------------------------------------------#
# try to print values in (mote,meters, floating point)
# however to interact with robot we will use
# (mote, mm, floating point).  GPS values should
# be converted right away in mote values
#
# sensor buffers:
#   ( sxg  , syg  ) : gps x,y of myself
#   sdg             : magnitude of gps deviation of myself
#   ( sxr  , syr  ) : rssi x,y of myself
#   ( pxg  , pyg  ) : gps x,y of other pursuer
#   ( pxr  , pyr  ) : rssi x,y of other pursuer
#   ( exg  , eyg  ) : gps x,y of evader
#   ( uxm  , uym  ) : magnetometer x,y of unknown object
#
# estimated state buffers:
#   ( sxEst , syEst , stEst) : estimated x,y,theta of myself
#   ( pxEst , pyEst , ptEst) : estimated x,y,theta of other pursuer
#   ( exEst , eyEst ) : estimated x,y of evader
#
# new sensor reading (True/False):
#   sg : self gps
#   sr : self rssi
#   pg : pursuer gps
#   pr : pursuer rssi
#   eg : evader gps
#   um : unknown magnetometer



#--------------------------------------------------#
# Libraries
#--------------------------------------------------#
from fpformat import fix
import sys, math, socket, time

from AriaPy import *
from GpsBoxPython import *

import TerminalFile, motePacket, estimate, moteGps
from robotSupport import *
from config import *




#--------------------------------------------------#
# Init
#--------------------------------------------------#
sxg = []
syg = []
sdg = []
#sxr = []
#syr = []
#exg = []
#eyg = []
uxm = []
uym = []
sxEst = []
syEst = []
stEst = []
exEst = []
eyEst = []
sg = False
#sr = False
#eg = False
um = False

f = file( PURSUE_LOG_FILENAME , "w" )

printFile( ">>> Initializing system" , f )
printFile( "" , f )

robot = ArRobot()
conn = ArTcpConnection()
Aria.init()

conn.setPort()

robot.setDeviceConnection( conn )
if (robot.blockingConnect() != 1):
    printFile( "Could not connect to robot, exiting" , f )
    Aria.shutdown()
    sys.exit(1)

robot.runAsync(1)
robot.lock()
robot.enableMotors()
robot.unlock()

gps = GpsBox( "serial,/dev/ttyS3,115200" )
keyboardInput = TerminalFile.TerminalFile( sys.stdin )  #scan stdin for keypress

#set up a socket for receiving evader information
evaderHost = sys.argv[1]
evaderPort = int(sys.argv[2])
s = socket.socket( socket.AF_INET , socket.SOCK_STREAM )
s.connect(( evaderHost , evaderPort ))
s.setblocking(0)



#--------------------------------------------------#
# Determine initial position/heading
#--------------------------------------------------#

#start the robot moving forward in a straight line
printFile( "" , f )
printFile( ">>> Initialize the robot's state" , f )
printFile( "" , f )
printFile( "--- Driving straight to initialize heading" , f )
printFile( "" , f )
robot.lock()
robot.move( PURSUE_INIT_DIST*1000 )
robot.unlock()

#take gps measurements while the robot moves
while not robot.isMoveDone( PURSUE_INIT_DIST_TOL*1000 ) :
    if gps.iterate( PURSUE_GPS_TIME_OUT ):

        #update our buffers of x,y points
        #take gps points in meters and convert to mote
        (x, y) = moteGps.gpsToMote(( gps.rfs().getCurrentX() , -gps.rfs().getCurrentY() ))
        updateBuffer( sxg , x )
        updateBuffer( syg , y )
        prtkb = gps.prtkb()
        dev = (prtkb.dev_latitude**2 + prtkb.dev_longitude**2)**(0.5)
        updateBuffer( sdg , dev )
        printFile( "--- GPS: (" + fix(x,4) + ", " + fix(y,4) + ")  --  dev:" + fix(dev,2) , f )

#use the collected x,y values to estimate and update the robot's state
printFile( "--- Updating robot's idea of its position" , f )
(x, y, t) = estimateRobotState( sxg , syg )
updateBuffer( sxEst , x )
updateBuffer( syEst , y )
updateBuffer( stEst , t )
printFile( "--- Estimated State: (" + fix(sxEst[-1],4) + ", " + fix(syEst[-1],4) + ", " + fix(stEst[-1],4) + ")" , f )
updateRobotState( robot , sxEst[-1] , syEst[-1] , stEst[-1] )

#clear the motion commands so actions or other motions can be executed
robot.lock()
robot.clearDirectMotion()
robot.unlock()




#--------------------------------------------------------------------------#
# Main control loop
#--------------------------------------------------------------------------#

#give the user a chance to abort at this point
printFile( "--- Press q to quit or c to continue" , f )
waiting = True
while waiting:
    charIn = keyboardInput.getch()
    if charIn == "q":
        shutdownRobot( robot , conn )
        sys.exit(1)
    if charIn == "c":
        waiting = False
    time.sleep(.2)

#set up a default goto action: goto your current location
#then we can just update this goal with the evader's position
printFile( "--- Setting up a default goto action" , f )
evaderPos = ArPose(sxEst[-1]*1000, syEst[-1]*1000, stEst[-1])
chaseEvaderAction = ArActionGoto( "chaseEvader", evaderPos, PURSUE_GOAL_TOL*1000, PURSUE_MAX_SPEED*1000, PURSUE_TURN_SPEED, PURSUE_TURN_ADJ )
robot.lock()
robot.addAction( chaseEvaderAction, 100 )  #set action with priority 100
robot.unlock()

#init main loop
printFile( ">>> Beginning evader chase routine" , f )
printFile( "" , f )
printFile( "--- Press q to quit at any time" , f )
printFile( "" , f )

iteration = 1
sgTick = 0
trackingEvader = False
buffer = ""

while keyboardInput.getch() != "q":

    printFile( "" , f )
    printFile( "" , f )
    printFile( ">>>>>>>>>>>>>>>>>>>>Iteration Number "+fix(iteration,0)+"<<<<<<<<<<<<<<<<<<<<" , f )




    ########################################################################
    # Check for new sensor readings (gps, mote packets, etc)
    ########################################################################

    #--------------------------------------------------#
    # Check for new mag packets
    #--------------------------------------------------#
    printFile( ">>> Searching for new mag packets" , f )
    um = False
    try:
        #while there is data to be read from the socket, keep doing that
        p = None
        while not p:
            buffer = buffer + s.recv(1)
            if len( buffer ) >= SOCKET_PACKET_LENGTH:
                buffer = buffer[-SOCKET_PACKET_LENGTH:]
                p = motePacket.findMagPacket( buffer )

        #we have found a good mag packet
        um = True
        x = p["magObjectX"]
        y = p["magObjectY"]
        updateBuffer( uxm , x )
        updateBuffer( uym , y )
        printFile( "--- Packet Found. Object at: (" + fix(x,2) + ", " + fix(y,2) + ")" , f )
        printFile( "" , f )

    except socket.error :
        printFile( "--- No new mote packets found" , f )
        printFile( "" , f )

    #-----------------------------------------------------#
    # Check for new GPS data
    #-----------------------------------------------------#
    printFile( ">>> Searching for new GPS update" , f )
    sg = False
    if gps.iterate( PURSUE_GPS_TIME_OUT ):

        sg = True

        #update our running buffers of x,y points
        (x, y) = moteGps.gpsToMote(( gps.rfs().getCurrentX() , -gps.rfs().getCurrentY() ))
        updateBuffer( sxg , x )
        updateBuffer( syg , y )
        prtkb = gps.prtkb()
        dev = (prtkb.dev_latitude**2 + prtkb.dev_longitude**2)**(0.5)
        updateBuffer( sdg , dev )
        printFile( "--- GPS: (" + fix(x,4) + ", " + fix(y,4) + ")  --  dev:" + fix(dev,2) , f )
        
    else:
        printFile( "--- No new GPS update available" , f )




    ########################################################################
    # Filter Sensor Readings and State Estimation
    ########################################################################
    printFile( ">>> Filtering data" , f )

    #keep a current estimate of my state (even though I don't update the robot's dead reckoning)
    (x, y, t) = estimateRobotState( sxg , syg )
    updateBuffer( sxEst , x )
    updateBuffer( syEst , y )
    updateBuffer( stEst , t )

    #process the new mag sensor readings
    if um :
        
        d = dist( (sxEst[-1],syEst[-1]) , (uxm[-1],uym[-1]) )
        printFile( "--- The distance between the new object and me is: " + fix(d,2) , f )
        if d < PURSUE_SELF_MAG_RADIUS :
            printFile( "----- This object is me or the evader is caught" , f )
            printFile( "----- I'm going to ignore this reading" , f )
        else:
            printFile( "----- This object is the evader" , f )

            #add these readings to the evader's estimated position
            updateBuffer( exEst , uxm[-1] )
            updateBuffer( eyEst , uym[-1] )
            
            #update our goto action to head towards the evader
            printFile( "----- Setting a new course for the evader" , f )
            evaderPos = ArPose( exEst[-1]*1000 , eyEst[-1]*1000 , 0 )  #theta is ignored, so use 0
            chaseEvaderAction.setGoal( evaderPos )
            trackingEvader = True
            





    ########################################################################
    # Update my sense of state
    ########################################################################
    if sg :  #if there is new gps data
        sgTick += 1
        if sgTick >= PURSUE_NUM_GPS_TICKS_UPDATE:  #if there is enough new data
            sgTick = 0
            printFile( "--- Updating robot's idea of its position" , f )
            printFile( "--- Estimated State: (" + fix(sxEst[-1],4) + ", " + fix(syEst[-1],4) + ", " + fix(stEst[-1],4) + ")" , f )
            updateRobotState( robot , sxEst[-1] , syEst[-1] , stEst[-1] )





    ########################################################################
    # Invoke *Explicit* control (instead of just letting goto-action do it's thing)
    ########################################################################

    printFile( ">>> Applying explicit control" , f )

    #-----------------------------------------------------#
    # Check your goal status
    #-----------------------------------------------------#
    if ( sxEst and syEst and exEst and eyEst ) and \
       ( dist( (sxEst[-1], syEst[-1]) , (exEst[-1], eyEst[-1]) ) < PURSUE_GOAL_TOL ) and \
           trackingEvader :
        printFile( "--- Evader Captured" , f )
        trackingEvader = False



    #-----------------------------------------------------#
    # Don't crash into evader
    #-----------------------------------------------------#
    if ( sxEst and syEst and exEst and eyEst ) and \
       ( dist( (sxEst[-1], syEst[-1]) , (exEst[-1], eyEst[-1]) ) < PURSUE_CRASH_RADIUS ) :

        #set goal to where I am to stop me from moving
        printFile( "--- Stopping myself so I don't crash into evader" , f )
        stopPos = ArPose( robot.getX() , robot.getY() , robot.getTh() )
        chaseEvaderAction.setGoal( stopPos )


        
    #-----------------------------------------------------#
    # Don't leave the grid
    #-----------------------------------------------------#
    if ( sxEst and syEst ) :
        inGrid = ( sxEst[-1] >= PURSUE_GRID_X_MIN ) and \
                 ( sxEst[-1] <= PURSUE_GRID_X_MAX ) and \
                 ( syEst[-1] >= PURSUE_GRID_Y_MIN ) and \
                 ( syEst[-1] <= PURSUE_GRID_Y_MAX )

        if not inGrid :
            #I'm outside the grid, set course for the middle
            printFile( "--- I'm outside the grid; Setting course for middle", f)
            gridMiddlePos = ArPose( float(PURSUE_GRID_X_MIN + PURSUE_GRID_X_MAX) * 1000 / 2 , \
                                    float(PURSUE_GRID_Y_MIN + PURSUE_GRID_Y_MAX) * 1000 / 2 ,
                                    0 )
            chaseEvaderAction.setGoal( gridMiddlePos )



    #-----------------------------------------------------#
    # Adjust speed according to the gps deviation
    #-----------------------------------------------------#
    speed = PURSUE_MAX_SPEED
    if sdg and sdg[-1] > PURSUE_GPS_DEV_MIN :

        dev = sdg[-1]
        if dev > PURSUE_GPS_DEV_MAX:
            dev = PURSUE_GPS_DEV_MAX

        slope = ( float( PURSUE_MAX_SPEED - PURSUE_MIN_SPEED ) ) / ( PURSUE_GPS_DEV_MIN - PURSUE_GPS_DEV_MAX )
        speed = slope * ( dev - PURSUE_GPS_DEV_MAX ) + PURSUE_MIN_SPEED
    chaseEvaderAction.setSpeed( speed*1000 )
    printFile( "--- Setting speed to: " + fix(speed,2) , f )
    

    iteration += 1



####################################################
#shutdown stuff
####################################################
s.close()  #close the socket
f.close() #close the log file
shutdownRobot( robot , conn )
