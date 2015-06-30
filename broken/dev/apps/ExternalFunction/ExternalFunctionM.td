/*
 * 
 *
 * "Copyright (c) 2001 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:  Robert Szewczyk
 *           Kamin Whitehouse
 *	     Nelson Lee 
 * Histroy:  Created: a long time ago to work with Bcast
 *           2/10/02: Kamin modified it to be an independant shared component
 *                    that could do more things.  It is now meant to be 
 *                    a standard component that goes along with the new 
 *                    generic_comm, allowing any node to store data on command
 *                    and then be put onto a programming board and have the 
 *                    data read out of the log.  Commands can be multi-hopped 
 *                    to the node or just fed in through the UART
 *
 *           6/26/02: Nelson ported what used to be COMMAND.c to
 *                    ExternalFunction in Nesc
 *	     
 * This component demonstrates a simple message interpreter. The component is
 * accessed through the command interface; when the command is finished
 * executing, the component signals the upper layers with the message buffer
 * and the status indicating whether the message should be further processed. 
 * 
 * $\Id$
 */

/****COMMANDS and their PARAMETERS
ADC (sensors):
   1.  Activate/Deactivate (1 for activate, 0 for deactivate)
   2.  Data Channel (0 is for Signal Strength, 1 for light, etc
   3.  Destination: 0 Pack->UART,1 RawData->UART,2 Pack->BCast,3 data->log 
   4.  #Samples -- max number of samples to be collected. 0x00 means infinite
   5.  #Bytes -- the length of each sample in bytes, 0x00 means 2 bytes
   6.  Reset sample count //0 or 1

LOG:
   Note that this command sends data to the UART
   1.  Data Format: -- should the data be sent as raw data or as a packet
   2.  Line numbers:  which lines should be read from the log

POWER MODE:
   1.  FULL SLEEP or RADIO ON/OFF
   2.  Time in seconds

RADIO POWER:
   1.  potentiometer setting
   2.  1 for increase 0 for decrease

RADIO_JAM:
   1.  1 for turn on 0 for turn off

SOUNDER:
   1.  ???
*/



includes ExternalFunctionMsg;

