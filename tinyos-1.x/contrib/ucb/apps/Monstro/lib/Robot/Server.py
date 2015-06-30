#!/usr/bin/env python


import socket, sys, cPickle, time, logging, signal, Queue, string
from threading import Thread
import PickleSocket, IdHash
import jpype, pytos



class MessageDispatch( Thread ) :



    def __init__( self , resources , queue , logger , threadIds ) :
        Thread.__init__( self )
        self.__inQueue = queue
        self.__logger = logger
        self.__shutdown = False
        self.__QUEUE_TIMEOUT = 2
        self.__threadIds = threadIds

        # downcase all the resource names
        self.__resources = {}
        for (key,value) in resources.iteritems() :
            self.__resources.update({ string.lower(key) : value })


    def destroy( self ) :
        self.__shutdown = True


    def __destroy( self ) :
        self.__logger.info( "shutting down" )
        del self.__threadIds[ id(self) ]
        #self.__logger.warn( "could not clean up myself for my parent" )


    def run( self ) :

        if not jpype.isThreadAttachedToJVM() :
            jpype.attachThreadToJVM()


        while not self.__shutdown :


            # --------------------------------------------------
            # read in and check new RPC messages
            # --------------------------------------------------
            try:

                # try to get a new message from the inQueue and either block until a new message arrives
                # eventually timeout, so you can check if this thread is being shutdown
                try:
                    ( returnPickleSocket , msg ) = self.__inQueue.get( True , self.__QUEUE_TIMEOUT )
                except Queue.Empty :
                    continue
                
                ( objName , methodName , arg_tuple , arg_dict ) = msg
                objName = string.lower(objName)
                self.__logger.debug( "Received RPC tuple %s" % repr(msg) )

                if not isinstance( arg_tuple , tuple ) :
                    raise ValueError

                if not isinstance( arg_dict , dict ) :
                    raise ValueError

            except ValueError, inst :
                self.__logger.error( "Ignoring message: Received ill-formed RPC message" )
                continue

            
            # --------------------------------------------------
            # execute the RPC command
            # --------------------------------------------------
            if objName in self.__resources :

                self.__logger.debug( "Evaluating %s.%s" % (objName , methodName) )
                obj = self.__resources[ objName ]

                try:
                    f = eval( "obj." + methodName )

                    result = f( *arg_tuple , **arg_dict )

                    self.__logger.debug( "returning results: " + repr( result ) )

                    try :
                        returnPickleSocket.send( result )
                    except Exception, inst :
                        self.__logger.error( "Could not send return value (see below)" )
                        self.__logger.error( inst.__str__ )
                    
                except AttributeError , inst :
                    self.__logger.error( "Ignoring message: Object %s does not have the %s method" % (objName,methodName) )
                except TypeError , inst :
                    self.__logger.error( "Ignoring message: Ill-formed arguments to %s.%s" % (objName,methodName) )
                except inst :
                    self.__logger.error( "Call to %s.%s failed (see below)" % (objName,methodName) )
                    self.__logger.error( inst.__str__ )
            else:
                self.__logger.error( "Ignoring message: Object %s does not exist" % objName )


        self.__destroy()




class ConnectionHandler( Thread ) :


    def __init__( self , conn , addr , logger , queue , threadIds ) :
        Thread.__init__( self )
        self.__inQueue = queue
        self.__logger = logger
        self.__pickleSocket = PickleSocket.PickleSocket( conn )
        self.__threadIds = threadIds


    def destroy( self ) :
        # this will trigger the recv() call in the run() method to throw an exception;
        # letting us safely end the loop and shutdown
        self.__logger.info( "forced to shut down my connection" )
        self.__pickleSocket.destroy()


    def __destroy( self ) :
        self.__logger.info( "shutting down" )

        self.__logger.info( "shutting down connection" )
        self.__pickleSocket.destroy()

        self.__logger.debug( "Removing myself from the active thread list" )
        del self.__threadIds[ id(self) ]


    def run( self ) :
        while True:

            try :

                # wait for a new message from client
                self.__logger.debug( "Waiting for new messages; pickleSocket.recv()" )
                newMsg = self.__pickleSocket.recv( 5*60 )  # wait up to 5 minutes, before killing the socket
                self.__logger.debug( "received new message: %s" % repr(newMsg) )

                # put the new message on the dispatch queue
                try :
                    self.__inQueue.put_nowait(( self.__pickleSocket , newMsg ))
                except Queue.Full :
                    self.__logger.warn( "queue full -- dropping new message: %s" % repr(newMsg) )

            # except ( EOFError , socket.error , PickleSocket.Destroyed , PickleSocket.Timeout ) :
            except :
                self.__logger.info( "connection closed" )
                break

        self.__destroy()





