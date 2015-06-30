/*
 * @(#)COMMAND.c
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
 * Histroy:  Created: a long time ago to work with Bcast
 *           2/10/02: Kamin modified it to be an independant shared component
 *                    that could do more things.  It is now meant to be 
 *                    a standard component that goes along with the new 
 *                    generic_comm, allowing any node to store data on command
 *                    and then be put onto a programming board and have the 
 *                    data read out of the log.  Commands can be multi-hopped 
 *                    to the node or just fed in through the UART
 *
 * This component demonstrates a simple message interpreter. The component is
 * accessed through the command interface; when the command is finished
 * executing, the component signals the upper layers with the message buffer
 * and the status indicating whether the message should be further processed. 
 * 
 * $\Id$
 */


/**** always include command_format.h if you want to send a command to this component ****/

#include "tos.h"
#include "dbg.h"
#include "command_format.h"
#include "COMMAND.h"


#define ADC               1   //retrieves data from the ADC 
#define LOG               2   //tells the node to read the log to the UART
#define POWER_MODE        3   //tells the node to go to sleep 
#define RADIO_POWER       4   //adjusts the transmission power
#define RADIO_JAM         5   //tells the radio to jam, ie constantly send a 1
#define SOUNDER           6  //turns the audio sounder on
#define CLOCK             7  //sets the clock tick rate


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



// Since the commands are executed within a task, the local state needs to 
// store the command

#define TOS_FRAME_TYPE COMMAND_obj_frame
TOS_FRAME_BEGIN(COMMAND_obj_frame) {
  command_bfr cmd_bfr;
  command_bfr* cmd;	 //store the command so we can execute it in a task 
  char pending;          //indicates whether a command is being executed now
}
TOS_FRAME_END(COMMAND_obj_frame);