module ExternalFunctionM {
  provides {
    interface StdControl;
    interface FunctionExecute;
  }
  uses {
    interface Clock;
    interface Leds;
    interface IntOutput;
    interface StdControl as StdControlComm;
    interface StdControl as StdControlRFM;
    interface StdControl as StdControlOscope;
    interface ReceiveMsg as CommandMsg;
    interface Oscope;
    interface Pot;
    interface Radio;
  }
}
implementation {
  enum {
    ADC              = 1,  //retrieves data from the ADC 
    LOG              = 2,  //tells the node to read the log to the UART
    POWER_MODE       = 3,  //tells the node to go to sleep 
    RADIO_POWER      = 4,  //adjusts the transmission power
    RADIO_JAM        = 5,  //tells the radio to jam, ie constantly send a 1
    SOUNDER          = 6,  //turns the audio sounder on
    CLOCK            = 7   //sets the clock tick rate
  };
  


  uint8_t pending;
  uint8_t sounderLength;
  command_bfr cmd_bfr;
  command_bfr* cmd;	 //store the command so we can execute it in a task 
  
  /**
   * task that processes and executes stored cmd_bfr
   *
   * @return returns <code>void</code>
   **/  
  task void evalCmd() {
    char successful=1; //this flag indicates if the command was successful
    dbg(DBG_USR1, "\n");
    dbg(DBG_USR1, "action=\%d",cmd->action);
    
    switch (cmd_bfr.action) 
      {
      case ADC:       //tells the node to start sensing.
	if(cmd_bfr.args[5] != 0x00)
	  call Oscope.resetSampleCount();
	if(cmd_bfr.args[4] != 0x00) {
	  call Oscope.setBytesPerSample(cmd_bfr.args[4]);
	}
	
	call Oscope.setMaxSamples(cmd_bfr.args[3]);
	call Oscope.setSendType(cmd_bfr.args[2]);
	call Oscope.setDataChannel(cmd_bfr.args[1]);
	if(cmd_bfr.args[0]==0) {
	  call Oscope.deactivate();
	}
	else {
	  call Oscope.activate();
	}
	break;
      case LOG:            //tells the node to read the log to the UART
	break;
      case POWER_MODE:               //tells the node to go to sleep 
	dbg(DBG_USR1, "comm power mode set to \%d", cmd_bfr.args[0]);
	if (cmd_bfr.args[0] == 0) {
	  call StdControlComm.stop();
	  call StdControlRFM.stop();
	}
	else {
	  call StdControlComm.start();
	  call StdControlRFM.start();
	}
	break;
      case RADIO_POWER:     //tells the radio and UART to change power mode
	switch(cmd_bfr.args[0]){
	case 0:
	  dbg(DBG_USR1, "pot DECREMENTED");
	  //the following call to Pot crashes the mote
	  call Pot.decrease();
	  call Leds.redToggle();
	  break;
	case 1:
	  dbg(DBG_USR1, "pot INCREMENTED");
	  //the following call to Pot crashes the mote
	  //call Pot.increase();
	  break;
	case 2:
	  dbg(DBG_USR1, "setting POT to \%d", cmd_bfr.args[1]);
	  //the following call to Pot crashes the mote
	  //call Pot.set(cmd_bfr.args[1]);
	  break;
	}
      case RADIO_JAM:       //adjusts the transmission power
	if(cmd_bfr.args[0]==1){
	  dbg(DBG_USR1, "radio jamming ON");
	  call Radio.txMode();
	  call Radio.txBit(1);
	} else {
	  dbg(DBG_USR1, "radio jamming OFF");
	  call Radio.txBit(0);
	  call Radio.rxMode();
	}
	break;
      case SOUNDER:      
	if(cmd_bfr.args[0]==1){
	  dbg(DBG_USR1, "sounder ON");
	  //SET_PW2_PIN();
	  // needs to be called once Sounder is supported in NESC!!!!!
	} else if(cmd_bfr.args[0]==0){
	  dbg(DBG_USR1, "radio jamming OFF");
	  //CLR_PW2_PIN();
	  // needs to be called once Sounder is supported in NESC!!!!
	} else if(cmd_bfr.args[0]==2){
	  dbg(DBG_USR1, "set Sounder Length");
	    // sounderLength = cmd_bfr.args[1];
	    // needs to be called once Sounder is supported in NESC!!!!
	} else if(cmd_bfr.args[0]==3){
	  dbg(DBG_USR1, "set MICROPHONE GAIN");
	    // TOS_CALL_COMMAND(COMMAND_SET_MIC_GAIN)(VAR(cmd)->args[1]);
	    // needs to be called once Mic is supported in NESC!!!!!!
	}
	  break;
      case CLOCK:
	call Clock.setRate(cmd_bfr.args[0], cmd_bfr.args[1]);    /* set clock interval */
	break;
      }
    
    //if the command was successful, set the LEDS to the specified value
    if(cmd_bfr.action!=0xf0)
      //call IntOutput.output((int8_t)(cmd_bfr.action & 0xffff));
    
    //indicate that a command is no longer executing
    pending = 0;
    //call Leds.redOn();
    
    //signal an event indicating that the command is done, and if it succeeded
    dbg(DBG_USR1, ("Command executed successfully"));
    signal FunctionExecute.functionExecuteDone((String)cmd, SUCCESS);
  }

  /**
   * Initialize Leds, GenericComm, RFM, OSCOPE, Pot.
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.init() {
    call Leds.init();
    call StdControlComm.init();
    call StdControlRFM.init();
    call StdControlOscope.init();
    //call Clock.setRate(32,0x07);
    // Pot value initialized to median value (0 high, 99 low)
    call Pot.init(50);
    pending = 0;
    dbg(DBG_USR1, "COMMAND initialized");
    return SUCCESS;
  }

  /**
   * Start things up. Calls start on sub components, GenericComm, RFM, Oscope
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.start() {
    dbg(DBG_USR1, "COMMAND started");
    call StdControlComm.start();
    call StdControlRFM.start();
    call StdControlOscope.start();
    return SUCCESS;
  }

  /**
   * Halt execution of the application.
   * calls stop methods of GenericComm, RFM, Oscope
   * 
   * @return Always returns <code>SUCCESS</code>
   **/
  command result_t StdControl.stop() {
    dbg(DBG_USR1, "COMMAND stopped");
    call StdControlComm.stop();
    call StdControlRFM.stop();
    call StdControlOscope.stop();
    return SUCCESS;
  }

  /**
   * Process the data portion of the message received from the <code>CommandMsg.receive</code> event.  
   *
   * @return pointer received (msg)
   **/
  event TOS_MsgPtr CommandMsg.receive(TOS_MsgPtr msg) {
    call Leds.greenToggle();
    if (call FunctionExecute.execute((String)msg->data)) {
      return msg;
    } 
    else {
      return msg;
    }
  }

  /**
   * scmd is going to be used as a cmd_bfr*
   * processes the cmd_bfr* if no other command is currently being processed or executing
   * 
   * @return returns <code>SUCCESS</code> if cmd_bfr is accepted, <code>FAIL</code> otherwise
   **/
  command result_t FunctionExecute.execute(String scmd) {
    if (pending) {
      return FAIL;
    }
    pending = 1;
    cmd = (command_bfr*)scmd;
    cmd_bfr = *cmd;
    post evalCmd();
    return SUCCESS;
  }
  
  
  /**
   * Default handler for <code>FunctionExecute.functionExecuteDone</code> event
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  default event result_t FunctionExecute.functionExecuteDone(String scmd, result_t success) {
    return SUCCESS;
  }
    
  
  /**
   * Handler for the <code>Radio.txBitDone</code> event
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Radio.txBitDone() {
    return SUCCESS;
  }
    

  /**
   * Handler for the <code>Radio.rxBitDone</code> event
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Radio.rxBit(uint8_t bit) {
    return SUCCESS;
  }

  /**
   * Handler for the <code>Clock.fire</code> event
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t Clock.fire() {
    return SUCCESS;
  }

  /**
   * Handler for the <code>IntOutput.outputComplete</code> event
   *
   * @return Always returns <code>SUCCESS</code>
   **/
  event result_t IntOutput.outputComplete(result_t success) {
    return success;
  }
  
}  










