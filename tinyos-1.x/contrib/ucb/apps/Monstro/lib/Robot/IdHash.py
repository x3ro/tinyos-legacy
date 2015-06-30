import threading

class IdHashException( Exception ) :
    pass

class IdHash( object ) :


    def __init__( self ) :
        self.__dict = {}
        self.__dictAccess = threading.Semaphore()
        self.__hashAccess = threading.Semaphore()


    def disable( self ) :
        """Disable IdHash such that actions on the queue with throw exceptions instead of blocking"""
        self.__hashAccess.acquire()


    def enable( self ) :
        """Enable IdHash such that actions on the queue with stop throwing and just block if needed exceptions"""
        self.__hashAccess.release()


    def remove( self , id ) :
        if not self.__hashAccess.acquire( False ) :
            raise IdHashException , "This object is disabled"

        self.__dictAccess.acquire()
        if id in self.__dict :
            obj = self.__dict[ id ]
            del self.__dict[ id ]
            self.__dictAccess.release()
            self.__hashAccess.release()
            return obj
        else :
            self.__dictAccess.release()
            self.__hashAccess.release()
            raise IdHashException , "Invalid ID"


    def add( self , obj ) :
        if not self.__hashAccess.acquire( False ) :
            raise IdHashException , "This object is disabled"

        self.__dictAccess.acquire()
        objId = id(obj)
        self.__dict.update({ objId : obj })
        self.__dictAccess.release()
        self.__hashAccess.release()
        return objId


    def iteritems( self ) :
        """You must disable the object while using this iterator"""
        return self.__dict.iteritems()
