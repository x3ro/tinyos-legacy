#!/usr/bin/python

# RadioTest genradio program
# Generates radio testing programs
#
# Copyright (c) 2004 TU Delft/TNO
# All rights reserved.
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without written agreement is
# hereby granted, provided that the above copyright notice and the following
# two paragraphs appear in all copies of this software.
#
# IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
# PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
# ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
# COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER 
# IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
# OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
# MODIFICATIONS.

import getopt,sys
from Enum import Enum

class Radio(Enum):
	raw = 1
	radiocontrol = 2
	tmac = 3
	mintroute = 4

class Data(Enum):
	tx = 1
	rx = 2
	both = 3

def usage():
	print "Usage: %s [-r,--radio %s] [-d,--data %s] (-s,--sleepy) (-u,--unicast) (-p,--power)" % (sys.argv[0],"|".join(Radio.__members__),"|".join(Data.__members__))
	sys.exit(1)

try:
	opts,args = getopt.getopt(sys.argv[1:],'r:d:sup',["radio","data","sleepy","unicast","power"])
except getopt.GetoptError:
	usage()


radio = None
data = None
sleepy = False
unicast = False
powerManagement = False

if len(args)>0:
	print "Error: junk in command line '%s'"%args
	usage()

for o,a in opts:
	if o in ("-r","--radio"):
		try:
			radio = Radio.valid(a)
		except:
			print "Invalid radio model '%s'"%a

	elif o in ("-d","--data"):
		try:
			data = Data.valid(a)
		except:
			print "Invalid data mode '%s'"%a
	elif o in ("-s","--sleepy"):
		sleepy = True
	elif o in ("-u","--unicast"):
		unicast = True
	elif o in ("-p","--power"):
		powerManagement = True
	else:
		print "Error: invalid option '%s'"%o
		usage()

if radio == None:
	print "Must specify a radio model!"
	usage()

if data == None:
	print "Must specify a data mode!"
	usage()

RadioTest = file("RadioTest.nc",'w')
if radio in [Radio.tmac,Radio.mintroute]:
	RadioTestMSG = file("RadioTestMSG.h",'w')
	print >> RadioTestMSG,"""
enum {
  AM_CHIRPMSG = 6
};"""
	RadioTestMSG.close()
	print >> RadioTest,"includes RadioTestMSG;"

RadioTest.write("configuration RadioTest {}\n")
RadioTest.write("implementation {\n")
print >> RadioTest,"""\t#ifdef NO_LEDS
	components NoLeds as LedsC;
	#else
	components LedsC;
	#endif"""
if sleepy:
	if radio in [Radio.tmac,Radio.mintroute]:
		print >>RadioTest,"\tcomponents TimerC;"
	else:
		print >>RadioTest,"\tcomponents ClockMSM;"
if powerManagement:
	print >>RadioTest, "\tcomponents HPLPowerManagementM as Power;"
if radio == Radio.raw:
	print >> RadioTest,"""
	components Main, RadioTestM, RadioSPIC;
	RadioTestM.RadioSPI -> RadioSPIC;
	RadioTestM.Debug -> RadioSPIC;"""
elif radio == Radio.radiocontrol:
	print >> RadioTest,"""
	components Main, RadioTestM, RadioControl;
	RadioTestM.Radio -> RadioControl;
	RadioTestM.Debug -> RadioControl;
	RadioTestM.RadioState -> RadioControl;
	RadioTestM.PhyComm -> RadioControl;"""
elif radio == Radio.tmac:
	print >> RadioTest,"""
	components Main, RadioTestM, GenericComm as Comm, UARTDebugC;
	Main.StdControl -> Comm;
	RadioTestM.CommControl -> Comm;
	RadioTestM.SendMsg -> Comm.SendMsg[AM_CHIRPMSG];
	RadioTestM.ReceiveMsg -> Comm.ReceiveMsg[AM_CHIRPMSG];
	RadioTestM.Debug -> UARTDebugC;"""
