// $Id: pic18f452hardware.h,v 1.1 2005/04/13 16:38:06 hjkoerber Exp $

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
 * @author: Philip Levis
 * @author: Nelson Lee
 * @author: Hans-Joerg Koerber 
 *         <hj.koerber@hsu-hh.de>
 *	   (+49)40-6541-2638/2627
 *
 * $Date: 2005/04/13 16:38:06 $ 
 * $Revision: 1.1 $
 *
 */


#ifndef _H_pic18f452_h
#define _H_pic18f452_h


#include <timers.h>

#define TOSH_ASSIGN_PIN(name, port, bit) \
static inline void TOSH_SET_##name##_PIN() {PORT##port##bits_R##port##bit=1;} \
static inline void TOSH_CLR_##name##_PIN() {PORT##port##bits_R##port##bit=0;} \
static inline uint8_t TOSH_READ_##name##_PIN() {return PORT##port##bits_R##port##bit;} \
static inline void  TOSH_WRITE_##name##_PIN(uint8_t value) {PORT##port##bits_R##port##bit=value;} \
static inline void TOSH_MAKE_##name##_OUTPUT(){TRIS##port##bits_TRIS##port##bit=0;} \
static inline void TOSH_MAKE_##name##_INPUT() {TRIS##port##bits_TRIS##port##bit=1;} \


#define TOSH_ALIAS_OUTPUT_ONLY_PIN(alias, connector)\
static inline void TOSH_SET_##alias##_PIN() {TOSH_SET_##connector##_PIN();} \
static inline void TOSH_CLR_##alias##_PIN() {TOSH_CLR_##connector##_PIN();} \
static inline void TOSH_MAKE_##alias##_OUTPUT() {TOSH_MAKE_##connector##_OUTPUT();} \


#define TOSH_SIGNAL(signame)					\
void signame() __attribute__ ((signal, spontaneous, C))

#define TOSH_INTERRUPT(signame)				\
void signame() __attribute__ ((interrupt, spontaneous, C))



/*----------------------------------------------------------------------------
 * Since the syntax of the pic's inline assembly can't be understood by ncc
 * this backdoor is used                        
 * 
 *      1. declaration of a dummy variable, e.g. "int asm_nop" in the
 *		   header pic128f452.h	 
 *      2. replacement of the dummy by the original assembly lines using the 
 *		   perl script -> "_asm nop _endsam"
 *--------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------
 * Here comes the anchor of the atomic-routine                          	
 *--------------------------------------------------------------------------*/


typedef uint8_t __nesc_atomic_t;

void __nesc_enable_interrupt(void)
{
  INTCONbits_GIE = 1;
  INTCONbits_PEIE = 1;            //enable all peripheral interrupts
}

inline __nesc_atomic_t __nesc_atomic_start(void) __attribute__((spontaneous))
{
  __nesc_atomic_t result = INTCONbits_GIE;
  INTCONbits_GIE = 0;
  return result;
}

inline void __nesc_atomic_end(__nesc_atomic_t reenable_interrupt) __attribute__((spontaneous))
{
 
   INTCONbits_GIE = reenable_interrupt;  
}


/*----------------------------------------------------------------------------
 * Here comes the sleep-routine
 *
 *   For the EnOcean platform we choose a power management method which is 
 *   similar to Telos. In the TOSH_sleep ()-function the peripheral modules 
 *   which add delta current (ADC)are checked whether they are running or not. 
 *   If no peripheral module is running we turn off the radio receiver and 
 *   the a/d-converter, start the watch dog timer and enter the low power 
 *   sleep mode.Sleep time is specified in watch dog timer periods and the 
 *   watch dog timer is used as the  wake-up source. Note that a running timer0
 *   is adjusted correctly.  
 *   The PIC wake-up time is 2 ms plus 1024 clock cycles. Additionally it
 *   takes 2 ms to write the postscaler into the respective config bits which
 *   reside in flash.
 *   That is why in the case of our platform sleep mode will not be 
 *   entered as often as in the case of a MSP430 based platform and thus 
 *   resulting in increased power consumption.                        	
 *--------------------------------------------------------------------------*/


bool SleepMode_disabled = FALSE;        // change to TRUE if sleep should be disabled

void Sleep_enable(){
  SleepMode_disabled = FALSE;
}

void Sleep_disable(){
  SleepMode_disabled = TRUE;
}

