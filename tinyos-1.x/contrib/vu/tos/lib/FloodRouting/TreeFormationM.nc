/*
 * Copyright (c) 2003, Vanderbilt University
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
 * Author: Gabor Pap, Miklos Maroti
 * Date last modified: 11/06/03
 */
 
/* VIJAI: Changed IntCommand.execute(...) :
		  1. Changed "ret" to 16 bit return.
		  2. Removed (uint8_t) downcast from funtion calls.
*/
 
includes TreeFormationMsg;

module TreeFormationM{
	provides{
		interface TreeFormation;
		interface IntCommand;
		interface StdControl;
	}
	uses{
		interface FloodRouting;
		//interface Timer;
	}
}

implementation{

    enum{
    	PARENT_COUNT = 8,
    };
    
    typedef struct ParentStat{
    	uint16_t parent;	  // the ID of the parent
    	uint8_t msgCount;	  // the messageCount for this parent
    } ParentStat;

    uint16_t root = 0xFFFF;
    uint16_t parent = 0xFFFF;
	uint16_t gParent = 0xFFFF;
	uint16_t ggParent = 0xFFFF;
	uint16_t gggParent = 0xFFFF;
	uint8_t lastSeqNum;
	uint8_t buffer[90];
    ParentStat stat[PARENT_COUNT];
    
    /**** StdControl ****/

	command result_t StdControl.init(){
	    uint8_t i;
	    
	    for (i = 0;i<PARENT_COUNT;i++){
	        ParentStat parentStat = stat[i];
            parentStat.msgCount = 0;
	    }

	    return SUCCESS; 
	}

	command result_t StdControl.stop(){
		call FloodRouting.stop();
		return SUCCESS;
	}

	command result_t StdControl.start(){
		call FloodRouting.init(9, 1, buffer, sizeof(buffer));
		return SUCCESS;
    }

    /**** TreeFormation ****/

	command void TreeFormation.setRoot(){
		if( root != TOS_LOCAL_ADDRESS )
			lastSeqNum = 0xFF;
			
		root = TOS_LOCAL_ADDRESS;
        parent = TOS_LOCAL_ADDRESS;
	    gParent = TOS_LOCAL_ADDRESS;
	    ggParent = TOS_LOCAL_ADDRESS;
	    gggParent = TOS_LOCAL_ADDRESS;
	}

	command uint16_t TreeFormation.getRoot(){
		return root;
	}

	command uint16_t TreeFormation.getGrandParent(){
        return gParent;
	}

	/**** implementation ****/

	TreeFormationMsg msg;

	task void sendMsg(){
		atomic{
            msg.seqNum = lastSeqNum;
	        msg.node = TOS_LOCAL_ADDRESS;
	        msg.parent = parent;
	        msg.gParent = gParent;
	        msg.ggParent = ggParent;
		}
        call FloodRouting.send(&msg);
	}

	event result_t FloodRouting.receive(void* p){
	    TreeFormationMsg* m = (TreeFormationMsg*)p;
	    
	    uint8_t i;
	    uint8_t countMin = 0xFF;
	    uint8_t countMax = 0;
	    uint8_t minPlace = 0;
	    uint8_t maxPlace = 0;
	    uint8_t msgPlace = 0;
	    bool new = TRUE;
	    
	    for (i = 0;i<PARENT_COUNT;i++){
	        ParentStat* parentStat = stat+i;
	        if (parentStat->parent == m->node){
	            parentStat->msgCount++;
	            new = FALSE;
	            msgPlace = i;
	        }
            if (parentStat->msgCount >= countMax){
                countMax = parentStat->msgCount;
                maxPlace = i;
            }
            if (parentStat->msgCount < countMin){
                countMin = parentStat->msgCount;
                minPlace = i;
            }
	    }
	    
	    if (msgPlace == maxPlace){
    	    lastSeqNum = m->seqNum;
            parent = m->node;
	        gParent = m->parent;
	        ggParent = m->gParent;
	        gggParent = m->ggParent;
	    }

	    if (new){
            ParentStat* parentStat = stat+minPlace;
            parentStat->parent = m->node;
            parentStat->msgCount = 1;
	    }


		return SUCCESS;
	}

/*	event result_t Timer.fired(){
		if( (++lastSeqNum & 0x0F) == 0x0F )
			call Timer.stop();

		post sendMsg();
		return SUCCESS;
	}
*/
	/**** remote command ****/
	
	command void IntCommand.execute(uint16_t param){
		uint16_t ret = 0xFFFF;

		if( param == 0 )
			ret = call TreeFormation.getRoot();
		else if( param == 1 )
			ret = call TreeFormation.getGrandParent();
		else if( param == 2 ){
			call TreeFormation.setRoot();
			ret = SUCCESS;
		}

		signal IntCommand.ack(ret);
	}
}