elif radio == Radio.mintroute:
	print >> RadioTest,"""
	components Main, RadioTestM, UARTDebugC;
	components WMEWMAMultiHopRouter as Router;
	components GenericCommPromiscuous as Comm;
	Main.StdControl -> Router;
	RadioTestM.Send -> Router.Send[AM_CHIRPMSG];
	RadioTestM.Receive -> Router.Intercept[AM_CHIRPMSG];
	Router.ReceiveMsg[AM_CHIRPMSG] -> Comm.ReceiveMsg[AM_CHIRPMSG];
	RadioTestM.Debug -> UARTDebugC;

	RadioTestM.RouteControl -> Router.RouteControl;"""
else:
	raise Exception, "Can't handle "+str(radio)
if sleepy and radio in [Radio.mintroute,Radio.tmac]:
	print >> RadioTest,"""
    Main.StdControl -> TimerC;
    RadioTestM.Timer -> TimerC.Timer[unique("Timer")];"""
if sleepy and radio not in [Radio.tmac,Radio.mintroute]:
	print >>RadioTest,"\tRadioTestM.Clock -> ClockMSM;"
if powerManagement:
	print >>RadioTest, "\tRadioTestM.PowerEnable -> Power.Enable;"
print >>RadioTest,"""
	Main.StdControl -> RadioTestM;
	RadioTestM.Leds -> LedsC;
}
"""

RadioTest.close()

RadioTestM = file("RadioTestM.nc",'w')

print >>RadioTestM, """
module RadioTestM
{
	provides interface StdControl;
	uses 
	{"""
if radio not in [Radio.tmac,Radio.mintroute]:
	print >>RadioTestM,"\t\tinterface StdControl as Radio;"
if radio == Radio.raw:
	print >>RadioTestM,"""
		interface RadioSPI;"""
elif radio == Radio.radiocontrol:
	print >>RadioTestM,"""
		interface PhyComm;
		interface RadioState;"""
elif radio == Radio.tmac:
	print >>RadioTestM,"""
		interface StdControl as CommControl;
		interface SendMsg;
		interface ReceiveMsg;"""
elif radio == Radio.mintroute:
	print >>RadioTestM,"""		interface Send;
		interface Intercept as Receive;
		interface RouteControl;"""
else:
	raise Exception, "Can't handle "+str(radio)
if sleepy:
	if radio not in [Radio.tmac,Radio.mintroute]:
		print >>RadioTestM,"\t\tinterface ClockMS as Clock;"
	else:
		print >>RadioTestM,"\t\tinterface Timer;"
if powerManagement:
	print >>RadioTestM,"\t\tcommand result_t PowerEnable();"

print >>RadioTestM,"""
		interface Leds;
		interface UARTDebug as Debug;
	}
}

implementation
{
#include "TMACEvents.h"

	void sendRadio();"""
#testbytes = "\\x0f\\x3c\\x55\\x99\\xAB\\xCD"
#testbytes = "\\xcf\\xcf\\x0c\\xcc\\x0a\\x0a\\x02\\x00\\x01\\x01\\x5f\\x02\\x35\\x96" # SYNC packet w/ start symbol
testbytes = "\\x0a\\x0a\\x02\\x00\\x01\\x01\\x5f\\x02\\x35\\x96" # SYNC packet
#testbytes = "\\xcf\\xcf\\x0c\\xcc\\x0a\\x07\\x01\\x00\\x00\\x00\\x22\\x00\\x1c\\xad\\x00"# RTS packet w/ start symbol
print >>RadioTestM,"\tchar *testbytes = \"%s\";"%testbytes
print >>RadioTestM,"\tuint8_t length = %d;"%(len(testbytes)/4)

print >>RadioTestM,"""
	int8_t counter=0;
	uint32_t packets=0;
	int16_t sleeptime=0;
	enum {Red=1,Green=2,Yellow=4};"""
if radio in [Radio.tmac,Radio.mintroute]:
	print >>RadioTestM,"""
	TOS_Msg msg;				/* Message to be sent out */"""
print >>RadioTestM,"""
	command result_t StdControl.init()
	{
		counter = 0;
		packets = 0;"""
if powerManagement:
	print >>RadioTestM,"\t\tcall PowerEnable();"
	print >>RadioTestM,"\t\tcbi(EIMSK, 1);"
if radio not in [Radio.tmac,Radio.mintroute]:
	print >>RadioTestM,"\t\tcall Debug.init(7);"
	print >>RadioTestM,"\t\tcall Debug.txState(RADIO_TEST_INIT);"
