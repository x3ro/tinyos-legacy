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


Decompile TSP byte code

February 2005
Andrew Christian
'''

from compileTSP import g_ByteCodes
from functions import makeFunctionList
import sys

#####################################################

class PCode:
    'A single line in the decompiler'
    def __init__(self,code,index):
        self.code = code   # Numeric code
        self.index = index

        for k,v in g_ByteCodes.items():
            if v == code:
                self.name = k

    def __str__(self):
        return "%3d:    %s (%d)" % (self.index,self.name,self.code)
    
class Decompiler:
    def __init__(self,flist):
        self.flist = flist

    def decompile(self,bcode):
        pcode  = []
        jumps  = []

        print 'Decompiling'
        # Extract byte codes
        i = 0
        while (bcode[i] != 0):
            c = PCode(bcode[i],i)
            pcode.append(c)
            i += 1

            if c.name == 'JUMP_IF_FALSE' or c.name == 'JUMP_IF_TRUE' or c.name == 'JUMP':
                c.location = (bcode[i] << 8) + bcode[i+1]
                i += 2
                if c.location not in jumps:
                    jumps.append(c.location)

            if c.name == 'ASSIGN' or c.name == 'PUSH_VAR':
                c.varindex = bcode[i]
                i += 1

            if c.name == 'PUSH':
                c.location = bcode[i]
                i += 1
                
            if c.name == 'PUSH_CONST':
                c.value = (bcode[i] << 8) + bcode[i+1]
                i += 2

            if c.name == 'PUSH_STRING':
                offset     = (bcode[i] << 8) + bcode[i+1]
                c.svalue   = ""
                while bcode[offset] != 0:
                    c.svalue += chr(bcode[offset])
                    offset += 1
                i += 2

            if c.name == 'CALLFUNC':
                c.value  = bcode[i]
                c.svalue = self.flist[c.value].name
                i += 1

        pcode.append(PCode(0,i))

        for p in pcode:
            line = "%3d: " % p.index
            if p.index in jumps:
                line += ">>> "
            else:
                line += "    "
            line += p.name

            if hasattr(p,'location'):
                line += " %d" % p.location

            if hasattr(p,'varindex'):
                line += " v%d" % p.varindex

            if hasattr(p,'value'):
                line += " #%d" % p.value

            if hasattr(p,'svalue'):
                line += " '%s'" % p.svalue

            print line

################################################################

if __name__=='__main__':
    import getopt

    def usage():
        print """
        Usage:  decompileTSP.py [OPTS] FILENAME

        Valid options:
             -v, --verbose
             -f, --functions FUNCTION_FILE      A file with defined external functions
        """
        sys.exit(1)
    
    try:
        (options,argv) = getopt.getopt(sys.argv[1:], 'vhf:', ['verbose', 'help', 'functions='])
    except Exception, e:
        print e
        usage()

    verbose    = 0
    ffile      = ""
    
    for (k,v) in options:
        if k in ('-v', '--verbose'):
            verbose += 1
        elif k in ('-f', '--functions'):
            ffile = v
        elif k in ('-h', '--help'):
            usage()
        else:
            usage()

    if len(argv) < 1:
        usage()

    if ffile:
        flist = makeFunctionList(ffile,verbose)
    else:
        flist = None

    d = Decompiler(flist)


