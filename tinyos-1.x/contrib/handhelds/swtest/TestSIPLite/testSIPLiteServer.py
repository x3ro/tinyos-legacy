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


  Twisted client that contacts a SIPLite server

  Andrew Christian <andrew.christian@hp.com>
  March 2005
'''

from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor

import sys, struct, re

def parse_host(host,default_port=5062):
    'Parse strings of the form HOST[:PORT]'
    port = default_port

    if ':' in host:
        host, port = host.split(':')
        port = int(port)

    return host, port

class SIPLiteTestReceiver( DatagramProtocol ):
    'Set up an SIPLite receiver'
    def datagramReceived(self, datagram, addr):
        print struct.unpack('H',datagram[:2])[0],
        sys.stdout.flush()

class SIPLiteTestClient( DatagramProtocol ):
    def __init__(self,host,remote_port,protocol):
        self.host         = host
        self.remote_port  = remote_port
        self.timeout      = 10
        self.protocol     = protocol

        receiver = SIPLiteTestReceiver()
        reactor.listenUDP( 0, receiver )
        self.local_port = receiver.transport.getHost().port

    def startProtocol(self):
        self.transport.connect(self.host, self.remote_port)
        self.sendDatagram()

    def sendDatagram(self):
        msglist = ["INVITE SIPLITE/1.0",
                   "Expires: %d" % self.timeout,
                   "Call-ID: FOOBAR",
                   "",
                   "m=%d %d" % (self.local_port, self.protocol) ]
        msg = "\r\n".join(msglist) + "\r\n"
        print "\nSEND INVITE expires %d" % self.timeout
        
        self.transport.write(msg)

        if self.timeout:
            reactor.callLater( self.timeout * 0.6, self.sendDatagram )
        
    def datagramReceived(self, datagram, addr):
        print '\nCOMMAND:', repr(datagram), "from", repr(addr)
        expires = re.search( r'Expires: (\d+)', datagram).group(1)
        if expires and int(expires) == 0:
            reactor.stop()

    def terminate(self):
        self.timeout = 0
        self.sendDatagram()
        
    
def usage():
    print """
    Usage: testSIPLiteServer.py [OPTIONS] HOST[:PORT] 

    Remote port defaults to 5062
    
    Valid options are:

         -v, --verbose        May be repeated for more detail
         -p, --protocol=NUM   Protocol to use (1=fast, 2=slow)
         -h, --help           This help
         
    """
    sys.exit(0)


if __name__ == '__main__':
    import getopt

    config = { 'verbose'     : 0,
               'remote_port' : 5062,
               'protocol'    : 1 }


    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vhp:',
                                        ['verbose', 'help', 'protocol='])
    except Exception, e:
        print e
        usage()

    for (k,v) in options:
        if k in ('-v', '--verbose'):
            config['verbose'] += 1
        elif k in ('-h', '--help'):
            usage()
        elif k in ('-p', '--protocol'):
            config['protocol'] = int(v)
        else:
            print "I didn't understand that"
            usage()

    if len(argv) != 1:
        print "must supply at least one host and data string"
        usage()


    host, remote_port = parse_host(argv[0],config['remote_port'])

    if config['verbose']:
        print 'Connecting to', host, remote_port, "protocol", config['protocol']

    rtpc = SIPLiteTestClient(host,remote_port,config['protocol'])
    reactor.listenUDP( 0, rtpc )
    reactor.callLater( 20, rtpc.terminate)
    
    reactor.run()
