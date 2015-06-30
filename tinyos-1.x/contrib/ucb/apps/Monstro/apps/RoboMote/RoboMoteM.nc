// $Id: RoboMoteM.nc,v 1.6 2005/07/14 20:21:56 shawns Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * @author Shawn Schaffert
 */

/* Based on RoboMote by John Breneman */

/* This software is intended to be installed on a Telos (rev B) mote connected
 * to the motor controllers of the Monstro robotic platform.
 * This code provides support to enable/disable the motors, adjust the
 * trim, invoke movement, and adjust the safety "keep alive" timer.
 * Also, note that the trim values are saved
 * to flash which will persist across reboots -- but not programmings.
 * Additionally, after a reboot, the motors will be disabled and will
 * not be enabled until the mote receives both an "enable motors" message
 * and a "set movement" message.  All messages are sent/received over
 * the UART for RoboMote and over both UART and radio for the RoboMoteGenericComm.
 */


includes RoboMote; 
includes Messages;



module RoboMoteM {
  provides interface StdControl;
  uses interface StdControl as PWMControl;
  uses interface ReceiveMsg as ReceiveMotorQueryMsg;
  uses interface ReceiveMsg as ReceiveMotorMovementMsg;
  uses interface ReceiveMsg as ReceiveMotorTrimMsg;
  uses interface ReceiveMsg as ReceiveMotorStateMsg;
  uses interface ReceiveMsg as ReceiveMotorKeepAliveMsg;
  uses interface SendMsg as SendMotorMovementMsg;
  uses interface SendMsg as SendMotorTrimMsg;
  uses interface SendMsg as SendMotorStateMsg;
  uses interface Timer as LEDTimer;
  uses interface Timer as KeepAliveTimer;
  uses interface TelosPWM as PWM;
  uses interface Leds;
  uses interface InternalFlash;
}



