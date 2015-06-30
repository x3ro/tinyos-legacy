/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
 * "Copyright (c) QUEUE_LENGTH000-QUEUE_LENGTH003 The Regents of the University  of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*                                                                      tab:4
 * Copyright (c) QUEUE_LENGTH003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:     Nandu Kushalnagar
 *
 */


#ifndef SEND_SIMPLEQUEUE_SIZE
#define SEND_SIMPLEQUEUE_SIZE 10
#endif

#ifndef SEND_QUEUE_MAX_RETRIES
#define SEND_QUEUE_MAX_RETRIES 3
#endif

module SimpleQueueM {
   provides {
      interface StdControl as Control;
      interface BareSendMsg as Send;
   }
   uses {
      interface StdControl as SubControl;
      interface BareSendMsg as SubSend;
   }
}

implementation {
   typedef struct QueueEnt {
      TOS_MsgPtr origMsg;
      TOS_Msg msg;
	  uint8_t sendAttempts;
      struct QueueEnt *next;
   } QueueEnt;

   QueueEnt entryBuffers[SEND_SIMPLEQUEUE_SIZE];
   QueueEnt * emptyList;
   QueueEnt * queueHead;
   bool sendPending;

   command result_t Control.init() {
      int i;
      emptyList = NULL;
      for (i=0; i<SEND_SIMPLEQUEUE_SIZE; i++) {
         entryBuffers[i].next = emptyList;
		 entryBuffers[i].sendAttempts = 0;
         emptyList = &(entryBuffers[i]);
      }
      sendPending = FALSE;
      queueHead = NULL;
   }

   command result_t Control.start() {
      return SUCCESS;
   }

   command result_t Control.stop() {
      return SUCCESS;
   }

   // return a slot from the empty list
   QueueEnt * getNewEntry() {
      QueueEnt * ret = emptyList;

      if (ret != NULL) {  // make sure the queue is not empty
         emptyList = ret->next;
      }
      return ret;
   }

   // add a new message to the end of the list
   void enqueueMessage(QueueEnt *newEnt) {
      newEnt->next = NULL;

      if (queueHead == NULL) {
         queueHead = newEnt;
      } else {
         QueueEnt * ent;
         for (ent = queueHead; ent->next != NULL; ent = ent->next);
         ent->next = newEnt;
      }
   }

   void dequeueMessage() {
      // move the queue head to the empty list
      QueueEnt * ent = queueHead;
      queueHead = queueHead->next;  // dequeue from send queue

      ent->next = emptyList;  // enqueue onto emtpy list
      emptyList = ent;

      ent->sendAttempts = 0;
   }

   uint8_t queueLen() {
      QueueEnt *ent = queueHead;
      uint8_t len=0;

      while (ent != NULL) {
         ent = ent->next;
         len++;
      }

      return len;
   }

   // generate any outstanding sendDone events
   task void signalSendDone() {
      QueueEnt * ent;

      for (ent = queueHead; ent != NULL; ent = ent->next) {
         if (ent->origMsg != NULL) {
            dbg(DBG_USR1, "SimpleQueueM signaling send done\n");
	        signal Send.sendDone(ent->origMsg, SUCCESS);
            ent->origMsg = NULL;
         }
      }
   }

   task void attemptToSend() {
      dbg(DBG_USR1, "SimpleQueueM Inside attemptToSend\n");
	  if (queueHead == NULL || sendPending == TRUE) {
         return;
      }
      if (queueHead->sendAttempts >= SEND_QUEUE_MAX_RETRIES) {
         dbg(DBG_USR1, "SimpleQueueM exceeded no of retries\n");
         dequeueMessage();
		 post attemptToSend();
      }
	  sendPending = TRUE;
      dbg(DBG_USR2, "SimpleQueueM Calling UART Send\n");
      if (call SubSend.send(&queueHead->msg) == FAIL) {
         sendPending = FALSE;
         dbg(DBG_USR1, "SimpleQueueM failed to send\n");
         queueHead->sendAttempts++;
		 post attemptToSend();
      }
   }

   command result_t Send.send(TOS_MsgPtr msg) {
      QueueEnt * newEntry = getNewEntry();

      dbg(DBG_USR2, "SimpleQueueM send(), queueing packet"
		         "(queue len = %d)\n",queueLen());

      if (newEntry == NULL) {  // queue is full
         dbg(DBG_USR2, "SimpleQueueM send(), FAILED: queue full"
		         "(queue len = %d)\n",queueLen());
         return FAIL;
      }
      newEntry->origMsg = msg;
      memcpy(&newEntry->msg, msg, sizeof(TOS_Msg));
	  newEntry->sendAttempts = 0;

      // enqueue new entry
      enqueueMessage(newEntry);

      dbg(DBG_USR1, "SimpleQueueM send(), SUCCESS (queue len = %d)\n",
                                                        queueLen());
	  post signalSendDone();
      post attemptToSend();
      return SUCCESS;
   }

   event result_t SubSend.sendDone(TOS_MsgPtr msg, result_t success) {
      if ((sendPending == TRUE) && (msg == &queueHead->msg)) {
         sendPending = FALSE;

         dbg(DBG_USR2, "SimpleQueueM got send done\n");

         if (success == SUCCESS) {
            dequeueMessage();
            dbg(DBG_USR1, "SimpleQueueM (queue len = %d)\n",queueLen());
         } else {
            dbg(DBG_USR1, "SimpleQueueM sub-send failed\n");
         }
      }
	  if (queueHead != NULL) {
	     post attemptToSend(); //trigger to send pending elements
      }
      return SUCCESS;
   }

   default event result_t Send.sendDone(TOS_MsgPtr msg, result_t success) {
      return SUCCESS;
   }
}
