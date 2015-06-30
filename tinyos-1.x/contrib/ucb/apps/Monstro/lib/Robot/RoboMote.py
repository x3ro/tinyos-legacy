#!/usr/bin/env python

import time, os, sys, Queue
import jpype
from jpype import jimport as jclass
from pytos.Comm import Comm, MessageQueue
import pytos.util.NescApp as NescApp
import Config



# --------------------------------------------------
# pytos init
# --------------------------------------------------
app = NescApp.NescApp( os.path.join(os.path.dirname(__file__),"../../apps/RoboMote/build/telosb/") )
enums = app.enums
msgs = app.msgs



# --------------------------------------------------
# exceptions
# --------------------------------------------------
class RoboMoteException( Exception ) :
    pass




# --------------------------------------------------
# fix range -- clip a float into the range [-1,1],
# then change it to an int in [-128,127]
# --------------------------------------------------
def moteRange( val ) :
    val = int( val * 128 )
    val = max( min( 127 , val ) , -128 )
    return val




# --------------------------------------------------
# fix range -- change a int in [-128,127] to a float in
# [-1,1]
# --------------------------------------------------
def userRange( val ) :
    val = val / 128.0
    return round(val,4)




# --------------------------------------------------
# RoboMote
# --------------------------------------------------
class RoboMote( object ) :



    def __init__( self , moteComStr ) :

        self.__msgQueue = MessageQueue( 5 )
        self.__nextMessageType = None

        # connect to the mote
        self.__moteComStr = moteComStr
        self.__comm = Comm()
        self.__comm.connect( self.__moteComStr )

        # When receiving these messages, queue them up
        self.__comm.register( msgs[ "MotorState" ] , self.__msgQueue )
        self.__comm.register( msgs[ "MotorTrim" ] , self.__msgQueue )
        self.__comm.register( msgs[ "MotorMovement" ] , self.__msgQueue )



    def __query( self , queryType , returnMsgName ) :
        self.__nextMessageName = returnMsgName
        motorQueryMsg = msgs[ "MotorQuery" ]
        motorQueryMsg.type = queryType
        self.__comm.send( enums.TOS_BCAST_ADDR , motorQueryMsg );



    def getNextMsg( self , timeout = 1 ) :

        try:
            (addr,msg) = self.__msgQueue.get( True , timeout )
        except Queue.Empty :
            return None

        if msg.nescType == self.__nextMessageName :
            return msg

        return None



    def destroy( self ) :
        self.stopMovement()
        self.disableMotors()
        self.__comm.disconnect( self.__moteComStr )



    def sendKeepAlive( self , timeout = 0 ) :
        """Timeout is in seconds; 0 is interpreted (on the mote side) as use the previous value"""
        m = msgs[ "MotorKeepAlive" ]
        m.stayAliveMillis = timeout*1000.0
        self.__comm.send( enums.TOS_BCAST_ADDR , m )



    def enableMotors( self ) :
        m = msgs[ "MotorState" ]
        m.motorState = enums.MOTORSTATE_ENABLED
        self.__comm.send( enums.TOS_BCAST_ADDR , m )



    def disableMotors( self ) :
        m = msgs[ "MotorState" ]
        m.motorState = enums.MOTORSTATE_DISABLED
        self.__comm.send( enums.TOS_BCAST_ADDR , m )



    def stopMovement( self ):
        self.setMovement( 0.0 , 0.0 , 0.0 , 0.0 )



    def setMovement( self , turnA = 0.0 , turnB = 0.0 , speedA = 0.0 , speedB = 0.0 ) :
        """all values between -1 and 1"""
        m = msgs[ "MotorMovement" ]
        m.turnA = moteRange(turnA)
        m.turnB = moteRange(turnB)
        m.speedA = moteRange(speedA)
        m.speedB = moteRange(speedB)
        self.__comm.send( enums.TOS_BCAST_ADDR , m )


            
    def setTrim( self , turnA = 0.0 , turnB = 0.0 , speedA = 0.0 , speedB = 0.0 ):
        """all values between -1 and 1"""
        m = msgs[ "MotorTrim" ]
        m.turnATrim = moteRange(turnA)
        m.turnBTrim = moteRange(turnB)
        m.speedATrim = moteRange(speedA)
        m.speedBTrim = moteRange(speedB)
        self.__comm.send( enums.TOS_BCAST_ADDR , m )



    def getStateDict( self ) :
        enabled = self.isEnabled()
        if not isinstance( enabled , bool ) :
            return None
        return { "enabled" : enabled }

    

    def isEnabled( self ) :

        self.__query( enums.MOTORQUERY_STATE , "MotorState" )
        msg = self.getNextMsg()

        if not msg :
            return None
        
        if msg.motorState == enums.MOTORSTATE_DISABLED :
            return False
        return True



    def getTrim( self ) :

        self.__query( enums.MOTORQUERY_TRIM , "MotorTrim" )
        msg = self.getNextMsg()

        if not msg :
            return None

        trim = ( userRange( msg.turnATrim ) ,
                 userRange( msg.turnBTrim ) ,
                 userRange( msg.speedATrim ) ,
                 userRange( msg.speedBTrim ) )
        return trim



    def getTrimDict( self ) :
        trim = self.getTrim()

        if not trim :
            return None

        trimDict = { "turnATrim" : trim[0] ,
                     "turnBTrim" : trim[1] ,
                     "speedATrim" : trim[2] ,
                     "speedBTrim" : trim[3] }
        return trimDict


        
    def getMovement( self ) :

        self.__query( enums.MOTORQUERY_MOVEMENT , "MotorMovement" )
        msg = self.getNextMsg()

        if not msg :
            return None

        movement = ( userRange( msg.turnA ) ,
                     userRange( msg.turnB ) ,
                     userRange( msg.speedA ) ,
                     userRange( msg.speedB ) )
        return movement



    def getMovementDict( self ) :
        movement = self.getMovement()

        if not movement :
            return None

        movementDict = { "turnA" : movement[0] ,
                         "turnB" : movement[1] ,
                         "speedA" : movement[2] ,
                         "speedB" : movement[3] }
        return movementDict



    def getAllDict( self ) :

        d = {}
        for newDict in ( self.getStateDict() , self.getTrimDict() , self.getMovementDict() ) :
            if newDict :
                d.update( newDict )
        return d