if radio == Radio.raw:
	print >>RadioTestM, "		call RadioSPI.init();"
elif radio == Radio.radiocontrol:
	print >>RadioTestM, "		call Radio.init();"
	if data == Data.tx:
		print >>RadioTestM,"		sleeptime=600;"
elif radio == Radio.tmac:
	print >>RadioTestM, "		call CommControl.init();"
elif radio == Radio.mintroute:
	print >>RadioTestM, "		msg.addr = 0;"
else:
	raise Exception,"Can't handle %s"%str(radio)
	
print >>RadioTestM,"""
		call Leds.init();
		//call Debug.txStatus(_LED_SET,Red);
		return call Leds.redOn();
	}

	command result_t StdControl.start()
	{
		//call RadioSPI.idle();
		//call Debug.txStatus(_LED_UNSET,Yellow);
		call Leds.yellowOff();
"""
if sleepy:
	if radio not in [Radio.tmac,Radio.mintroute]:
		print >>RadioTestM, "		call Clock.start();"
	else:
		if data==Data.both:
			print >>RadioTestM, """
		if (TOS_LOCAL_ADDRESS == 0) // sender
			call Timer.start(TIMER_REPEAT, 1000);"""
		else:
			if radio == Radio.mintroute:
				print >>RadioTestM, "		call Timer.start(TIMER_REPEAT, 8192);"
			else:
				print >>RadioTestM, "		call Timer.start(TIMER_REPEAT, 1000);"
if radio == Radio.raw:
	print >>RadioTestM,"		call RadioSPI.idle();"
elif radio == Radio.radiocontrol:
	print >>RadioTestM,"""\t\tcall Radio.start();
		call RadioState.idle();"""
elif radio in [Radio.tmac,Radio.mintroute]:
	pass
else:
	raise Exception, "Can't handle "+str(radio)

if data in [Data.tx,Data.both]:
	if radio in [Radio.radiocontrol,Radio.tmac,Radio.mintroute]:
		print >>RadioTestM,"\t\tpackets=1;"
	if not sleepy:
		print >>RadioTestM,"\t\tsendRadio();"

if radio == Radio.mintroute:
	print >>RadioTestM,"\n		call RouteControl.setUpdateInterval(8); // gets multiplied up to 8192"
print >>RadioTestM,"""
		return SUCCESS;
	}

	command result_t StdControl.stop()
	{
		counter = -1;
		//call Debug.txStatus(_LED_UNSET,Red);
		call Leds.redOff();"""
if radio == Radio.radiocontrol:
	print >>RadioTestM,"		call Radio.stop();"
print >>RadioTestM,"""
		return SUCCESS;
	}"""

if radio in [Radio.tmac,Radio.mintroute]:
	print >>RadioTestM,"""
	void sendComplete()
	{
		packets++;
	}"""
print >>RadioTestM,"""
	void sendRadio()
	{
		if (sleeptime !=0)
			return;
		if (counter!=-1)
		{"""
if radio not in [Radio.radiocontrol,Radio.tmac,Radio.mintroute]:
	print >>RadioTestM,"""
			if (counter==length)
			{
				counter=0;
				packets++;"""
if radio == Radio.mintroute and data != Data.rx:
	print >>RadioTestM,"""			uint16_t len;
			void *ptr = call Send.getBuffer(&msg,&len);
			if (len<length)
			{
				call Debug.tx16status(__RX_ERROR,2);
				return;
			}
			memcpy(ptr,testbytes,length);
			if (call Send.send(&msg,length) == FAIL)
			{
				sendComplete();
				call Leds.yellowToggle();
				dbg(DBG_ERROR,"Couldn't send message");
			}
			else
			{"""

if radio not in [Radio.tmac,Radio.mintroute] or data!=Data.tx:
	if data==Data.tx:
		if sleepy:
			count = 1
		else:
			count = 20
		print >>RadioTestM,"\t\t\tif ((packets %% %d)==0)"%count
	if data!=Data.rx:
		print >>RadioTestM,"\t\t\t{";
		#print >>RadioTestM,"\t\t\t\tcall Debug.txStatus(_LED_TOGGLE,Yellow);"
		print >>RadioTestM,"\t\t\t\tcall Leds.yellowToggle();"
		print >>RadioTestM,"\t\t\t}";
