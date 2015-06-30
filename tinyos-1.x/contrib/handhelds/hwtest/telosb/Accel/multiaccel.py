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
#  multiaccel.py
#
#  Subscribe to a set of accelerometers and display the data

from twisted.internet import gtk2reactor
gtk2reactor.install()

import gobject, gtk

import sys,struct,time,re
import pango

from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor
from twisted.python import util

import math, operator

VERBOSE     = 0
RMS_RANGE   = 10
DATA_POINTS = 200

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
    def __init__(self,mw):
        self.mw = mw

    def datagramReceived(self, datagram, addr):
        hd = AccelData( datagram )
        if VERBOSE > 1: print hd

        self.mw.add_data( hd.number, hd.xsamples, hd.ysamples )

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

def parse_host(host,default_port=5062):
    'Parse strings of the form HOST[:PORT]'
    port = default_port

    if ':' in host:
        host, port = host.split(':')
        port = int(port)

    return host, port

###########################################################################################

class DataWidget(gtk.HBox):
    'Display data from a single accelerometer'

    def __init__(self,host,port,ddelist):
        gtk.HBox.__init__(self)

        vbox = gtk.VBox()
        label = gtk.Label('%s:%d' % (host,port))
        vbox.pack_start(label)
        label = gtk.Label('None')
        vbox.pack_start(label)
        self.msgLabel = label
        
        self.pack_start(vbox, expand=gtk.FALSE, fill=gtk.FALSE)

        drawingarea = gtk.DrawingArea()
        drawingarea.set_size_request(DATA_POINTS,100)
        drawingarea.connect('expose-event', self.on_expose_event)
        self.pack_start(drawingarea, expand=gtk.TRUE, fill=gtk.TRUE)

        self.host = host
        self.port = port
        self.drawingarea = drawingarea
        self.ddelist = ddelist

        self.xdata   = [0] * DATA_POINTS
        self.ydata   = [0] * DATA_POINTS
        self.gclist = None
        self.first_msg = None
        self.last_msg  = None

    def add_data(self,seqno,xdata,ydata):
        'Data has been received.  Update the display'
        if self.first_msg is None:
            self.first_msg = seqno
            self.last_msg  = seqno
        else:
            delta = seqno - self.last_msg - 1
            if delta:
                print >>sys.stderr, "%s lost %d messages at message %d [first=%d, last=%d]" % (self.host,delta,seqno,self.first_msg,self.last_msg)
            self.last_msg = seqno

        self.msgLabel.set_text("%d" % seqno)

        self.xdata = self.xdata[len(xdata):] + list(xdata)
        self.ydata = self.ydata[len(ydata):] + list(ydata)

        self.drawingarea.queue_draw()

    def on_expose_event(self,widget,event):
        'Draw the canvas'
        if not self.gclist:
            self.gclist = [ dde.make_gc(widget) for dde in self.ddelist ]

        for dde,gc in zip(self.ddelist,self.gclist):
            dde.draw( widget, gc, self.xdata, self.ydata )

###########################################################################################

def parse_host(host,default_port=5062):
    'Parse strings of the form HOST[:PORT]'
    port = default_port

    if ':' in host:
        host, port = host.split(':')
        port = int(port)

    return host, port

def draw_series( widget, gc, data ):
    r = widget.get_allocation()
    height = r.height
    xscale = float(r.width) / (len(data) - 1)
    yscale = float(r.height) / 4096

    count = len(data)
    for i in range(0,count-1):
        widget.window.draw_line(gc,
                                int(xscale * i), height - int(yscale * data[i]),
                                int(xscale * (i+1)), height - int(yscale * data[i+1]))
    
def draw_x( widget, gc, xdata, ydata ):
    draw_series( widget, gc, xdata )

def draw_y( widget, gc, xdata, ydata ):
    draw_series( widget, gc, ydata )

def draw_mag( widget, gc, xdata, ydata ):
    zdata = [ math.sqrt((x - 2048) * (x-2048) + (y-2048)*(y-2048)) for x,y in zip(xdata,ydata)]
    draw_series( widget, gc, zdata )

