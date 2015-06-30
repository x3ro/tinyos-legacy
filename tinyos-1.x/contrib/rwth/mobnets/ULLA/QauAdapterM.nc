/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
 /**
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
 
includes hardware;

module QauAdapterM {
  provides {
    interface StdControl;
		interface ProcessCmd[uint8_t id];
  }
	uses {
		interface ProcessCmd as ProcessQuery[uint8_t id];
		interface Leds;
	}
}

implementation {

  uint8_t nConds;
	
  command result_t StdControl.init() {
		atomic {
		  nConds = 0;
		}
	  return  SUCCESS;
	}
	
	command result_t StdControl.start() {
	
	  return  SUCCESS;
	}
	
	command result_t StdControl.stop() {
	
	  return  SUCCESS;
	}
	
	command result_t ProcessCmd.execute[uint8_t id](TOS_MsgPtr pmsg) {
	  struct QueryMsgNew *qnmsg = (struct QueryMsgNew *)pmsg->data;
		TOS_Msg temp;
		struct QueryMsg *qomsg = (struct QueryMsg *)(&temp)->data;
		uint8_t i, cIndex=0;
		uint8_t foundLpId = 0, processThisLpId = 0;
	  dbg(DBG_USR1, "\n\n\n\n QauAdapter \n\n\n\n");
		memcpy(&temp, pmsg, 10); 
		
		if (qnmsg->dataType == COND_MSG) {
		  // if it is a condition message we need to extract into several messages (one condition/message)
			#if 1
			for (i=0; i<CONDITION_SIZE && i<nConds; i++) 
			{
				if (qnmsg->u.cond[i].field == LP_ID)
				{
					foundLpId = 1;
					if (qnmsg->u.cond[i].value == TOS_LOCAL_ADDRESS) processThisLpId = 1;
				}
			}
			
			if (foundLpId == 1 && processThisLpId != 1) 
			{ 
				return FAIL;
			}
			#endif
			else 
			{
				memcpy((&temp)->data,pmsg->data, 12);
				for (i=0; i<CONDITION_SIZE && i<nConds; i++) {
					TOSH_uwait(6000);
					TOSH_uwait(6000);
					TOSH_uwait(6000);
					TOSH_uwait(6000);
					TOSH_uwait(6000);
					TOSH_uwait(6000);
					TOSH_uwait(6000);
					TOSH_uwait(6000);
					TOSH_uwait(6000);
		
					qomsg->u.cond.field = qnmsg->u.cond[i].field;
					qomsg->u.cond.op = qnmsg->u.cond[i].op;
					qomsg->u.cond.value = qnmsg->u.cond[i].value;
					qomsg->index = cIndex;
				
					cIndex++;
					call ProcessQuery.execute[id](&temp);
			}
			
			atomic nConds -= i+1;
			}	
			
		}
		else {
		  atomic nConds = qnmsg->numConds;
			call ProcessQuery.execute[id](pmsg);
		} //*/
	  return SUCCESS;
	}
	
	event result_t ProcessQuery.done[uint8_t id](TOS_MsgPtr pmsg, result_t status) {
    dbg(DBG_USR1, "ProcessQuery done: prepare to send back\n");
    return SUCCESS;
  }
	

}
