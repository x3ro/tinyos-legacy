import Config

class DummyGps( object ) :

    def iterate( self , timeout = 0.2 ) :
        return True

    def getPos( self ) :
        return (0.0,0.0)

    def getTime( self ) :
        return 0.0



class RealGps( object ) :


    def __init__( self , connectionStr = None ) :
        from GpsBoxPython import GpsBox
        if connectionStr :
            self.gps = GpsBox( connectionStr )
        else :
            self.gps = GpsBox( Config.GPS_SERIAL_PARAMS )

        
    def iterate( self , timeout = Config.GPS_DEFAULT_TIMEOUT ) :
        return self.gps.iterate( timeout )


    def getPos( self ) :
        x = self.gps.rfs().getCurrentX()
        y = self.gps.rfs().getCurrentY()
        return ( x , y )


    def getTime( self ) :
        #return self.gps.vlhb().seconds
        return self.gps.prtkb().time



def getGps( dummy = False , connectionStr = None ) :
    if dummy :
        return DummyGps()
    else :
        return RealGps( connectionStr )
    
