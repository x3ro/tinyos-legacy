import math
from fpformat import fix
from AriaPy import *
import estimate
from config import *


def updateBuffer( bufferList , newValue ):
    bufferList.append(newValue)
    bufferList = bufferList[-PURSUE_SENSOR_BUFFER_SIZE:]




def printFile( str , file ):
    print str
    file.write( str + "\n" )




def dist( w , z):
    return ( (w[0] - z[0])**2 + (w[1] - z[1])**2 )**(0.5)




def estimateRobotState( x , y ):
    #estimate x,y,theta

    #if (len(x) < 1) or (len(y) < 1) :
    #    return (None, None, None)
    #else:
    xEst = estimate.mean(x, PURSUE_XY_NUM_AVE)
    yEst = estimate.mean(y, PURSUE_XY_NUM_AVE)
    thetaEst = estimate.estimateTheta(x, y) * 180 / math.pi  #in degrees
    return (xEst, yEst, thetaEst)




def updateRobotState( robot , xEst , yEst , thetaEst ):
    
    #update the robot's idea of it's state with our estimates (xEst, yEst, thetaEst) in meters and degrees
    estPos = ArPose(xEst*1000, yEst*1000, thetaEst)  #update it's internal state (which is in mm,degrees)
    robot.lock()
    robot.moveTo( estPos , True )
    robot.unlock()




def shutdownRobot( robot , conn ) :
    robot.disableMotors()
    robot.stop()
    robot.stopRunning()
    robot.waitForRunExit()
    robot.disconnect()

    conn.close()
    
    Aria.uninit()
    Aria.shutdown()
    Aria.exit()

