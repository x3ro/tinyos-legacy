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


Common tokenizing and tree stuff

February 2005
Andrew Christian
'''

#####################################################

class Token:
    def __init__(self, type, attr=None, lineno=-1):
        self.type   = type
        self.attr   = attr
        self.lineno = lineno
                
    def __cmp__(self, o):
        return cmp(self.type, o)

    def __repr__(self):
        if self.attr is not None:
            return "%s token on line %d" % (self.attr, self.lineno)
        return "%s token on line %d" % (self.type, self.lineno)

	#  __getitem__	only if you have heterogeneous ASTs
	#def __getitem__(self, i):
	#	raise IndexError


class AST:
    def __init__(self, type):
        self.type = type
        self._kids = []
        self.lineno = -1

    def __getitem__(self, i):
        return self._kids[i]

    def __len__(self):
        return len(self._kids)

    def __setslice__(self, low, high, seq):
        self._kids[low:high] = seq

    def __cmp__(self, o):
        return cmp(self.type, o)

    def __repr__(self):
        if hasattr(self,'attr') and self.attr is not None:
            return "%s token on line %d" % (self.attr, self.lineno)
        return "%s token on line %d" % (self.type, self.lineno)

#####################################################

def tokenize_by_line(scanner,filename):
    '''Parse a data file with a line-by-line scanner
       Pass the class of the scanner and the filename
       Returns a token list
    '''
    fd = open(filename)
    tlist = []

    input = fd.readline()
    lineno = 1
    while input:
        bs = scanner(lineno)
        tlist += bs.tokenize(input)
        lineno += 1
        input = fd.readline()

    fd.close()
    return tlist

def parse_tokens(parser,tlist):
    p = parser(AST)
    atree = p.parse(tlist)
    return atree

#####################################################

import re
def dump_token_list(tlist):
    foo = re.compile('\n')
    for t in tlist:
        if t.attr:
            print t.lineno, "TOKEN %s '%s'" % (t.type, foo.sub('.',t.attr))
        else:
            print t.lineno, "TOKEN", t.type

def dump_ast(atree,depth=0):
    foo = re.compile('\n')
    if hasattr(atree,'attr') and atree.attr is not None:
        a = atree.attr
        if type(a) is str: a = foo.sub('.',a)
        print " " * depth, atree.type, a
    else:
        print " " * depth, atree.type
    try:
        for k in atree:
            dump_ast(k,depth+1)
    except:
        pass
