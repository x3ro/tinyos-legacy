/*
 * Copyright (c) 2004, Technische Universität Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universität Berlin nor the names 
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/** - Description ----------------------------------------------------------
 * This component manages the ADC12's reference voltage generator.
 * The internal turn-on time is 17ms, thus the component is programmed  
 * split-phase, i.e. after the command <code>get</code> has been called 
 * you will eventually get the event <code>isStable</code> when vref is 
 * stable.
 *
 * The generator should be turned off to both save power and allow other 
 * components to switch to another reference voltage when not in use.  To
 * do so, the <code>release</code> command is available.
 *
 * There are two different reference voltages available with this 
 * component.  They are a 1.5 reference voltage and a 2.5 reference 
 * voltage.  Only one can be set at any given time, however. If a 
 * component, therefore, tries to call the <code>get</code> command on the
 * reference voltage that is not currently set, the <code>get</code> 
 * command will return a FAIL.  Only once all components using a certain 
 * reference voltage have called the <code>release</code> command, will a 
 * call to the <code>get</code> command with a different reference voltage 
 * return a SUCCESS.
 *    
 * Since the 17 millisecond delay is only required when switching the 
 * RefVolt component on after it has been turned off, a timer is used to
 * delay the actual switching off of the component after it has been 
 * released for the last time.  This allows other components to start using
 * the reference voltage immediately if they try to access it within a 
 * reasonable amount of time.  The delay for this timer is set in RefVolt.h
 * as SWITCHOFF_INTERVAL.
 *
 * If a component calls the <code>get</code> command when the RefVolt 
 * component is in the off state and no other components have called the
 * <code>get</code> command before this component calls release, AND the 
 * <code>release</code> command is called before the <code>isStable</code> 
 * event returns, then the RefVolt component will never be turned on and the 
 * <code>isStable</code> event will never be triggered.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.5 $
 * $Date: 2004/07/08 13:50:26 $
 * @author: Jan Hauer (hauer@tkn.tu-berlin.de)
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
module RefVoltM
{
  provides interface RefVolt;
  uses {
    interface HPLADC12;
    interface TimerMilli as SwitchOnTimer;
    interface TimerMilli as SwitchOffTimer;
  }
}

implementation
{
  enum
  {
    REFERENCE_OFF,
    REFERENCE_1_5V_PENDING, 
    REFERENCE_2_5V_PENDING,
    REFERENCE_1_5V_STABLE,
    REFERENCE_2_5V_STABLE,
  };

  norace uint8_t semaCount;
  norace uint8_t state;
  norace bool switchOff;
  
  inline void switchRefOn(uint8_t vref);
  inline void switchRefOff();
  inline void switchToRefStable(uint8_t vref);
  inline void switchToRefPending(uint8_t vref);
  
  task void switchOnDelay();
  task void switchOffDelay();
  task void switchOffRetry();
  
  async command result_t RefVolt.get(RefVolt_t vref) {
    result_t result = SUCCESS;
  
    atomic {
      if(semaCount == 0) {
        if(call HPLADC12.isBusy())
          result = FAIL;
        else {
          if(state == REFERENCE_OFF)
            switchRefOn(vref);
          else if((state == REFERENCE_1_5V_PENDING && vref == REFERENCE_2_5V) ||
                  (state == REFERENCE_2_5V_PENDING && vref == REFERENCE_1_5V))
                    switchToRefPending(vref);
          else if((state == REFERENCE_1_5V_STABLE  && vref == REFERENCE_2_5V) ||
                  (state == REFERENCE_2_5V_STABLE  && vref == REFERENCE_1_5V))
                    switchToRefStable(vref);
          semaCount++;
          switchOff = FALSE;
          result = SUCCESS;
        }
      }
      else if((state == REFERENCE_1_5V_PENDING && vref == REFERENCE_1_5V) ||
              (state == REFERENCE_2_5V_PENDING && vref == REFERENCE_2_5V) ||
              (state == REFERENCE_1_5V_STABLE  && vref == REFERENCE_1_5V) ||
              (state == REFERENCE_2_5V_STABLE  && vref == REFERENCE_2_5V)) {
        semaCount++;
        switchOff = FALSE;
        result = SUCCESS;
      }
      else result = FAIL;
    }
    return result;
  }
  
  inline void switchRefOn(uint8_t vref) {
    call HPLADC12.disableConversion();
    call HPLADC12.setRefOn();
    if (vref == REFERENCE_1_5V){
      call HPLADC12.setRef1_5V();
      atomic state = REFERENCE_1_5V_PENDING;
    } 
    else {
      call HPLADC12.setRef2_5V();
      atomic state = REFERENCE_2_5V_PENDING;
    }  
    post switchOnDelay();
  }
  
  inline void switchToRefPending(uint8_t vref) {
    switchRefOn(vref);
  }
  
  inline void switchToRefStable(uint8_t vref) {
    switchRefOn(vref);
  }
        
  task void switchOnDelay(){
    call SwitchOnTimer.setOneShot(STABILIZE_INTERVAL);
  }

  event result_t SwitchOnTimer.fired() {
    atomic {
      if (state == REFERENCE_1_5V_PENDING)
        state = REFERENCE_1_5V_STABLE;
      if (state == REFERENCE_2_5V_PENDING)
        state = REFERENCE_2_5V_STABLE;
    }
    if (state == REFERENCE_1_5V_STABLE)
      signal RefVolt.isStable(REFERENCE_1_5V);    
    if (state == REFERENCE_2_5V_STABLE)
      signal RefVolt.isStable(REFERENCE_2_5V);         
    return SUCCESS;
  }

  async command result_t RefVolt.release() {
    result_t result = FAIL;
    
    atomic {
      if(semaCount <= 0)
        result = FAIL;
      else {
        semaCount--;
        if(semaCount == 0) {
          if(state == REFERENCE_1_5V_PENDING ||
             state == REFERENCE_2_5V_PENDING) {
            switchOff = TRUE;
            switchRefOff();
          }
          else {
            switchOff = TRUE;
            post switchOffDelay();
          }
          result = SUCCESS;
        }
      }
    }  
    return result;
  }
  
  inline void switchRefOff() {
    result_t result;
  
    atomic {
      if(switchOff == FALSE)
        result = FAIL;
      else if(call HPLADC12.isBusy()) {
        result = FAIL; 
      }
      else {
        call HPLADC12.disableConversion();
        call HPLADC12.setRefOff();
        state = REFERENCE_OFF;
        result = SUCCESS;
      }
    }
    if(switchOff == TRUE && result == FAIL)
      post switchOffRetry();
  }
            
  task void switchOffDelay(){
    if(switchOff == TRUE)
      call SwitchOffTimer.setOneShot(SWITCHOFF_INTERVAL); 
  }
  
  task void switchOffRetry(){
    if(switchOff == TRUE)
      call SwitchOffTimer.setOneShot(SWITCHOFF_RETRY); 
  }
             
  event result_t SwitchOffTimer.fired() {
    switchRefOff();
    return SUCCESS;
  }
  
  async command RefVolt_t RefVolt.getState() {
    if (state == REFERENCE_2_5V_STABLE)
      return REFERENCE_2_5V;
    if (state == REFERENCE_1_5V_STABLE)
      return REFERENCE_1_5V;
    return REFERENCE_UNSTABLE;
  }
  
  async event void HPLADC12.memOverflow(){}
  async event void HPLADC12.timeOverflow(){}
  async event void HPLADC12.converted(uint8_t number){}
}



