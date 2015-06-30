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

   IMAP Lite Client

   This client presents an IMAPLite interface and contains a message
   store.  

   Author:  Andrew Christian <andrew.christian@hp.com>
            16 March 2005
'''

from twisted.internet import gtk2reactor
gtk2reactor.install()

from twisted.internet import reactor, defer
from twisted.internet.protocol import Factory, ClientFactory
from twisted.protocols.basic import LineReceiver

import gobject, gtk, sys, pango

import sys, time

####################################################################################

class MsgStore(gtk.ListStore):
    '''
    Store MSG, Timestamp, UID
    '''
    def __init__(self):
        gtk.ListStore.__init__( self,gobject.TYPE_STRING, gobject.TYPE_INT, gobject.TYPE_INT )

    def add_message(self,id,date,msg):
        iter = self.append()
        self.set(iter, 0, msg, 1, int(date), 2, int(id))


####################################################################################

class IMAPClient(LineReceiver):
    def __init__(self,mailbox):
        self.msg_add = []
        self.msg_del = []
        self.mailbox = mailbox
        
    def lineReceived(self,line):
        if self.f:
            self.f(line)

    def connectionMade(self):
        self.start_cycle()

    def start_cycle(self):
        self.f = self.handle_select
        self.transport.write('SELECT %s\r\n' % self.mailbox)
        
    def handle_fetch(self,line):
        print 'Fetch', self.model_index, self.msg_id, line
        if line.startswith('OK'):
            ok, id, date, msg = line.split(None,3)
            id = int(id)
            date = int(date)

            if self.model_index >= len(self.model):
                self.model.add_message(id,date,msg)
                self.model_index = len(self.model)
                self.msg_id = id + 1
            else:
                model_id = self.model[ self.model_index ][2]
                if id > model_id:
                    print 'Deleting message at index', self.model_index
                    del self.model[self.model_index]
                    self.model_index = 0
                    self.msg_id      = 0   # Start over
                elif id < model_id:
                    print 'Adding message', id, model_id, date, msg
                    self.model.add_message(id,date,msg)
                    self.model_index = 0
                    self.msg_id      = 0   # Start over
                else:
                    self.model_index += 1
                    self.msg_id = id + 1

            self.transport.write('FETCH %d\r\n' % self.msg_id)
        else:
            self.f = None
            reactor.callLater(5.0, self.start_cycle)

    def handle_select(self,line):
        #print line
        if self.msg_add:
            p = self.msg_add.pop()
            self.transport.write('APPEND %d %s\r\n' % p)
            return

        if self.msg_del:
            p = self.msg_del.pop()
            self.transport.write('STORE %d FLAGS DELETE\r\n' % p)
            return
            
        self.f           = self.handle_fetch
        self.msg_id      = 0
        self.model_index = 0
        self.transport.write('FETCH %d\r\n' % self.msg_id)

    def send_message(self,msg):
        #print 'Appending', msg
        self.msg_add.append((int(time.time()), msg))

    def delete_message(self,msg_id):
        #print 'Deleting', msg_id
        self.msg_del.append(msg_id)
        
####################################################################################

class IMAPClientFactory(ClientFactory):
    def __init__(self,model,mw,mailbox):
        self.model = model
        self.mw = mw
        self.mailbox = mailbox

    def buildProtocol(self,addr):
        ic = IMAPClient(self.mailbox)
        ic.model = model
        mw.client = ic
        return ic

####################################################################################
    
def format_time_column(column, cell, model, iter, user_data):
    t = model.get_value(iter,user_data)
    if t <= 0:
        cell.set_property('text','Unknown')
    else:
        cell.set_property('text', time.strftime("%d %b %H:%M",time.localtime(t)))

class MessageList(gtk.TreeView):
    def __init__(self,model):
        gtk.TreeView.__init__(self)
        self.set_model(model)
        self.append_column( gtk.TreeViewColumn('Message', gtk.CellRendererText(), text=0))
        self.insert_column_with_data_func(-1, 'Time', gtk.CellRendererText(),
                                          format_time_column, 1 )
#        self.append_column( gtk.TreeViewColumn('Date', gtk.CellRendererText(), text=1))
        self.append_column( gtk.TreeViewColumn('UniqueID', gtk.CellRendererText(), text=2))
        self.connect('key-press-event', self.handle_keypress)

    def handle_keypress(self, widget, event):
        'Delete a row if the user presses the DELETE key'
        print 'Keypress'
        if gtk.gdk.keyval_from_name('Delete') == event.keyval:
            model, iter = widget.get_selection().get_selected()
            if iter:
                id = model[model.get_path(iter)[0]][2]
                self.mw.delete_message(id )
            return gtk.TRUE
        return gtk.FALSE

        

####################################################################################
        
class MainWindow(gtk.Window):
    def __init__(self,model):
        gtk.Window.__init__(self)
        self.set_title('IMAPLite Client')
        self.connect('destroy', lambda w:gtk.main_quit())

        vbox = gtk.VBox()
        scroll = gtk.ScrolledWindow()
        scroll.set_policy( gtk.POLICY_NEVER, gtk.POLICY_AUTOMATIC )

        mlist = MessageList(model)
        mlist.mw = self
        scroll.add(mlist)
        vbox.pack_start(scroll, expand=gtk.TRUE, fill=gtk.TRUE)

        hbox = gtk.HBox()
        hbox.pack_start( gtk.Label('New message:'), expand=gtk.FALSE, fill=gtk.FALSE)
        entry = gtk.Entry()
        hbox.pack_start( entry, expand=gtk.TRUE, fill=gtk.TRUE )

        btn = gtk.Button('send')
        btn.set_property('sensitive', gtk.FALSE)
        hbox.pack_end(btn,expand=gtk.FALSE,fill=gtk.FALSE)

        btn.connect('clicked', self.send_message, entry)
        entry.connect('activate', self.activate_entry)
        entry.connect('changed', self.entry_changed, btn )
        
        vbox.pack_start(hbox, expand=gtk.FALSE, fill=gtk.FALSE)

        self.add(vbox)
        self.show_all()

    def delete_message(self, id):
        self.client.delete_message(id)

    def send_message(self, button, entry):
        self.activate_entry(entry)

    def activate_entry(self, entry):
        t = entry.get_text()
        entry.set_text('')
        self.client.send_message( t )

    def entry_changed(self, entry, button):
        t = entry.get_text()
        if len(t) > 0:
            button.set_property('sensitive', gtk.TRUE)
        else:
            button.set_property('sensitive', gtk.FALSE)

if len(sys.argv) > 1:
    mailbox = sys.argv[1]
else:
    mailbox = "mailbox1"

model = MsgStore()
mw = MainWindow(model)
reactor.connectTCP('localhost',3143,IMAPClientFactory(model,mw,mailbox))
reactor.run()
        
        
