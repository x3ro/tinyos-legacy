#!/usr/bin/python

import sys, re,math

#start = re.compile("____STARTSYM_CHECK \d+ \d+ \d+ (\d+)")
start = re.compile("__RADIO_TEST_RECV \d+ \(0x([0-9A-F]{2})01\)")

def thex(num):
	start = hex(num)
	while start[0].lower()!='x':
		start = start[1:]
	return start[1:]

total = 0L
max = long(math.pow(2,32))
hibit = long(math.pow(2,7))
while True:
	line = sys.stdin.readline()
	match = start.search(line)
	if match!=None:
		numbers = [long(x,16) for x in match.groups()]
		for x in numbers:
			inv = []
			print thex(x).rjust(3)[:-1],
			for i in range(8):
				total = total*2
				if total>=max:
					total -= max
				if x>=hibit:
					total +=1
				inv.append(thex(max-total-1).rjust(9).replace(" ","0")[:-1])
				print thex(total).rjust(9).replace(" ","0")[:-1],
				x *=2
				if x>=hibit*2:
					x -= hibit*2
			print ""
			#print "   "+" ".join(inv)
	#else:
	#	print "line",line
	
