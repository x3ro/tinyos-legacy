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
 *
 * Ulla Event Processing implementation
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/


includes UQLCmdMsg;

module EventProcessorM {

    provides 	{
      interface StdControl;
      interface ProcessCmd as ProcessEvent[uint8_t channel];
    }
    uses {
    
      interface Leds;

    }
}

/* 
 *  Module Implementation
 */

implementation 
{
  TOS_MsgPtr msg;	       
  TOS_Msg buf;

  command result_t StdControl.init() {
    msg = &buf;

    call Leds.init();
    return (SUCCESS);
  }
  
  /* start generic communication interface */
  command result_t StdControl.start(){
    return (SUCCESS);
  }

  /* stop generic communication interface */
  command result_t StdControl.stop(){
    return (SUCCESS);
  } 
  
  command result_t ProcessEvent.execute[uint8_t channel](TOS_MsgPtr pmsg) {
    
    //call RequestUpdate.execute(pmsg);
    return SUCCESS;
  }
  /*
  command result_t AttributeEvent.execute(TOS_MsgPtr pmsg) {
    
    //call RequestUpdate.execute(pmsg);
    return SUCCESS;
  }
  
  command result_t LinkEvent.execute(TOS_MsgPtr pmsg) {
    
    //call RequestUpdate.execute(pmsg);
    return SUCCESS;
  }
  
  command result_t CompleteCmdEvent.execute(TOS_MsgPtr pmsg) {
    
    //call RequestUpdate.execute(pmsg);
    return SUCCESS;
  } */
  /*
  event result_t ProcessQuery.done(TOS_MsgPtr pmsg, result_t status) {
    msg = pmsg;
    //call Leds.redToggle();
    if (status) {
      post forwarder();
    } else {	
      bcast_pending = 0;
    }
    return SUCCESS;
  } */

} // end of implementation