class ResourceServer( object ) :


    def __init__( self , port , msgQueueLen , resources , logFileName = None , logFileBytes = 50*1024 ) :

        self.__resources = resources
        self.__inQueue = Queue.Queue( msgQueueLen )
        #self.__host = socket.gethostname()
        #self.__host = "192.168.0.2"
        self.__host = ""
        self.__port = port
        self.__children = {}  # keep track of child threads using their ids
        self.__socket = None
        

        # --------------------------------------------------
        # Setup the logger
        # --------------------------------------------------
        logging.basicConfig( level=logging.DEBUG , format="%(asctime)s %(levelname)s %(name)s %(message)s" )
        if logFileName :
            from logging import handlers
            logFile = handlers.RotatingFileHandler( logFileName , maxBytes = logFileBytes )
            logFile.setLevel( logging.DEBUG )
            formatter = logging.Formatter( "%(asctime)s %(levelname)s %(name)s %(message)s" )
            logFile.setFormatter(formatter)
            logging.getLogger("").addHandler( logFile )
        self.__logger = logging.getLogger( "ResourceServer" )
        


        # --------------------------------------------------
        # Setup signal handlers to shutdown the server nicely
        # --------------------------------------------------
        signal.signal( signal.SIGTERM , self.__destroy )
        signal.signal( signal.SIGQUIT , self.__destroy )
        signal.signal( signal.SIGINT , self.__destroy )



    def __destroy( self , sigNum , stackFrame ) :
        self.__logger.warn( "Shutting down" )

        # shutdown the server socket
        self.__logger.debug( "Closing server socket" )
        if self.__socket :
            self.__socket.close()

        # shutdown children
        for (cid , child) in self.__children.copy().iteritems() :
            self.__logger.debug( "Shutting down %s child" % repr(child) )
            child.destroy()
        self.__children = None

        # exit
        time.sleep( 5 )   #give the other threads a second before shutting down and killing the logger
        sys.exit(0)



    def start( self ) :


        # start the message dispatcher thread
        self.__logger.info( "starting the dispatcher" )
        messageDispatch = MessageDispatch( self.__resources , self.__inQueue , logging.getLogger( "MessageDispatcher" ) , self.__children )
        self.__children.update({ id(messageDispatch) : messageDispatch })
        # messageDispatch.setDaemon( True )
        messageDispatch.start()


        # Create a socket for the server
        self.__logger.info( "opening the server socket" )
        try :
            self.__socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        except socket.error :
            self.__socket = None


        # Bind server socket to its host,port & make it a listening socket
        try :
            self.__socket.bind((self.__host, self.__port))
            self.__socket.listen(1)
        except socket.error :
            self.__socket.close()
            self.__socket = None

        # Check if socket is OK
        if self.__socket is None:
            self.__logger.error( "could not open socket" )
            self.__destroy( None , None )
        else :
            self.__logger.info( "listening on port %i" % self.__port )


        # Listen/connect to clients
        while True :

            try :
                conn, addr = self.__socket.accept()
                self.__logger.info( "connected to by %s" % repr(addr) )

                self.__logger.debug( "spawning a handler for connection %s" % repr(addr) )
                handler = ConnectionHandler( conn , addr , logging.getLogger( "ConnectionHandler-%s:%s" % addr ) , self.__inQueue , self.__children )
                self.__children.update({ id(handler) : handler })
                handler.start()
            except socket.error :
                break

            






if __name__ == "__main__" :


    logFileName = None
    if len(sys.argv) > 2 :
        print "USAGE: %s [logFile]" % sys.argv[0]
        sys.exit(1)
    elif len(sys.argv) == 2 :
        logFileName = sys.argv[1]

    import Config, Util

    resources = Util.getResources()
    s = ResourceServer( Config.PORT , Config.SERVER_MSG_QUEUE_LENGTH , resources , logFileName , Config.LOG_FILE_BYTES )
    s.start()
