// $Id: hardware.h,v 1.3 2005/05/19 11:08:16 hjkoerber Exp $

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
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */ 


/*
 * @author Jason Hill
 * @author Philip Levis
 * @author Nelson Lee
 * @author David Gay
 * @author: Hans-Joerg Koerber 
 *          <hj.koerber@hsu-hh.de>
 *	    (+49)40-6541-2638/2627

 *
 * $Date: 2005/05/19 11:08:16 $
 * $Revision: 1.3 $
 *
 */



#ifndef _H_hardware_h
#define _H_hardware_h


//#define TOSH_NEW_AVRLIBC // mica128 requires avrlibc v. 20021209 or greater
#include "pic18f4620_defs.h"
#include "pic18f4620hardware.h"


// LED assignments
TOSH_ASSIGN_PIN(RED_LED, D, 0);              
TOSH_ASSIGN_PIN(GREEN_LED, D, 1);
TOSH_ASSIGN_PIN(YELLOW_LED, D, 2);


// Radio transmitter control assignments
TOSH_ASSIGN_PIN(TX_BASE, B, 1 );
TOSH_ASSIGN_PIN(TX_ON, B, 3 ); 
TOSH_ASSIGN_PIN(TX_DATA, B, 5 ); 
TOSH_ASSIGN_PIN(TX_ANT_ON, D, 7 );

// Radio receiver control assignments
TOSH_ASSIGN_PIN(RX_RSSI, A, 0);              
TOSH_ASSIGN_PIN(RX_RF_GAIN, A, 4);          // RX_RF_gain = 0  scales down the gain about 18 dB,for the concrete functioning refer to the infineon "tda 5200" manual, p. 4-3 
TOSH_ASSIGN_PIN(NOT_RX_ON, C, 2); 
TOSH_ASSIGN_PIN(RX_DATA, B, 4); 
TOSH_ASSIGN_PIN(RX_ANT_ON, D, 6 );

// Uart assignments
TOSH_ASSIGN_PIN(SER_TX, C, 6);
TOSH_ASSIGN_PIN(SER_RX, C, 7);
TOSH_ASSIGN_PIN(SER_RX_NN, B, 0);           // NN = not needed, but implemented on EnOcean

// SPI assignments
TOSH_ASSIGN_PIN(SCK, C, 3);
TOSH_ASSIGN_PIN(SDI, C, 4);
TOSH_ASSIGN_PIN(SDO, C, 5);

// RTC assignments
TOSH_ASSIGN_PIN(RTC_INT, B, 2); 

// Reference Voltage assignments
TOSH_ASSIGN_PIN(Vref_SUPPLY, D, 5)
TOSH_ASSIGN_PIN(Vref_HIGH, A, 3);

// I2C  assignments
TOSH_ASSIGN_PIN(SCL, C, 3);
TOSH_ASSIGN_PIN(SDA, C, 4);
           
 
// Power Control assignmenst
TOSH_ASSIGN_PIN(PORTA1, A, 1);
TOSH_ASSIGN_PIN(PORTA2, A, 2);
TOSH_ASSIGN_PIN(PORTA5, A, 5);

//TOSH_ASSIGN_PIN(PORTC, C, 0);             // used by 32.768 kHz crystal
//TOSH_ASSIGN_PIN(PORTC, C, 1);
TOSH_ASSIGN_PIN(PORTD3, D, 3);
TOSH_ASSIGN_PIN(PORTD4, D, 4); 
TOSH_ASSIGN_PIN(EXP_IO_3, D, 3);
TOSH_ASSIGN_PIN(EXP_IO_4, D, 4);
TOSH_ASSIGN_PIN(PORTE0, E, 0)
TOSH_ASSIGN_PIN(PORTE1, E, 1);
TOSH_ASSIGN_PIN(PORTE2, E, 2);

//ICD2 PINS
TOSH_ASSIGN_PIN(ICSP_CLK, B, 6);
TOSH_ASSIGN_PIN(ICSP_DATA, B, 7);


