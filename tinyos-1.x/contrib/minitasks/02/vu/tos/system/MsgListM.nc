/*
 * Copyright (c) 2002, Vanderbilt University
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
 * Author: Miklos Maroti, Gabor Pap
 * Date last modified: 5/14/03
 */

 /*
 Description: This "component" manages chained lists of TOS_Msg-s. It uses 
 two pointers plus the crc field of the TOS_Msg, therefore messages should not 
 be part of any list when they are passed to the radio component! One message 
 can only be part of one list at a time, but this is not ensured by this 
 component, so the user of this has to take care of it!
*/

includes MsgList;

module MsgListM {
	provides {
		interface MsgList;
	}
}

implementation{

	/*
	 This method must always be called first on a list!
	*/
	command void MsgList.init(TOS_MsgList *list) {
		atomic {
			list->head = 0;
			list->tail = & list->head;
		}
	}
	
	command bool MsgList.isEmpty(TOS_MsgList *list) {
		bool ret;
		atomic ret = (list->head == 0);
		return ret;
	}
	
	#define NEXT(ELEM) (*(TOS_MsgPtr*)(&(ELEM->crc)))
	
	command TOS_MsgPtr MsgList.getFirst(TOS_MsgList *list){
		TOS_MsgPtr ret;
		atomic ret = list->head;
		return ret;
	}
	
	command TOS_MsgPtr MsgList.next(TOS_MsgPtr elem) {
		TOS_MsgPtr ret;
		atomic ret = NEXT(elem);
		return ret;
	}
	
	command void MsgList.addFirst(TOS_MsgList *list, TOS_MsgPtr elem) {
		atomic {
			NEXT(elem) = list->head;
			if (list->head == 0)
				list->tail = & NEXT(elem);
			list->head = elem;
		}
	}
	
	command void MsgList.addLast(TOS_MsgList *list, TOS_MsgPtr elem) {
		atomic {
			NEXT(elem) = 0;
			*(list->tail) = elem;
			list->tail = & NEXT(elem);
		}
	}
	
	command void MsgList.addAll(TOS_MsgList *list, TOS_MsgPtr first, uint8_t size) {
		while( size-- > 0 )
			call MsgList.addFirst(list, first++);
	}
	
	command TOS_MsgPtr MsgList.removeFirst(TOS_MsgList *list) {
		TOS_MsgPtr ret;
		atomic {
			ret = list->head;
			if( (list->head = NEXT(ret)) == 0 )
				list->tail = & list->head;
		}
		return ret;
	}
	
	command uint8_t MsgList.getLength(TOS_MsgList *list) {
		uint8_t msgsInQueue = 0;
		TOS_MsgPtr msgPtr = call MsgList.getFirst(list);
		while( msgPtr != 0 ) {
			msgsInQueue++;
			msgPtr = call MsgList.next(msgPtr);
		}
		return msgsInQueue;
	}
}
