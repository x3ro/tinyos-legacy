import socket, cPickle
import Config, PickleSocket, Gps


def makeClient( host = "localhost" , port = Config.PORT , direct = False , dummy = False , ignoreLostPackets = False ) :

    if dummy :  #just simulate the resources
        return DummyResources()
    elif direct :   #skip the server, directly connect to the resources on my machine
        return None  #FIXME: not implemented yet
    else :  #connect to the server
        return Client( host , port , ignoreLostPackets )



class DummyResources( object ) :

    def __init__( self ) :
        self.gps = Gps.DummyGps()
        self.roboMote = None
        self.tosBase = None


class Error( Exception ) :
    pass


class Timeout( Error ) :
    pass



class Client( object ) :

    def __init__( self , host = "localhost" , port = Config.PORT , timeout = Config.CLIENT_DEFAULT_TIMEOUT , ignoreLostPackets = False ) :
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(( host , port ))
        self.__pickleSocket = PickleSocket.PickleSocket( s )
        self.__timeout = timeout
        self.__ignoreLostPackets = ignoreLostPackets

    def __send( self , msg ) :
        self.__pickleSocket.send( msg )
        try :
            results = self.__pickleSocket.recv( self.__timeout )
            return results
        except PickleSocket.Timeout :
            if self.__ignoreLostPackets :
                return None
            else :
                raise Timeout
        except PickleSocket.Error :
            if self.__ignoreLostPackets :
                return None
            else :
                raise Error
            
    def __getattr__( self , objName ) :
        return MethodName( objName , self.__send )



class MethodName( object ) :

    def __init__( self , objName , sendFcn ) :
        self.__objName = objName
        self.__sendFcn = sendFcn

    def __getattr__( self , methodName ) :
        return lambda *args , **argd : self.__sendFcn(( self.__objName , methodName , args , argd ))



if __name__ == "__main__" :

    # connect to server
    c = makeClient()
    roboMote = c.roboMote

    # after connecting, cmds look local, just like before
    print roboMote.disableMotors()
    print roboMote.enableMotors()
    print roboMote.getMovement()
    print roboMote.setMovement( -.5 , .5 , .75 , 1.0 )
    print roboMote.getMovement()
    print roboMote.getAllDict()


    # connect to (dummy) gps
    # c = makeClient( dummy = True )
    # gps = c.gps

    # use dummy gps
    # print gps.iterate()  # request new readings
    # print gps.getPos()    # get new x,y
    # print gps.getTime()    # get time (float) (seconds into the week)
