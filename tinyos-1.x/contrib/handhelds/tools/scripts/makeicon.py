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



Convert PNM files into icons suitable for display on a Clipboard
screen.

P1(PBM) - ascii bitmap (only two colors)
P2(PGM) - ascii greymap (only grey levels)
P3(PPM) - ascii truecolor
P4(PBM) - binary bitmap
P5(PGM) - binary greymap
P6(PPM) - binary truecolor

Icons are usually 24 pixels width by 16 pixels tall.  They are stored
in a uint8_t array in the following format:

  0 1 2 3 4 5 6 7     0 1 2 3 4 5 6 7    0 1 2 3 4 5 6 7

       Byte #0            Byte #16            Byte #32
       Byte #1            Byte #17            Byte #33
          .                   .                  .
       Byte #15           Byte #31            Byte #47

Note that the bit order is LSB first.  Black pixels have the bit SET,
white pixels have the bit cleared.

However....to match the font drawing code, we actually need to order
the bytes WITHIN each icon to be arranged on rows.  For example, say
we had three icons in a file, each with row stride 3 and height 4.  The
bytes would be laid out:

      0  1  2   9 10 11  18 19 20    
      3  4  5  12 13 14  21 22 23
      6  7  8  15 16 17  24 25 26

We expect to find a comment line in the PNM file that specifies the
number of icons (and we expect each icon to have a width that is
a multiple of 8).  The comment line should look like:

   # IconCount <number>


         Andrew Christian <andrew.christian@hp.com>
         18 March 2005
'''

import sys
from os.path import basename

bitval = [ 1, 2, 4, 8, 16, 32, 64, 128 ]

def byte_to_ascii(x):
    result = ""
    for t in bitval:
        result += x & t and '#' or ' '
    return result

def reverse_byte(x):
    result = 0
    if x & 1: result += 128
    if x & 2: result += 64
    if x & 4: result += 32
    if x & 8: result += 16
    if x & 16: result += 8
    if x & 32: result += 4
    if x & 64: result += 2
    if x & 128: result += 1
    return result

def pack_bytes(values):
    'Pack a sequence of 1 and 0 values into bytes'
    result = []
    while len(values):
        c = sum([x[0] * x[1] for x in zip(values[:8],bitval)])
        result.append(c)
        values = values[8:]
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
        self.icon_count = 1

        line = fd.readline()
        while line.startswith('#'):
            d = line.split()
            if len(d) == 3 and d[1] == "IconCount":
                self.icon_count = int(d[2])
            line = fd.readline()

        total_width, self.height = map(int, line.split())
        self.width = total_width / self.icon_count

        self.row_stride = self.width / 8
        self.data    = [ [] for x in range(self.icon_count) ]  # One per icon
        self.bytes   = self.height * self.row_stride * self.icon_count
        
    def max_gray(self,fd):
        'Read the next text line for an integer value'
        line = fd.readline()
        while line.startswith('#'):
            line = fd.readline()

        return int(line)

    def fill_data(self,values):
        '''Take a list of byte values and pack them into the
           individual icons in drawing order'''

        i = 0
        while len(values):
            self.data[i] += values[:self.row_stride]
            values = values[self.row_stride:]
            i += 1
            if i >= self.icon_count: i = 0
        
    def load_P2(self,fd):
        'Load an ASCII portable gray map'
        self.width_height(fd)
        maxgray = self.max_gray(fd)

        # Read the file and convert to 1's and 0's
        values = [int(x) < maxgray / 2 and 1 or 0 for x in fd.read().split()]
        values = pack_bytes(values)
        self.fill_data(values)

    def load_P4(self,fd):
        'Load a binary bitmap'
        self.width_height(fd)
        values = [reverse_byte(ord(x)) for x in fd.read()]
        self.fill_data(values)
        
    def ascii_art(self,index):
        data = self.data[index]
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
const uint8_t %s_icon_data[%d] = {
""" % (name, self.bytes)
        for d in self.data:
            result += "    " + "".join(["%d," % x for x in d]) + "\n"
        result += "};\n";

        result += """
// struct ICON { uint8_t width, uint8_t height, uint8_t row_stride, uint8_t count, uint8_t *data };        
const struct ICON %s_icon = { %d, %d, %d, %d, &icon_%s_data };
""" % (name, self.width, self.height, self.row_stride, self.icon_count,name)
        return result

    def hexdump(self):
        print "/* %s X=%d Y=%d count=%d" % (basename(self.filename)
                                            ,self.width, self.height, self.icon_count)
        for i in range(self.icon_count):
            print self.ascii_art(i)
        print "*/"

        print self.data_structure()

print """
/* Autogenerated ICON file */
"""
for f in sys.argv[1:]:
    b = Bitmap(f)
    b.hexdump()
