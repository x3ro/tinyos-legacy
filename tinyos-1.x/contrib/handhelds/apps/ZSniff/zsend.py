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

   Send arbitrary packets on 802.15.4

   Andrew Christian  <andrew.christian@hp.com>
   May 2005
'''

import sys,struct,time

from ZigbeeDecoding import decode_packet, BasicMessageReceiver, RFChannelPacket

from twisted.internet.serialport import SerialPort
from twisted.internet import reactor

VERBOSE = 0

###########################################################################################

class Transmitter(BasicMessageReceiver):
    def __init__(self,config,pkt):
        BasicMessageReceiver.__init__(self,VERBOSE)
        self.channel  = config['channel']
        self.number   = config['number']
        self.pkt = pkt

    def msgReceived(self,msg):
        if len(msg) <= 0:
            return

        try:
            pkt = decode_packet(msg)
            if VERBOSE: print pkt.singleline()
        except:
            print "Unable to decode packet", pkt

        if pkt.contains(RFChannelPacket):
            msg = '\2' + self.pkt.pkt
            while self.number:
                self.sendMessage(msg)
                self.transport.flushOutput()
                if VERBOSE: print 'Sent message'
                self.number -= 1

            reactor.stop()

    def connectionMade(self):
        if VERBOSE: print 'Setting channel to', self.channel
        msg = struct.pack('4B', 1, 1, 1, self.channel)
        self.sendMessage(msg)

    def connectionLost(self):
        print 'Lost'

###########################################################################################

class FCF:
    FRAME_TYPE_BEACON       = 0x00
    FRAME_TYPE_DATA         = 0x01
    FRAME_TYPE_ACK          = 0x02
    FRAME_TYPE_CMD          = 0x03
    FRAME_TYPE_MASK         = 0x07
    
    SECURITY_ENABLED        = 0x08
    FRAME_PENDING           = 0x10
    ACK_REQUEST             = 0x20
    INTRA_PAN               = 0x40
    
    DEST_MODE_SHORT         = 0x08
    DEST_MODE_LONG          = 0x0c

    SRC_MODE_SHORT          = 0x80
    SRC_MODE_LONG           = 0xc0

    def __init__(self,args):
        self.fcf1 = 0
        self.fcf2 = 0

        for a in args.split(','):
            try:
                v = a.split('=',1)
                f = getattr(self,'t_' + v[0])
                f(v[1:])
            except:
                print >>sys.stderr, "Unrecognized fcf option", a
                sys.exit(1)

        self.data = struct.pack('BB',self.fcf1,self.fcf2)

    def t_beacon(self,v):      self.fcf1 |= FCF.FRAME_TYPE_BEACON
    def t_data(self,v):        self.fcf1 |= FCF.FRAME_TYPE_DATA
    def t_ack(self,v):         self.fcf1 |= FCF.FRAME_TYPE_ACK
    def t_cmd(self,v):         self.fcf1 |= FCF.FRAME_TYPE_CMD
    def t_type(self,v):        self.fcf1 |= int(v[0])
    def t_secure(self,v):      self.fcf1 |= FCF.SECURITY_ENABLED
    def t_pend(self,v):        self.fcf1 |= FCF.FRAME_PENDING
    def t_ackreq(self,v):      self.fcf1 |= FCF.ACK_REQUEST
    def t_intrapan(self,v):    self.fcf1 |= FCF.INTRA_PAN
    def t_destshort(self,v):   self.fcf2 |= FCF.DEST_MODE_SHORT
    def t_destlong(self,v):    self.fcf2 |= FCF.DEST_MODE_LONG
    def t_srcshort(self,v):    self.fcf2 |= FCF.SRC_MODE_SHORT
    def t_srclong(self,v):     self.fcf2 |= FCF.SRC_MODE_LONG
        
    def __str__(self):
        return "%02x:%02x" % (self.fcf1,self.fcf2)

    
class SendPacket:
    def __init__(self,arglist):
        pkt = ''

        for a in arglist:
            if a[0].isdigit():
                pkt += chr(int(a,0))
            else:
                v = a.split('=',1)
                try:
                    f = getattr(self,'t_' + v[0])
                    pkt += f(v[1])
                except:
                    print >>sys.stderr, "Unrecognized packet option", a
                    sys.exit(1)

        self.pkt = pkt

    def t_raw(self,v):
        'A raw character string'
        return eval("'" + v + "'")

    def t_pad(self,v):
        'Add N bytes of padding'
        return "\0" * int(v)

    def t_short(self,v):
        'Add a short address'
        return struct.pack('<H',int(v,0))

    def t_panid(self,v):
        'Add a pan id'
        return struct.pack('<H',int(v,0))

    def t_long(self,v):
        'Add a long address (8 bytes)'
        return struct.pack('>6BH',160,160,0,0,0,0,int(v,0))

    def t_fcf(self,v):
        fcf = FCF(v)
        return fcf.data

    def __str__(self):
        return ":".join(["%02x" % ord(x) for x in self.pkt])

def usage(dict):
    print """
Usage: zsend.py [OPTIONS] PACKET_DATA+

Valid options are:

     -v, --verbose        May be repeated for more detail
     -h, --help           This help
     -d, --dev=DEVICE     Use TTY device DEVICE (%(dev)s)
     -b, --baud=RATE      Set baud rate to RATE (%(baudrate)d)
     -c, --channel=NUM    Comma-separated list of channels (default 11)
     -n, --num=NUM        Number of packets to send

Packet data options:

     NUM                  Insert a single byte
     raw=STRING           Put in raw bytes from string
     pad=NUM              Insert NUM padding bytes
     short=NUM            Insert a short address (2 bytes)
     long=NUM             Insert a long-address (8 bytes); set the bottom two

     fcf=flist            Set FCF fields, where flist is a comma separated
                          list.

     Here are some sample packets:

 Sample packets:

   Beacon:           fcf=beacon,srcshort 100 panid=3 short=7 15 0 0x40 0 0 raw='fuzzy'
   Beacon request:   fcf=cmd,srcshort 100 panid=3 short=7 7
                     fcf=cmd,destlong 100 panid=3 long=55 7

   Generic command packet
   fcf=cmd,destshort,srcshort 100 panid=100 short=100 panid=101 short=101 pad=80

    """ % dict
    sys.exit(0)


if __name__ == '__main__':
    import getopt
    config = { 'dev'     : '/dev/ttyUSB0',
               'baudrate': 57600,
               'channel' : 11,
               'number'  : 1
               }

    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vhd:b:c:n:',
                                        ['verbose', 'help', 'dev=', 'baudrate=', 'channel=', 'number='])
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
        elif k in ('-c', '--channel'):
            config['channel'] = int(v)
        elif k in ('-n', '--number'):
            config['number'] = int(v)
        else:
            usage(config)

    if len(argv) <= 0:
        print "too few arguments"
        usage(config)

    pkt = SendPacket(argv)
    print "Sending", pkt

    SerialPort(Transmitter(config,pkt), config['dev'], reactor, baudrate=config['baudrate'])
    reactor.run()
