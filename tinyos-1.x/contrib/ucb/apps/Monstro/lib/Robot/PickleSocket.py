import socket, cPickle, select, threading



class Error( Exception ) :
    pass



class Timeout( Error ) :
    pass



class Destroyed( Error ) :
    pass



class PickleSocket( object ) :



    def __init__( self , socketObject ) :
        self.__conn = socketObject
        self.__fd = self.__conn.makefile()
        self.__unpickler = cPickle.Unpickler( self.__fd )
        self.__pickler = cPickle.Pickler( self.__fd )
        self.__destroyed = False
        self.__sendLock = threading.Semaphore()
        self.__recvLock = threading.Semaphore()


    def destroy( self ) :
        self.__recvLock.acquire()
        self.__sendLock.acquire()
        try :
            if not self.__destroyed :
                self.__destroyed = True
                self.__fd.close()
                self.__conn.close()
                del self.__fd
                del self.__conn
                del self.__unpickler
                del self.__pickler
            self.__sendLock.release()
            self.__recvLock.release()
        except :
            self.__sendLock.release()
            self.__recvLock.release()
            raise



    def recv( self , timeout = None ):

        try:
            if timeout :
                ready = select.select( [self.__fd] , [] , [], timeout )
            else :
                ready = select.select( [self.__fd] , [] , [] )
        except select.error:
            self.destroy()
            raise Destroyed

        if not ready[0] :
            raise Timeout

        self.__recvLock.acquire()

        if self.__destroyed :
            self.__recvLock.release()
            raise Destroyed

        try :
            obj = self.__unpickler.load()
            self.__recvLock.release()
            return obj
        except ( EOFError , socket.error ) :
            self.__recvLock.release()
            self.destroy()
            raise Destroyed



    def send( self , obj ):

        self.__sendLock.acquire()

        if self.__destroyed :
            self.__sendLock.release()
            raise Destroyed

        try :
            self.__pickler.dump( obj )
            self.__fd.flush()
            self.__sendLock.release()
        except :
            self.__sendLock.release()
            raise
