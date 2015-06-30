#!/usr/bin/python
#
# Copyright (c) 2004,2005 Hewlett-Packard Company
# All rights reserved
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:

#    * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#    * Neither the name of the Hewlett-Packard Company nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
#  apdump.py
#
#   Parse and display access point information

import sys,struct,time

from ZigbeeDecoding import BasicMessageReceiver

from twisted.internet.serialport import SerialPort
from twisted.internet import reactor

###########################################################################################

def to_hex_string(data):
    return ":".join(["%02x" % ord(x) for x in data])

def decode_associate(msg):
    (saddr,) = struct.unpack('!H',msg[:2])
    laddr = to_hex_string(msg[2:10])
    flags = ord(msg[10])

    return 'ASSOC    %s (%d) 0x%02x' % (laddr, saddr, flags)

def decode_reassociate(msg):
    (saddr,) = struct.unpack('!H',msg[:2])
    laddr = to_hex_string(msg[2:10])
    flags = ord(msg[10])

    return 'RE_ASSOC %s (%d) 0x%02x' % (laddr, saddr, flags)

def decode_stale(msg):
    (saddr,) = struct.unpack('!H',msg[:2])
    laddr = to_hex_string(msg[2:10])
    flags = ord(msg[10])

    return 'STALE    %s (%d) 0x%02x' % (laddr, saddr, flags)

def decode_released(msg):
    (saddr,) = struct.unpack('!H',msg[:2])
    laddr = to_hex_string(msg[2:10])
    flags = ord(msg[10])

    return 'RELEASED %s (%d) 0x%02x' % (laddr, saddr, flags)

def decode_arp(msg):
    (saddr,) = struct.unpack('!H',msg[:2])
    laddr = to_hex_string(msg[2:10])
    flags = ord(msg[10])
    ipaddr = '.'.join(["%d" % ord(x) for x in msg[11:15]])

    return 'ARP %s (%d) 0x%02x %s' % (laddr, saddr, flags, ipaddr)

def decode_data(msg):
    (saddr,) = struct.unpack('!H',msg[:2])
    return 'DATA (%d) %s' % (saddr, to_hex_string(msg[2:]))

def decode_table(msg):
    (count,) = struct.unpack('!B',msg[:1])
    msg = msg[1:]
    result = "TABLE (%d)" % count
    while len(msg):
        (flags,saddr) = struct.unpack('!BH',msg[:3])
        laddr = to_hex_string(msg[3:11])
        queue_len = ord(msg[11])
        msg = msg[12:]
        result += " [%s (%d) 0x%02x %d]" % (laddr,saddr,flags,queue_len)

    return result

g_PacketTypes = ( ("\x01\x01", decode_associate),
                  ("\x01\x02", decode_reassociate),
                  ("\x01\x03", decode_stale),
                  ("\x01\x04", decode_released),
                  ("\x01\x05", decode_arp),
                  ("\x02",     decode_data),
                  ("\x03\x01", decode_table),
                  )

def parse_packet(msg):
    for s,f in g_PacketTypes:
        if msg.startswith(s):
            try:
                return f(msg[len(s):])
            except Exception, e:
                return 'Error in processing' + e + to_hex_string(msg)
            return

    return 'Unknown packet type' + to_hex_string(msg)

###########################################################################################

class APDump(BasicMessageReceiver):
    '''Communicate with an Access Point'''

    def __init__(self,config):
        BasicMessageReceiver.__init__(self,config['verbose'])
        self.count = 0

    def msgReceived(self,msg):
        if len(msg) <= 0:
            return

        print "%7.2f" % (time.time() - self.start_time), parse_packet(msg)

    def handleTimeout(self):
        msg = struct.pack('2B', 1, 1)   # Request the association table
        self.sendMessage(msg)

        reactor.callLater( 5, self.handleTimeout );
        
    def connectionMade(self):
        msg = struct.pack('2B', 1, 1)   # Request the association table
        self.sendMessage(msg)

        reactor.callLater( 5, self.handleTimeout );
        

###########################################################################################

def usage(dict):
    print """
    Usage: apdump.py [OPTIONS]

    Valid options are:

         -v, --verbose        May be repeated for more detail
         -h, --help           This help
         -d, --dev=DEVICE     Use TTY device DEVICE (%(dev)s)
         -b, --baud=RATE      Set baud rate to RATE (%(baudrate)d)
    """ % dict
    sys.exit(0)


if __name__ == '__main__':
    import getopt
    config = { 'verbose' : 0,
               'dev'     : '/dev/ttyUSB0',
               'baudrate': 19200
               }

    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vhd:b:',
                                        ['verbose', 'help', 'dev=', 'baudrate='])
    except Exception, e:
        print e
        usage(config)

    for (k,v) in options:
        if k in ('-v', '--verbose'):
            config['verbose'] += 1
        elif k in ('-h', '--help'):
            usage(config)
        elif k in ('-d', '--dev'):
            config['dev'] = v
        elif k in ('-b', '--baudrate'):
            config['baudrate'] = int(v)
        else:
            usage(config)

    if len(argv) > 0:
        print "too many arguments"
        usage(config)

    SerialPort( APDump(config), config['dev'], reactor, baudrate=config['baudrate'])
    reactor.run()
