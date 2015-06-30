Instructions to install radio stack for mica2dot platform.
Author: Jaein Jeong <jaein@eecs.berkeley.edu>

This program is to support ChipCon CC1000 radio in MICA2 and DOT3
platforms and was written in nesC programming language. 

1) This program assumes that you've already installed TinyOS v1.0.
   What we want to do extract dot3radio.tar.gz file and overwrite
   the extracted files to tinyos-1.x directory.

   untar dot3radio.tar.gz into a temporary directory (e.g. /temp).
   copy the extracted files into tinyos-1.x directory.
   new platform was added under tinyos-1.x/tos/platform/mica2dot
   Some files in tinyos-1.x/apps/ and tinyos-1.x/nesc were also modified.

2) Existing installation of nesC compiler doesn't recognize new platform
   directory (mica2dot), so it needs to be compiled again.
   type "which ncc" and delete that instance of ncc.
   go to tinyos-1.x/nesc directory 
   type ./configure and
   make
   make install

3) Now you can use the same interface GenericComm to send and receive
   packets. When you want to build an application for DOT3, you can type

   make mica2dot install

   To confirm that the radio works with DOT3 platform, try to load
   CntToLedsAndRfm to one mote (sender) and RfmToLeds to another mote
   (receiver). If the LED in the receiver blinks as the sender blinks,
   then it's succsessful. Try to turn off the sender mote, the receiver
   should stop blinking.

4) This program supports two different versions: the one with
   error correction code (ECC) and the one without it.
   Currently, the program is set to use ECC.
   If you want to override it, you can modify RFCommC.nc file which
   is in tinyos-1.x/tos/platform/mica2dot/RFCommC.nc

	configuration RFCommC
	{
	  provides {
	    interface RFComm;
	  }
	}
	implementation
	{
	  components RFCommM, ChannelMonEccC, ChipconC;
	
	  RFComm = RFCommM.RFComm;
	
	  RFCommM.ChannelMon -> ChannelMonEccC;
	  RFCommM.Chipcon -> ChipconC;
	
	}

   In the code above, replace all occurences of ChannelMonEccC with
   ChannelMonC if you want to use non-ECC version of radio stack.

5) Now you can use the same interface GenericComm to send and receive
   packets. When you want to build an application for DOT3, you can type

   make mica2dot install

   To confirm that the radio works with DOT3 platform, try to load
   CntToLedsAndRfm to one mote (sender) and RfmToLeds to another mote
   (receiver). If the LED in the receiver blinks as the sender blinks,
   then it's succsessful. Try to turn off the sender mote, the receiver
   should stop blinking.

6) You can try different error correction code by changing SecDedEncoding
   module in tinyos-1.x/tos/platform/mica2dot/ChannelMonEccC.nc.
   SecDedEncoding was made for RFM radio and inefficient due to DC balancing.
   Instead, you can use one of the following modules:

   -- Single Error Correction and Double Error Detection --
   SecDedEncoding1Byte: encodes 1 byte data into 2 byte code word
   SecDedEncoding2Byte: encodes 2 byte data into 3 byte code word
   SecDedEncoding3Byte: encodes 3 byte data into 4 byte code word
   -- Double Error Correction and Triple Error Detection --
   DecTedEncoding:      encodes 1 byte data into 2 byte code word 
 
	configuration ChannelMonEccC {
	  provides interface ChannelMon;
	}
	implementation {
	  components ChannelMonEccM, ChipconC, RandomLFSR, SpiByteFifoC,
        	     SecDedEncoding, ADCC;
	  ChannelMon = ChannelMonEccM.ChannelMon;
	  ChannelMonEccM.Chipcon -> ChipconC;
	  ChannelMonEccM.Random -> RandomLFSR;
	  ChannelMonEccM.SpiByteFifo -> SpiByteFifoC;
	  ChannelMonEccM.Code -> SecDedEncoding.Code;
	  ChannelMonEccM.ADC -> ADCC.ADC[0];
	}

7) You can use the signal strength of the received signal by reading
   strength field at the message arrival. Application needs to import
   two interfaces: RSSI and ReceiveMSG. Initially use enable signal
   strength reading by RSSI.rssi_enable(). When you receive a message
   in ReceiveMsg.receive(), you can read the signal strength using
   strength field. 

   Example.

        -- Configuration File --

	configuration AppNode { }
	implementation
	{
	  components Main, AppNodeM, LedsC,
	             GenericComm as Comm,
	             RFCommC, TimerC;

	  Main.StdControl -> AppNodeM;

	  AppNodeM.CommControl -> Comm;
	  AppNodeM.AppNodeReport -> Comm.ReceiveMsg[REPORT_CHANNEL];
	  AppNodeM.RSSI -> RFCommC.RSSI;
	  ...
	}

        -- Implementation File --

	module AppNodeM
	{
	  provides interface StdControl;
	  uses {
	    interface StdControl as CommControl;
	    interface ReceiveMsg as AppNodeReport;
	    interface RSSI;
	  }
	}
	...

	  command result_t StdControl.init() {
	    ...
	    call RSSI.rssi_enable();
	    ...
	  }
	
	  event TOS_MsgPtr AppNodeReport.receive(TOS_MsgPtr m) {
	    uint16_t value = m->strength;
	    ...
	  }
	