def draw_rms( widget, gc, xdata, ydata ):
    'Calculate RMS value over RMS_RANGE elements'
    zdata = [ ((x - 2048) * (x-2048) + (y-2048)*(y-2048)) for x,y in zip(xdata,ydata)]
    data = [ math.sqrt(reduce(operator.add, zdata[i:i+RMS_RANGE]) / RMS_RANGE) for i in range(len(zdata) - RMS_RANGE)]

    r = widget.get_allocation()
    height = r.height
    xscale = float(r.width) / (len(zdata) - 1)
    yscale = float(r.height) / 4096

    count = len(data)
    delta = RMS_RANGE / 2
    for i in range(0,count-1):
        widget.window.draw_line(gc,
                                int(xscale * (i + delta)), height - int(yscale * data[i]),
                                int(xscale * (i+1 + delta)), height - int(yscale * data[i+1]))


class DataDisplayElement(gtk.HBox):
    '''
    A single element that is used for display.  We implement it with a
    set of widgets so we can show colors
    '''

    def __init__(self,label,turned_on=False,color='#000000',drawfunction=None):
        gtk.HBox.__init__(self)

        da = gtk.DrawingArea()
        da.set_size_request( 10, 10 )
        da.modify_bg( gtk.STATE_NORMAL, gtk.gdk.color_parse(color))
        self.pack_start(da, expand=gtk.TRUE, fill=gtk.TRUE )
        
        cb = gtk.CheckButton(label)
        if turned_on:
            cb.set_active( gtk.TRUE )
        cb.connect('toggled', self.on_toggle)
        self.pack_start(cb)

        self.checkbox     = cb
        self.color        = color
        self.drawfunction = drawfunction

    def make_gc(self,widget):
        'Allocate a GC with a color'
        gc = widget.window.new_gc()
        gc.set_line_attributes(1, gtk.gdk.LINE_SOLID,
                                    gtk.gdk.CAP_ROUND, gtk.gdk.JOIN_ROUND)
        colormap = widget.get_colormap()
        gc.set_foreground(colormap.alloc_color(self.color))
        return gc

    def on_toggle(self,widget):
        'We could force a redraw, but that seems unnecessary'
        pass

    def draw(self, widget, gc, xdata, ydata ):
        if self.checkbox.get_active():
            self.drawfunction( widget, gc, xdata, ydata )
    
###########################################################################################

class MainWindow(gtk.Window):
    'A container that holds all of the child windows'
    def __init__(self, config, hostlist):
        gtk.Window.__init__(self)

        self.set_title('Accelerometer Data Display')
        self.connect('destroy', lambda w: gtk.main_quit())

        vbox = gtk.VBox()
        hbox = gtk.HBox()

        ddelist = [ DataDisplayElement('X Data',   gtk.TRUE,  '#880000', draw_x),
                    DataDisplayElement('Y Data',   gtk.TRUE,  '#008800', draw_y),
                    DataDisplayElement('Magnitude',gtk.FALSE, '#000088', draw_mag),
                    DataDisplayElement('RMS',      gtk.FALSE, '#008888', draw_rms) ]

        for dde in ddelist:
            hbox.pack_start(dde, expand=gtk.FALSE)
            
        vbox.pack_start(hbox,expand=gtk.FALSE)
        
        for hostname in hostlist:
            host,port = parse_host(hostname)
            
            dw = DataWidget(host,port,ddelist)
            vbox.pack_start(dw)

            rtpc = SIPLiteTestClient(host,port,config['protocol'],dw)
            reactor.listenUDP( 0, rtpc )
        
        self.add(vbox)
        self.show_all()

    def on_check_toggle(self,widget,btn):
        print widget, btn


###########################################################################################

def usage():
    print """
    Usage: multiaccel.py [OPTIONS] HOST[:PORT]+

    Remote port defaults to 5062
    
    Valid options are:

         -v, --verbose        May be repeated for more detail
         -p, --protocol=NUM   Protocol to use (1=fast, 2=slow)
         -o, --out=FILE       File to store data in
         -d, --data=NUM       Number of points to display (default %d)
         -r, --rms=NUM        RMS average over (default %d)
         -h, --help           This help
         
    """ % (DATA_POINTS,RMS_RANGE)
    sys.exit(0)

if __name__ == '__main__':
    import getopt
    config = { 'verbose'     : 0,
               'out'         : None,
               'protocol'    : 1 }

    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vhp:o:d:r:',
                                        ['verbose', 'help', 'protocol=', 'out=', 'data=', 'rms='])
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
        elif k in ('-d', '--data'):
            DATA_POINTS = int(v)
        elif k in ('-r', '--rms'):
            RMS_RANGE = int(v)
        else:
            print "I didn't understand that"
            usage()

    if len(argv) < 1:
        print "must supply at least one host"
        usage()

    mw = MainWindow(config, argv)
    reactor.run()
