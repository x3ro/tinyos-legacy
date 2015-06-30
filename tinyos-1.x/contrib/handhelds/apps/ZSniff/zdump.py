#!/usr/bin/python
#
# Copyright (c) 2005 Hewlett-Packard Company
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
#  zdump.py
#
#   Parse and display packets captured from TOSBase or ZSniff
#
#  Author:  Andrew Christian <andrew.christian@hp.com>
#           November 2004

import sys,struct,time

from ZigbeeDecoding import decode_packet, BasicMessageReceiver, MyError

from twisted.internet.serialport import SerialPort
from twisted.internet import reactor

###########################################################################################

class RawReceive(BasicMessageReceiver):
    'A trivial message receiver that just displays bytes received and does no decoding'
    def __init__(self,config):
        BasicMessageReceiver.__init__(self,config['verbose'])
        self.channel_list  = config['channels']
        self.channel_index = 0

    def msgReceived(self,msg):
        if len(msg):
            print "%.2f (%d)" % ((time.time() - self.start_time), len(msg)), ':'.join(["%02x" % ord(x) for x in msg])
    
    def connectionMade(self):
        msg = struct.pack('4B', 1, 1, 1, self.channel_list[self.channel_index] )
        self.sendMessage(msg)

###########################################################################################

class TOSReceive(BasicMessageReceiver):
    'Decode TOS messages as specified in the telos platform'
    def __init__(self,config):
        BasicMessageReceiver.__init__(self,config['verbose'])

    def msgReceived(self,msg):
        if len(msg) <= 0:
            return

        try:
            pkt = TOSPacket(msg)
            print "%.2f" % (time.time() - self.start_time), pkt.singleline()
        except Exception, e:
            print 'Could not decode ', ':'.join(["%02x" % ord(x) for x in msg]), e

    def connectionMade(self):
        pass

###########################################################################################

class SniffReceive(BasicMessageReceiver):
    '''Decode a message from the ZSniff protocol.
       The first byte of the message tells you the type of data being
       sent.  1 = 802.15.4 packet, 2 = other message.
       '''
    def __init__(self,config):
        BasicMessageReceiver.__init__(self,config['verbose'])
        self.timeout       = config['timeout']
        self.channel_list  = config['channels']
        self.channel_index = 0
        self.ip            = config['ip']
        self.multiline     = config['multiline']
        self.filters       = config['filter']

    def msgReceived(self,msg):
        if len(msg) <= 0:
            return

        try:
            pkt = decode_packet(msg, self.ip)

            for f in self.filters:
                if not f.apply(pkt):
                    return
                
            print "%-8.2f" % (time.time() - self.start_time),
            if self.multiline:
                rlist = pkt.multiline()
                print rlist[0]
                for line in rlist[1:]:
                    print " " * 8, line
                print
            else:
                print pkt.singleline()
        except MyError, e:
            print e
        except Exception, e:
            print '**** Unable to decode packet ******', e
            print ":".join(["%02x" % ord(x) for x in msg])

    def handleTimeout(self):
        msg = struct.pack('3B', 1, 0, 0 )   # Request radio statistics
        self.sendMessage(msg)

        msg = struct.pack('3B', 1, 0, 2 )   # Request radio state
        self.sendMessage(msg)

        if len(self.channel_list) > 1:
            self.channel_index += 1
            if self.channel_index >= len(self.channel_list):
                self.channel_index = 0
            
            msg = struct.pack('4B', 1, 1, 1, self.channel_list[self.channel_index] )
            self.sendMessage(msg)

        reactor.callLater( self.timeout, self.handleTimeout )

    def connectionMade(self):
        msg = struct.pack('4B', 1, 1, 1, self.channel_list[self.channel_index] )
        self.sendMessage(msg)

        if self.timeout > 0:
            reactor.callLater( self.timeout, self.handleTimeout )
    
###########################################################################################

class FilterAttribute:
    def __init__(self,e):
        (self.arg, self.value) = e.split('=')
        if self.value.isdigit():
            self.value = int(self.value)

    def apply(self,pkt):
        if not hasattr(pkt,self.arg):
            return False

        a = getattr(pkt,self.arg)
        return a == self.value

class FilterType:
    def __init__(self,e):
        self.value = e

    def apply(self,pkt):
        return pkt.isa(self.value)
    
def make_filter(e):
    if '=' in e:
        return FilterAttribute(e)
    return FilterType(e)

###########################################################################################

def usage(dict):
    print """
    Usage: zdump.py FORMAT [OPTIONS]

    Valid formats are:

         raw            Just display bytes received from USB
         tos            Decode messages from TOSBase
         sniff          Decode framed 802.15.4 packets from ZSniff

    Valid options are:

         -v, --verbose        May be repeated for more detail
         -h, --help           This help
         -d, --dev=DEVICE     Use TTY device DEVICE (%(dev)s)
         -b, --baud=RATE      Set baud rate to RATE (%(baudrate)d)
         -m, --multiline      Multiline output
         -f, --filter=FILTER  Filter packets by expression (see below)

    'sniff' mode options
         -c, --channels=LIST  Comma-separated list of channels (default 11)
         -t, --timeout=NUM    Seconds between timeouts
         -i, --ip             Decode Link layer packets

    Filter options:

        arg=value          Match a particular argument to a value.  For example,
                              'll_protocol=1'    (match ARP packets)
                              'arp_name=REQUEST' (match an ARP REQUEST packet)

        type               Match a generic packet type.  Valid types include:
                              beacon, cmd, arp, icmp, ip, ll, data, ack, other,
                              mac, radio, stats, channel, state, unknown

    Multiple filters form an implicit boolean 'AND'
    """ % dict
    sys.exit(0)


if __name__ == '__main__':
    import getopt
    config = { 'verbose' : 0,
               'dev'     : '/dev/ttyUSB0',
               'baudrate': 57600,
               'channels': [11],
               'timeout' : 0,
               'format'  : 'header',
               'multiline' : False,
               'ip'        : False,
               'filter'    : [] }

    format_dict = {  'raw'   : RawReceive,
                     'tos'   : TOSReceive,
                     'sniff' : SniffReceive }

    if len(sys.argv) < 2:
        usage(config)

    format_name = sys.argv[1]
    if not format_dict.has_key(format_name):
        print "Invalid format", format_name
        usage(config)

    try:
        (options, argv) = getopt.getopt(sys.argv[2:], 'vhd:b:c:t:imf:',
                                        ['verbose', 'help', 'dev=', 'baudrate=', 'channels=',
                                         'timeout=', 'ip', 'multiline','filter='])
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
        elif k in ('-c', '--channels'):
            config['channels'] = map(int,v.split(','))
        elif k in ('-t', '--timeout'):
            config['timeout'] = float(v)
        elif k in ('-i', '--ip'):
            config['ip'] = True
        elif k in ('-m', '--multiline'):
            config['multiline'] = True
        elif k in ('-f', '--filter'):
            config['filter'].append(make_filter(v))
        else:
            usage(config)

    if len(argv) > 1:
        print "too many arguments"
        usage(config)

    SerialPort(format_dict[format_name](config), config['dev'], reactor, baudrate=config['baudrate'])
    reactor.run()
