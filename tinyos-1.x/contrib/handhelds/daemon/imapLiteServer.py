#!/usr/bin/python
'''
   Copyright (c) 2005 Hewlett-Packard Company
   All rights reserved

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:

      * Redistributions of source code must retain the above copyright
         notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
         copyright notice, this list of conditions and the following
         disclaimer in the documentation and/or other materials provided
         with the distribution.
      * Neither the name of the Hewlett-Packard Company nor the names of its
         contributors may be used to endorse or promote products derived
         from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

   IMAP Lite Server

   This server presents an IMAPLite interface and contains a message
   store.  It also has a simple web interface (on port 8080) for
   displaying message lists and (eventually) allowing people to
   leave messages for each other.

   Author:  Andrew Christian <andrew.christian@hp.com>
            16 March 2005
'''

from twisted.internet.protocol import Factory
from twisted.protocols.basic import LineReceiver
from twisted.internet import reactor
from twisted.web import server
from twisted.web.resource import Resource

import sys

g_verbose = 0
g_UniqueID = 0

########################################################################

class Message:
    def __init__(self,id=0):
        global g_UniqueID

        if id == 0:
            g_UniqueID += 1
            id = g_UniqueID
        self.id = id

    def __eq__(self,other):
        return self.id == other.id

    def __str__(self):
        return "Message %d '%s' %d '%s'" % (self.id, self.mailbox,
                                            self.timestamp, self.text)

########################################################################

class MessageStore:
    'In a newer version, we will use a database backend'
    
    def __init__(self):
        self.messages  = []     # List of class Message

    def select(self,mailbox,max_id):
        count  = 0
        unseen = 0
        for m in self.messages:
            if m.mailbox == mailbox:
                count += 1
                if m.id > max_id:
                    unseen += 1
        return (count, unseen)

    def fetch(self,mailbox,msg_id):
        for m in self.messages:
            if m.mailbox == mailbox and m.id >= msg_id:
                return m
        return None

    def remove(self,mailbox,msg_id):
        testm = Message(msg_id)
        try:
            self.messages.remove(testm)
            return True
        except ValueError:
            return False
    
    def append(self,mailbox,timestamp,text):
        m = Message()
        m.mailbox = mailbox
        m.timestamp = timestamp
        m.text = text
        self.messages.append(m)
        return m.id

########################################################################

class IMAPLite(LineReceiver):
    def connectionMade(self):
        self.mailbox = None
        if g_verbose:
            print "Connection made", self.transport.getPeer()

    def connectionLost(self,reason):
        if g_verbose:
            print 'Connection lost'

    def checkMailbox(self):
        if not self.mailbox:
            self.transport.write("BAD Must select mailbox\r\n")
        return self.mailbox

    def n_SELECT(self,args):
        '''SELECT mailbox [MAXID msg_id]
               OK EXISTS num UNSEEN num

           EXISTS = number of messages in this mailbox
           UNSEEN = number of messages in mailbox with id > msg_id
        '''
        arglist = args.split()
        mailbox = arglist[0]
        maxid   = 0
        
        if len(arglist) == 3 and arglist[1] == 'MAXID':
            maxid = int(arglist[2])

        self.mailbox = mailbox
        (count, unseen) = self.factory.msg_store.select( mailbox, maxid )
        self.transport.write("OK EXISTS %d UNSEEN %d\r\n" % (count, unseen))

        if g_verbose:
            print 'SELECT', mailbox, maxid
            print '  -> EXISTS', count, 'UNSEEN', unseen
        

    def n_FETCH(self,args):
        '''FETCH msg_id [FLAGS HEADER]
              OK msg_id timestamp text...

           Returns the first message with id >= msg_id.
           If FLAGS HEADER is specified, only return the msg_id
           Returns "NO" if no message exists
        '''
        arglist = args.split()
        msg_id = int(arglist[0])

        if not self.checkMailbox(): return

        header_only = (len(arglist) == 3 and arglist[1] == 'FLAGS' and arglist[2] == 'HEADER')

        msg = self.factory.msg_store.fetch( self.mailbox, msg_id )
        if msg:
            if header_only:
                self.transport.write("OK %d\r\n" % (msg.id))
            else:
                self.transport.write("OK %d %d %s\r\n" % (msg.id, msg.timestamp, msg.text))
        else:
            self.transport.write("NO\r\n")

        if g_verbose:
            print 'FETCH', msg_id, ( header_only and "HEADER" or "")
            print msg
        
    def n_STORE(self,args):
        '''STORE msg_id FLAGS DELETE
              OK or NO

           Deletes a message from the current mailbox.
        '''
        arglist = args.split()
        msg_id = arglist[0]

        if not self.checkMailbox(): return

        if len(arglist) == 3 and arglist[1] == 'FLAGS' and arglist[2] == 'DELETE':
            if self.factory.msg_store.remove( self.mailbox, int(msg_id)):
                self.transport.write("OK\r\n")
            else:
                self.transport.write("NO\r\n")
        else:
            self.transport.write("BAD STORE cmd\r\n")

        if g_verbose:
            print 'STORE', msg_id, arglist
        
    def n_APPEND(self,args):
        '''APPEND timestamp text...
               OK msg_id

           Stores a new message and returns the msg_id
        '''
        timestamp, msg = args.split(None,1)
        timestamp = int(timestamp)

        if not self.checkMailbox(): return

        msg_id = self.factory.msg_store.append(self.mailbox,timestamp, msg)
        self.transport.write("OK %d\r\n" % msg_id)

        if g_verbose:
            print 'APPEND', timestamp, msg
        
    def lineReceived(self,line):
        try:
            cmd, args = line.split(None,1)
            f = getattr(self,'n_'+cmd)
            f(args)
        except:
            self.transport.write('BAD\r\n')
    
########################################################################

class IMAPLiteFactory(Factory):
    protocol = IMAPLite

    def __init__(self,ms):
        self.msg_store = ms


########################################################################

class TopPage(Resource):
    def __init__(self,ms):
        Resource.__init__(self)
        self.msg_store = ms

    def getChild(self,name,request):
        if name == '': return self
        return Resource.getChild(self,name,request)
    
    def render_GET(self,request):
        request.write("""<html>
        <head><title>IMAP Lite Server</title></head>
        <body>
        <h1>Messages</h1><table>
        <tr><th>ID</th><th>Mailbox</th><th>Timestamp</th><th>Text</th></tr>
        """)

        for m in self.msg_store.messages:
            request.write("<tr><td>%d</td><td>%s</td><td>%d</td><td>%s</td></tr>" %
                          (m.id, m.mailbox, m.timestamp,m.text))
        request.write("""
        </table>
        </body></html>""")
        request.finish()
        return server.NOT_DONE_YET

########################################################################

def usage():
    print """
    Usage: imapLiteServer.py [OPTIONS] 

    Valid options are:

         -v, --verbose        May be repeated for more detail
         -h, --help           This help
         -p, --port=NUM       IMAPLite port (default 3143)
         
    """
    sys.exit(0)


if __name__ == '__main__':
    import getopt

    port = 3143
    
    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vhp:',
                                        ['verbose', 'help', 'port='])
    except Exception, e:
        print e
        usage()

    for (k,v) in options:
        if k in ('-v', '--verbose'):
            g_verbose += 1
        elif k in ('-h', '--help'):
            usage()
        elif k in ('-p', '--port'):
            port = int(v)
        else:
            usage()

    ms = MessageStore()
    reactor.listenTCP(port, IMAPLiteFactory(ms))

    root = TopPage(ms)
    site = server.Site(root)
    reactor.listenTCP(8080, site)
    
    reactor.run()