implementation {


  TOS_Msg motorMovementMsg;
  TOS_Msg motorTrimMsg;
  TOS_Msg motorStateMsg;
  TOS_Msg motorKeepAliveMsg;
  TOS_Msg outgoingMsg;
  MotorMovement_t motorMovement;
  MotorTrim_t motorTrim;
  MotorState_t motorState;
  MotorKeepAlive_t motorKeepAlive;
  bool motorMovementIsSet;
  bool pwmStarted;
  bool sendPending;



  event result_t SendMotorMovementMsg.sendDone( TOS_MsgPtr msgSentPtr , result_t success ) {
    if( msgSentPtr == &outgoingMsg) {
      sendPending = FALSE;
    }
    return SUCCESS;
  }



  event result_t SendMotorTrimMsg.sendDone( TOS_MsgPtr msgSentPtr , result_t success ) {
    if( msgSentPtr == &outgoingMsg) {
      sendPending = FALSE;
    }
    return SUCCESS;
  }



  event result_t SendMotorStateMsg.sendDone( TOS_MsgPtr msgSentPtr , result_t success ) {
    if( msgSentPtr == &outgoingMsg) {
      sendPending = FALSE;
    }
    return SUCCESS;
  }




  /* **************************************************
   * Init the mote -- everything is assumed to be in
   * the disabled/off state
   * ************************************************** */
  command result_t StdControl.init() {
    call Leds.init();
    call PWMControl.init();
    motorMovementIsSet = FALSE;
    motorState.motorState = MOTORSTATE_DISABLED;
    pwmStarted = FALSE;
    sendPending = FALSE;

    motorKeepAlive.stayAliveMillis = KEEP_ALIVE_TIMER_PERIOD_DEFAULT;
    motorMovement.turnA = 0;
    motorMovement.turnB = 0;
    motorMovement.speedA = 0;
    motorMovement.speedB = 0;

    return SUCCESS;
  }




  /* **************************************************
   * Start the mote -- read the motor trim values from
   * the flash if possible
   * ************************************************** */
  command result_t StdControl.start() {

    // start a timer for flashing LEDs
    call LEDTimer.start(TIMER_REPEAT, LED_TIMER_PERIOD);

    // start a timer for killing the motors if we do not receive any messages for a while
    call KeepAliveTimer.start(TIMER_ONE_SHOT, motorKeepAlive.stayAliveMillis);
    //call KeepAliveTimer.start(TIMER_REPEAT, motorKeepAlive.stayAliveMillis);
    
    // initialize the trim state with previous trim values saved in the flash -- or default values
    if ( (call InternalFlash.read( (int8_t*)INTERNAL_FLASH_ADDR , &motorTrim , sizeof(motorTrim) )) != SUCCESS ) {
      motorTrim.speedATrim = 0;
      motorTrim.speedBTrim = 0;
      motorTrim.turnATrim = 0;
      motorTrim.turnBTrim = 0;
    }
    return SUCCESS;
  }


 

  /* **************************************************
   * Stop the mote -- motors/PWMs need to be shutdown
   * ************************************************** */
  command result_t StdControl.stop() {
    call LEDTimer.stop();
    call KeepAliveTimer.stop();
    call PWMControl.stop();
    pwmStarted = FALSE;
    motorMovementIsSet = FALSE;
    motorState.motorState = MOTORSTATE_DISABLED;
    return SUCCESS;
  }




 
  /* **************************************************
   * actuate/manage the PWM signals to reflect the 
   * current motor state
   * ************************************************** */
  task void actuate() {

    atomic {

      // Before any actuation can occur (or even starting the
      // PWMs up), we must have received a motorMovement message
      if( motorMovementIsSet ) {

	// Futhermore, the motors must be in the enabled state
	// to start/continue actuation
	if( motorState.motorState == MOTORSTATE_ENABLED ) {
	  int8_t turnA = motorMovement.turnA;
	  int8_t turnB = motorMovement.turnB;
	  int8_t speedA = motorMovement.speedA;
	  int8_t speedB = motorMovement.speedB;
	  
	  if(!pwmStarted) {
	    call PWMControl.start();
	    call PWM.setFreq( 17476 ); // 60 Hz
	    pwmStarted = TRUE;
	    call Leds.redOn();
	  }
	  
	  call PWM.setHigh1( 2*(turnA+128) + 1537 + motorTrim.turnATrim );
	  call PWM.setHigh2( 2*(127-turnB) + 1537 + motorTrim.turnBTrim );
	  call PWM.setHigh3( 2*(speedA+128) + 1537 + motorTrim.speedATrim );
	  call PWM.setHigh0( 2*(127-speedB) + 1537 + motorTrim.speedBTrim );
	  
	  
	  // Futhermore, if the motors are disabled, we may need to
	  // shut the PWMs down
	} else if( (motorState.motorState == MOTORSTATE_DISABLED) && pwmStarted ) {
	  call PWMControl.stop();
	  pwmStarted = FALSE;
	  call Leds.redOff();
	}
      }
    }
  }




  /* **************************************************
   * reset the keep alive timer
   * ************************************************** */
  void resetKeepAliveTimer() { 

    // stop the keep alive timer
    call KeepAliveTimer.stop();
    call Leds.greenOff();

    // restart the keep alive timer
    call KeepAliveTimer.start(TIMER_ONE_SHOT, motorKeepAlive.stayAliveMillis);
  }




  /* **************************************************
   * Receive Keep Alive Messages and reset the keep
   * alive timer
   * ************************************************** */
  event TOS_MsgPtr ReceiveMotorKeepAliveMsg.receive( TOS_MsgPtr msgPtr ) {

    TOS_MsgPtr oldMsgPtr;
    MotorKeepAlive_t* newKeepAliveMsgPtr;

    // check to see if it is a 0 valued keep alive -- meaning reset the timer, but keep the same period as before
    newKeepAliveMsgPtr = (MotorKeepAlive_t*)msgPtr->data;
    if( (newKeepAliveMsgPtr->stayAliveMillis) != 0 ) {

      // swap the old/new TOS_Msg buffers
      oldMsgPtr = &motorKeepAliveMsg;
      motorKeepAliveMsg = (TOS_Msg) *msgPtr;
      msgPtr = oldMsgPtr;

      // change the keep alive timer's value
      motorKeepAlive = *((MotorKeepAlive_t*) motorKeepAliveMsg.data);
    }

    // reset the keep alive timer
    resetKeepAliveTimer();

    // recycle the old TOS_Msg buffer
    return msgPtr;
  }




  /* **************************************************
   * Receive Motor Query Messages and send the requested
   * info
   * ************************************************** */
  event TOS_MsgPtr ReceiveMotorQueryMsg.receive( TOS_MsgPtr msg ) {

    MotorQuery_t* queryMsgPtr;

    // reset the keep alive timer
    resetKeepAliveTimer();

    queryMsgPtr = (MotorQuery_t*)msg->data;

    if( !sendPending ) {

      if( queryMsgPtr->type == MOTORQUERY_STATE ) {
	*((MotorState_t*) outgoingMsg.data) = motorState;
	if( call SendMotorStateMsg.send( TOS_UART_ADDR , sizeof( motorState ) , &outgoingMsg ) ) {
	  sendPending = TRUE;
	}

      } else if( queryMsgPtr->type == MOTORQUERY_TRIM ) {
	*((MotorTrim_t*) outgoingMsg.data) = motorTrim;
	if( call SendMotorTrimMsg.send( TOS_UART_ADDR , sizeof( motorTrim ) , &outgoingMsg ) )
	  sendPending = TRUE;

      } else if( queryMsgPtr->type == MOTORQUERY_MOVEMENT ) {
	*((MotorMovement_t*) outgoingMsg.data) = motorMovement;
	if( call SendMotorMovementMsg.send( TOS_UART_ADDR , sizeof( motorMovement ) , &outgoingMsg ) )
	  sendPending = TRUE;
      }
    }

    return msg;
  }




  /* **************************************************
   * Receive Motor Trim Messages, reset our trim state,
   * and write this new trim value to the flash
   * ************************************************** */
  event TOS_MsgPtr ReceiveMotorTrimMsg.receive( TOS_MsgPtr msgPtr ) {

    TOS_MsgPtr oldMsgPtr;

    // reset the keep alive timer
    resetKeepAliveTimer();

    // swap the old/new TOS_Msg buffers
    oldMsgPtr = &motorTrimMsg;
    motorTrimMsg = (TOS_Msg) *msgPtr;
    msgPtr = oldMsgPtr;

    // update the trim state
    motorTrim = *((MotorTrim_t*) motorTrimMsg.data);

    // write the new trim values to flash
    call InternalFlash.write( (uint16_t*)INTERNAL_FLASH_ADDR , &motorTrim , sizeof(motorTrim) );

    // recycle the old TOS_Msg
    return msgPtr;
  }




  /* **************************************************
   * Receive Motor State Messages and update the motor
   * state
   * ************************************************** */
  event TOS_MsgPtr ReceiveMotorStateMsg.receive( TOS_MsgPtr msgPtr ) {

    TOS_MsgPtr oldMsgPtr;

    // reset the keep alive timer
    resetKeepAliveTimer();

    // swap the old/new TOS_Msg buffers
    oldMsgPtr = &motorStateMsg;
    motorStateMsg = (TOS_Msg) *msgPtr;
    msgPtr = oldMsgPtr;

    // update the motor state
    motorState = *((MotorState_t*) motorStateMsg.data);

    // actuate the motors
    post actuate();

    // recycle the old TOS_Msg
    return msgPtr;
  }




  /* **************************************************
   * Receive Motor Movement Messages and reset motor
   * movement state
   * ************************************************** */
  event TOS_MsgPtr ReceiveMotorMovementMsg.receive( TOS_MsgPtr msgPtr ) {

    TOS_MsgPtr oldMsgPtr;

    // reset the keep alive timer
    resetKeepAliveTimer();

    // swap the old/new TOS_Msg buffers
    oldMsgPtr = &motorMovementMsg;
    motorMovementMsg = (TOS_Msg) *msgPtr;
    msgPtr = oldMsgPtr;

    // update the motor movement state
    motorMovement = *((MotorMovement_t*)motorMovementMsg.data);
    motorMovementIsSet = TRUE;

    // actuate the motors
    post actuate();

    // recycle the old TOS_Msg buffer
    return msgPtr;
  }



  
  /* **************************************************
   * Upon led timer firing, toggle some LEDS to indicate
   * the mote status
   * ************************************************** */
  event result_t LEDTimer.fired() {
    call Leds.yellowToggle();  //mote is alive
    return SUCCESS;
  }




  /* **************************************************
   * Upon keep alive timer firing, stop the motors
   * ************************************************** */
  event result_t KeepAliveTimer.fired() {

    // set the motor state to disabled
    motorState.motorState = MOTORSTATE_DISABLED;

    // disable the motors
    post actuate();

    // turn on the green LED to indicated that the safety mechanism has been enabled
    call Leds.greenOn();

    return SUCCESS;
  }

  
}