// Task for evaluating the command. At the end of the task, signal 
// a command_done event, indicat with a fail or succeed flag
TOS_TASK(eval_cmd) {
  char successful=1; //this flag indicates if the command was successful
  dbg(DBG_USR1, ("\n"));
  dbg(DBG_USR1, ("action=\%d",VAR(cmd)->action));
  
  switch (VAR(cmd)->action) 
    {
    case ADC:       //tells the node to start sensing.
      if(VAR(cmd)->arg[5] != 0x00)
	TOS_CALL_COMMAND(COMMAND_OSCOPE_RESET_SAMPLE_COUNT)();
      if(VAR(cmd)->arg[4] != 0x00)
	TOS_CALL_COMMAND(COMMAND_OSCOPE_SET_BYTES_PER_SAMPLE)(VAR(cmd)->arg[4]);
      TOS_CALL_COMMAND(COMMAND_OSCOPE_SET_MAX_SAMPLES)(VAR(cmd)->arg[3]);
      TOS_CALL_COMMAND(COMMAND_OSCOPE_SET_SEND_TYPE)(VAR(cmd)->arg[2]);
      TOS_CALL_COMMAND(COMMAND_OSCOPE_SET_DATA_CHANNEL)(VAR(cmd)->arg[1]);
      if(VAR(cmd)->arg[0]==0)
	TOS_CALL_COMMAND(COMMAND_STOP_SENSING)();
      else
	TOS_CALL_COMMAND(COMMAND_START_SENSING)();
      break;
    case LOG:            //tells the node to read the log to the UART
      break;
    case POWER_MODE:               //tells the node to go to sleep 
      dbg(DBG_USR1, ("comm power mode set to \%d", VAR(cmd)->arg[0]));
      TOS_CALL_COMMAND(COMMAND_SET_COMM_POWER_MODE)(VAR(cmd)->arg[0]);
      break;
    case RADIO_POWER:     //tells the radio and UART to change power mode
      switch(VAR(cmd)->arg[0]){
      case 0:
	dbg(DBG_USR1, ("pot DECREMENTED"));
	TOS_CALL_COMMAND(COMMAND_POT_DEC)();
	break;
      case 1:
	dbg(DBG_USR1, ("pot INCREMENTED"));
	TOS_CALL_COMMAND(COMMAND_POT_INC)();
	break;
      case 2:
	dbg(DBG_USR1, ("setting POT to \%d", VAR(cmd)->arg[1]));
	TOS_CALL_COMMAND(COMMAND_SET_POT)(VAR(cmd)->arg[1]);
	break;
      }
    case RADIO_JAM:       //adjusts the transmission power
      if(VAR(cmd)->arg[0]==1){
	dbg(DBG_USR1, ("radio jamming ON"));
	//	TOS_CALL_COMMAND(COMMAND_SET_TX_MODE)();
	//	TOS_CALL_COMMAND(COMMAND_SET_TX_BIT)(1);
      } else {
	dbg(DBG_USR1, ("radio jamming OFF"));
	//	TOS_CALL_COMMAND(COMMAND_SET_TX_BIT)(0);
	//	TOS_CALL_COMMAND(COMMAND_SET_RX_MODE)();
      }
      break;
    case SOUNDER:      
      if(VAR(cmd)->arg[0]==1){
	dbg(DBG_USR1, ("sounder ON"));
	  SET_PW2_PIN();
      } else if(VAR(cmd)->arg[0]==0){
	dbg(DBG_USR1, ("radio jamming OFF"));
	    CLR_PW2_PIN();
      } else if(VAR(cmd)->arg[0]==2){
	dbg(DBG_USR1, ("set Sounder Length"));
	//	    sounderLength = VAR(cmd)->arg[1];
      } else if(VAR(cmd)->arg[0]==3){
	dbg(DBG_USR1, ("set MICROPHONE GAIN"));
	//	    TOS_CALL_COMMAND(COMMAND_SET_MIC_GAIN)(VAR(cmd)->arg[1]);
      }
      break;
    case CLOCK:
      TOS_CALL_COMMAND(COMMAND_CLOCK_INIT)(VAR(cmd)->arg[0],VAR(cmd)->arg[1]);    /* set clock interval */
      break;
    }
  
  //if the command was successful, set the LEDS to the specified value
  if(VAR(cmd)->leds!=0xf0)
     TOS_CALL_COMMAND(COMMAND_SET_LEDS)((short)(VAR(cmd)->leds & 0xffff));
  
  //indicate that a command is no longer executing
  VAR(pending) = 0;
  //TOS_CALL_COMMAND(COMMAND_RED_LED_OFF)();

  //signal an event indicating that the command is done, and if it succeeded
  dbg(DBG_USR1, ("Command executed successfully"));
  TOS_SIGNAL_EVENT(COMMAND_DONE)((char*)VAR(cmd), successful);
}

char TOS_COMMAND(COMMAND_INIT) () {
  VAR(pending) = 0;
  dbg(DBG_USR1, ("COMMAND initialized"));
  //TOS_CALL_COMMAND(COMMAND_SUB_INIT)();
  return 1;
}


char TOS_COMMAND(COMMAND_START)(){
  dbg(DBG_USR1, ("COMMAND started"));
  return 1;
}



TOS_MsgPtr TOS_MSG_EVENT(COMMAND_MSG)(TOS_MsgPtr msg) {
  if(TOS_CALL_COMMAND(COMMAND_EXECUTE)((char*)msg->data)) {
    return msg;
  } else {
    return msg;
  }
}


char TOS_EVENT(COMMAND_SEND_DONE) (TOS_MsgPtr msg) {
    return 1;
} 


//if you want to send COMMAND commands from another component, use the 
//following two functions

char TOS_COMMAND(COMMAND_EXECUTE)(char* cmd) {
    if (VAR(pending)) {
	return 0;
    }
    VAR(pending) = 1;
    //    TOS_CALL_COMMAND(COMMAND_RED_LED_ON)();
    VAR(cmd) = (command_bfr*)cmd;
    VAR(cmd_bfr) = *(VAR(cmd));
    TOS_POST_TASK(eval_cmd);
    return 1;
}

char TOS_EVENT(COMMAND_CMD_DONE) (char* cmd, char success) {
  return success;
} 


















