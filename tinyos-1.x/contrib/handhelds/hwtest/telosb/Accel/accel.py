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
#  accel.py
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

VERBOSE = 0

###########################################################################################

class AccelData:
    'Unpack a struct XpodData from the pulse-ox sensor'
    def __init__(self,data):
        self.number  = struct.unpack('I',data[:4])[0]
        format = "%dH" % (len(data[4:]) / 2)
        self.samples = struct.unpack(format,data[4:])

        self.xsamples = self.samples[::2]
        self.ysamples = self.samples[1::2]

    def __str__(self):
        return "%d  x=" % self.number + str(self.xsamples) + " y=" + str(self.ysamples)

class SIPLiteTestReceiver( DatagramProtocol ):
    'Set up an SIPLite receiver'
    def __init__(self,mw,filename):
        self.mw = mw
        self.fd = None

        if filename is not None:
            self.fd = open(filename,'w')
        
    def datagramReceived(self, datagram, addr):
        hd = AccelData( datagram )

        if VERBOSE > 1: print hd
        if self.fd is not None:
            for index in range(len(hd.xsamples)):
                print >>self.fd, "%d %d %d %d" % (hd.number, index,
                                                  hd.xsamples[index], hd.ysamples[index])
        self.mw.add_data( hd.number, hd.xsamples, hd.ysamples )

class SIPLiteTestClient( DatagramProtocol ):
    def __init__(self,host,remote_port,protocol,mw,filename):
        self.host         = host
        self.remote_port  = remote_port
        self.timeout      = 10
        self.protocol     = protocol
            
        receiver = SIPLiteTestReceiver(mw, filename)
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
        if VERBOSE: print "\nSEND INVITE expires %d" % self.timeout
        
        self.transport.write(msg)

        if self.timeout:
            reactor.callLater( self.timeout * 0.6, self.sendDatagram )
        
    def datagramReceived(self, datagram, addr):
        if VERBOSE: print '\nCOMMAND:', repr(datagram), "from", repr(addr)
        expires = re.search( r'Expires: (\d+)', datagram).group(1)
        if expires and int(expires) == 0:
            reactor.stop()

    def terminate(self):
        self.timeout = 0
        self.sendDatagram()
    
###########################################################################################

class MainWindow:
    def __init__(self, host, remote_port ):
        gladefile = util.sibpath(__file__, 'accel.glade' )
        self.glade = glade.XML(gladefile)

        self.glade.signal_autoconnect(self)
        self.setWidgetsFromGladefile()

        self._mainWindow.show()

        self.xdata   = [0] * 200
        self.ydata   = [0] * 200
        self.xgc     = None
        self.ygc     = None
        self.xwidget = None
        self.ywidget = None
        self.first_msg = None
        self.last_msg  = None

        self._ipLabel.set_markup("<b>IP %s:%d</b>" % (host, remote_port))

    def setWidgetsFromGladefile(self):
        widgets = ( 'mainWindow', 'ipLabel', 'xValue', 'yValue',
                    'xLabel', 'yLabel', 'drawX', 'drawY', 'statusBar' )
        gw = self.glade.get_widget
        for widgetName in widgets:
            setattr(self, "_" + widgetName, gw(widgetName))

        self._statusContext = self._statusBar.get_context_id("Main Window")

        for lb in (self._xValue, self._yValue, self._xLabel, self._yLabel):
            lb.modify_font(pango.FontDescription("sans 14"))

    def statusMsg(self,text):
        self._statusBar.push(self._statusContext,text)

    def add_data(self,seqno,xdata,ydata):
        if self.first_msg is None:
            self.first_msg = seqno
            self.last_msg  = seqno
        else:
            delta = seqno - self.last_msg - 1
            if delta:
                print "Lost %d messages at message %d [first=%d, last=%d]" % (delta,seqno,self.first_msg,self.last_msg)
            self.last_msg = seqno

        self.statusMsg( "Message: %d" % seqno )
        self._xValue.set_text("%d" % xdata[0])
        self._yValue.set_text("%d" % ydata[0])

        self.xdata = self.xdata[len(xdata):] + list(xdata)
        self.ydata = self.ydata[len(ydata):] + list(ydata)

        if self.xwidget: self.xwidget.queue_draw()
        if self.ywidget: self.ywidget.queue_draw()

    def make_gc(self,widget,color="#000000"):
        gc = widget.window.new_gc()
        gc.set_line_attributes(1, gtk.gdk.LINE_SOLID,
                                    gtk.gdk.CAP_ROUND, gtk.gdk.JOIN_ROUND)
        colormap = widget.get_colormap()
        gc.set_foreground(colormap.alloc_color(color))
        return gc

    def on_drawX_expose_event(self,widget,event):
        if not self.xwidget: self.xwidget = widget
        if not self.xgc:
            self.xgc = self.make_gc(widget,"#0000FF")
            self.xgc2 = self.make_gc(widget)
        self.expose_event(widget,self.xdata,self.xgc)

    def on_drawY_expose_event(self,widget,event):
        if not self.ywidget: self.ywidget = widget
        if not self.ygc:
            self.ygc = self.make_gc(widget,"#00FF00")
        self.expose_event(widget,self.ydata,self.ygc)

    def expose_event(self,widget,data,gc):
        r = widget.get_allocation()
        xscale = float(r.width) / (len(data) - 1)
        yscale = float(r.height) / 4096
        count = len(data)
        
        for i in range(0,count-1):
              widget.window.draw_line(gc,
                                      int(xscale * i), int(yscale * data[i]),
                                      int(xscale * (i+1)), int(yscale * data[i+1]))
    
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
    Usage: accel.py [OPTIONS] HOST[:PORT] 

    Remote port defaults to 5062
    
    Valid options are:

         -v, --verbose        May be repeated for more detail
         -p, --protocol=NUM   Protocol to use (1=fast, 2=slow)
         -o, --out=FILE       File to store data in
         -h, --help           This help
         
    """
    sys.exit(0)

if __name__ == '__main__':
    import getopt
    config = { 'verbose'     : 0,
               'remote_port' : 5062,
               'out'         : None,
               'protocol'    : 1 }

    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vhp:o:',
                                        ['verbose', 'help', 'protocol=', 'out='])
    except Exception, e:
        print e
        usage()

    for (k,v) in options:
        if k in ('-v', '--verbose'):
            VERBOSE += 1
        elif k in ('-h', '--help'):
            usage()
        elif k in ('-p', '--protocol'):
            config['protocol'] = int(v)
        elif k in ('-o', '--out'):
            config['out'] = v
        else:
            print "I didn't understand that"
            usage()

    if len(argv) != 1:
        print "must supply a host and an optional port"
        usage()

    host, remote_port = parse_host(argv[0],config['remote_port'])
    if VERBOSE: print 'Connecting to', host, remote_port, "protocol", config['protocol']

    mw = MainWindow(host, remote_port)

    rtpc = SIPLiteTestClient(host,remote_port,config['protocol'],mw,config['out'])
    reactor.listenUDP( 0, rtpc )
    reactor.run()
