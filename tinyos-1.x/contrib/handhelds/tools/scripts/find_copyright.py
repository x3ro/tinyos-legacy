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


  A program to walk a directory and print out the types of
  copyright notices it finds.

  Andrew Christian <andrew.christian@hp.com>
  June 2005
'''

import os, re, sys
from spark import GenericScanner

class ScanCopyright(GenericScanner):
    '''Process a copyright notice'''
    def tokenize(self, input):
        self.rv = ''
        GenericScanner.tokenize(self, input)
        return self.rv

    def t_whitespace(self,s):
        r' (?:[\s.,*])+ '
        self.rv += r'\W*'

    def t_protect(self,s):
        r' \( | \) '
        self.rv += "\\" + s

    def t_field_date(self,s):
        r' <YEAR> '
        self.rv += r'(?P<YEAR>\d+(?:[,-]\d+)*)'

    def t_field_other(self,s):
        r' <\w+> '
        self.rv += '(?P' + s + '.*?)'

    def t_word(self,s):
        r' \w+ '
        self.rv += s
        
        
class Copyright:
    'Encapsulate a copyright notice'
    MASTERLIST = []
    
    def __init__(self,name,notice):
        scanner = ScanCopyright()
        self.name   = name
        e = scanner.tokenize(notice)
        self.parser = re.compile(e)
        self.MASTERLIST.append(self)

    def match(self,data):
        cs = self.parser.search(data)
        return cs

    def __str__(self):
        return self.name

def find_copyright(filename):
    fd = open(filename)
    data = fd.read()
    fd.close()

    for c in Copyright.MASTERLIST:
        cs = c.match(data)
        if cs: return c, cs

def process_file(name):
    c,cs = find_copyright(name)
    print name, c, cs.groupdict()
    
def process_directory(directory):
    for root,dirs,files in os.walk(directory):
        for f in files:
            if f.endswith('.nc') or f.endswith('.c') or f.endswith('.h') or f.endswith('.py'):
                name = os.path.join(root,f)
                process_file(name)

        if 'CVS' in dirs:
            dirs.remove('CVS')

###########################################################################
#
# Here follows an ordered list of copyright notices.  I've included all
# the notices I ran across while processing the contrib/hp section of the
# tinyos tree.  HP's policy is use the BSD license, except when specifying
# a Linux kernel file (where it should be GNU)
#
###########################################################################

Copyright('BSD','''Copyright (c) <YEAR>, <OWNER>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the distribution.
    * Neither the name of the <ORGANIZATION> nor the names of its
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
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.''')

Copyright('MIT','''Copyright (c) <YEAR> <OWNER>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.''')

Copyright('UC','''Copyright (c) <YEAR> <OWNER>
All rights reserved.

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose, without fee, and without written agreement is
hereby granted, provided that the above copyright notice, the following
two paragraphs and the author appear in all copies of this software.
 
IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.''')

Copyright('Intel','''Copyright (c) <YEAR> Intel Corporation
All rights reserved.

This file is distributed under the terms in the attached INTEL-LICENSE     
file. If you do not find these files, copies can be found by writing to
Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
94704.  Attention:  Intel License Inquiry.''')

Copyright('GNUShort','''Copyright <YEAR> <OWNER>

Use consistent with the GNU GPL is permitted,
provided that this copyright notice is
preserved in its entirety in all copies and derived works.

<ORGNIZATION> MAKES NO WARRANTIES, EXPRESSED OR IMPLIED,
AS TO THE USEFULNESS OR CORRECTNESS OF THIS CODE OR ITS
FITNESS FOR ANY PARTICULAR PURPOSE.''')

Copyright('GNUShort2', '''Copyright (C) <YEAR> <OWNER>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free
Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.''')

Copyright('Brief', '''Copyright (C) <YEAR> <OWNER>''')

Copyright('Not Found','')

#########################################################################

def usage():
    print """
    Usage: find_copyright.py [OPTIONS] [DIRECTORY+]

    Valid options:
                    -h, --help     This help

    If no directory is specified, we use the current directory.
    """
    sys.exit(0)


if __name__ == '__main__':
    import getopt
    dlist = ['.']

    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'h',['help'])
    except Exception, e:
        print e
        usage()

    for (k,v) in options:
        if k in ('-h', '--help'):
            usage()
        else:
            print "I didn't understand that"
            usage()

    if len(argv):
        dlist = argv

    for d in dlist:
        if os.path.isfile(d):
            process_file(d)
        else:
            process_directory(d)

    