void TOSH_SET_PIN_DIRECTIONS(void)
{

  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();

  TOSH_MAKE_TX_BASE_OUTPUT();
  TOSH_MAKE_TX_ON_OUTPUT();
  TOSH_MAKE_TX_DATA_OUTPUT();
  TOSH_MAKE_TX_ANT_ON_OUTPUT();
  TOSH_MAKE_RX_RSSI_INPUT();             
  TOSH_MAKE_RX_RF_GAIN_OUTPUT();            
  TOSH_MAKE_NOT_RX_ON_OUTPUT(); 
  TOSH_MAKE_RX_DATA_INPUT(); 
  TOSH_MAKE_RX_ANT_ON_OUTPUT();

  TOSH_MAKE_SER_TX_INPUT();                 // make SER_TX pin input in order to save current during sleep
  TOSH_MAKE_SER_RX_INPUT(); 
  TOSH_MAKE_SER_RX_NN_INPUT(); 

  TOSH_MAKE_SCK_OUTPUT();                   // outputs, so that we can drive them high in order to save energy (pull-ups!!!) during sleep 
  TOSH_MAKE_SDI_OUTPUT();                    
  TOSH_MAKE_SDO_OUTPUT();

  TOSH_MAKE_RTC_INT_INPUT();

  TOSH_MAKE_Vref_HIGH_INPUT();
  TOSH_MAKE_Vref_SUPPLY_OUTPUT();

  TOSH_MAKE_PORTA1_OUTPUT();
  TOSH_MAKE_PORTA2_OUTPUT();
  TOSH_MAKE_PORTA5_OUTPUT();

  TOSH_MAKE_PORTD3_OUTPUT();
  TOSH_MAKE_PORTD4_OUTPUT();

  TOSH_MAKE_PORTE0_OUTPUT();
  TOSH_MAKE_PORTE1_OUTPUT();
  TOSH_MAKE_PORTE2_OUTPUT();
 
  TOSH_MAKE_ICSP_CLK_OUTPUT();
  TOSH_MAKE_ICSP_DATA_OUTPUT();     

  TOSH_CLR_RED_LED_PIN();                 // comment out if no LEDs are attached 
  TOSH_CLR_YELLOW_LED_PIN();
  TOSH_CLR_GREEN_LED_PIN();
  
  TOSH_CLR_TX_BASE_PIN();  
  TOSH_CLR_TX_ON_PIN(); 
  TOSH_CLR_TX_DATA_PIN();
  TOSH_CLR_TX_ANT_ON_PIN();  
  TOSH_CLR_RX_RF_GAIN_PIN();
  TOSH_SET_NOT_RX_ON_PIN();
  TOSH_CLR_RX_ANT_ON_PIN();
  TOSH_CLR_SER_TX_PIN();  

  TOSH_SET_SCK_PIN();                     // make SCL and SDA output and drive high for minimal current consumption during sleep 
  TOSH_SET_SDI_PIN();                     // by driving the pins high the pull-ups do not lead to additive current in sleep  
  TOSH_CLR_SDO_PIN();


  TOSH_SET_Vref_SUPPLY_PIN();             // we turn on the voltage reference per default
  TOSH_mswait(5);                         // it takes 5.25 ms to get a stable Vref after turning the reference on
  TOSH_uwait(250);                         // -> Vref needs 750 us to reach a peak value of 4.2 V  and from that point additional 4.5 ms until 
                                          //    stable Vref = 4.096 V are reached
                                          // -> so wait 5,25 ms until Vref is stable  
                                          // if you want to save energy during sleep than set VrefSleep_enabled = TRUE in pic18f4620hardare.h

  TOSH_CLR_PORTA1_PIN();
  TOSH_CLR_PORTA2_PIN();  

  TOSH_CLR_PORTA5_PIN();
  TOSH_CLR_PORTD3_PIN();
  TOSH_CLR_PORTD4_PIN(); 
  TOSH_CLR_PORTE0_PIN();
  TOSH_CLR_PORTE1_PIN();
  TOSH_CLR_PORTE2_PIN();  



  TOSH_CLR_ICSP_CLK_PIN();
  TOSH_CLR_ICSP_DATA_PIN();  
}

enum {
  TOSH_ADC_PORTMAPSIZE = 8                //there are just 8 ad-converter inputs available
};

#endif //_H_hardware_h




