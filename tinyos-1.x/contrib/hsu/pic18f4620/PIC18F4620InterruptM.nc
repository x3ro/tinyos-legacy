// $Id: PIC18F4620InterruptM.nc,v 1.4 2005/12/07 18:59:19 hjkoerber Exp $

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
 */

/* @author Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 * 
 * $Date: 2005/12/07 18:59:19 $
 * $Revision: 1.4 $
 */

module PIC18F4620InterruptM
{
 
  provides {
    interface PIC18F4620Interrupt as TIMER1_Overflow;
    interface PIC18F4620Interrupt as ADC_Interrupt;
    interface PIC18F4620Interrupt as UART_Transmit_Interrupt;
    interface PIC18F4620Interrupt as UART_Receive_Interrupt;
    interface PIC18F4620Interrupt as MSSP_Interrupt;
    interface PIC18F4620Interrupt as EnOceanRF_Receive_Interrupt;
  }
}

implementation
{ 
  task void HandleUartTXIF();  

  TOSH_INTERRUPT(InterruptHandler)
  {
    if ( PIE1bits_TMR1IE) {
      if ( PIR1bits_TMR1IF) {
           PIR1bits_TMR1IF = 0;
          signal TIMER1_Overflow.fired();
        }
    } 
   
    if (PIE1bits_ADIE){
      if (PIR1bits_ADIF){
	PIR1bits_ADIF=0;
	signal ADC_Interrupt.fired();
      }
    }

/*-------------------------------------------------------------------------
 * UART transmit flag will be  automatically cleared by updating the 
 * transmit register TXREG  with a new byte 
 *------------------------------------------------------------------------*/    

    if (PIE1bits_TXIE){
      if (PIR1bits_TXIF){
	PIE1bits_TXIE = 0;;
	post  HandleUartTXIF();
        while(!TXSTAbits_TRMT){;}
      }
    }
    
/*-------------------------------------------------------------------------
 * UART receive flag will be  automatically cleared when register 
 * RCREG is read 
 *------------------------------------------------------------------------*/
 
    if (PIE1bits_RCIE){
      if (PIR1bits_RCIF){
	signal  UART_Receive_Interrupt.fired();
      } 
    }
   
   if (PIE1bits_SSPIE){
      if (PIR1bits_SSPIF){
        PIR1bits_SSPIF=0;
        signal MSSP_Interrupt.fired();	
      }
    }
    			  

    if (INTCONbits_RBIE){
      if(INTCONbits_RBIF){
	signal EnOceanRF_Receive_Interrupt.fired();
      }
    }
  }	


  default async event result_t TIMER1_Overflow.fired() {PIR1bits_TMR1IF = 0;return SUCCESS;}
  default async event result_t ADC_Interrupt.fired(){PIR1bits_ADIF=0;return SUCCESS;}
  default async event result_t UART_Transmit_Interrupt.fired(){return SUCCESS;}
  default async event result_t UART_Receive_Interrupt.fired(){return SUCCESS;}
  default async event result_t MSSP_Interrupt.fired(){PIR1bits_SSPIF=0; return SUCCESS;}
  default async event result_t EnOceanRF_Receive_Interrupt.fired(){return SUCCESS;}
  
  task void HandleUartTXIF(){
    signal  UART_Transmit_Interrupt.fired();
  }
}



