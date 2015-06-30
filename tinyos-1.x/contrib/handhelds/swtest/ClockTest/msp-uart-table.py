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


   MSP Uart calculations in table form

   Andrew Christian <andrew.christian@hp.com>
   April 2005
'''

import sys

VERBOSE = 0

def mod_bit( bit, byte ):
    byte &= 0xff
    byte += byte << 8
    if (1<<bit) & byte:
        return 1
    return 0

def calculate_error( baudrate, clockrate, divisor, mbits ):
    'Calculate the worst-case error for a particular divisor and mbits'
    effective = 0.0
    desired   = 0.0
    max_error = 0.0
    delta_t   = 1.0 / baudrate

    for bit in range(10):   # Start bit + 8 bits + stop bit
        effective += 1.0 / (clockrate / (float(divisor) + mod_bit(bit,mbits)))
        desired   += delta_t
        error = abs( effective - desired )
        if error > max_error:
            max_error = error

    if VERBOSE > 1:
        print >>sys.stderr, "  Error %d, divisor %d, mbits=%x max_error=%f" % ( baudrate,
                                                                                divisor,
                                                                                mbits, max_error)
    return max_error

def find_best_mbits( baudrate, clockrate, divisor ):
    'Given a divisor, find the best possible modulus bits'
    best_error = calculate_error( baudrate, clockrate, divisor, 0 )
    best_mbits = 0 
    
    for mbits in range(1,256):
        e = calculate_error( baudrate, clockrate, divisor, mbits )
        if e < best_error:
            best_error = e
            best_mbits = mbits

    if VERBOSE:
        print >>sys.stderr, "Checking %d, divisor %x   best values mbits=%x error=%f" % (baudrate,
                                                                                         divisor,
                                                                                         best_mbits,
                                                                                         best_error)
    return best_error, best_mbits
    

def find_best_divisor( baudrate, clockrate ):
    'Calculate baudrate values'
    divisor = clockrate / baudrate
    e, mbits   = find_best_mbits( baudrate, clockrate, divisor )
    e2, mbits2 = find_best_mbits( baudrate, clockrate, divisor + 1 )

    if e < e2: return divisor, mbits
    return divisor + 1, mbits2


def usage():
    print >>sys.stderr, """
    Usage: msp-uart-table.py [OPTIONS] CLOCKRATE

    Valid options are:

         -v, --verbose        May be repeated for more detail
         -h, --help           This help
         -b, --baud=LIST      List of baudrates (comma-separated)          

    Clock rate can be a number (in Hz) or can have 'K' or 'M' appended
         
    """ 
    sys.exit(0)


if __name__=='__main__':
    import getopt

    rates = ( 1200, 1800, 2400, 4800, 9600, 19200, 38400, 57600, 76800, 115200, 230400, 262144 )
    try:
        (options, argv) = getopt.getopt(sys.argv[1:], 'vhb:', ['verbose', 'help','baud='])
    except Exception, e:
        print >>sys.stderr, e
        usage(config)

    for (k,v) in options:
        if k in ('-v', '--verbose'):
            VERBOSE += 1
        elif k in ('-h', '--help'):
            usage()
        elif k in ('-b', '--baud'):
            rates = [ int(x) for x in v.split(',')]
        else:
            usage()

    if len(argv) != 1:
        print >>sys.stderr, "Must specify a clock frequency"
        usage()

    cf = argv[0]
    if cf[-1] in ('k', 'K'):
        clockrate = int(cf[:-1]) * 1024
    elif cf[-1] in ('m', 'M'):
        clockrate = int(cf[:-1]) * 1024 * 1024
    else:
        clockrate = int(cf)

    print "// Clockrate = %d" % clockrate
    for br in rates:
        divisor, mbits = find_best_divisor( br, clockrate )
        print "UBR_SMCLK_%d=0x%04x,   UMCTL_SMCLK_%d=0x%02x," % ( br, divisor, br, mbits )
        
