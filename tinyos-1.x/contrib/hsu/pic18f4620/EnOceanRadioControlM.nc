// $Id: EnOceanRadioControlM.nc,v 1.2 2005/08/15 14:51:48 hjkoerber Exp $ 

/* 
 * Copyright (c) Helmut-Schmidt-University, Hamburg
 *		 Dpt.of Electrical Measurement Engineering  
 *		 All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions 
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright 
 *   notice, this list of conditions and the following disclaimer in the 
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Helmut-Schmidt-University nor the names 
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
 * @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 * @author Housam Wattar 
 *         <wattar@hsu-hh.de>
 *	   (+49)40-6541-2638/2627 
 * 
 * $Revision: 1.2 $
 * $Date: 2005/08/15 14:51:48 $ 
 *
 */

module EnOceanRadioControlM {
  provides {
    interface StdControl as StdControl;
    interface EnOceanRadioControl;
  }
}

implementation{

  command result_t StdControl.init() {
    /*    TOSH_MAKE_TX_BASE_OUTPUT();               // configure TX_BASE as output pin
    TOSH_MAKE_TX_DATA_OUTPUT();               // configure TX_DATA as output pin
    TOSH_MAKE_TX_ANT_ON_OUTPUT();             // configure TX_ANT_ON as output pin
    TOSH_MAKE_TX_ON_OUTPUT();                 // configure TX_ON as output pin
    TOSH_MAKE_RX_ANT_ON_OUTPUT();             // configure RX_ANT_ON as output pin
    TOSH_MAKE_NOT_RX_ON_OUTPUT();             // configure NOT_RX_ON as output pin
    TOSH_MAKE_RX_DATA_INPUT();                // configure RX_DATA as input pin
    TOSH_MAKE_RX_RF_GAIN_OUTPUT();            // configure RX_RF_GAIN as output pin
    */return SUCCESS;
  }

  command result_t StdControl.start() {
    return SUCCESS;
  } 

  command result_t StdControl.stop() {
    TOSH_CLR_TX_BASE_PIN();                   // clear TX_BASE 
    TOSH_CLR_TX_DATA_PIN();                   // clear TX_DATA 
    TOSH_CLR_TX_ANT_ON_PIN();                 // clear TX_ANT_ON 
    TOSH_CLR_RX_ANT_ON_PIN();                 // clear RX_ANT_ON
    TOSH_CLR_TX_ON_PIN();                     // turn off the transmitter 
    TOSH_SET_NOT_RX_ON_PIN();                 // turn off the receiver (negative logic)        
    TOSH_CLR_RX_RF_GAIN_PIN();                // clear  RX_RF_GAIN
    return SUCCESS;
  }

  async command result_t EnOceanRadioControl.TxMode() {
    INTCONbits_RBIE = 0;                      // disable receive interrupt
    TOSH_SET_NOT_RX_ON_PIN();                 // turn off the receiver (negative logic)
    TOSH_SET_TX_ANT_ON_PIN();                 // set TX_ANT_ON 
    TOSH_CLR_RX_ANT_ON_PIN();                 // clear RX_ANT_ON 
    TOSH_SET_TX_ON_PIN();                     // turn on the transmitter    
    return SUCCESS;
  }

  async command result_t EnOceanRadioControl.RxMode() {
    TOSH_CLR_TX_ON_PIN();                     // turn off the transmitter 
    TOSH_CLR_TX_ANT_ON_PIN();                 // clear TX_ANT_ON 
    TOSH_SET_RX_ANT_ON_PIN();                 // set RX_ANT_ON 
    TOSH_SET_RX_RF_GAIN_PIN();                // high_rf_gain per default
    TOSH_CLR_NOT_RX_ON_PIN();                 // turn on the receiver (negative logic)   
    INTCONbits_RBIE = 1;                      // enable receive interrupt
    return SUCCESS;
  }

  command result_t EnOceanRadioControl.ConfigureRFGain(uint8_t mode) {
    if(mode == 1)
      TOSH_SET_RX_RF_GAIN_PIN();                //set rf_gain high
    else
      TOSH_CLR_RX_RF_GAIN_PIN();                //set rf_gain low
  }

  command result_t EnOceanRadioControl.GetRFGain(){
    result_t mode;
      mode= (result_t) TOSH_READ_RX_RF_GAIN_PIN();
    return mode;
  }
}