# --------------------------------------------------
# Check if this is a roboMote
# --------------------------------------------------
def isRoboMote( moteCom ) :
    roboMote = RoboMote( moteCom )
    if roboMote.getStateDict() :
        time.sleep(0.5)
        roboMote.destroy()
        time.sleep(0.5)
        return True
    else :
        time.sleep(0.5)
        roboMote.destroy()
        time.sleep(0.5)
        return False









if __name__ == "__main__" :

    import keyPress


    def awb( val , change , lowerBound=-1.0 , upperBound=1.0 ) :
        val = val + change
        if val < lowerBound :
            val = lowerBound
        elif val > upperBound :
            val = upperBound
        return val



    if "MOTECOM" in os.environ :
        roboMote = RoboMote( os.environ["MOTECOM"] )
    else:
        raise RoboMoteException , "The MOTECOM environment variable needs to be set"

    kp = keyPress.keyPress()
    c = kp.getChar()

    turnA = 0.0
    turnB = 0.0
    speedA = 0.0
    speedB = 0.0

    roboMote.enableMotors()
    roboMote.setMovement( turnA , turnB , speedA , speedB )

    while c != "q" :

        keyPressed = False
        if c == "h" : #left
            turnA = awb( turnA , 0.1 )
            turnB = awb( turnB , 0.1 )
            keyPressed = True
        elif c == "n" : #right
            turnA = awb( turnA , -0.1 )
            turnB = awb( turnB , -0.1 )
            keyPressed = True
        elif c == "c" : #forward
            speedA = awb( speedA , 0.05 )
            speedB = awb( speedB , 0.05 )
            keyPressed = True
        elif c == "w" : #reverse
            speedA = awb( speedA , -0.05 )
            speedB = awb( speedB , -0.05 )
            keyPressed = True
        elif c == "t" : #center
            turnA = 0.0
            turnB = 0.0
            speedA = 0.0
            speedB = 0.0
            keyPressed = True

        if keyPressed :
            roboMote.setMovement( turnA , turnB , speedA , speedB )
            print (turnA,turnB,speedA,speedB)
            keyPressed = False

        c = kp.getChar()

    roboMote.stopMovement()
    roboMote.disableMotors()
    roboMote.destroy()

