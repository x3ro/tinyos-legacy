// $Id: HPLMSSPM.nc,v 1.4 2005/12/07 18:59:19 hjkoerber Exp $

/*
 * Copyright (c) 2004-2005, Technische Universitat Berlin
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
 * - Neither the name of the Technische Universitat Berlin nor the names
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
 * @author: Jan Hauer (hauer@tkn.tu-berlin.de)
 * @author: Joe Polastre
 * @author Hans-Joerg Koerber
 *         <hj.koerber@hsu-hh.de>
 *	     (+49)40-6541-2638/2627
 * @author Tobias Brennenstuhl
 	     <tobias.brennenstuhl@hsu-hh.de>
 * $Revision: 1.4 $
 * $Date $
 *
 */

module HPLMSSPM {

/****************************************************************************************************************/
/* 						provided interfaces									    */
/****************************************************************************************************************/

  provides {
    	interface HPLMSSPControl as MSSPControl;
    	interface HPLI2CInterrupt;
    	interface HPLSPIInterrupt;
  }

/****************************************************************************************************************/
/* 						used interfaces										    */
/****************************************************************************************************************/

  uses {
    interface PIC18F4620Interrupt as MSSP_Interrupt;
  }
}

implementation

/****************************************************************************************************************/
/* 						implementation										    */
/****************************************************************************************************************/

