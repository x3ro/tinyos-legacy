#! /usr/bin/env python
#
# $Id: start_recording.py,v 1.2 2009/07/24 18:56:20 ayer1 Exp $
#
# Copyright (c) 2007, Intel Corporation
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# Redistributions of source code must retain the above copyright notice, 
# this list of conditions and the following disclaimer. 
# 
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution. 
# 
# Neither the name of the Intel Corporation nor the names of its contributors
# may be used to endorse or promote products derived from this software 
# without specific prior written permission. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
# 
#   Author:  Jason Waterman
#            July, 2007

import serial
import struct
import time
import random
import sys
import shimmerUtil


# Find the data serial port
# this needs to find the real serial port
port = shimmerUtil.find_data_port(True)
if port == '':
    print 'Could not find SHIMMER data port port.  Exiting.'
    sys.exit()

speed = 115200
print 'Found SHIMMER data port on %s' % (port)
ser = serial.Serial(port, speed, timeout = 1)
ser.flushInput()

offset = 0.0
print "Syncronizing clocks..."
loop = 5

# t1 = host time at start of packet send
# t2 = shimmer time
# t3 = host time at received reply
#
# round trip delay = t3 - t1
for n in range(0,loop):
    t1 = time.time()
    ser.write('s')
    d = ser.read(4)
    t3 = time.time()
    t2 = struct.unpack('I', d)[0]
    # convert SHIMMER time into seconds
    t2 = t2/32768.0

    # Calculate delay, round trip time divided by 2
    delay = (t3-t1)/2.0
    # Calculate offset 
    current_offset = t1 - t2 - delay
    #print t1, t2, current_offset
    offset += current_offset
    time.sleep(random.random())
offset = offset/float(loop)
print "Offset is: %r" % offset

# We have the offset.  Now store it on the SHIMMER
ser.write('r')
offset_str = struct.pack('d', offset)
ser.write(offset_str)

# Now read it back to make sure the offset was received correctly
ser.write('o')
offset_str = ser.read(8)
new_offset = struct.unpack('d',offset_str)[0]

if new_offset != offset:
    print "Error writing offset to SHIMMER.  Please try again."
    ser.close()
    sys.exit(1)

# We are now ready to generate our marker block.  The marker starts
# with the 0x0000 (normally the SHIMMER timestamp goes here) and then
# the 8 byte offset offset followed by 500 bytes of random characters
# and a 2 byte checksum.

data = '\x00\x00' + offset_str
for i in range(500):
    data += chr(random.randint(0,255))
data += struct.pack('H',shimmerUtil.crc_compute(data))

# Now send this marker to SHIMMER
# We have the offset.  Now store it on the SHIMMER
ser.write('m')
ser.write(data)

ser.write('e')
new_data = ser.read(512)

if new_data != data:
    print "File marker mismatch.  Please try again."
    ser.close()
    sys.exit(1)

now = time.strftime('%m/%d/%Y %H:%M:%S',
                    time.localtime(time.time()))
print "Starting recording at %s" % now 
ser.write('a')

# All done, close up shop
time.sleep(1) # give time to do the write
ser.close()

