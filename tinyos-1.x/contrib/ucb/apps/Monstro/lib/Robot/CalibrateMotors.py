if __name__ == "__main__" :

    import keyPress, sys


    def usage() :
        print "USAGE: %s [-d|-h host_name]" % sys.argv[0]
        sys.exit(1)
        
    if len(sys.argv) == 2 :   # direct connection
        if sys.argv[1] != "-d" :
            usage()
        import Util
        res = Util.getResources()
        roboMote = res[ "roboMote" ]
    elif len(sys.argv) == 3 :  # client/server connection
        if sys.argv[1] != "-h" :
            usage()
        hostname = sys.argv[2]
        import Client
        c = Client.makeClient( host = hostname )
        roboMote = c.roboMote
    else :
        usage()




    kp = keyPress.keyPress()

    def wait() :
        print "<press any key to continue>"
        kp.getChar( True )


    sequenceFront = ( (0,0,0,0) , (0,0,1,0) , (0,0,-1,0) , (0,0,0,0) )
    sequenceRear = ( (0,0,0,0) , (0,0,0,-1) , (0,0,0,1) , (0,0,0,0) )
    sequenceNames = ( "near the GPS" , "opposite the GPS" )
    sequences = ( sequenceFront , sequenceRear )


    for seq,seqName in zip(sequences,sequenceNames) :

        print
        print "Make sure both motor controllers are off."
        wait()

        print
        print "Do the following to the motor controller %s only." % seqName

        roboMote.setTrim(0,0,0,0)
        roboMote.setMovement(*seq[0])
        roboMote.enableMotors()
        roboMote.sendKeepAlive( 60 )

        print
        print "Press and hold the black button on the motor controller."
        print "Power the motor controller on."
        print "Wait for the red LED to turn on"
        print "Then release the black button"
        wait()

        roboMote.setMovement(*seq[1])
        roboMote.sendKeepAlive()
        print
        print "Wait for the green LED to turn on."
        wait()

        roboMote.setMovement(*seq[2])
        roboMote.sendKeepAlive()
        print
        print "Wait for the green LED to begin flashing."
        wait()

        roboMote.setMovement(*seq[3])
        roboMote.sendKeepAlive()
        print
        print "Wait for all LEDs except the red to turn off."
        wait()

        print
        print "Turn this motor controller off."
        wait()


    roboMote.sendKeepAlive( 2 )
    kp.destroy()
