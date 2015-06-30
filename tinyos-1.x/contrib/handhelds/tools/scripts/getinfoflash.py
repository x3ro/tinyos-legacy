#!/usr/bin/python
"""
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


Retrieve info flash from MSP430 processor

Author: Andrew Christian <andrew.christian@hp.com>
        April 2005

"""

import sys, struct
from msp430 import memory, jtag

#########################################################################

def tohex(x):
    return ":".join(["%02x" % ord(i) for i in x])

def toip(x):
    return ".".join(["%d" % ord(i) for i in x])

def tostring(x):
    i = x.find("\0")
    if i > 0:
        return x[:i]
    return x

class InfoMem:
    'Based on the tinyos-1.x/contrib/hp/tos/interface/InfoMem.h file'
    VERSION1_1 = '<8s4s16sH4sH4sh'
    
    def __init__(self,data):
        version = struct.unpack('<H',data[:2])[0]

        if version != 0x0101:
            print >>sys.stderr, "Unrecognized version %02x" % version, version, 0x0101
            return

        v = self.VERSION1_1
        count = struct.calcsize(v)

        (mac, ip, ssid, pan_id,
         registrar_ip, registrar_port, ntp_ip,
         gmt_offset_minutes ) = struct.unpack( v, data[2:2+count])

        self.version      = version
        self.mac          = tohex(mac)
        self.ip           = toip(ip)
        self.ssid         = tostring(ssid)
        self.pan_id       = "0x%04x" % pan_id
        self.registrar_ip = toip(registrar_ip)
        self.registrar_port = registrar_port
        self.ntp_ip       = toip(ntp_ip)

    def __str__(self):
        p =  "Version:   %04x\n" % self.version
        p += "Mac:       %s\n" % self.mac
        p += "IP:        %s\n" % self.ip
        p += "SSID:      '%s'\n" % self.ssid
        p += "Pan ID:    %s\n" % self.pan_id
        p += "Registrar: %s:%d\n" % (self.registrar_ip, self.registrar_port)
        p += "NTP:       %s\n" % self.ntp_ip
        return p

#########################################################################

def usage():
    print """
    Usage: getinfoflash.py [OPTIONS]

    Valid options:
                    -v, --verbose     Provide verbose information
                    -l, --lpt PORT    JTAG port
    """
    sys.exit(0)

def main():
    import getopt
    verbose = False
    lpt     = None
    
    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vl:',
                                        ['verbose','lpt='])
    except Exception, e:
        print e
        usage()

    for (k,v) in options:
        if k in ('-v', '--verbose'):
            verbose = True
        elif k in ('-l', '--lpt'):
            lpt = v
        else:
            print "I didn't understand that"
            usage()

    jtagobj = jtag.JTAG()
    jtagobj.connect(lpt)

    try:
        data = jtagobj.uploadData( 4096, 256 )
        im = InfoMem(data)
        print im
    finally:
        jtagobj.reset(1,1)
        jtagobj.close()

if __name__ == '__main__':
    try:
        main()
    except SystemExit:
        raise
    except KeyboardInterrupt:
        sys.stderr.write("User abort")
        sys.exit(1)
    except Exception, msg:
        sys.stderr.write("\nError: %s\n" % msg )
        sys.exit(1)