{

/****************************************************************************************************************/
/* 						MSSPControl.isI2C										    */
/****************************************************************************************************************/

  async command bool MSSPControl.isI2C() {
    bool result = FALSE;
    uint8_t SSPMbits = SSPCON1_register & 0x0f;                 				// Synchronous Serial Port Mode (SSPM) select bits are bits 0-3 of SSPCON1
    atomic {
      if ((SSPMbits >= 0x06) && (SSPMbits <= 0x0f) && (SSPCON1bits_SSPEN == 1)) 	//SSPEN = Synchronous Serial Port Enable bit
	result = TRUE;
    }
    return result;
  }


/****************************************************************************************************************/
/* 						MSSPControl.isSPI										    */
/****************************************************************************************************************/

async command bool MSSPControl.isSPI() {
    bool result = FALSE;
    uint8_t SSPMbits = SSPCON1_register & 0x22;							// SSPM enable! Setting SPI Master Mode, clock=Fosc/64
    atomic {
      if ((SSPMbits >=0x05) && (SSPCON1bits_SSPEN == 1))					// SSPM enabled?
	 result = TRUE;
    }
    return result;

}

/****************************************************************************************************************/
/* 						MSSPControl.getMode									    */
/****************************************************************************************************************/

  async command pic18f4620_msspmode_t MSSPControl.getMode() {
    if (call MSSPControl.isI2C())
      return MSSP_I2C;
    else if (call MSSPControl.isSPI())
      return MSSP_SPI;
    else
      return MSSP_NONE;
  }


/****************************************************************************************************************/
/* 						MSSPControl.setMode									    */
/****************************************************************************************************************/

/**
   * Sets the MSSP mode to one of the options from pic18f4620_msspmode_t
   * defined in pic18f4620mssp.h
   */
  async command void MSSPControl.setMode( pic18f4620_msspmode_t _mode) {
    switch (_mode) {
      case MSSP_SPI:
      call MSSPControl.setModeSPI();
      break;
    case MSSP_I2C:
      call MSSPControl.setModeI2C();
      break;
    default:
      break;
    }
  }

/****************************************************************************************************************/
/* 						MSSPControl.enableI2C									    */
/****************************************************************************************************************/

  async command void MSSPControl.enableI2C() {
    atomic{
      TRISCbits_TRISC3 = 1;                  							// configure SCL as required (Datasheet page 112)
      TRISCbits_TRISC4 = 1;                  							// configure SCA as required (Datasheet page 112)
      SSPCON1bits_SSPEN = 0x1;               							// Enables the serial port and configures the SDA and SCL pins as the serial port pins
    }
  }

/****************************************************************************************************************/
/* 						MSSPControl.enableSPI									    */
/****************************************************************************************************************/

  async command void MSSPControl.enableSPI() {
    atomic{
      TRISCbits_TRISC2 = 0x0;			   							// configure MSSP pins
      TRISCbits_TRISC3 = 0x0;
      TRISCbits_TRISC4 = 0x1;
      TRISCbits_TRISC5 = 0x0;
    }
  }
/****************************************************************************************************************/
/* 						MSSPControl.disableI2C									    */
/****************************************************************************************************************/

  async command void MSSPControl.disableI2C() {
    if (call MSSPControl.isI2C())
      atomic{
       SSPCON1bits_SSPEN = 0x0;              							// Disables serial port and configures these pins as I/O port pins

       TRISCbits_TRISC3 = 0;                 							// make SCL and SDA output and drive high for minimal current consumption during sleep
       LATCbits_LATC3=0x1;                   							// by driving the pins high the pull-ups do not lead to additive current in sleep
       TRISCbits_TRISC4 = 0;
       LATCbits_LATC4=0x1;
      }
  }

/****************************************************************************************************************/
/* 						MSSPControl.disableSPI									    */
/****************************************************************************************************************/

  async command void MSSPControl.disableSPI() {
    if (call MSSPControl.isSPI())
      atomic{
       SSPCON1bits_SSPEN = 0x0;									// Disable the serial port

       TRISCbits_TRISC2 = 0x0;									// Configure MSSP pins as outputs
       LATCbits_LATC2 = 0x1;
       TRISCbits_TRISC3 = 0;
       LATCbits_LATC3=0x0;
       TRISCbits_TRISC4 = 0;
       LATCbits_LATC4=0x1;
       TRISCbits_TRISC5 = 0;
       LATCbits_LATC5=0x1;
      }
  }

/****************************************************************************************************************/
/* 						MSSPControl.setModeI2C									    */
/****************************************************************************************************************/

  async command void MSSPControl.setModeI2C() {

    if (call MSSPControl.getMode() == MSSP_I2C)							// check if we are already in I2C mode
      return;

    call MSSPControl.disableSPI();          	

    atomic {
      SSPCON1bits_SSPM3 = 0x1;		     							// i2c master mode, 7-bit addr,clock = FOSC/(4 * (SSPADD + 1))
      SSPCON1bits_SSPM2 = 0x0;
      SSPCON1bits_SSPM1 = 0x0;
      SSPCON1bits_SSPM0 = 0x0;

      SSPSTATbits_SMP =1;                    							// I2C standard speed mode, scl frequency = 100 kHz
      SSPADD_register = 0x63;

      TRISCbits_TRISC3 = 1;                  							// configure SCL as required (Datasheet page 112)
      TRISCbits_TRISC4 = 1;                  							// configure SCA as required (Datasheet page 112)

      SSPCON1bits_SSPEN = 0x1;               							// Enables the serial port and configures the SDA and SCL pins as the serial port pins
      PIR1bits_SSPIF = 0x0;                  							// clear the MSSP interrupt flag
      PIE1bits_SSPIE = 0x1;                 							// enable MSSP interrupt by default,
    }
    return;
  }

/****************************************************************************************************************/
/* 						MSSPControl.setModeSPI									    */
/****************************************************************************************************************/

async command void MSSPControl.setModeSPI() {

   if (call MSSPControl.getMode() == MSSP_SPI)  // check if we are already in SPI mode
     return;

    call MSSPControl.disableI2C();

    atomic {
      SSPCON1bits_SSPM3 = 0x0;
      SSPCON1bits_SSPM2 = 0x0;
      SSPCON1bits_SSPM1 = 0x0;                 							// SPI master mode,clock = FOSC/16 -> 2.5 MHz at fosc = 40 MH
      SSPCON1bits_SSPM0 = 0x1;

      SSPCON1bits_CKP=0;										// Idle state for clock is a low level
      SSPSTATbits_CKE=1;										// Transmit occurs on transition from active to Idle clock state
      SSPSTATbits_SMP=1;										// Input data sampled at end of data output time

      TRISDbits_TRISD3 = 0x0;										// !CS
      TRISCbits_TRISC3 = 0x0;										// Clock
      TRISCbits_TRISC4 = 0x1;										// SD IN
      TRISCbits_TRISC5 = 0x0;										// SD OUT

      SSPCON1bits_SSPEN = 0x1;									// Enables the serial port and configures SCK, SDO, SDI and !CS as serial port pins
      PIR1bits_SSPIF = 0x0;										// clear the MSSP interrupt flag
      PIE1bits_SSPIE = 0x1;										// enables the MSSP interrupt

      INTCONbits_GIE = 0x1;
      INTCONbits_PEIE = 0x1;
    }
    return;
  }

/****************************************************************************************************************/
/* 						MSSP_Interrupt.fired						*/
/****************************************************************************************************************/

 async event result_t MSSP_Interrupt.fired(){    						// deceide whether we have to fire SPI- or I2C-Interrupt
    if (call MSSPControl.isI2C())
      signal HPLI2CInterrupt.fired();
      else if (call MSSPControl.isSPI())
      signal HPLSPIInterrupt.fired();
    return SUCCESS;
  }

}
