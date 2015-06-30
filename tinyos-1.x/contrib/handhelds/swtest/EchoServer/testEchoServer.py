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


 Twisted client that contacts an echo server over and over again

   Andrew Christian <andrew.christian@hp.com>
   25 January 2005
'''

from twisted.internet.protocol import ConnectedDatagramProtocol
from twisted.internet import reactor

import sys

def parse_host(host):
    'Parse strings of the form HOST[:PORT]'
    port = 7

    if ':' in host:
        host, port = host.split(':')
        port = int(port)

    return host, port

class InstanceCounter:
    def __init__(self):
        self._count = 0

    def add(self):
        self._count += 1

    def sub(self):
        self._count -= 1
        return self._count

g_IC = InstanceCounter()

class EchoTestClient( ConnectedDatagramProtocol ):
    def __init__(self, data):
        self._data = data
        g_IC.add()

    def startProtocol(self):
        self.sendDatagram()

    def sendDatagram(self):
        self.transport.write(self._data)
        
    def datagramReceived(self, datagram):
        print 'Datagram received', repr(datagram)
        if not g_IC.sub():
            reactor.stop()
        
def usage():
    print """
    Usage: testEchoServer.py [OPTIONS] HOST[:PORT] DATA [HOST[:PORT] DATA]+

    Port defaults to 7
    
    Valid options are:

         -v, --verbose        May be repeated for more detail
         -h, --help           This help
         
    """ 
    sys.exit(0)


if __name__ == '__main__':
    import getopt

    verbose = False

    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vh',
                                        ['verbose', 'help'])
    except Exception, e:
        print e
        usage()

    for (k,v) in options:
        if k in ('-v', '--verbose'):
            verbose = True
        elif k in ('-h', '--help'):
            usage()
        else:
            usage()

    if len(argv) < 2 or len(argv) % 2 != 0:
        print "must supply at least one host and data string"

    while len(argv) > 1:
        host, port = parse_host(argv[0])
        data = argv[1]

        protocol = EchoTestClient(data)
        if verbose: print 'Connecting to', host, port
        reactor.connectUDP( host, port, protocol )

        argv = argv[2:]

    reactor.run()
