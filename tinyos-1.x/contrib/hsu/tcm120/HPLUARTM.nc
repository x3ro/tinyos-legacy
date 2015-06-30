// $Id: HPLUARTM.nc,v 1.1 2005/04/13 16:38:06 hjkoerber Exp $
/*								       
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


/*
 * @author: Jason Hill
 * @author: David Gay
 * @author: Philip Levis
 * @author: Phil Buonadonna
 * @author: Joe Polastre
 * @author: Hans-Joerg Koerber 
 *          <hj.koerber@hsu-hh.de>
 *	    (+49)40-6541-2638/2627
 * 
 * $Date: 2005/04/13 16:38:06 $
 * $Revision: 1.1 $
 */

/* UART-Trasmit works as follows:
 * 
 * The first byte is written into the TXREG by a task from an upper layer 
 * component. Enabling the uart transmit interrupt directly causes an interrupt
 * after the byte written to TXREG has been shifted out into the TSR-Register.
 * In the associated interrupt service routine (isr) the transmit interrupt is disabled
 * in order to prevent an immediate subsequent interrupt because the transmit 
 * interrupt flag (TXIF)is still set.In addtion the task HandleUartTransmit is posted
 * which will cause the upper layer component to hand over the next byte to HPLUARTM.
 * Besides the isr enables the transmitter which doesn't has to be turned of by a stop 
 * command.
 * The isr can be found in PIC18F452InterruptM.nc
 */

module HPLUARTM {
  provides interface HPLUART as UART;

  uses  {
    interface PIC18F452Interrupt as UART_Transmit_Interrupt;
    interface PIC18F452Interrupt as UART_Receive_Interrupt;
  }
}

implementation
{
  async command result_t UART.init() {

    // UART will run at:
    // 58.140 kbps, N-8-1

    RCSTAbits_SPEN = 1;		// enable serial port 
    TXSTAbits_SYNC = 0;		// asynchronous mode
    TXSTAbits_TX9 = 0;  	// 8-bit transmission
    RCSTAbits_RX9 = 0;          // 8-bit reception
 
    TXSTAbits_BRGH = 1;		// high speed mode

    SPBRG_register = 42; 		// initialize ther baud rate generator register with 42
 			   	// actually generated baudrate = 58.140 kbps (refer to  PIC Datasheet,page 168) 
                                // this is the setting which works with both the java listen and bcastinject tool
 	
 
    PIE1bits_RCIE =  1;         // enable usart receive interrupt
    RCSTAbits_CREN = 1;         // enable continuous receive	 

    
    return SUCCESS;
  }

  async command result_t UART.stop(){
     RCSTAbits_SPEN = 0;		// disable serial port   
     TOSH_CLR_SER_TX_PIN();
  }


  default async event result_t UART.get(uint8_t data) { return SUCCESS; }

  async event result_t UART_Receive_Interrupt.fired(){
    uint8_t received_data = RCREG_register;
    signal UART.get(received_data);
    return SUCCESS;  
  }

  default async event result_t UART.putDone() { return SUCCESS; }

  async event result_t UART_Transmit_Interrupt.fired(){
    signal UART.putDone();
    return SUCCESS;
  }

  command async result_t UART.put(uint8_t transmit_data) {
    TXREG_register = transmit_data;      // loading TXREG with new data will start the transmission
    TXSTAbits_TXEN = 1;	                 // enable transmission 
    PIE1bits_TXIE = 1;                   // enable usart transmit interrupt
    return SUCCESS;
  }
}
