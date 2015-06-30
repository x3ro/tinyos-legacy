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
#  pulseox.py
#
#  Subscribe to a pulse-ox SIPLite server and display data stream.

from twisted.internet import gtk2reactor
gtk2reactor.install()

import gobject, gtk
from gtk import glade

import sys,struct,time,re
import pango

from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor
from twisted.python import util

###########################################################################################

class HeartData:
    'Unpack a struct XpodData from the pulse-ox sensor'
    def __init__(self,data):
        (self.number, self.hr, self.hrd, self.spo2, self.spo2d,
         self.ehr, self.ehrd, self.spo2slew, self.spo2btob,
         self.espo2, self.espo2d)  = struct.unpack('IhhBBhh4b', data[:18])
        self.status = [ord(x) for x in data[18:68:2]]
        self.pleth  = [ord(x) for x in data[19:69:2]]
        self.firmware = ord(data[68])

class HeartDataLite:
    'Unpack a struct XpodData from the pulse-ox sensor'
    def __init__(self,data):
        (self.number, self.hr, self.hrd, self.spo2, self.spo2d) = struct.unpack('IhhBB', data)

class SIPLiteTestReceiver( DatagramProtocol ):
    'Set up an SIPLite receiver'
    def __init__(self,mw):
        self.mw = mw
        
    def datagramReceived(self, datagram, addr):
        hd = HeartData( datagram )

        if hd.hr < 511: hrText = "%d" % hd.hr
        else:           hrText = "N/A"
        if hd.spo2 < 127: spText = "%d" % hd.spo2
        else:             spText = "N/A"

        mw._heartRateLabel.set_text( hrText )
        mw._oxygenationLabel.set_text( spText )
        mw.add_pleth_data( hd.number, hd.pleth )

class SIPLiteTestClient( DatagramProtocol ):
    def __init__(self,host,remote_port,protocol,mw):
        self.host         = host
        self.remote_port  = remote_port
        self.timeout      = 10
        self.protocol     = protocol

        receiver = SIPLiteTestReceiver(mw)
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
    
###########################################################################################

class MainWindow:
    def __init__(self):
        gladefile = util.sibpath(__file__, 'pulseox.glade' )
        self.glade = glade.XML(gladefile)

        self.glade.signal_autoconnect(self)
        self.setWidgetsFromGladefile()

        self._mainWindow.show()

        self.index   = 0
        self.datalen = 225
        self.pdata   = [0] * self.datalen
        self.gc      = None
        self.widget  = None

    def setWidgetsFromGladefile(self):
        widgets = ( 'mainWindow', 'heartRateLabel', 'oxygenationLabel',
                    'spo2_graph', 'statusBar' )
        gw = self.glade.get_widget
        for widgetName in widgets:
            setattr(self, "_" + widgetName, gw(widgetName))

        self._statusContext = self._statusBar.get_context_id("Main Window")
        self._heartRateLabel.modify_font(pango.FontDescription("sans 20"))
        self._oxygenationLabel.modify_font(pango.FontDescription("sans 20"))

    def statusMsg(self,text):
        self._statusBar.push(self._statusContext,text)

    def add_pleth_data(self,seqno,pleth_list):
        self.statusMsg( "Message: %d" % seqno )
        for p in pleth_list:
            self.pdata[self.index] = p
            self.index = (self.index + 1) % self.datalen

        if self.widget:
            self.widget.queue_draw()
        
    def on_spo2_graph_expose_event(self, widget, event):
        if not self.gc:
            self.widget = widget
            self.gc = widget.window.new_gc()
            self.gc.set_line_attributes(1, gtk.gdk.LINE_SOLID,
                                        gtk.gdk.CAP_ROUND, gtk.gdk.JOIN_ROUND)
            self.red_gc    = widget.window.new_gc()
            self.yellow_gc = widget.window.new_gc()
            self.green_gc  = widget.window.new_gc()

            colormap = widget.get_colormap()

            red    = colormap.alloc_color( 65535, 0, 0  )
            yellow = colormap.alloc_color( 65535, 65535, 0 )
            green  = colormap.alloc_color( 0, 65536, 0 )
            
            self.red_gc.set_foreground( red )
            self.yellow_gc.set_foreground( yellow )
            self.green_gc.set_foreground( green )

        r = widget.get_allocation()
        xscale = float(r.width) / (len(self.pdata) - 1)
        yscale = float(r.height) / 255
        
        for i in range(0,self.datalen - 1):
              widget.window.draw_line(self.gc,
                             int(xscale * i),
                             int(yscale * self.pdata[(self.index + i) % self.datalen]), 
                             int(xscale * (i+1)),
                             int(yscale * self.pdata[(self.index + 1 + i) % self.datalen]))
    
    def on_mainWindow_delete_event(self, widget, data):
        gtk.main_quit()

    def on_mainWindow_destroy_event(self, widget):
        gtk.main_quit()


###########################################################################################

def parse_host(host,default_port=5062):
    'Parse strings of the form HOST[:PORT]'
    port = default_port

    if ':' in host:
        host, port = host.split(':')
        port = int(port)

    return host, port

def usage():
    print """
    Usage: pulseox.py [OPTIONS] HOST[:PORT] 

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
        print "must supply a host and an optional port"
        usage()

    host, remote_port = parse_host(argv[0],config['remote_port'])
    if config['verbose']:
        print 'Connecting to', host, remote_port, "protocol", config['protocol']

    mw = MainWindow()

    rtpc = SIPLiteTestClient(host,remote_port,config['protocol'],mw)
    reactor.listenUDP( 0, rtpc )
    reactor.run()