if data == Data.both:
	if radio == Radio.raw:
		print >>RadioTestM,"\t\t\t\tcall RadioSPI.idle();"
	elif radio == Radio.radiocontrol:
		print >>RadioTestM,"\t\t\t\tcall RadioState.idle();"
		
	if radio not in [Radio.radiocontrol,Radio.tmac]:
		print >>RadioTestM,"\t\t\t\tif ((packets % 2)!=0)"

	if radio == Radio.raw:
		if not sleepy:
			print >>RadioTestM,"\t\t\t\t\tcall RadioSPI.txMode();"
		else:
			print >>RadioTestM,"""
				{
					call RadioSPI.sleep();
					sleeptime = 600;
					return;
				}"""

if radio not in [Radio.radiocontrol,Radio.tmac,Radio.mintroute]:
	print >>RadioTestM,"			}"
if data in [Data.tx,Data.both]:
	if data == Data.both:
		print >>RadioTestM,"\t\t\tif ((packets % 2)!=0)"
	if radio not in [Radio.radiocontrol,Radio.tmac,Radio.mintroute]:
		print >>RadioTestM,"""\t\t\t{
				//call Debug.txStatus(_RADIO_TEST_XMIT,testbytes[counter]);"""
	if radio == Radio.raw:
		print >>RadioTestM,"\t\t\t\tcall RadioSPI.send(testbytes[counter]);"
	elif radio in [Radio.radiocontrol,Radio.tmac,Radio.mintroute]:
		if radio == Radio.radiocontrol:
			print >>RadioTestM,"""
			{
				result_t ret = call PhyComm.txPkt(testbytes,length);
				if (ret == SUCCESS)
				{"""
		elif radio == Radio.tmac:
			print >>RadioTestM,"""
			memcpy(msg.data,testbytes,length);
			if (call SendMsg.send(""",
			if unicast:
				if data == Data.both:
					print >>RadioTestM,"""1""",
				else:
					print >>RadioTestM,"""0""",
			else:
				print >>RadioTestM,"""TOS_BCAST_ADDR""",
			print >>RadioTestM,""", length, &msg) == FAIL)
				sendComplete();
			else
			{"""
		print >>RadioTestM,"""\t\t\t\tint i;
				for (i=0;i<length;i++)
					call Debug.txStatus(_RADIO_TEST_XMIT,testbytes[i]);
				dbg(DBG_PACKET,"Send completed succesfully\\n");"""
		if radio == Radio.radiocontrol:
			print >>RadioTestM,"""
				packets++;
				}"""
			
	print >>RadioTestM,"\t\t\t}"
if radio not in [Radio.radiocontrol,Radio.tmac,Radio.mintroute]:
	print >>RadioTestM,"\t\t\tcounter++;"
print >>RadioTestM,"\t\t}\n\t}"

if radio == Radio.raw:
	print >>RadioTestM,"""
	event result_t RadioSPI.dataReady(uint8_t byte, bool valid)
	{
		uint16_t temp = byte;
		call Debug.tx16status(__RADIO_TEST_RECV,(temp<<8)|valid);
		sendRadio();
		return SUCCESS;
	}
"""
elif radio == Radio.radiocontrol:
	print >>RadioTestM,"""
	event result_t PhyComm.startSymDetected(PhyPktBuf *packet) {return SUCCESS;}
	
	event PhyPktBuf* PhyComm.rxPktDone(PhyPktBuf* packet, uint16_t error, uint16_t rssi)
	{
		if (error == 0)
		{
			/*uint8_t i;
			for (i=1;i<packet[0];i++)
				call Debug.txStatus(_PKT_DATA,packet[i]);*/"""
	if sleepy:
		count = 1
	else:
		count = 20
	print >>RadioTestM,"\t\t\tif ((packets %% %d)==0)"%count
	print >>RadioTestM,"""
			{
				call Debug.tx16status(__RADIO_TEST_RECV,0);
				call Leds.yellowToggle();
			}
		}
		call Debug.tx16status(__RX_ERROR,error);
		packets++;"""
	if sleepy:
		if data == Data.rx:
			print >>RadioTestM,"""
			call RadioState.sleep();
			sleeptime = 600;"""
	else:
		print >>RadioTestM,"\t\tsendRadio();"
	print >>RadioTestM,"""
		return packet;
	}
"""

