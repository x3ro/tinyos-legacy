/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * @author Brano Kusy, kusy@isis.vanderbilt.edu
 * @modified 11/21/05
 */

to play around with our java application, e.g. to see replay of the localization 
of a large scale experiment, see
    contrib/vu/tools/java/isis/nest/localization/rips/compilationInstructions.txt

1. COMPILE THE MOTE CODE:
=================================
1.  install the newest tinyos-1.x at least version 1.1.14, we will refer to 
    the directory of this installation as $(CVS_TINYOS)
    
2.  grab a copy of the contrib/vu/tinyos-1.x tree from to a directory, different from 
    $(CVS_TINYOS) we will refer to this directory as $(ISIS_TINYOS)
    
3.  go to $(CVS_TINYOS)/tools/make/Makelocal (if it does not exist, create a 
    blank file) and add there the following lines
    
    TINYOS_NP := BNP
    VUTOS := /cygdrive/$(ISIS_TINYOS)/tos

4.  go to $(ISIS_TINYOS)/apps/RipsOneHop directory and type 'make mica2' to compile
    the tinyos code
        

We control RIPS from java:
Java applications required for rips measurement:
------------------------------------------------
1. %T/../tools/java/net/tinyos/mcenter/MessageCenter framework
2. %T/../tools/java/net/tinyos/mcenter/RemoteControl app
3. %T/../tools/java/net/tinyos/mcenter/BigMSGDisplay app

Measurement steps
-----------------
1. upload RipsOneHopC application to 4 mica2/xsm motes with 4 different IDs: A,B,C,D 
   upload 1 mote with TOSBase and connect it to a PC
2. send out StartMeasurementCommand remote control message (defined below in RemContrl section) 
    with parameters (1,B,0) to the mote A, we call A a 'master', B an 'assistant',
    and all the other motes are 'slaves'
3. StartMeasurementControl starts the following sequence:
   3a. calibration of A and B motes (A sends a synchronization msg (am=82) and slaves reply with 
       calibration msg (am=83) after a while)
   3b. if A is sucessfully calibrated to B, then mote A starts an interference measurement: 
       - A sends sync msg (am=82)
       - C and D measure their absolute phases offsetC_i/offsetD_i at 22 predefined carrier frequencies 
         f_i (for the exact carrier frequencies look at array channels[] below)
       - C and D report a data buffer with 22 RipsPacket packets (defined in RipsPhaseOffset.h) 
         using BigMSGDisplay
   3b' if calibration fails, interference measurement ends without further message traffic
4. you can parse the  buffers reported in step 3b. and compute the phase offsets 
    gamma_i = offsetC_i - offsetD_i for each carrier freuency f_i, i=1..22 
    (see bigMsg-parsing.xls for raw buffer parsing)
5. if interferometric range Dabcd = Dad-Dac+Dbc-Dbd and lambda_i=speed_light/f_i then 
    Dabcd (mod lambda_i) = gamma_i
    
How to use RemoteControl
------------------------
RemoteControl application needs to be started in MessageCenter framework. The RemoteControl app has the 
following control elements:
 - we are interested only in Parameter tab (there are 2 other tabs available: 'Int','Start/Stop')
 - 'appId' field demuxes remote commands for different applications (sth like AM-type in TOS_Msg)
 - 'target' field specifies node-id of the node who will receive remote command
 - 'Parameter Data' specify the parameters separated with spaces,  1 byte param is given as a number 
    (i.e. 0-255), 2 byte params are given by number followed by 'w' (i.e. 0w-65535w)
 - messages will be propagated multihop from the base station connected to java through Serial 
   Connector
   
Define the following remote control messages:

1. StartMeasurementCommand - starts the Rips measurement
    'target' is set to a master node
    'appId' = 0x12
    'Parameter Data' = {
        uint8_t seqNum 
        uint16_t assistID 
     }
    
  example: i want mote 123 to be master, mote 234 to be asisstant 
          'Parameter Data' = 1 234w, 'target' = 123          
            
2. DataCollectionParamsCommand - changes parameters of Rips online
    'target' - typically 0xFFFF which means all motes
    'appId' - 0x11
    'Parameter Data' = {
        uint8_t masterPwr;          //specify TX power of the master's radio
        uint8_t assistPwr;          //specify TX power of the assistants's radio
        uint8_t algorithmType;      //specify at what carrier freqs will slaves measure absolute phases,
                                    //use 52 for hopping through frequencies (see below), 
                                    //use 53(default) for prespecified freqs

        int16_t interferenceFreq;   //what interference frequency will be used
        uint8_t tsNumHops;          //up to how many hops time-sync message propagates
        int8_t  channelA;           //at which freq we do the calibration
        int8_t  channelB;
        int16 initialTuning;        //calibration param
        int8  tuningOffset;         //calibration param
        uint8 numTuneHops;          //calibration param
        uint8 numVees;              //calibration param
    
        uint8 numChanHops;          //if 52 is used as algorithmType, then the absolute phases are measured
        int8 initialChannel;        //at initialChannel(ICH), then at channel ICH plus channelOffset(CHO),
        int8 channelOffset;         //numChanHops(numCH) times -> so all channels at which abs.phase is
                                    //meaured are ICH,ICH+CHO,ICH+2*CHO,...,ICH+(numCH-1)*CHO
    }
    
    example:
            'target' = 0xffff
            'Parameter Data' =  inside: 1   1   53 350w 3 40 -40 -65w 5 26 2 21 -55 2
                               outside: 128 128 53 350w 3 40 -40 -65w 5 26 2 21 -55 2
            slaves measure absolute offsets at predefined channels (see array channel[] below)

    example for 'frequency hopping':
            'target' = 0xffff
            'Parameter Data' = inside:  1   1   52 350w 3 40 -40 -65w 5 26 2 54 -55 2
                               outside: 128 128 52 350w 3 40 -40 -65w 5 26 2 54 -55 2 
            slaves measure absolute offsets at 55 channels: -55,-53,-51,...,53

Important settings
==================        
channel 0 corresponds to 430.1MHz
channel sepparation is .536 MHz

channels[] array (defined in RipsDataStoreM.nc): 
        -61,60,-54,41,40,31,23,17,15,3,2,-61,60,-54,-42,-33,-25,-19,-17,-5,-2,-1 corresponds to
        [in MHz] 397.98	461.70	401.67	451.70	451.17	446.43	442.22	439.06	438.00	431.69	431.16	397.98	461.70	401.67	407.99	412.73	416.94	420.10	421.15	427.47	429.05	429.58
        these are the carrier frequencies where phase offsets are measured using default settings