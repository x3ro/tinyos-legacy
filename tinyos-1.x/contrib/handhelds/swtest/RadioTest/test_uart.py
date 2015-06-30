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


  Test the UART

  Andrew Christian <andrew.christian@hp.com>
  May 2005
'''

import sys,struct,time,signal

from twisted.internet import protocol
from twisted.internet.serialport import SerialPort
from twisted.internet import reactor

VERBOSE = 0

###########################################################################################

class BasicMessageReceiver(protocol.Protocol):
    """A receiver for Basic Message strings

    A basic message is terminated by 0x7e.  All
    0x7e and 0x7d characters are replaced by 0x7d 0x20^byte
    """
    MAX_LENGTH = 256

    def __init__(self):
        self.recvd        = ""
        self.synchronized = False
        self.start_time   = time.time()

    def msgReceived(self,msg):
        'Override this'
        raise NotImplementedError
    
    def dataReceived(self,recvd):
        if VERBOSE > 1: print 'received', ["%02x" % ord(x) for x in recvd]
        self.recvd = self.recvd + recvd
        while len(self.recvd):
            index = self.recvd.find(chr(0x7e))
            if index < 0:
                break

            msg = self.recvd[:index]
            self.recvd = self.recvd[index+1:]

            if not self.synchronized:
                if len(msg) and VERBOSE:
                    print 'Synchronizing', len(msg), 'characters', ["%02x" % ord(x) for x in msg]
                self.synchronized = True
            elif len(msg):
                vlist = msg.split(chr(0x7d))
                if VERBOSE > 2: print 'vlist', vlist
                try:
                    msg = vlist[0] + ''.join([chr(ord(v[0]) ^ 0x20) + v[1:] for v in vlist[1:]])
                    self.msgReceived(msg)
                except Exception, e:
                    # A bad packet can have two 'x7d' bytes in a row
                    if VERBOSE:
                        print 'Decoding error', e, vlist

        if len(self.recvd) > BasicMessageReceiver.MAX_LENGTH:
            self.recvd = ''
            self.synchronized = False
            print 'Lost synchronization'

    def sendMessage(self,data):
        'Send an encoded string'
        if VERBOSE: print 'Raw send:', ":".join(["%02x" % ord(x) for x in data])
        msg = chr(0x7e)
        escape_list = (chr(0x7d), chr(0x7e))
        for d in data:
            if d in escape_list:
                msg += chr(0x7d) + chr(ord(d) ^ 0x20)
            else:
                msg += d
        msg += chr(0x7e)
        if VERBOSE > 1: print 'Writing', ":".join(["%02x" % ord(x) for x in msg])
        self.transport.write(msg)
            

###########################################################################################

def to_hex(data):
    return ":".join(["%02x" % ord(x) for x in data])

class Transmitter(BasicMessageReceiver):
    def __init__(self,config,pkt):
        BasicMessageReceiver.__init__(self)
        self.pkt = pkt
        self._sent     = 0
        self._received = 0
        self._bad      = 0

    def dump(self):
        print "Lost %d of %d received [%d sent]" % (self._bad, self._received, self._sent)

    def send_packet(self):
        self._sent += 1
        self.sendMessage(self.pkt)
        self.transport.flushOutput()
        if VERBOSE: print 'Sent message', to_hex(self.pkt)
        
    def msgReceived(self,msg):
        if len(msg) <= 0:
            return

        self._received += 1
        try:
            if VERBOSE:
                print to_hex(msg)
            if msg != self.pkt:
                self._bad += 1
                print 'Error: ', to_hex(msg), "(%d of %d [%d])" % (self._bad, self._received, self._sent)
            
        except Exception, e:
            print e

        self.send_packet()

    def connectionMade(self):
        self.send_packet()

    def connectionLost(self):
        print 'Lost'

###########################################################################################

def usage(dict):
    print """
Usage: test_uart.py [OPTIONS]

Valid options are:

     -v, --verbose        May be repeated for more detail
     -h, --help           This help
     -d, --dev=DEVICE     Use TTY device DEVICE (%(dev)s)
     -b, --baud=RATE      Set baud rate to RATE (%(baudrate)d)
    """ % dict
    sys.exit(0)


if __name__ == '__main__':
    import getopt
    config = { 'dev'     : '/dev/ttyUSB0',
               'baudrate': 57600
               }

    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vhd:b:',
                                        ['verbose', 'help', 'dev=', 'baudrate='])
    except Exception, e:
        print e
        usage(config)

    for (k,v) in options:
        if k in ('-v', '--verbose'):
            VERBOSE += 1
        elif k in ('-h', '--help'):
            usage(config)
        elif k in ('-d', '--dev'):
            config['dev'] = v
        elif k in ('-b', '--baudrate'):
            config['baudrate'] = int(v)
        else:
            usage(config)

    pkt = "1234567890"
    t = Transmitter(config,pkt)
    SerialPort(t, config['dev'], reactor, baudrate=config['baudrate'])

    reactor.run()
    t.dump()
