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
 * @modified 04/11/05
 */

//how to get the list of receivers
enum{
    ALL_RCVS_TYPE = 0,
    GIVEN_RCVS_TYPE = 1,
};

enum{
    CHANNELS_SET_CMD = 0x10,
    PARAMS_SET_CMD = 0x11,
    CHANNELS_NUM = 22,
    NUM_RECEIVERS = 10,
	ROUTING_BUFF_SIZE = 1000,
};

struct DataCollectionParams{
    uint8_t masterPwr;//0
    uint8_t assistPwr;//1

    uint8_t algorithmType;//2
    int16_t interferenceFreq;//3,4
    uint8_t tsNumHops;//5

    //tuning
    int8_t  channelA;//6
    int8_t  channelB;//7
    int16_t initialTuning;//8,9
    int8_t  tuningOffset;//10
    uint8_t numTuneHops;//11
    uint8_t numVees;//12

    //measurement
    uint8_t numChanHops;//13
    int8_t initialChannel;//14
    int8_t channelOffset;//15
    
};

struct SyncPacket{
    uint8_t seqNum;
    uint16_t masterID;
    uint16_t assistID;
    uint8_t rcvID[NUM_RECEIVERS]; //if rcvID[0]==0 -> get all receivers
                                  //   rcvID[0]==1 -> get first 10
                                  //   otherwise   -> use rcvID field to determine
    int8_t channelA;
//    int8_t channelB;
    uint8_t  assistPwr;
    uint8_t  hopType;
    uint8_t  numHops;
};

struct MeasurementSetup{
    uint8_t seqNumber;
    uint16_t masterID;
    uint16_t assistantID;
    uint8_t rcvID[NUM_RECEIVERS];
};
