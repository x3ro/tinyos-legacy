import jpype
import Tkinter as Tk
import Joystick, time, sys
from threading import Timer


class ControlCenter( object ) :

    def __init__( self , root , connStr , directConnection = False) :

        # connect to the robot server
        self.__directConnection = directConnection
        self.__connStr = connStr
        self.connect()
        
        # create main window
        self.root = root
        self.rootFrame = Tk.Frame( root , padx = 5 , pady = 5 )
        self.rootFrame.pack()

        # --------------------------------------------------
        # input group frame
        # --------------------------------------------------

        # input frame
        self.inputFrame = Tk.LabelFrame( self.rootFrame , text = "Input Device" , padx = 5 , pady = 5 , borderwidth = 2 )
        self.inputFrame.pack( fill="both" , expand="yes" , side = Tk.TOP )

        # joystick check button 
        self.joystickActive = False
        self.joystickPrevButtonDown = False
        self.joystickTimerPeriod = 0.2  # updated is kind-of slow to prevent jitter/jumping around of the motors
        self.joystickTimer = None
        self.joystick = Joystick.Joystick()
        var = Tk.IntVar()
        self.joystickCheckButton = Tk.Checkbutton( self.inputFrame , text="Joystick", command = self.joystickCheckButtonEvent , variable = var )
        self.joystickCheckButton.getValue = var.get
        if not self.joystick.init() :
            self.joystickCheckButton[ "state" ] = Tk.DISABLED
        self.joystickCheckButton.pack( side = Tk.TOP )

        # mouse check box
        var = Tk.IntVar()
        self.mouseCheckButton = Tk.Checkbutton( self.inputFrame , text="Mouse" , variable = var )
        self.mouseCheckButton.getValue = var.get
        self.mouseCheckButton.pack( side = Tk.TOP )

        # movement canvas
        self.movementLastValue = (0,0,0,0)
        self.movementCanvasWidth = 200
        self.movementCanvasHeight = 200
        self.movementCanvas = Tk.Canvas( self.inputFrame , width = self.movementCanvasWidth , height = self.movementCanvasHeight , bg = 'white' )
        self.movementCanvas.pack( side = Tk.RIGHT )

        # mouse on movementCanvas
        self.movementCanvas.bind( "<Button-1>" , self.movementCanvasMouseButtonDown )
        self.movementCanvas.bind( "<ButtonRelease-1>" , self.movementCanvasMouseButtonUp )
        self.movementCanvas.bind( "<B1-Motion>" , self.movementCanvasMouseMotion )
        self.movementCanvaslineId = self.movementCanvas.create_line( self.movementCanvasWidth/2 ,
                                                                     self.movementCanvasHeight/2 ,
                                                                     self.movementCanvasWidth/2 ,
                                                                     self.movementCanvasWidth/2 ,
                                                                     width=3 , fill="blue", arrowshape = (10, 10, 3),
                                                                     arrow = "last")

        # --------------------------------------------------
        # hardware frame
        # --------------------------------------------------

        # hardware frame
        self.hardwareFrame = Tk.LabelFrame( self.rootFrame , text = "Hardware Settings" , padx = 5 , pady = 5 , borderwidth = 2 )
        self.hardwareFrame.pack( fill="both" , expand="yes" , side = Tk.TOP )

        # enable/disable motors button
        self.motorsEnabled = False
        self.motorsButton = Tk.Button( self.hardwareFrame , text="Enable Motors", command = self.motorsButtonPressed )
        self.motorsButton.pack( side = Tk.LEFT )


        # trim -- FIXME: use Tk.scale
        #self.turnATrimScrollbar = Tk.Scrollbar( root )
        #self.turnATrimScrollbar.pack( side = Tk.LEFT )
        #self.turnATrimScrollbar["command"] = self.turnAScroll
        #self.turnATrimScrollbar.set(0.5,0.6)

        # --------------------------------------------------
        # output device frame
        # --------------------------------------------------

        # output frame
        self.outputFrame = Tk.LabelFrame( self.rootFrame , text = "Output Device" , padx = 5 , pady = 5 , borderwidth = 2 )
        self.outputFrame.pack( fill="both" , expand="yes" , side = Tk.TOP )

        # output button setup
        self.outputButtonValue = Tk.StringVar()
        self.outputButton = []

        # MOTECOM output button
        self.moteComFrame = Tk.Frame( self.outputFrame )
        self.moteComFrame.pack()
        button = Tk.Radiobutton( self.moteComFrame , text = "MOTECOM" , variable = self.outputButtonValue , value = "motecom" ,
                                 command = self.outputButtonEvent )
        button.pack( side = Tk.LEFT )
        self.outputButton.append( button )
        self.moteComEntry = Tk.Entry( self.moteComFrame , state = Tk.DISABLED )
        self.moteComEntry.pack( side = Tk.LEFT )

        # RoboServ output button
        button = Tk.Radiobutton( self.outputFrame , text = "RoboServ@" , variable = self.outputButtonValue , value = "roboserv" ,
                                 command = self.outputButtonEvent )
        button.pack( side = Tk.TOP )
        self.outputButton.append( button )

        # connect to output button
        self.outputConnected = False
        self.outputConnectButton = Tk.Button( self.outputFrame , text = "Connect to Output" , command = self.outputConnectButtonPressed )
        self.outputConnectButton.pack()
        


        # --------------------------------------------------
        # general events
        # --------------------------------------------------

        # keep alive timer
        self.keepAliveTimerPeriod = 1
        self.enableKeepAliveTimer()

        # event handler for closing window
        self.root.protocol( "WM_DELETE_WINDOW" , self.exit )




    def exit( self ) :
        self.disableKeepAliveTimer()
        self.disableJoystick()
        self.root.destroy()
        try :
            self.__roboMote.stopMovement()
            self.__roboMote.disableMotors()
        except :
            pass


    #--------------------------------------------------
    # Connect to mote or server
    #--------------------------------------------------
    def connect( self ) :

        success = False
        while not success :
            try :
                print "Trying to connect..."
                if self.__directConnection :
                    from Robot import RoboMote
                    self.__roboMote = RoboMote.RoboMote( self.__connStr )
                    success = True
                else :
                    from Robot import Client
                    c = Client.makeClient( host = self.__connStr , ignoreLostPackets = True )
                    self.__roboMote = c.roboMote
                    success = True
            except :
                time.sleep( 10 )
        print "Connected"

    #--------------------------------------------------
    # Keep Alive Timer
    #--------------------------------------------------
    def enableKeepAliveTimer( self ) :
        self.keepAliveTimerActive = True
        self.keepAliveTimer = Timer( self.keepAliveTimerPeriod , self.keepAliveTimerEvent ).start()
        
    def disableKeepAliveTimer( self ) :
        self.keepAliveTimerActive = False
        time.sleep( self.keepAliveTimerPeriod * 2 )  # make sure any timers have time to finish firing

    def keepAliveTimerEvent( self ) :

        if self.__directConnection :
            if not jpype.isThreadAttachedToJVM() :
                jpype.attachThreadToJVM()

        if self.keepAliveTimerActive :
            success = False
            while not success :
                try :
                    self.__roboMote.sendKeepAlive()
                    success = True
                except :
                    self.connect()
                    
            self.keepAliveTimer = Timer( self.keepAliveTimerPeriod , self.keepAliveTimerEvent ).start()

        else :  #keepAliveTimer is not active
            if self.keepAliveTimer :
                self.keepAliveTimer.stop()
            self.keepAliveTimer = None



    #--------------------------------------------------
    # Output button
    #--------------------------------------------------
    def outputButtonEvent( self ) :
        if self.outputButtonValue.get() == "motecom" :
            self.moteComEntry[ "state" ] = Tk.NORMAL
        else: 
            self.moteComEntry[ "state" ] = Tk.DISABLED

    def outputConnectButtonPressed( self ) :
        #try :
        #    pass
        #except :
        self.outputConnectButton[ "text" ] = "Failed to connect"
        self.outputConnectButton[ "background" ] = "red"
        #self.outputConnectButton[ "text" ] = "connect"
        
        
    #--------------------------------------------------
    # Movement canvas:
    #   x,y are assumed to be in terms of normal x,y
    #   coords; (0,0) at the center of the canvas;
    #   x,y each range from -1 to 1
    #--------------------------------------------------

    def updateMovementCanvas( self , x , y ) :

        # clip x,y range to [-1,1]
        x = min( max(x,-1) , 1)
        y = min( max(y,-1) , 1)

        # change x and y range to [0,1]
        arrowX = ( x + 1 ) / 2
        arrowY = ( y + 1 ) / 2

        # draw the arrow
        arrowX = arrowX * self.movementCanvasWidth
        arrowY = (1-arrowY) * self.movementCanvasHeight
        self.movementCanvas.coords( self.movementCanvaslineId , self.movementCanvasWidth/2 ,
                                    self.movementCanvasHeight/2 , arrowX , arrowY )

        # actuate the motors
        # round the values to prevent jitter
        turnA = round(-x,1)
        speedA = round(y,1)
        turnB = turnA
        speedB = speedA
        newMovement = (turnA,turnB,speedA,speedB)

        if not (newMovement == self.movementLastValue) :
            self.movementLastValue = newMovement

            success = False
            while not success :
                try :
                    self.__roboMote.setMovement( *newMovement )
                    success = True
                except :
                    self.connect()


    #--------------------------------------------------
    # Mouse
    #--------------------------------------------------

    def updateMovementCanvasMouse( self , xMouse , yMouse ) :
        self.updateMovementCanvas( xMouse * 2.0 / self.movementCanvasWidth - 1 , 1 - yMouse * 2.0 / self.movementCanvasWidth )

    def movementCanvasMouseButtonDown( self , event ) :
        if self.mouseCheckButton.getValue() :
            self.updateMovementCanvasMouse( event.x , event.y )
            
    def movementCanvasMouseButtonUp( self , event ) :
        if self.mouseCheckButton.getValue() :
            self.updateMovementCanvas( 0.0 , 0.0 )

    def movementCanvasMouseMotion( self , event ) :
        if self.mouseCheckButton.getValue() :
            self.updateMovementCanvasMouse( event.x , event.y )
    

    #--------------------------------------------------
    # Joystick
    #--------------------------------------------------

    def enableJoystick( self ) :
        self.joystickActive = True
        self.joystickTimer = Timer( self.joystickTimerPeriod , self.joystickTimerEvent ).start()
        
    def disableJoystick( self ) :
        self.joystickActive = False
        time.sleep( self.joystickTimerPeriod * 2 )  # make sure any timers have time to finish firing

    def joystickTimerEvent( self ) :
        if self.__directConnection :
            if not jpype.isThreadAttachedToJVM() :
                jpype.attachThreadToJVM()
        if self.joystickActive :
            self.joystick.update()
            if not self.joystick.getButton(0) :
                if self.joystickPrevButtonDown : # if button was just recently let up
                    self.joystickPrevButtonDown = False
                    self.updateMovementCanvas( 0.0 , 0.0 )
            else :
                self.joystickPrevButtonDown = True
                if self.joystick.getButton(1) :
                    self.updateMovementCanvas( self.joystick.getAxis(0) , -self.joystick.getAxis(1) )
                elif self.joystick.getButton(3) :
                    self.updateMovementCanvas( self.joystick.getAxis(0) , -self.joystick.getAxis(1) / 2.0 )
                elif self.joystick.getButton(2) :
                    self.updateMovementCanvas( self.joystick.getAxis(0) , -self.joystick.getAxis(1) / 4.0 )
                else :
                    self.updateMovementCanvas( self.joystick.getAxis(0) , -self.joystick.getAxis(1) / 6.0 )
            self.joystickTimer = Timer( self.joystickTimerPeriod , self.joystickTimerEvent ).start()

        else :  #joystick is not active
            if self.joystickTimer :
                self.joystickTimer.stop()
            self.joystickTimer = None
            self.joystickPrevButtonDown = False
            self.updateMovementCanvas( 0.0 , 0.0 )


    def joystickCheckButtonEvent( self ) :
        if self.joystickCheckButton.getValue() :
            self.enableJoystick()
        else :
            self.disableJoystick()


    #--------------------------------------------------
    # Motors
    #--------------------------------------------------

    def enableMotors( self ) :
        self.motorsEnabled = True
        self.motorsButton["text"] = "Disable Motors"

        success = False
        while not success :
            try :
                self.__roboMote.enableMotors()
                success = True
            except :
                self.connect()

    def disableMotors( self ) :
        self.motorsEnabled = False
        self.motorsButton["text"] = "Enable Motors"
        success = False
        while not success :
            try :
                self.__roboMote.disableMotors()
                success = True
            except :
                self.connect()

    def motorsButtonPressed( self ):
        if self.motorsEnabled :
            self.disableMotors()
        else :
            self.enableMotors()


    #--------------------------------------------------
    # Trim
    #--------------------------------------------------

#     def turnAScroll( self , *args ) :
#         if len(args) == 2 : # drag-n-drop scroll
#             offset = args[1]
#         elif len(args) == 3 : # click scroll
#             step = args[1]
#             what = args[1]





if __name__ == "__main__" :

    def usage() :
        print "Usage:"
        print "  SEND RAW TOS MSGS: %s -r MOTECOM" % sys.argv[0]
        print "  CONNECT TO SERVER: %s -h hostname" % sys.argv[0]
        sys.exit(1)


    if (len( sys.argv ) == 3) and (sys.argv[1] == "-r") :  # "direct" connection
        connStr = sys.argv[2]
        directConnection = True
    elif (len( sys.argv ) == 3) and (sys.argv[1] == "-h") :  # connect through the server
        connStr = sys.argv[2]
        directConnection = False
    else :
        usage()
        
    root = Tk.Tk()
    app = ControlCenter( root , connStr , directConnection )
    root.mainloop()


