// $Id: hardware.h,v 1.1 2005/04/13 16:38:06 hjkoerber Exp $

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
 * $Date: 2005/04/13 16:38:06 $
 * $Revision: 1.1 $
 *
 */

  
#ifndef _H_hardware_h
#define _H_hardware_h


#define TOSH_NEW_AVRLIBC 
#include "pic18f452_defs.h"
#include "pic18f452hardware.h"


// LED assignments
TOSH_ASSIGN_PIN(RED_LED, C, 1);              // OUT_0
TOSH_ASSIGN_PIN(GREEN_LED, C, 2);            // OUT_1
TOSH_ASSIGN_PIN(YELLOW_LED, C, 3);           // OUT_2


// Radio transmitter control assignments
TOSH_ASSIGN_PIN(TX_BASE, B, 1 );
TOSH_ASSIGN_PIN(TX_ON, B, 3 ); 
TOSH_ASSIGN_PIN(TX_DATA, B, 5 ); 
TOSH_ASSIGN_PIN(TX_ANT_ON, C, 5 );

// Radio receiver control assignments
//TOSH_ASSIGN_PIN(RX_RSSI, A, 0);            // the RSSI is defined in sensorboard.h
TOSH_ASSIGN_PIN(RX_RF_GAIN, A, 4);           // RX_RF_gain = 0  scales down the gain about 18 dB,for the concrete functioning refer to the infineon "tda 5200" manual, p. 4-3 
TOSH_ASSIGN_PIN(NOT_RX_ON, C, 0); 
TOSH_ASSIGN_PIN(RX_DATA, B, 4); 
TOSH_ASSIGN_PIN(RX_ANT_ON, B, 2 );

// Uart assignments
TOSH_ASSIGN_PIN(SER_TX, C, 6);
TOSH_ASSIGN_PIN(SER_RX, C, 7);

// Expansion board assignments
TOSH_ASSIGN_PIN(EXP_IO_0, D, 0);
TOSH_ASSIGN_PIN(EXP_IO_1, D, 1);
TOSH_ASSIGN_PIN(EXP_IO_2, D, 2);
TOSH_ASSIGN_PIN(EXP_IO_3, D, 3);
TOSH_ASSIGN_PIN(EXP_IO_4, D, 4);
TOSH_ASSIGN_PIN(EXP_IO_5, D, 5);
TOSH_ASSIGN_PIN(EXP_IO_6, D, 6);
TOSH_ASSIGN_PIN(EXP_IO_7, D, 7);

// Power Control assignmenst
TOSH_ASSIGN_PIN(PORTA1, A, 1);
TOSH_ASSIGN_PIN(PORTA2, A, 2);
TOSH_ASSIGN_PIN(PORTA3, A, 3);
TOSH_ASSIGN_PIN(PORTA5, A, 5);

TOSH_ASSIGN_PIN(OUT_3, C, 4);

TOSH_ASSIGN_PIN(EXP_IO_8, E, 0)
TOSH_ASSIGN_PIN(EXP_IO_9, E, 1);
TOSH_ASSIGN_PIN(EXP_IO_10, E, 2);

//ICD2 PINS
TOSH_ASSIGN_PIN(ICSP_CLK, B, 6);
TOSH_ASSIGN_PIN(ICSP_DATA, B, 7);


void TOSH_SET_PIN_DIRECTIONS(void)
{
   TRISA_register = 0x01;		//'00000001';
   PORTA_register = 0x00;		//'00000000';
   TRISB_register = 0x11;		//'00010001';
   PORTB_register = 0x00;		//'00000000';
   TRISC_register = 0x80;		//'10000000';
   PORTC_register = 0x01;		//'00000001';    // NOT_RX_ON = 1; -> receiver is switched off
   TRISD_register = 0x00;		//'00000000';
   PORTD_register = 0x00;		//'00000000';
   TRISE_register = 0x00;               //'00000000';
   PORTE_register = 0x00;     	        //'00000000';
}

enum {
  TOSH_ADC_PORTMAPSIZE = 8                //there are just 8 ad-converter inputs available
};

#endif //_H_hardware_h




