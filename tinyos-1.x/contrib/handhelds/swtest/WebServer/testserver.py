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


 Twisted client that contacts a web server over and over and over...

 Use this to connect to an HTTP server to verify that you get the
 correct number of bytes back each time (good for testing a mote)

  Andrew Christian <andrew.christian@hp.com>
  January 2005
'''

from twisted.internet.protocol import Protocol, ClientFactory
from twisted.internet import reactor

import sys
import urlparse

def parse_url(url):
    'Break a url down into a host, port, and remainder.  Return a tuple'
    host = ''
    port = 80
    arg  = '/'
    if url.startswith('http://'):
        url = url[7:]

    if '/' in url:
        host, arg = url.split('/',1)
    else:
        host = url

    if ':' in host:
        host, port = host.split(':')
        port = int(port)

    if not len(arg):
        arg = '/'

    return host, port, arg

class InstanceCounter:
    def __init__(self, verbose=False):
        self._count = 0
        self._verbose = verbose

    def add(self):
        self._count += 1
        if self._verbose:
            print 'IC', self._count

    def sub(self):
        self._count -= 1
        if self._verbose:
            print 'IC', self._count
        if self._count == 0:
            reactor.stop()

g_IC = InstanceCounter()


class ServerTestClient( Protocol ):
    def __init__(self, index):
        self._rxcount = 0
        self._index   = index
        
    def connectionMade(self):
        print 'CONNECT    %3d  %s' % (self._index, self.factory._url)
        self.transport.write("GET %s HTTP/1.0\r\nUser-Agent: TestServer/1.0\r\n\r\n" % self.factory._arg)

    def dataReceived(self,data):
        self._rxcount += len(data)
        if self.factory._config['verbose'] > 1:
            sys.stdout.write(data)
            sys.stdout.flush()

    def connectionLost(self, reason):
        if self.factory._bytes != self._rxcount:
            print 'ERROR      %3d  %s  Bad byte count %d (should be %d)' % (self._index,
                                                                        self.factory._url,
                                                                        self._rxcount,
                                                                        self.factory._bytes)
        else:
            print 'DISCONNECT %3d  %s' % (self._index, self.factory._url)
        sys.stdout.flush()
        

class ServerTestFactory( ClientFactory ):
    protocol = ServerTestClient

    def __init__(self, config, url, arg, bytes ):
        self._url     = url
        self._arg     = arg
        self._config  = config
        self._bytes   = bytes
        self._clients = 0          # Counter the number of clients on-going

    def startedConnecting( self, connector ):
        g_IC.add()
        if self._config['verbose']: print 'Started to connected'
        
    def buildProtocol( self, addr):
        if self._config['verbose']: print 'Connected', addr
        self._clients += 1

        stc = ServerTestClient( self._clients )
        stc.factory = self
        return stc

    def clientConnectionLost( self, connector, reason ):
        if self._config['verbose']: print 'Lost connection, reason=', reason
        g_IC.sub()

    def clientConnectionFailed( self, connector, reason ):
        if self._config['verbose']: print 'Failed connection, reason=', reason
        g_IC.sub()

def usage(dict):
    print """
    Usage: testserver.py [OPTIONS] URL BYTES [URL BYTES]*

    Valid options are:

         -v, --verbose        May be repeated for more detail
         -h, --help           This help
         -i, --instances=NUM  Number of instances of each URL to retrieve
         
    """ % dict
    sys.exit(0)


if __name__ == '__main__':
    import getopt
    config = { 'verbose' : 0,
               'instances' : 1 }

    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vhi:',
                                        ['verbose', 'help', 'instances='])
    except Exception, e:
        print e
        usage(config)

    for (k,v) in options:
        if k in ('-v', '--verbose'):
            config['verbose'] += 1
        elif k in ('-h', '--help'):
            usage(config)
        elif k in ('-i', '--instances'):
            config['instances'] = int(v)
        else:
            usage(config)

    if not len(argv):
        print "must supply at least one URL"
        usage(config)

    while len(argv):
        url = argv[0]
        bytes = int(argv[1])
        argv = argv[2:]
        
        host, port, arg = parse_url(url)
        stf = ServerTestFactory( config, url, arg, bytes )
        
        for i in range(config['instances']):
            reactor.connectTCP( host, port, stf )

    reactor.run()
