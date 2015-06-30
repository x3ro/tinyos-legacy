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


Track down the use of atomic statements in MSP430 source code

Author:  Andrew Christian <andrew.christian@hp.com>
         May 2005
'''

import sys, os,re
VERBOSE=0

#########################################################################

class Function:
    '''
    A single MSP430 function with a list of the functions that it calls.
    '''

    def __init__(self,location,name):
        self.location  = int(location,16)
        self.name      = name
        self.call_list = []
        self.special   = False

    def add_call(self,location):
        loc = int(location)
        if loc not in self.call_list:
            self.call_list.append(loc)

    def reconcile(self,flist):
        'Match up line numbers to functions'
        clist2 = []
        for c in self.call_list:
            clist2.append( flist.match(c))
        self.call_list = clist2

    def calls_function(self,cmatch):
        'Checks that we call a named function'
        for c in self.call_list:
            if cmatch.search(c.name):
                return True
        return False

    def gname(self):
        return self.name.replace('$','__')

    def pname(self):
        return self.name.replace('$','\\n')

    def dump(self):
        print  "%04x: %s" % (self.location, self.name)
        for c in self.call_list:
            print "  ", c
            
    def __str__(self):
        return "%04x: %s" % (self.location, self.name)
            
#########################################################################

class ObjectFile:
    '''
    Read an object file and build a list of functions.  Each function has
    a list of all of the functions that it calls.
    '''

    m1 = re.compile(r'^([0-9a-f]+) <(.*)>:')
    m2 = re.compile(r'call\s+#([0-9]+)')

    def __init__(self,fd):
        self.flist = []
        
        while 1:
            line = fd.readline()
            if not line: break

            m = ObjectFile.m1.match(line)
            if m:
                f = Function(*m.groups())
                self.flist.append(f)
                continue

            m = ObjectFile.m2.search(line)
            if m:
                f.add_call(m.group(1))

        for f in self.flist:
            f.reconcile(self)

    def match(self,location):
        for f in self.flist:
            if f.location == location:
                return f
        return None

    def mark_by_name(self,name):
        'Mark functions with this name'
        m = re.compile(name)
        for f in self.flist:
            f.mark = m.search(f.name) and True or False
            if f.mark: f.special = True
        return [ x for x in self.flist if x.mark ]

    def mark_down(self,check_list):
        'Mark all functions below this list'
        while check_list:
            check_function = check_list.pop()
            for f in check_function.call_list:
                if not f.mark:
                    f.mark = True
                    check_list.append(f)

    def mark_up(self,check_list):
        'Mark all functions above this list'
        while check_list:
            check_function = check_list.pop()
            for f in self.flist:
                if not f.mark and check_function in f.call_list:
                    f.mark = True
                    check_list.append(f)

    def filter_marked(self):
        'Remove unmarked items from the list'
        self.flist = [ x for x in self.flist if x.mark ]
        for f in self.flist:
            f.call_list = [ x for x in f.call_list if x in self.flist ]
        
    def filter_down(self,name):
        'Mark functions with this name or children of this name'
        check_list = self.mark_by_name(name)
        self.mark_down(check_list)
        self.filter_marked()
        
    def filter_up(self,name):
        'Mark functions with this name and functions that call it'
        check_list = self.mark_by_name(name)
        self.mark_up(check_list)
        self.filter_marked()

    def filter_up_down(self,name):
        'Mark functions with this name, functions that call it, and functions it calls'
        check_list = self.mark_by_name(name)
        self.mark_up(check_list[:])
        self.mark_down(check_list[:])
        self.filter_marked()

    def dump(self):
        for f in self.flist:
            f.dump()

    def draw_graph(self,fd):
#    ratio=compress;
#    margin="0,0";
#    ranksep=0.0005;
#    nodesep=0.1;
        print >>fd, '''
digraph "foo" {
    rankdir=LR;
    ratio=compress;
    margin="0,0";
    ranksep=0.0005;
    nodesep=0.1;
    node [shape=ellipse style=filled fillcolor="#e0e0e0"];
    node [fontsize=10 height=.1 width=.1];
    edge [fontsize=9 arrowsize=.8];
    node [fontcolor=blue];
    edge [fontcolor=blue];
    
'''
        for f in self.flist:
            tag = ""
            if f.special: tag = ',fillcolor="#ffe0e0"'
            print >>fd, '   %s [label="%s"%s];' % (f.gname(),f.pname(),tag)

        for f in self.flist:
            for c in f.call_list:
                print >>fd, '    %s -> %s;' % (f.gname(), c.gname())

        print >>fd, '}'
            

            

#########################################################################

def usage():
    print """
    Usage: calltree.py [OPTIONS] FILENAME

    Valid options:

            -t, --top=NAME      Limit output to functions at or below NAME
            -b, --bottom=NAME   Limit output to functions at or above NAME
            -s, --select=NAME   Limit output to functions above or below NAME
            -g, --graph=NAME    Write a graph
            -v, --verbose       Provide verbose information
    """
    sys.exit(0)


if __name__ == '__main__':
    import getopt
    graph    = None
    toplist  = []
    botlist  = []
    sellist  = []

    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vt:b:s:g:',
                                        ['verbose','top=','bottom=','select=','graph='])
    except Exception, e:
        print e
        usage()

    for (k,v) in options:
        if k in ('-v', '--verbose'):
            VERBOSE += 1
        elif k in ('-s', '--select'):
            sellist.append(v)
        elif k in ('-t', '--top'):
            toplist.append(v)
        elif k in ('-b','--bottom'):
            botlist.append(v)
        elif k in ('-g', '--graph'):
            graph = v
        else:
            print "I didn't understand that"
            usage()

    if len(argv) != 1:
        print "must supply an object file"
        usage()

    if VERBOSE:
        print 'Running in VERBOSE=', VERBOSE

    fd = os.popen('msp430-objdump -d -j .text ' + argv[0], 'r')

    ob = ObjectFile(fd)
    for f in sellist: ob.filter_up_down(f)
    for f in toplist: ob.filter_down(f)
    for f in botlist: ob.filter_up(f)
    
    if not graph:
        ob.dump()

    if graph:
        v = graph.split('.')
        if len(v) > 1:
            (gname, gtype) = v
        else:
            gname = graph
            gtype = 'png'
            
        fd = os.popen('dot -T%s > %s.%s' % (gtype, gname, gtype),'w')
        ob.draw_graph(fd)
        fd.close()
