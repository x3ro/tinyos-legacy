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

module ButtonsM {
  provides 
    {
      interface Buttons;
    }
  
  uses 
    {
      interface Timer as Timer0;
      interface Timer as Timer1;
      interface Timer as Timer2;
      interface Timer as Timer3;
      interface Leds;
      interface LCD; // debugging only XXX
      

      interface MSP430Interrupt as Button0Interrupt;
      interface MSP430Interrupt as Button1Interrupt;
      interface MSP430Interrupt as Button2Interrupt;
      interface MSP430Interrupt as Button3Interrupt;
    }
  
}

implementation {
#define BUTTON0 0
#define BUTTON1 1
#define BUTTON2 2
#define BUTTON3 3

  
  
#define DEBOUNCE_DELAY 30
#define INITIAL_AR_DELAY 250
#define CONTINUOUS_AR_DELAY 250
#define NUM_BUTTONS 4
  enum state 
    {
      WAIT_FOR_BDOWN = 1,
      BDOWN_HIT,
      WAIT_FOR_DEBOUNCE_DOWN,
      WAIT_FOR_AR1,
      WAIT_FOR_AR2,
      BUP_FAST,
      AR1,
      AR2,
      BUP_SLOW,
      WAIT_FOR_DEBOUNCE_UP,
      ENABLE_BDOWN_INT
    };

  enum errors 
    {
      BAD_BUTTON_INT = 1,
      BAD_BUTTON_CHANGE,
      BAD_BUTTON_AR,
      BAD_TIMERSTART,
      BAD_TIMERSTOP,
      BAD_BUTTONENABLE,
      BAD_HANDLE_STATE_CALL
      
    };


  uint8_t buttonState[NUM_BUTTONS];
  uint8_t buttonMaskUp;
  uint8_t buttonMaskDown;
  
  


  

  bool ButtonsEnabled;
  bool autoRepeat;  
  uint8_t LastButtonMask;
  bool LastAutoRepeat;
  uint16_t autoRepeatRateInitial;
  uint16_t autoRepeatRateContinuous;
  uint8_t autoRepeatRateInitialDiv;
  uint8_t autoRepeatRateContinuousDiv;

  
  //counters for test
  uint8_t initialARCtr0;
  uint8_t continuousARCtr0;
  uint8_t initialARCtr1;
  uint8_t continuousARCtr1;
  uint8_t initialARCtr2;
  uint8_t continuousARCtr2;
  uint8_t initialARCtr3;
  uint8_t continuousARCtr3;

  enum interruptState
    {
      INTERRUPT_OFF=-1,
      INTERRUPT_UPEDGE=TRUE,
      INTERRUPT_DOWNEDGE=FALSE
    };
  

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
  
  

  async command result_t Buttons.enable(){
    // set buttons to a falling edge interrupt -- gives mousedown
    
    atomic 
      {
	
	ButtonsEnabled = TRUE;
	LastAutoRepeat = FALSE;	
	autoRepeatRateInitial = INITIAL_AR_DELAY;
	autoRepeatRateContinuous = CONTINUOUS_AR_DELAY;
	autoRepeatRateInitialDiv = 1;
	autoRepeatRateContinuousDiv = 1;

	initialARCtr0=1;
	continuousARCtr0=1;
	initialARCtr1=1;
	continuousARCtr1=1;
	initialARCtr2=1;
	continuousARCtr2=1;
	initialARCtr3=1;
	continuousARCtr3=1;

	buttonMaskUp = 0x0;
	buttonMaskDown = 0x0;
	buttonState[BUTTON0] = WAIT_FOR_BDOWN;
	buttonState[BUTTON1] = WAIT_FOR_BDOWN;
	buttonState[BUTTON2] = WAIT_FOR_BDOWN;
	buttonState[BUTTON3] = WAIT_FOR_BDOWN;		
      }
    
    controlInterrupts(BUTTON0,INTERRUPT_DOWNEDGE);
    controlInterrupts(BUTTON1,INTERRUPT_DOWNEDGE);
    controlInterrupts(BUTTON2,INTERRUPT_DOWNEDGE);
    controlInterrupts(BUTTON3,INTERRUPT_DOWNEDGE);

    return SUCCESS;
  }
  


  async command result_t Buttons.disable(){
    atomic {
      ButtonsEnabled = FALSE;
      controlInterrupts(BUTTON0,INTERRUPT_OFF);
      controlInterrupts(BUTTON1,INTERRUPT_OFF);
      controlInterrupts(BUTTON2,INTERRUPT_OFF);
      controlInterrupts(BUTTON3,INTERRUPT_OFF);
    }
    return SUCCESS;
  }


  uint8_t getCurrentState()
    {
      uint8_t buttonData = 0x0;

      

      buttonData = (TOSH_READ_BUTTON1_PIN()?0:1);
      buttonData |= (TOSH_READ_BUTTON2_PIN()?0:2);
      buttonData |= (TOSH_READ_BUTTON3_PIN()?0:4);
      buttonData |= (TOSH_READ_BUTTON4_PIN()?0:8);

      return buttonData;
    }
  
  
  void startTimer(int which,int when)
    {
      result_t res = SUCCESS;
#if 0
    if (TOSH_READ_ADC_2_PIN())
      TOSH_CLR_ADC_2_PIN();
    else
      TOSH_SET_ADC_2_PIN();
#endif

      switch(which){	
      case BUTTON0:
	res = call Timer0.start(TIMER_ONE_SHOT, when);	  
	break;
      case BUTTON1:
	res = call Timer1.start(TIMER_ONE_SHOT, when);	  
	break;
      case BUTTON2:
	res = call Timer2.start(TIMER_ONE_SHOT, when);	  
	break;
      case BUTTON3:
	res = call Timer3.start(TIMER_ONE_SHOT, when);	  
	break;
      }
    }

  void stopTimer(int which)
    {
      switch(which){
      case BUTTON0:
	call Timer0.stop();
	break;
      case BUTTON1:
	call Timer1.stop();
	break;
      case BUTTON2:
	call Timer2.stop();
	break;
      case BUTTON3:
	call Timer3.stop();
	break;
      default:
	break;
      }
    }
  



  
  void handleButtonChange(int which)
    {
      uint8_t mask,maskUp,maskDown;
      uint16_t ari,arc;
      uint8_t state;    
      atomic 
	{
	  LastButtonMask = getCurrentState();
	  mask = LastButtonMask;
	  maskUp = buttonMaskUp;
	  maskDown = buttonMaskDown;
	  ari = autoRepeatRateInitial;
	  arc = autoRepeatRateContinuous;	
	  state = buttonState[which];	
	}
#if 0
    if (TOSH_READ_ADC_2_PIN())
      TOSH_CLR_ADC_2_PIN();
    else
      TOSH_SET_ADC_2_PIN();
#endif

    


      switch (state)
	{
	case BDOWN_HIT:
	  startTimer(which,DEBOUNCE_DELAY);
	  atomic
	    buttonState[which] = WAIT_FOR_DEBOUNCE_DOWN;
	  break;	  
	case BUP_SLOW:
	case BUP_FAST:
	  startTimer(which,DEBOUNCE_DELAY);
	  atomic
	    buttonState[which] = WAIT_FOR_DEBOUNCE_UP;
	  break;
	case WAIT_FOR_AR1:
	  startTimer(which,ari);
	  atomic
	    buttonState[which] = AR1;
	  break;
	case WAIT_FOR_AR2:
	  startTimer(which,arc);
	  atomic
	    buttonState[which] = AR2;
	  break;
	case WAIT_FOR_BDOWN:
	  // do nothing here. this is where the up debounce resets us too and we just wait
	  break;
	default:
	  break;
	}
    }
  
  
  

  
  task void handleButton0Change()
    {
      handleButtonChange(BUTTON0);
      
    }
  task void handleButton1Change()
    {
      handleButtonChange(BUTTON1);
      
    }
  task void handleButton2Change()
    {
      handleButtonChange(BUTTON2);
      
    }
  task void handleButton3Change()
    {
      handleButtonChange(BUTTON3);
      
    }

  void buttonUpDownEnable(int which,int upDown)
    {
      // assumes coming in that the interrupt has already been disabled by someone else
      controlInterrupts(which,upDown); 
    }
  
  

  // called from interrupt context
  void handleTimerFired(int which)
    {
      
      uint8_t mask,maskUp,maskDown;
      uint8_t state;
    
      atomic
	{
	  mask = getCurrentState();
	  maskUp = buttonMaskUp;
	  maskDown = buttonMaskDown;
	  state = buttonState[which];
	}
      

      switch (state){	  
      case WAIT_FOR_DEBOUNCE_DOWN:
	if (mask & (1 << which)){	    
	  atomic
	    buttonState[which] = WAIT_FOR_AR1;
	  // enable interrupts for button up
	  buttonUpDownEnable(which,INTERRUPT_UPEDGE);
	}
	else{	
	  atomic
	    buttonState[which] = BUP_FAST;
	  if (!(maskUp & (1 << which)))
	    signal Buttons.up(mask);
	}
	break;      
      case WAIT_FOR_DEBOUNCE_UP:
	if (!(mask & (1 << which))){
	  // button is still released
	  atomic
	    buttonState[which] = WAIT_FOR_BDOWN;
	  // enable interrupts for button down
	  buttonUpDownEnable(which,INTERRUPT_DOWNEDGE);
	}
	else{	
	  atomic
	    buttonState[which] = BDOWN_HIT;
	  if ((maskDown & (1 << which)))
	    signal Buttons.down(mask,FALSE);
	}	

	break;
      case AR1:
#if 1
	if (TOSH_READ_ADC_2_PIN())
	  TOSH_CLR_ADC_2_PIN();
	else
	  TOSH_SET_ADC_2_PIN();
#endif

	if (mask & (1 << which)){
	  atomic
	    buttonState[which] = WAIT_FOR_AR2;	
	  if (!(maskDown & (1 << which)))
	    signal Buttons.down(mask,TRUE);
	
	}
	else{
	  //guess we squeezed in before the interrupt got fired
	  // error it for now and see if we ever get here

	  atomic
	    buttonState[which] = BUP_SLOW; // but no fire up signal on the error
	}
	break;
      case AR2:
#if 1
	if (TOSH_READ_ADC_2_PIN())
	  TOSH_CLR_ADC_2_PIN();
	else
	  TOSH_SET_ADC_2_PIN();
#endif
	if (mask & (1 << which)){
	  atomic
	    buttonState[which] = WAIT_FOR_AR2;
	  if (!(maskDown & (1 << which)))
	    signal Buttons.down(mask,TRUE);	
	}
	else{
	  //guess we squeezed in before the interrupt got fired
	  // error it for now and see if we ever get here

	  atomic
	    buttonState[which] = BUP_SLOW; // but no fire up signal on the error
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
#if 0
    if (TOSH_READ_ADC_2_PIN())
      TOSH_CLR_ADC_2_PIN();
    else
      TOSH_SET_ADC_2_PIN();
#endif
    
      handleTimerFired(BUTTON0);    
      post handleButton0Change();    
      return SUCCESS;
    }
  
  event result_t Timer1.fired()
    {
#if 0
    if (TOSH_READ_ADC_2_PIN())
      TOSH_CLR_ADC_2_PIN();
    else
      TOSH_SET_ADC_2_PIN();
#endif

      handleTimerFired(BUTTON1);    
      post handleButton1Change();    
      return SUCCESS;
    }
  event result_t Timer2.fired()
    {
    handleTimerFired(BUTTON2);    
    post handleButton2Change();    
    return SUCCESS;
    }
  event result_t Timer3.fired()
    {
      handleTimerFired(BUTTON3);    
      post handleButton3Change();    
      return SUCCESS;
    }


  

  // called from interrupt context
  void handleInterruptFired(int which)
    {
      uint8_t mask,maskUp,maskDown;

#if 1
      if (TOSH_READ_ADC_1_PIN())
	TOSH_CLR_ADC_1_PIN();
      else
	TOSH_SET_ADC_1_PIN();
#endif
      atomic 
	{
	  LastButtonMask = getCurrentState();
	  mask = LastButtonMask;
	  maskUp = buttonMaskUp;
	  maskDown = buttonMaskDown;
	
	}
      //button down interrupt
      if (buttonState[which] == WAIT_FOR_BDOWN){
	// in case we are bouncing
	mask |= (1 < which);
	buttonState[which] = BDOWN_HIT;
#if 0
	XXX
	  // signals the initial down event
	if (!(maskDown & (1 << which)))
	  signal Buttons.down(mask,FALSE);
#endif
      }
      //button up interrupt
      else if ((buttonState[which] == WAIT_FOR_AR1)||
	       (buttonState[which] == AR1) ||
	       (buttonState[which] == AR2)){
	// kill the timer running for the ar check as we are done with that.
	stopTimer(which);	

	// in case we are bouncing
	mask &=  ~(1 < which);      
	buttonState[which] = BUP_SLOW;
	if (!(maskUp & (1 << which)))
	  signal Buttons.up(mask);
      }    
      else {
	buttonState[which] = BUP_SLOW; // but no fire up signal on the error
      }

    }
  
 
  async event void Button0Interrupt.fired() {

    // no more interrupts till they are reenebled
    controlInterrupts(BUTTON0,INTERRUPT_OFF);
    handleInterruptFired(BUTTON0);    
    post handleButton0Change();

  }

  async event void Button1Interrupt.fired() {
    // no more interrupts till they are reenebled
    controlInterrupts(BUTTON1,INTERRUPT_OFF);
    handleInterruptFired(BUTTON1);    
    post handleButton1Change();

  }
  async event void Button2Interrupt.fired() {
    // no more interrupts till they are reenebled
    controlInterrupts(BUTTON2,INTERRUPT_OFF);
    handleInterruptFired(BUTTON2);    
    post handleButton2Change();
  }
  async event void Button3Interrupt.fired() {
    // no more interrupts till they are reenebled
    controlInterrupts(BUTTON3,INTERRUPT_OFF);
    handleInterruptFired(BUTTON3);    
    post handleButton3Change();
  }




      
}
  
  



