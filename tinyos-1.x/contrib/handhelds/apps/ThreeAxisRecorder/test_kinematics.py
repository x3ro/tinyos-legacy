# Use this to test sending commands to SHIMMER interactively at the
# python command prompt:
#
# from test_kinematics import *
# 
# will set it up for you. 

import serial
import struct

ser = serial.Serial('/dev/ttyUSB2', 115200)
ser.flushInput()
