#!/usr/bin/env python2.1
"""
Convert Intel HEX files to C code to embed

USAGE: ihex2c.py input.a43 outname [const]

This generates a file named "outname.ci" which contains an array
named "unsigned short funclet_outname[]". That array contains the
machine code from the input file.

The optional argument "const" changes the array type to "const
unsigned short" if present.

Actualy it can read TI-Text too. Specifying a "-" as filename makes
it reading from the standard input, but then only Intel-Hex format
is supported.

(C) 2002 Chris Liechti <cliechti@gmx.net>
This is distributed under a Python style license.

Requires Python 2+
"""

import sys

VERSION = "1.0"

#for the use with memread
def hexdump( (adr, memstr) ):
    """Print a hex dump of data collected with memread
    arg1: tuple with adress, memory
    return None"""
    count = 0
    ascii = ''
    for value in map(ord, memstr):
        if not count: print "%04x: " % adr,
        print "%02x" % value,
        ascii = ascii + ((32 < value < 127) and chr(value) or '.')
        count = count + 1
        adr = adr + 1
        if count == 16:
            count = 0
            print "  ", ascii
            ascii = ''
    if count < 16: print "   "*(16-count), " ", ascii

class Segment:
    "store a string with memory contents along with its startaddress"
    def __init__(self, startaddress = 0, data=None):
        if data is None:
            self.data = ''
        else:
            self.data = data
        self.startaddress = startaddress

    def __getitem__(self, index):
        return self.data[index]

    def __len__(self):
        return len(self.data)

    def __repr__(self):
        return "Segment(startaddress = 0x%04x, data=%r)" % (self.startaddress, self.data)

class Memory:
    "represent memory contents. with functions to load files"
    def __init__(self, filename=None):
        self.segments = []
        if filename:
            self.filename = filename
            self.loadFile(filename)

    def append(self, seg):
        self.segments.append(seg)

    def __getitem__(self, index):
        return self.segments[index]

    def __len__(self):
        return len(self.segments)

    def loadIHex(self, file):
        "load data from a (opened) file in Intel-HEX format"
        segmentdata = []
        currentAddr = 0
        startAddr   = 0
        lines = file.readlines()
        for l in lines:
            if l[0] != ':': raise Exception("File Format Error\n")
            l = l.strip()       #fix CR-LF issues...
            length  = int(l[1:3],16)
            address = int(l[3:7],16)
            type    = int(l[7:9],16)
            check   = int(l[-2:],16)
            if type == 0x00:
                if currentAddr != address:
                    if segmentdata:
                        self.segments.append( Segment(startAddr, ''.join(segmentdata)) )
                    startAddr = currentAddr = address
                    segmentdata = []
                for i in range(length):
                    segmentdata.append( chr(int(l[9+2*i:11+2*i],16)) )
                currentAddr = length + currentAddr
            elif type == 0x01:
                pass
            else:
                sys.stderr.write("Ignored unknown field (type 0x%02x) in ihex file.\n" % type)
        if segmentdata:
            self.segments.append( Segment(startAddr, ''.join(segmentdata)) )

    def loadTIText(self, file):
        "load data from a (opened) file in TI-Text format"
        next        = 1
        currentAddr = 0
        startAddr   = 0
        segmentdata = []
        #Convert data for MSP430, TXT-File is parsed line by line
        while next >= 1:
            #Read one line
            l = file.readline()
            if not l: break #EOF
            l = l.strip()
            if l[0] == 'q': break
            elif l[0] == '@':        #if @ => new address => send frame and set new addr.
                #create a new segment
                if segmentdata:
                    self.segments.append( Segment(startAddr, ''.join(segmentdata)) )
                startAddr = currentAddr = int(l[1:],16)
                segmentdata = []
            else:
                for i in string.split(l):
                    segmentdata.append(chr(int(i,16)))
        if segmentdata:
            self.segments.append( Segment(startAddr, ''.join(segmentdata)) )

    def loadFile(self, filename):
        "fill memory with the contents of a file. file type is determined from extension"
        if filename[-4:].lower() == '.txt':
            self.loadTIText(open(filename, "rb"))
        else:
            self.loadIHex(open(filename, "rb"))

    def getMemrange(self, fromadr, toadr):
        "get a range of bytes from the memory. unavailable values are filled with 0xff."
        res = ''
        toadr = toadr + 1   #python indxes are excluding end, so include it
        while fromadr < toadr:
            for seg in self.segments:
                segend = seg.startaddress + len(seg.data)
                if seg.startaddress <= fromadr and fromadr < segend:
                    if toadr > segend:   #not all data in segment
                        catchlength = segend-fromadr
                    else:
                        catchlength = toadr-fromadr
                    res = res + seg.data[fromadr-seg.startaddress : fromadr-seg.startaddress+catchlength]
                    fromadr = fromadr + catchlength    #adjust start
                    if len(res) >= toadr-fromadr:
                        break   #return res
            else:   #undefined memory is filled with 0xff
                    res = res + chr(255)
                    fromadr = fromadr + 1 #adjust start
        return res

def main():

    if len(sys.argv) < 3:
        sys.stderr.write(__doc__)
        sys.exit(2)
    filename = sys.argv[1]
    outname  = sys.argv[2]

    opts = sys.argv[3:]

    mem = Memory()                                  #prepare downloaded data
    if filename == '-':                             #for stdin:
        mem.loadIHex(sys.stdin)                     #assume intel hex
    elif filename:
        mem.loadFile(filename)                      #autodetect otherwise

    if len(mem) != 1:
        sys.stderr.write("a file with exactly one segment is required!\n")
        sys.exit(1)
        
    output = open(outname+".ci", "w")
    bytes = 0
    for seg in mem:
        hexdump((seg.startaddress, seg.data))
        bytes = bytes + len(seg.data)
        if 'const' in opts:
            output.write("const ")
        output.write("unsigned short funclet_%s[] = {\n\t" % outname)
        output.write(',\n\t'.join([("0x%04x" % (ord(seg.data[i]) + (ord(seg.data[i+1])<<8)))
                        for i in range(0,len(seg.data),2)]))
        output.write("\n};\n")
    sys.stderr.write("%i bytes.\n" % bytes)
    output.close()

if __name__ == '__main__':
    if sys.hexversion < 0x2010000:
        sys.stderr.write("Python 2.1 or newer required\n")
        sys.exit(1)
    main()
