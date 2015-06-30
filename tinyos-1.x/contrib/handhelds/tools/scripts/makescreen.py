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



Convert PNM files into screens suitable for display on an OSRAM OLED

P1(PBM) - ascii bitmap (only two colors)
P2(PGM) - ascii greymap (only grey levels)
P3(PPM) - ascii truecolor
P4(PBM) - binary bitmap
P5(PGM) - binary greymap
P6(PPM) - binary truecolor

Screens are usually 128x80x4 pixels.  They are stored in screen natural
order, which is

    0-low   0-high 1-low 1-high ....  127-low 127-high
  128-low 128-high ....
      .
                                      5519-low 5519-high

More bits set = brighter byte

         Andrew Christian <andrew.christian@hp.com>
         June 2005
'''

import sys
from os.path import basename

bitval = " .,:;xoab=OX*%@#"          

def byte_to_ascii(x):
    return bitval[x & 0x0f] + bitval[ (x >> 4) & 0x0f]

def pack_bytes(values):
    'Pack a sequence of 1 and 0 values into bytes'
    result = []

    while len(values):
        c = values[0] + 16 * values[1]
        result.append(c)
        values = values[2:]
    return result

class Bitmap:
    def __init__(self,filename):
        self.filename   = filename
        fd = open(filename)

        self.filetype = fd.readline().split()[0]
        load_function = getattr(self,"load_" + self.filetype, None)
        if not load_function:
            print >>sys.stderr, 'Unrecognized file type', self.filetype
            sys.exit(1)
            
        load_function( fd )
        fd.close()

    def width_height(self,fd):
        line = fd.readline()
        while line.startswith('#'):
            d = line.split()
            line = fd.readline()

        total_width, self.height = map(int, line.split())
        self.width = total_width 

        self.row_stride = self.width / 2
        self.data    = []
        self.bytes   = self.height * self.row_stride
        
    def max_gray(self,fd):
        'Read the next text line for an integer value'
        line = fd.readline()
        while line.startswith('#'):
            line = fd.readline()

        return int(line)

    def load_P2(self,fd):
        'Load an ASCII portable gray map'
        self.width_height(fd)
        maxgray = self.max_gray(fd)

        graystep = (1+maxgray) / 16
        values = [int(x) / graystep for x in fd.read().split()]
        self.coverage = float(sum(values)) / (15 * len(values))
        self.data = pack_bytes(values)

    def load_P5(self,fd):
        'Load a binary graymap'
        self.width_height(fd)
        maxgray = self.max_gray(fd)

        graystep = (1+maxgray) / 16
        values = [ord(x) / graystep for x in fd.read()]
        self.coverage = float(sum(values)) / (15 * len(values))
        self.data = pack_bytes(values)
        
    def ascii_art(self):
        data = self.data
        result = ""
        for i in range(0,len(data),self.row_stride):
            result += "".join([byte_to_ascii(x) for x in data[i:i+self.row_stride]]) + "\n"
        return result

    def data_structure(self):
        bname = basename(self.filename)
        name = bname
        if '.' in name:
            name = name.split('.',1)[0]

        result = """
const uint8_t %s_screen_data[%d] = {
""" % (name, self.bytes)
        d = self.data
        while len(d):
            result += "    " + "".join(["%d," % x for x in d[:self.row_stride]]) + "\n"
            d = d[self.row_stride:]
        result += "};\n";

        return result

    def hexdump(self):
        print "/* %s X=%d Y=%d Density=%f" % (basename(self.filename)
                                    ,self.width, self.height, self.coverage)
        print self.ascii_art()
        print "*/"

        print self.data_structure()

print """
/* Autogenerated Screen file */
"""
for f in sys.argv[1:]:
    b = Bitmap(f)
    b.hexdump()
