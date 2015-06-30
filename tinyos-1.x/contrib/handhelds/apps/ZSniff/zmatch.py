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


  zmatchcurses

  Read broadcast packets from a single source and calculate
  updated statistics on RSSI and LQ.

  Andrew Christian
  3 February 2005
'''

import sys,struct,time

from ZigbeeDecoding import decode_packet, BasicMessageReceiver, DataFrame

from twisted.internet.serialport import SerialPort
from twisted.internet import reactor

import curses

###########################################################################################

class SniffReceive(BasicMessageReceiver):
    '''Decode a message from the ZSniff protocol.
       The first byte of the message tells you the type of data being
       sent.  1 = 802.15.4 packet, 2 = other message.
       '''
    def __init__(self, scr):
        BasicMessageReceiver.__init__(self,scr.config['verbose'])
        self.scr = scr

    def msgReceived(self,msg):
        if len(msg) <= 0:
            return

        pkt = decode_packet(msg)
        
        if pkt.contains(DataFrame) and pkt.crc_ok and pkt.data.startswith(self.scr.pattern):
            self.scr.add_packet(pkt)

    def connectionMade(self):
        scr = self.scr
        config = scr.config
        
        msg = struct.pack('4B', 1, 1, 1, config['channel'])
        self.sendMessage(msg)

###########################################################################################

from math import sqrt, exp, floor

class Statistics:
    'Store up statistics'
    def __init__(self):
        self.histogram = {}    # Maps from VALUE -> count
        self.total_packets = 0

    def add_value(self,value):
        if not self.histogram.has_key(value):
            self.histogram[value] = 1
        else:
            self.histogram[value] += 1
        self.total_packets += 1

    def min(self):
        if self.total_packets:
            return min(su.histogram.keys())
        return 0

    def max(self):
        if self.total_packets:
            return max(su.histogram.keys())
        return 0

    def stats(self):
        if self.total_packets == 0:
            return (0.0, 0.0)

        (sum, sum2) = (0L, 0L)
        for k,v in self.histogram.items():
            sum  += long(k) * long(v)
            sum2 += long(k) * long(k) * long(v)

        mean  = float(sum) / self.total_packets
        stdev = 0.0

        if self.total_packets > 1:
            stdev = sqrt( float( sum2 - sum * sum / self.total_packets ) / (self.total_packets - 1))

        return (mean, stdev)

###########################################################################################

class Screen:
    def __init__(self,config,pattern):
        self.config = config
        self.pattern = pattern
        self.plist = []
        self.rssi_stats = Statistics()
        self.lqi_stats  = Statistics()
        self.pause = False
    
    def logPrefix(self):
        return 'CursesClient'
            
    def connectionLost(self, reason):
        self.close()

    def fileno(self):
        return 0

    def doRead(self):
        "Input is available"
        c = self.stdscr.getch() # read a character

        if c == ord('q'):
            reactor.stop()
        if c == ord('r'):
            self.rssi_stats = Statistics()
            self.lqi_stats  = Statistics()
        if c == ord('p'):
            if self.pause:
                self.rssi_stats = Statistics()
                self.lqi_stats  = Statistics()
            self.pause = not self.pause

    def add_packet(self, pkt):
        if self.pause:
            return
        
        s = self.stdscr
        rows, cols = s.getmaxyx()

        self.rssi_stats.add_value( pkt.rssi )
        self.lqi_stats.add_value( pkt.lqi )

        count = self.rssi_stats.total_packets
        (rmean, rstdev) = self.rssi_stats.stats()
        (lmean, lstdev) = self.lqi_stats.stats()
        s.addnstr( 5, 0, "%5d   %9.2f   %11.2f   %8.2f  %10.2f" % (count, rmean, rstdev, lmean, lstdev), cols - 1)
        
        self.plist.append(pkt)
        if len(self.plist) > 10:
            self.plist = self.plist[1:]

        i = 7
        for p in self.plist:
            s.addnstr( i, 0, "%3d %4d %4d" % (p.dsn, p.rssi, p.lqi), cols - 1)
            s.clrtoeol()
            i += 1

        s.refresh()

    def run(self,stdscr):
        'Execute within a curses wrapper'
        self.stdscr = stdscr

        reactor.addReader(self)
        sr = SniffReceive(self)
        SerialPort( sr, self.config['dev'], reactor, baudrate=self.config['baudrate'])

        stdscr.addstr(0, 0, "Press 'q' to quit")
        stdscr.addstr(1, 0, "Press 'r' to reset statistics")
        stdscr.addstr(2, 0, "Press 'p' to pause")
        stdscr.addstr(4, 0, "COUNT   Mean RSSI   StdDev RSSI   Mean LQI  StdDev LQI")
        stdscr.refresh()
        
        reactor.run()

###########################################################################################

def usage(dict):
    print """
    Usage: zmatchcurses.py [OPTIONS] MATCH_STRING

         -v, --verbose        May be repeated for more detail
         -h, --help           This help
         -d, --dev=DEVICE     Use TTY device DEVICE (%(dev)s)
         -b, --baud=RATE      Set baud rate to RATE (%(baudrate)d)
         -c, --channel=NUM    11 to 26 (default %(channel)d)
    """ % dict
    sys.exit(0)


if __name__ == '__main__':
    import getopt
    config = { 'verbose' : 0,
               'dev'     : '/dev/ttyUSB0',
               'baudrate': 19200,
               'channel' : 11 }

    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vhd:b:c:',
                                        ['verbose', 'help', 'dev=', 'baudrate=', 'channel='])
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
        elif k in ('-c', '--channel'):
            config['channel'] = int(v)
        else:
            usage(config)

    if len(argv) != 1:
        print "wrong number of arguments"
        usage(config)

    screen = Screen(config,argv[0])
    curses.wrapper(screen.run)
