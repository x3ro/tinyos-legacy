#! /usr/bin/env python
#
# $Id: download_data.py,v 1.3 2009/07/24 18:56:20 ayer1 Exp $
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
#	Author:  Jason Waterman
#			 July, 2007

import serial
import struct
import time
import sys
import glob
import re
import os.path
import string
import platform
import getopt
import shimmerUtil

def get_data_port(sector):
	"""
	Reads a sector off of the SHIMMER sd card.

	This function returns the 512 bytes read from sd card on the
	sector specified.  Sector 0 is the file header, and the data is on
	the following sectors.	If there was a problem reading from the sd
	card, the empty string is returned.
	"""

	data = ''
	marker_not_found = 1

	# Command to read sector
	ser.write('f' + struct.pack('I', sector)) 

	# Look for start marker
	markers_seen = 0
	marker_found = 0
	while not marker_found:
		char = ser.read(1)
		# check for timeout
		if char == '':
			return data 
		if char == '\xaa':
			markers_seen += 1
			if markers_seen == 4:
				marker_found = 1
		else:
			markers_seen = 0
	# Found start of sector
	data = ser.read(512)
	if len(data) != 512:
		data = ''
		return data

	read_crc = struct.unpack('H', data[-2:])[0]
	calc_crc = shimmerUtil.crc_compute(data[0:-2])
	if read_crc != calc_crc:
		data = ''
	return data



def get_data_dev(sector):
	drive.seek((2000+sector)*512)
	data = drive.read(512)
	if len(data) != 512:
		data = ''
		return data

	read_crc = struct.unpack('H', data[-2:])[0]
	calc_crc = shimmerUtil.crc_compute(data[0:-2])
	if read_crc != calc_crc:
		data = ''
	return data



def get_data(sector):
	if platform.system() == 'Windows': 
		return get_data_port(sector)
	if port[0:11] == '/dev/ttyUSB':
		return get_data_port(sector)
	return get_data_dev(sector)



# main
# Print out revision number
revision_id = "$Revision: 1.3 $"
revision = revision_id.split()[1]
print >> sys.stderr, 'SHIMMER Data Downloader v%s' % (revision)

output_filename = ''
if platform.system() == 'Windows': 
	output_filename = 'output.csv'

port = ''

opts, args = getopt.getopt(sys.argv[1:], 'o:p:')
for o, a in opts:
	if o == '-o':
		output_filename = a
	if o == '-p':
		port = a

if port == '':
	# Find the data serial port
	# this one does not work over the serial port with shimmer2 in shimmer2 dock
	# since the card is connected directly !!!
	port = shimmerUtil.find_data_port()

if port == '':
	print >> sys.stderr, 'Could not find SHIMMER data port port.  Exiting.'
	sys.exit()

speed = 115200
print >> sys.stderr, 'Using SHIMMER data port on %s' % (port)
if port[0:11] == '/dev/ttyUSB' or platform.system() == 'Windows':
	ser = serial.Serial(port, speed, timeout = 1)
	ser.flushInput()
else:
	# direct read
	drive = open(port, "rb")
	# print drive

# Uncomment one of these depending on the senstivity of the SHIMMER
# 1.5g senstivity setting
#sensitivity = 0.8 * (3.0 / 3.3)
# 2g senstivity setting
#sensitivity = 0.6 * (3.0 / 3.3)
# 4g senstivity setting
sensitivity = 0.3 * (3.0 / 3.3)
# 6g senstivity setting
#sensitivity = 0.2 * (3.0 / 3.3)


# get file header
data = get_data(0)
if len(data) != 512:
	print >> sys.stderr, 'Bad file header read.  Only read %s bytes.  Exiting' \
		  % (len(data))
	sys.exit()
offset = struct.unpack('d',data[2:10])[0]
sectors_to_read = struct.unpack('I',data[10:14])[0]

# Keeps track of the overflow of the shimmer timestamp
overflow = 0
old_timestamp = 0


if output_filename:
	try:
		outfile = open(output_filename, 'w')
		print >> sys.stderr, "Writing output to %s" % output_filename
	except IOError:
		print >> sys.stderr, "Unable to open file %s for writing.  Exiting." % output_filename
		sys.exit()
else:
	outfile = sys.stdout

print >> sys.stderr, "Downloading %i sectors\n" % sectors_to_read
print >> sys.stderr, "Percent of download completed: 00",
for sector in xrange(1,sectors_to_read):
	data = get_data(sector)
	if data == '':	# Sector was bad
		# try again once
		data = get_data(sector)
		if data == '':	# Sector was indeed bad
			print >> sys.stderr, "\nSector %i has errors." % sector
			print >> sys.stderr, "Percent of download completed: %02d" % \
				  ((sector*100)/sectors_to_read),
			continue

	# timestamp is in UTC
	shimmer_timestamp = struct.unpack('I',data[0:4])[0]
	# Check for timestamp overflow
	if old_timestamp > shimmer_timestamp:
		overflow += 2**32
	old_timestamp = shimmer_timestamp
	shimmer_time = offset + (shimmer_timestamp + overflow)/32768.0
	shimmer_excel_time = ((shimmer_time - time.altzone)/86400.0) + 25569

	print >> sys.stderr, "\b\b\b%02d" % ((sector*100)/sectors_to_read),
	# Human readable time
	#time_str = time.strftime('%m/%d/%Y %H:%M:%S',
	#						  time.localtime(shimmer_time))
	for sample in range(4,508,6):
		(x,y,z) = struct.unpack('HHH', data[sample:sample+6])

		# Convert to g's.  A reading of 1638 = 1.0v with a 2.5v
		# reference.  First we divide by 1638 to convert sample back
		# to volts.  Then subtract the DC offset of the accelerometer.
		# Then divide by the senstivity to get g's.
		x = ((x/1638.0) - 1.5) / sensitivity
		y = ((y/1638.0) - 1.5) / sensitivity
		z = ((z/1638.0) - 1.5) / sensitivity

		# gat a time format usable in SPSS
		second_fraction = '%f' % shimmer_time
		second_fraction = second_fraction.split('.')[1]
		spss_time = string.upper(time.strftime('%d-%b-%Y %H:%M:%S',
											   time.localtime(shimmer_time))
								 + '.' + second_fraction)

		print >> outfile, "%s,%r,%r,%r,%r,%r" % (spss_time,shimmer_excel_time,x,y,z,
												 shimmer_time)

		# Measured time between samples.  It should be 0.01953125 but
		# the value below matches the data better
		shimmer_time += (0.019763785861017256)
		shimmer_excel_time = ((shimmer_time - time.altzone)/86400.0) + 25569

print >> sys.stderr, "\b\b\b100"

if port[0:11] == '/dev/ttyUSB' or platform.system() == 'Windows':
	# Turn on the green led and turn off the orange
	ser.write('gh')
	time.sleep(1) # give time for the write 
	ser.close()
else:
	drive.close()

