/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names 
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
 *
 * - Description ---------------------------------------------------------
 * Controlling the TDA5250.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2005/09/20 08:32:42 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
interface TDA5250Modes {
   /** 
      Signaled once when the radio is ready for the commands in
      this interface to be called
   */   
   event result_t ready();

   /**
      Set the mode of the radio 
      The choices are SLAVE_MODE, TIMER_MODE, SELF_POLLING_MODE
   */
   async command result_t SetTimerMode(float on_time, float off_time);
   async command result_t ResetTimerMode();
   async command result_t SetSelfPollingMode(float on_time, float off_time);
   async command result_t ResetSelfPollingMode();

   /**
      Switches radio between modes when in SLAVE_MODE
   */
   async command result_t RxMode();
   async command result_t SleepMode(); 
   async command result_t CCAMode();
  
   event result_t RxModeDone();
   event result_t SleepModeDone();
   event result_t CCAModeDone();
      
   /** 
      Signaled when the PWDD pin sends back an interrupt
      (Only running when in SELF_POLLING mode or TIMER mode)
   */
   async event void interrupt();
 }

