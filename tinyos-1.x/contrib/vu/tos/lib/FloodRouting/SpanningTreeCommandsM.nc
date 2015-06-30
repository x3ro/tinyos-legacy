/*
 * Copyright (c) 2004, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Vijayaraghavan Kalyanapasupathy
 * Date last modified: 05/20/2004
 */

module SpanningTreeCommandsM {

    provides {
        interface IntCommand;
        interface DataCommand as SpanningTreeDownloadConfigurationCommands;
    }
    uses {
        interface SpanningTreeParameters;
    }
}

implementation {
 /* IntCommand interface commands */

    command void IntCommand.execute(uint16_t param)    {
        uint16_t ret = 0xFFFF;
        dbg(DBG_USR1,"Recvd rem command id: %i @ node %i",param,TOS_LOCAL_ADDRESS);
        if( param == 0x00b0 ) {
            ret = call SpanningTreeParameters.setRoot();
        }
        else if( param ==  0x00b1 ) {
            ret = call SpanningTreeParameters.getParent();
        }
        else if( param ==  0x00b2 ) {
            ret = call SpanningTreeParameters.getGParent();
        }
        else if( param ==  0x00b3 ) {
            ret = call SpanningTreeParameters.getGGParent();
        }
        else if( param ==  0x00b4 ) {
            ret = call SpanningTreeParameters.getGGGParent();
        }
        else if( param ==  0x00b5 ) {
            ret = call SpanningTreeParameters.getLastSequenceNumber();
        }
        else if( param == 0x00b6 ) {
            ret = call SpanningTreeParameters.getHopCount();
        }
        else if( param == 0x00af) {
            call SpanningTreeParameters.clearParameters();
            ret = SUCCESS;
        }
        else if( param == 0x00ae) {
            ret = call SpanningTreeParameters.isRoot();
        }
        else if( param == 0x00ad) {
            ret = call SpanningTreeParameters.isInTree();
        }
        else if( param == 0x00ac) {
            call SpanningTreeParameters.setIsInTree();
            ret = call SpanningTreeParameters.isInTree();
        }
        if((param >= 0x00ac) && (param <= 0x00b6)){
            signal IntCommand.ack(ret);
        }
    }
    
    typedef struct _ParametersConfigMessage {
    	uint8_t appid;
    	uint8_t configMsg[TOSH_DATA_LENGTH-1];
    } ParametersConfigMessage;
    
    typedef struct _SpanningTreeConfigMessage {
    	uint16_t parent;
    	uint16_t gparent;
    	uint16_t ggparent;
    	uint16_t gggparent;
    	uint8_t  hopcount;
    } SpanningTreeConfigMessage;
    
    command void SpanningTreeDownloadConfigurationCommands.execute(void* data,uint8_t length){
    	ParametersConfigMessage *baseMsg = (ParametersConfigMessage*) data;
    	if(baseMsg -> appid == 0xa2){
	    	SpanningTreeConfigMessage *msg = (SpanningTreeConfigMessage*) baseMsg -> configMsg;
	    	call SpanningTreeParameters.setParent(msg->parent);
	    	call SpanningTreeParameters.setGParent(msg->gparent);
	    	call SpanningTreeParameters.setGGParent(msg->ggparent);
	    	call SpanningTreeParameters.setGGGParent(msg->gggparent);
	    	call SpanningTreeParameters.setHopCount(msg->hopcount);
	    	call SpanningTreeParameters.setIsInTree();
	    	signal SpanningTreeDownloadConfigurationCommands.ack(SUCCESS);
	   	}
    }
}

