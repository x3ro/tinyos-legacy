/* -*- mode:c++; indent-tabs-mode: nil -*-
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
 * Implementation module for controlling the Potentiometer
 * - Revision -------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2005/11/29 12:16:07 $
 * @author: Raffaele Rugin
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

module PotM 
{
    provides {
        interface Pot;
        interface StdControl;
    }  
    uses {
        interface HPLUSARTControl as USARTControl;
    }
}
implementation
{
    uint8_t Pot_value;
  
    /************** interface commands **************/
    command result_t StdControl.init() {
        TOSH_SEL_POT_EN_IOFUNC();
        TOSH_SEL_POT_SD_IOFUNC();
        TOSH_MAKE_POT_EN_OUTPUT();
        TOSH_MAKE_POT_SD_OUTPUT();
        TOSH_SET_POT_EN_PIN();
        TOSH_CLR_POT_SD_PIN();
        return SUCCESS;
    }  
  
    command result_t StdControl.stop() {
        TOSH_CLR_POT_SD_PIN();
        return SUCCESS;
    }
  
    command result_t StdControl.start() {
        TOSH_SET_POT_SD_PIN();
        return SUCCESS;
    }  
  
    command void Pot.set(uint8_t value) {
        TOSH_CLR_POT_EN_PIN();
        call USARTControl.tx(value);
        while (call USARTControl.isTxEmpty() == FAIL);
        TOSH_SET_POT_EN_PIN();
        Pot_value=value;
    }

    command uint8_t Pot.get() {
        return Pot_value;
    }
  
    command result_t Pot.increase() {
        if (Pot_value < 255) {
            Pot_value++;
            call Pot.set(Pot_value);
            return SUCCESS;
        }
        else return FAIL;
    }   

    command result_t Pot.decrease() {
        if (Pot_value > 0) {
            Pot_value--;
            call Pot.set(Pot_value);
            return SUCCESS;
        }
        else  return FAIL;
    }
}
