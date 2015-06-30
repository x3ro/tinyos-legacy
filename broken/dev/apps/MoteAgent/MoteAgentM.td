/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 * Author:   Su Ping
 *
 * Intel Research Berkeley Lab
 */

/** 
 *
 * This module implements a generic command processing interface.
 * The command comes in as a AM_CMDMSG typed message. 
 * The message is then parsed and processed. If a response is needed, 
 * This module sends a response back. 
 *
 * It provides StdControl interface and MoteAgent interface. 
 * 
 *
 **/

includes CmdRspMsg;

module MoteAgentM { 
    provides 	{
	interface StdControl;
    	interface MoteAgent; 
    }

    uses {
    interface Leds;
//    interface Clock;
    interface Pot;
//    interface ADC;
//    interface StdControl as ADCControl ;
    interface StdControl as SounderControl;
    interface SendMsg as SendResponse;;
    interface StdControl as CommControl;
//  interface EEPROMRead;
//  interface Sensing;//??
  }
}

/* 
 *  Module Implementation
 */

implementation 
{
  TOS_MsgPtr msg;	
  short parent;       
  int8_t pending;// pending command flag
  int8_t send_pending;
  TOS_Msg buf;


  /**
   *
   * This task evaluates a command and execute it if it is a supported
   * command.The protocol for the command interpreter is that
   * it operates on the message and returns a (potentially modified)
   * message to the calling layer, as well a status word for whether 
   * the message should be futher processed. 
   * 
   * @return Return: None
   **/

  task void cmdInterpret() {
    int8_t action, comp, status, param;
    uint8_t retVal;
    int16_t sender;
    struct CmdRspMsg * cmd = (struct CmdRspMsg *) msg->data;
    action = cmd->action;
    comp = cmd->compID;
    status = cmd->status;
    sender = cmd->source; // save sender address 
 
    // do local packet modifications: update the hop count and packet source
    cmd->hopCnt=0;
    cmd->source = TOS_LOCAL_ADDRESS;
   
    // Execute the command
    switch (cmd->compID ) {
    case LEDS:
      switch (cmd->action) {
        case GET:
          cmd->args[0]= call Leds.get();

          send_pending = call SendResponse.send(sender, sizeof(struct CmdRspMsg), msg);
            // dbg(AGENT, "sent LEDS get response ");
          break;
        case SET_ON:
        case SET_OFF:
        case SET_START:
        case SET_STOP:
          param = cmd->args[0];
          // set LEDS pin to param.
          call Leds.set(param);
          break;
      }
      break;
    case RADIO: //POT
      switch (cmd->action) {
        case GET:
          cmd->args[0] =call Pot.get();;
          if (send_pending==0) {
          send_pending = call SendResponse.send(sender, sizeof(struct CmdRspMsg), msg);
          }
          break;

        case SET_ON:
        case SET_OFF:
        case SET_START:
        case SET_STOP:
          call Pot.set(cmd->args[0]);
          break;
      }
/* not supported for this release
    case LIGHT:
      switch (cmd->action) {
        case GET:
         // what we want this command do? 
          //get n samples every m seconds? 
          // and send data back to BS or write to EEPROM?
	// args[0]=n; args[1]= m; 
          // if (args[2]) send reading back to cmd sender
          // else write the reading into EEPROM
          break;
        case SET_ON:
	// enable Photo sender
	break;
        case SET_OFF:
        // disable Photo sensor 
        break;
        case SET_START:
        // start sensing 
        break;
        case SET_STOP:
          //stop sending
          break;
      }
      break;

    case TEMP:
    case ACCEL:
    case MAGNET:
    case MICPHONE:
*/
    case SOUNDER:
        switch (cmd->action) {
		case GET:
          //should we sent current configuration to manager?
          break;
        case SET_ON:// enable
        case SET_OFF:// disable 
          // not allowed
          break; 
        case SET_START:
          // 
          call SounderControl.start();
        case SET_STOP:
          call SounderControl.stop();
          break;
      }
     break;
/* leave this out for now
    case LOGGER:
      switch (cmd->action) {
        case SET_ON:
        case SET_OFF:
        case SET_START:
        case SET_STOP:
          // not allowed
          break;
        case GET:
          // READ_LOG:
	if  (send_pending== 0) {
	if (call EEPROMRead.read(
				 (short)(cmd->args.rl_args.logLine), 
				 ((logmsg_t*) log_msg.data)->log)) {
	  send_pending ++;
	}
        }
      } // switch (cmd->action)
    break;
*/
    default: 
      // Component not supported 
  } // switch (cmd->compID)
  signal MoteAgent.executeDone(msg, SUCCESS );
}

  /** 
   *  Initialiation the application: 
   *  
   *  1. Initialize module static variables
   *  2. turn yellow Led on
   *  3. Initialize underlining communication layer
   *  @return Returns <code>SUCCESS</code> or <code>FAILED</code>
   **/

  command result_t StdControl.init() {
    msg = &buf;
    pending = 0;
    send_pending=0;
    //call Leds.yellowOn();
    // initialize low level component 
    call CommControl.init();
    call SounderControl.init();
	return SUCCESS ;
  }


  command result_t StdControl.start(){
    return SUCCESS;
  }

  command result_t StdControl.stop(){
    return SUCCESS;
  } 

/*
  // The log has completed the reading, and now we're ready to send out this
  // message. Note a potential problem: what is send_pending set to? 

  event result_t EEPROMRead.readDone(uint8_t * packet, result_t success) {
    if (success && send_pending) {
      send_pending = call SendLogMsg.send(TOS_BCAST_ADDR, sizeof(logmsg_t),
					  &log_msg);
    }
    return SUCCESS;
  }
*/
  /**
   * This command belongs to  interface MoteAgent.
   * It posts task cmdInterpret() to handle the recieved command
   * @return Always Returns <code>SUCCESS</code> 
   **/
  command result_t MoteAgent.execute(TOS_MsgPtr pmsg) {
    pending ++;
    msg = pmsg;
    post cmdInterpret();
    return SUCCESS;
  }

 
  /** 
   *	Default event handler for MoteAgent.executeDone event.
   *	
   *   @return Always Returns <code>SUCCESS</code>
   **/
  default event result_t MoteAgent.executeDone(TOS_MsgPtr pmsg, result_t status) {
    return SUCCESS;
  } 


  /**
   * Reset send_pending flag to 0 in response to SendMsg.sendDone event
   *
   * @return Returns <code>SUCCESS</code> or <code>FAILED</code>
   **/
  event result_t SendResponse.sendDone(TOS_MsgPtr pmsg, result_t status) {
    if (status== SUCCESS) send_pending =0;
    return status;
  }
  

} // end of implementation