if sleepy:
	if radio not in [Radio.tmac,Radio.mintroute]:
		print >>RadioTestM,"""
	event void Clock.fire(uint16_t ms)
	{
		if (sleeptime>0)
		{
			sleeptime-=ms;
			if (sleeptime<=0)
			{"""
		if radio == Radio.raw:
			print >>RadioTestM,"""
				call RadioSPI.idle();
				call RadioSPI.txMode();"""
		elif radio == Radio.radiocontrol:
			print >>RadioTestM,"\t\t\t\tcall RadioState.idle();"
		print >>RadioTestM,"""
				sendRadio();
			}
		}
	}
"""
	else:
		print >>RadioTestM,"""
	event result_t Timer.fired()
	{
		sendRadio();
		return SUCCESS;
	}
"""
	
if radio == Radio.raw:
	print >>RadioTestM,"	event result_t RadioSPI.xmitReady()"
elif radio == Radio.radiocontrol:
	print >>RadioTestM,"	event result_t PhyComm.txPktDone(PhyPktBuf *packet)"
if radio == Radio.mintroute:
	print >>RadioTestM,"\n	event result_t Receive.intercept(TOS_MsgPtr data, void* payload, uint16_t payloadLen)"
elif radio == Radio.tmac:
	print >>RadioTestM,"	event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr data)"
if radio in [Radio.tmac,Radio.mintroute]:
	print >>RadioTestM,"""	{
		uint8_t i;
		for (i=1;i<data->length;i++)
			call Debug.txStatus(_PKT_DATA,data->data[i]);
		packets++;"""
	if not sleepy:
		print >>RadioTestM,"""
		sendRadio();"""
	if data == Data.rx:
		print >>RadioTestM,"\t\tcall Leds.yellowToggle();"
	if radio == Radio.mintroute:
		print >>RadioTestM,"		return FAIL;"
	else:
		print >>RadioTestM,"		return data;"
	print >>RadioTestM,"	}"

if radio == Radio.mintroute:
	print >>RadioTestM,"\n	event result_t Send.sendDone(TOS_MsgPtr sent, result_t success)";
elif radio == Radio.tmac:
	print >>RadioTestM,"	event result_t SendMsg.sendDone(TOS_MsgPtr sent, result_t success)";
if radio in [Radio.tmac,Radio.mintroute]:
	print >>RadioTestM,"""	{
		int i;
		dbg(DBG_PACKET,"Senddone completed %ssuccessfully\\n",success==SUCCESS?"":"un");
		dbg(DBG_PACKET,"Sent packet:");
		for (i=0;i<sent->length;i++)
			dbg_clear(DBG_PACKET, "%02X ",(uint8_t)sent->data[i]);
		dbg_clear(DBG_PACKET,"\\n");
		if (success)
		{
			sendComplete();"""
	if not sleepy:
		print >>RadioTestM,"\t\t\tsendRadio();"
	if radio in [Radio.tmac,Radio.mintroute] and data == Data.tx:
		#print >>RadioTestM,"\t\t\tcall Debug.txStatus(_LED_TOGGLE,Green);"
		print >>RadioTestM,"\t\t\tcall Leds.greenToggle();"
	print >>RadioTestM,"""
		} else {
			call Leds.yellowToggle();
			call Debug.tx16status(__RX_ERROR,1);
		}
		return SUCCESS;"""
	
if radio not in [Radio.tmac,Radio.mintroute]:
	print >>RadioTestM,"\t{"
	if sleepy and data == Data.tx:
		print >>RadioTestM,"""
		call RadioState.sleep();
		sleeptime = 600;"""

	print >>RadioTestM,"""
		sendRadio();
		return SUCCESS;"""
print >>RadioTestM,"""
	}
}
"""
RadioTestM.close()

if unicast:
	if data == Data.tx:
		print "Node should be programmed as >=1 (will send to the 0 node)"
	elif data == Data.rx:
		print "Node should be programmed as 0"
	elif data == Data.both:
		print "TX is 0, RX is 1"
	else:
		raise Exception,"Instructions for this mode? %s"%data
