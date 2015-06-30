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


  Twisted client that contacts a TestTCP server

  Andrew Christian <andrew.christian@hp.com>
  March 2005
'''

from twisted.internet.protocol import Protocol, ClientFactory
from twisted.internet import reactor

import sys

def parse_host(host,default_port=5062):
    'Parse strings of the form HOST[:PORT]'
    port = default_port

    if ':' in host:
        host, port = host.split(':')
        port = int(port)

    return host, port

class TestTCP( Protocol ):

    def sendstuff(self,text="This is some more stuff\r\n"):
        self.transport.write(text)
        reactor.callLater(2,self.sendstuff)
        
    def connectionMade(self):
        self.sendstuff("First connection\r\n")
        
    def dataReceived(self, data):
        print data

class TestTCPFactory( ClientFactory ):
    protocol = TestTCP
    
    
def usage():
    print """
    Usage: testTCP.py [OPTIONS] HOST[:PORT] 

    Remote port defaults to 9009
    
    Valid options are:

         -v, --verbose        May be repeated for more detail
         -h, --help           This help
         
    """
    sys.exit(0)


if __name__ == '__main__':
    import getopt

    config = { 'verbose'     : 0,
               'remote_port' : 9009 }

    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vh',
                                        ['verbose', 'help'])
    except Exception, e:
        print e
        usage()

    for (k,v) in options:
        if k in ('-v', '--verbose'):
            config['verbose'] += 1
        elif k in ('-h', '--help'):
            usage()
        else:
            print "I didn't understand that"
            usage()

    if len(argv) != 1:
        print "must supply at least one host and data string"
        usage()


    host, remote_port = parse_host(argv[0],config['remote_port'])

    if config['verbose']:
        print 'Connecting to', host, remote_port

    f = TestTCPFactory()
    reactor.connectTCP( host, remote_port, f )
    reactor.run()