void TOSH_sleep()
{
   extern volatile uint8_t TOSH_sched_full;
  extern volatile uint8_t TOSH_sched_free;
  __nesc_atomic_t fInterruptFlags;
  uint8_t oldRxStatus;
  uint8_t oldADCStatus;
  uint16_t wdtPeriods;
  uint16_t sleepTicks;
  uint8_t wdtPostscaler = 0;
  uint8_t oldINTCON;
  uint8_t oldINTCON3;
  uint8_t oldPIE1;
  uint8_t oldPIE2;
  fInterruptFlags = __nesc_atomic_start();

  if ((SleepMode_disabled || TOSH_sched_full != TOSH_sched_free) ||  INTCONbits_TMR0IE == 0) {
      __nesc_atomic_end(fInterruptFlags);
      return;
    }
  else {
      if(ADCON0bits_GO == 0                   // check if ad-coversion is not running
	&&  (ReadTimer0 () <= 0xfcf7)         // check if  timer0 expires in more than 23.xx ms which is 
        && INTCONbits_TMR0IF == 0	 ){   // 	- the watchdog period = 18 ms in case of postscaler = 1
                                              // 	- plus 2ms + 1024 clock cycles wake-up time from sleep 
                                              //        - plus 2ms write-time for the wdt postscaler config bits
                                              //        - plus 0x5 ticks run time from this postion to postion 1 
                                              // -> so check if we have more than 23 ms (0x382) for sleep
	                                      // yes -> we have time to sleep
       
	oldRxStatus=PORTCbits_RC0;            // save old rx-status
	oldADCStatus= ADCON0bits_ADON;        // save old ADCON0-status
	
	oldINTCON = INTCON_register;                   // disable all peripheral interrupts and save old status
	INTCON_register &= 0xc7;
        oldINTCON3 = INTCON3_register;
	INTCON3_register &= 0xe7;
	oldPIE1 = PIE1_register;
        PIE1_register &= 0x0;
	oldPIE2 = PIE2_register;
        PIE2_register &= 0x0;	
        PORTCbits_RC0 = 1;                    // switch off the receiver  
	ADCON0bits_ADON = 0;                  // switch off the adc
	wdtPeriods = ((uint32_t)(0xffff - ReadTimer0()))/610;  // wdtPerios gives the number of 15.xx ms intervals or watchdog intervals respectively
                                                               // 0xffff - ReadTimer0 gives the ticks till the next timer0 interrupt
                                                               // /40 gives the ms till the next timer0 interrupt
                                                               // /15 gives the watchdog intervals till the next timer0 interrupt
                                                               // /610 instead of 600 (40*15) because of the watchdog interval is not exactly 15 ms
	while(wdtPeriods>1){
	  wdtPeriods = wdtPeriods>>1;
	  wdtPostscaler++;
	}

	if((((uint32_t)610)<<wdtPostscaler)+(uint32_t)ReadTimer0()+(uint32_t)160 > 0xffff) // position 1: here we check if the postscaler has to be adjust
	  wdtPostscaler--;                                                                     //             in order to prevent an timer overflow
	sleepTicks = (((uint16_t)610)<<wdtPostscaler)+ReadTimer0()+(uint16_t)160;          // sleepticks are the ticks which are lost during sleep because timer0
       										           // is not running then
	TBLPTR_register = 0x300003;                   // postion 2: here begins  the write cycle of the watch dog postscaler config bits which are in flash
                                             //            please refer to PIC18F452 manual p.195
	TABLAT_register = wdtPostscaler<<1;           // we want to write the postscaler bits into the right position of the WDTCON register, therefore let's shift one position
	asm_TBLWT = 1;
	EECON1bits_EEPGD = 1;
	EECON1bits_CFGS = 1;
	EECON1bits_WREN = 1;
	EECON2_register= 0x55;
	EECON2_register= 0xaa;
	EECON1bits_WR = 1;	
	asm_nop = 1;                 
	WDTCONbits_SWDTEN =1;                // enable watchdog timer
	WriteTimer0(sleepTicks);             // adjust timer0 with the ticks which we did not count during sleep  
        asm_clrwdt = 1;                      // clear watch dog timer
	asm_sleep = 1;                       // enter sleep mode
	WDTCONbits_SWDTEN =0;                // disable watchdog timer
        TBLPTR_register = 0x0;                        // clearing  the table pointer is the only way the later crc table reads will work
 	EECON1bits_EEPGD = 0;
	EECON1bits_CFGS = 0;
	EECON1bits_WREN = 0;
      PORTCbits_RC0 =  oldRxStatus;        // old rx-status
	ADCON0_register = oldADCStatus ;              // old ADCON0-status
        INTCON_register = oldINTCON;
	INTCON3_register = oldINTCON3;
        PIE1_register = oldPIE1;
	PIE2_register = oldPIE2;
       __nesc_atomic_end(fInterruptFlags); 
        }
      else {
        __nesc_atomic_end(fInterruptFlags);
        }
    }
}


void TOSH_wait(void)
{
        asm_nop = 1;                    // One instruction cycle consists of four oscillator periods		
	  		                // Thus 40 MHz external clock at OSC1 == 1 cycle per 100 n_sec	
}

#define TOSH_CYCLE_TIME_NS 100        



void TOSH_uwait(uint8_t u_sec)         //Wait for some time in u_sec + 3 µsec offset caused by function overhead
{      
  asm_nop = 1; 
  asm_nop = 1; 
 
  while(u_sec--!=0){
    asm_nop = 1;
  }
} 

#endif // _Hpic18f452_h



