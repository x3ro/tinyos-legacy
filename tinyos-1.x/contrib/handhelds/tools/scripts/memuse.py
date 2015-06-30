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


   Memory Usage:  Calculate memory usage for TinyOS modules

   Author: Andrew Christian <andrew.christian@hp.com>
           15 March 2005
'''

import sys, os

#########################################################################

class Symbol:
    def __init__(self,line):
        v = line.split()
        self.value  = int(v[0],16); 
        self.length = 0
        if len(v) == 4:
            self.length = int(v[1],16)
            v = v[1:]
        self.type = v[1]
        self.name = v[2]

    def __str__(self):
        return "%04x %04x %s %s" % (self.value, self.length, self.type, self.name)

def mycmp_sym(a,b):
    return cmp(b.length,a.length)

#########################################################################

def fsect(name,start,end):
    print "%14s  %04x-%04x (%d bytes)" % (name, start, end, end - start)

class ObjectFile:
    def __init__(self,fd):
        self.sections = { 'T' : [], 'B' : [], 'D' : [] }
        
        while 1:
            line = fd.readline()
            if not line: break

            sym = Symbol(line)

            if sym.name == '__data_start':
                self.data_start = sym.value
            if sym.name == '__bss_start':
                self.bss_start = sym.value
            elif sym.name == '__bss_end':
                section = None
                self.stack_start = sym.value
            elif sym.name == '__stack':
                self.stack_end = sym.value
            elif sym.name == '_reset_vector__':
                self.text_start = sym.value
            elif sym.name == '_etext':
                self.free_flash_start = sym.value
            elif sym.name == 'InterruptVectors':
                self.free_flash_end = sym.value

            if sym.length > 0:
                self.sections[sym.type.upper()].append(sym)

        self.above_stack  = self.text_start - self.stack_end
        self.stack_length = self.stack_end - self.stack_start
        self.free_flash   = self.free_flash_end - self.free_flash_start
        
    def summary(self):
        fsect('Data',        self.data_start, self.bss_start)
        fsect('BSS',         self.bss_start, self.stack_start)
        fsect('Stack',       self.stack_start, self.stack_end)
        fsect('Above stack', self.stack_end, self.text_start)
        fsect('Text (code)', self.text_start, self.free_flash_start)
        dinit_end = self.free_flash_start + self.bss_start - self.data_start
        fsect('Data init',   self.free_flash_start, dinit_end)
        fsect('Free Text',   dinit_end, self.free_flash_end)

    def dump(self):
        for k,v in self.sections.items():
            print {'T': 'TEXT', 'B': 'BSS', 'D':'DATA'}[k]
            for sym in v:
                print sym

#########################################################################

class Section:
    'A collection of used memory in a single type of section (code, data...)'
    def __init__(self,name):
        self.symbols = []
        self.size    = 0
        self.name    = name

    def add(self,sym):
        self.symbols.append(sym)
        self.size += sym.length

    def dump(self):
        dlist = self.symbols[:]
        dlist.sort(mycmp_sym)

        title = self.name
        for d in dlist:
            print '%10s %5d  %s' % (title,d.length, d.name.replace('$','.'))
            title = ''
            
#########################################################################

class CodeModule:
    'Functions and data associated with a known module (e.g. UIP_M)'
    def __init__(self,name):
        self.name     = name
        self.text_section = Section('TEXT')
        self.data_section = Section('DATA')

        self.sections = {'T': self.text_section,
                         'B': self.data_section,
                         'D': self.data_section }

    def add(self,sym):
        self.sections[sym.type.upper()].add(sym)
        
    def dump(self):
        self.data_section.dump()
        self.text_section.dump()

def mycmp_dsize(a,b):
    return cmp(b.data_section.size,a.data_section.size)

def mycmp_csize(a,b):
    return cmp(b.text_section.size,a.text_section.size)
        
#########################################################################

class CodeLibrary:
    'An entire program, broken down into CodeModules'
    def __init__(self,objfile):
        self.cmods = { }

        for v in objfile.sections.values():
            for c in v:
                section = 'other'
                if '$' in c.name:
                    section, c.name = c.name.split('$',1)
                if not self.cmods.has_key(section):
                    self.cmods[section] = CodeModule(section)
                self.cmods[section].add(c)

    def summary(self,datasort=False):
        'Print out just a sorted list of code modules'
        cmlist = self.cmods.values()
        cmlist.sort(datasort and mycmp_dsize or mycmp_csize)
        max_len = 0
        for v in cmlist:
            if len(v.name) > max_len: max_len = len(v.name)
        fformat = "%-" + str(max_len) + "s\t%5d\t%5d"

        print ("%-" + str(max_len) + "s\t%5s\t%5s") % ('Module', 'Data', 'Text')
        for v in cmlist:
            print fformat % (v.name, v.data_section.size, v.text_section.size)
        
    def dump(self,datasort=False):
        cmlist = self.cmods.values()
        cmlist.sort(datasort and mycmp_dsize or mycmp_csize)
        max_len = 0
        for v in cmlist:
            if len(v.name) > max_len: max_len = len(v.name)
        fformat = "%-" + str(max_len) + "s\tDATA=%d bytes  TEXT=%d bytes"

        for v in cmlist:
            print
            print fformat % (v.name, v.data_section.size, v.text_section.size)
            print
            v.dump()


#########################################################################

def usage():
    print """
    Usage: memuse.py [OPTIONS] FILENAME

    Valid options:
                    -v, --verbose     Provide verbose information
                    -d, --data        Sort by data use (instead of text)
    """
    sys.exit(0)


if __name__ == '__main__':
    import getopt
    verbose = False
    datasort = False

    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vd',
                                        ['verbose', 'data'])
    except Exception, e:
        print e
        usage()

    for (k,v) in options:
        if k in ('-v', '--verbose'):
            verbose = True
        elif k in ('-d', '--data'):
            datasort = True
        else:
            print "I didn't understand that"
            usage()

    if len(argv) != 1:
        print "must supply an object file"
        usage()

    fd = os.popen('msp430-nm -nS ' + argv[0], 'r')

    ob = ObjectFile(fd)
    cl = CodeLibrary(ob)

    if verbose:
        cl.dump(datasort)
    else:
        cl.summary(datasort)

    print "\nSummary:"
    ob.summary()

#    print "Stack size:", ob.stack_length
#    ob.dump()

    
