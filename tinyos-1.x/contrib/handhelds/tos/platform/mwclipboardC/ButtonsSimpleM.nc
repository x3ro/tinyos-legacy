/*
 * Copyright (c) 2005 Hewlett-Packard Company
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:

 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of the Hewlett-Packard Company nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.

 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors:             Brian Avery
 * This is an implementation of the Button module.
 */

// for size reasons we will now only support one button hit at a time

module ButtonsSimpleM {
  provides 
    {
      interface Buttons;
    }
  
  uses 
    {
      interface Timer as Timer0;
      interface Leds;
      interface LCD; // debugging only XXX
      

      interface MSP430Interrupt as Button0Interrupt;
      interface MSP430Interrupt as Button1Interrupt;
      interface MSP430Interrupt as Button2Interrupt;
      interface MSP430Interrupt as Button3Interrupt;
    }
  
}

implementation {
#define BUTTON0 0x01
#define BUTTON1 0x02
#define BUTTON2 0x04
#define BUTTON3 0x08

  enum interruptState
    {
      INTERRUPT_OFF=-1,
      INTERRUPT_UPEDGE=TRUE,
      INTERRUPT_DOWNEDGE=FALSE
    };
  
  
#define DEBOUNCE_DELAY 40
#define AR_DELAY 250

#define NUM_BUTTONS 4
int gActiveButton = -1;

  enum state 
    {
      WAIT_FOR_BDOWN = 1, // idle 
      BDOWN_HIT,          // we got a hit
      WAIT_FOR_DEBOUNCE_DOWN, // waiting for the debounce down to occur
      WAIT_FOR_AR,            // waiting for the ar timer to timeout or a button to get released
      BUP_FAST,		      // a button was released before the ar timer was set
      AR,		      // got an autorepeat
      BUP_SLOW,		      // button reeased after the ar timer has started running
      WAIT_FOR_DEBOUNCE_UP,   // button released wait for debounce to reenable
      ENABLE_BDOWN_INT        // reenable the down interrupts and wait till it starts again
    };


  uint8_t gButtonState;
  bool gButtonsEnabled;
  bool autoRepeat;  
  uint8_t LastButtonMask;
  bool LastAutoRepeat;

  //#define DEBUG_BUTTONS
#undef  DEBUG_BUTTONS  
  
#ifdef DEBUG_BUTTONS
#define BUTTON_ERROR(s,i ) {Error(s,i);}
#else
#define BUTTON_ERROR(s,i) {}  
#endif //DEBUG_BUTTONS  

#ifdef DEBUG_BUTTONS
  
  void Error(char *s,int e)
    {
      char buf[128];
      Point p = {2,100};
      volatile int hold;

      call LCD.clear();
      sprintf(buf,"%s:%d",s,e);	
      for (hold = 1; hold < 100; hold++)
	call LCD.gf_draw_string(buf,FONT_HELVETICA_R_12,&p,GF_OR);
    }
  
#endif //DEBUG_BUTTONS  

  /* interrupt state is:
   * -1 off,
   *  FALSE Downedge
   * TRUE upedge
   */  
  void controlInterrupts(int whichButton,enum interruptState state)
    {
      switch (whichButton){
      case BUTTON0:
	call Button0Interrupt.disable();
	call Button0Interrupt.clear();
	if (state >= 0){	  
	  call Button0Interrupt.edge(state);
	  call Button0Interrupt.enable();
	}	
	break;
      case BUTTON1:
	call Button1Interrupt.disable();
	call Button1Interrupt.clear();
	if (state >= 0){	  
	  call Button1Interrupt.edge(state);
	  call Button1Interrupt.enable();
	}	
	break;
      case BUTTON2:
	call Button2Interrupt.disable();
	call Button2Interrupt.clear();
	if (state >= 0){	  
	  call Button2Interrupt.edge(state);
	  call Button2Interrupt.enable();
	}	
	break;
      case BUTTON3:
	call Button3Interrupt.disable();
	call Button3Interrupt.clear();
	if (state >= 0){	  
	  call Button3Interrupt.edge(state);
	  call Button3Interrupt.enable();
	}	
	break;
      }
    }

  void allInterruptsOff()
    {
      controlInterrupts(BUTTON0,INTERRUPT_OFF);
      controlInterrupts(BUTTON1,INTERRUPT_OFF);
      controlInterrupts(BUTTON2,INTERRUPT_OFF);
      controlInterrupts(BUTTON3,INTERRUPT_OFF);
    }
  void allInterruptsOn(enum interruptState state)
    {
      controlInterrupts(BUTTON0,state);
      controlInterrupts(BUTTON1,state);
      controlInterrupts(BUTTON2,state);
      controlInterrupts(BUTTON3,state);
    }
  
      
  
  async command result_t Buttons.enable(){
    // set buttons to a falling edge interrupt -- gives mousedown
    
    atomic 
      {
	
	gButtonsEnabled = TRUE;
	LastAutoRepeat = FALSE;	
	gButtonState = WAIT_FOR_BDOWN;
      }
    allInterruptsOn(INTERRUPT_DOWNEDGE);
    return SUCCESS;
  }
  


  async command result_t Buttons.disable(){
    atomic {
      gButtonsEnabled = FALSE;
    }
    return SUCCESS;
  }

  // ony allowing 1 button down at a time for size reasons
  uint8_t getCurrentState()
    {
      uint8_t buttonData = 0x0;
      buttonData |= (TOSH_READ_BUTTON1_PIN()?0:BUTTON0);
      buttonData |= (TOSH_READ_BUTTON2_PIN()?0:BUTTON1);
      buttonData |= (TOSH_READ_BUTTON3_PIN()?0:BUTTON2);
      buttonData |= (TOSH_READ_BUTTON4_PIN()?0:BUTTON3);
      return buttonData;
    }
  
  

  void startTimer(int when)
    {
      result_t res = SUCCESS;

      res = call Timer0.start(TIMER_ONE_SHOT, when);	  
      if (res != SUCCESS)
	BUTTON_ERROR("Bad Timer Start",when);      
    }

  void stopTimer()
    {
      call Timer0.stop();
    }
  



  
  task void handleButtonChange()
    {
      int state;
      int activeButton;
      
      atomic 
	{
	  state = gButtonState;
	  activeButton = gActiveButton;	  
	}
      switch (state)
	{
	case BDOWN_HIT:
	  startTimer(DEBOUNCE_DELAY);
	  atomic
	    gButtonState = WAIT_FOR_DEBOUNCE_DOWN;
	  signal Buttons.down(activeButton,FALSE);
	  break;	  
	case BUP_SLOW:
	case BUP_FAST:
	  stopTimer();
	  atomic
	    gActiveButton=-1;
	  startTimer(DEBOUNCE_DELAY);
	  atomic
	    gButtonState = WAIT_FOR_DEBOUNCE_UP;
	  signal Buttons.up(activeButton);
	  break;
	case WAIT_FOR_AR:
	  //BUTTON_ERROR("hBC got to WFA:",state);
	  startTimer(AR_DELAY);
	  break;
	case AR:
	  signal Buttons.down(activeButton,TRUE);
	  startTimer(AR_DELAY);
	  atomic
	    gButtonState = WAIT_FOR_AR;
	  break;
	case WAIT_FOR_BDOWN:
	  atomic
	    gActiveButton=-1;
	  break;
	case WAIT_FOR_DEBOUNCE_UP:
	  // this is an error but i dont see it right now and its pretty harmless.
	  //find me later!!!
	  break;	  
	default:
	  BUTTON_ERROR("hBC bad state:",state);
	  
	  break;
	}
    }
  
  
  // called from interrupt context
  void handleTimerFired()
    {
      int state;
      int activeButton;      
      uint8_t buttonsDown = getCurrentState();

      atomic
	{
	  state = gButtonState;
	  activeButton = gActiveButton;	  
	}
      switch (state){	  
      case WAIT_FOR_DEBOUNCE_DOWN:
#if 0
	BUTTON_ERROR("hTF buttonsDown",buttonsDown);
	BUTTON_ERROR("hTF activeButton",activeButton);
#endif

	if (buttonsDown & activeButton){	    
	  atomic
	    gButtonState = WAIT_FOR_AR;
	  // enable interrupts for button up
	  controlInterrupts(activeButton,INTERRUPT_UPEDGE);	  
	}
	else{	
	  atomic 
	    gButtonState = BUP_FAST;
	}
	break;      
      case WAIT_FOR_DEBOUNCE_UP:
	if (buttonsDown){
	  // weve debounced and a button is pressed, so do it
	  // button is still released
	  atomic
	    {	      
	      gButtonState = BDOWN_HIT;
	      gActiveButton = buttonsDown;
	    }
	}
	else{
	  // buttons still released 
	  // enable interrupts for button down
	  allInterruptsOn(INTERRUPT_DOWNEDGE);
	  atomic
	    gButtonState = WAIT_FOR_BDOWN;
	}	

	break;
      case WAIT_FOR_AR:
	if (buttonsDown & activeButton){
	  atomic
	    gButtonState = AR;	
	}
	else{
	  allInterruptsOn(INTERRUPT_DOWNEDGE);
	  atomic
	    gButtonState = WAIT_FOR_BDOWN;
	}
	break;
      default:
	break;
      }
    }
  
  
  
  
  
  
  /**
   * when timer for button0
   *
   * @return Always returns <code>SUCCESS</code>
   **/


  event result_t Timer0.fired()
    {
      handleTimerFired();    
      post handleButtonChange();    
      return SUCCESS;
    }
  
  // called from interrupt context
  void handleInterruptFired(int which)
    {
      int state;      

      state = gButtonState;	  

      switch (state){
      case WAIT_FOR_BDOWN:
	gActiveButton = which;
	gButtonState = BDOWN_HIT;	
	break;
      case WAIT_FOR_AR:
      case AR:
	// this should be a button up interrupt
	if (gActiveButton != which)
	  BUTTON_ERROR("Bad Int in WAIT_AR",which);
	gButtonState = BUP_SLOW;
	break;	
      default:
	break;
      }
      post handleButtonChange();
    }
  

  async event void Button0Interrupt.fired() {
    // no more interrupts till they are reenebled
    allInterruptsOff();    
    handleInterruptFired(BUTTON0);    
  }

  async event void Button1Interrupt.fired() {
    // no more interrupts till they are reenebled
    allInterruptsOff();    
    handleInterruptFired(BUTTON1);    
  }
  async event void Button2Interrupt.fired() {
    // no more interrupts till they are reenebled
    allInterruptsOff();    
    handleInterruptFired(BUTTON2);    
  }
  async event void Button3Interrupt.fired() {
    // no more interrupts till they are reenebled
    allInterruptsOff();    
    handleInterruptFired(BUTTON3);    
  }




      
}
  
  



