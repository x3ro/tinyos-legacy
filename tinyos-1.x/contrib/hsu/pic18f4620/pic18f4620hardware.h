// $Id: pic18f4620hardware.h,v 1.2 2005/05/19 11:20:42 hjkoerber Exp $

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
 
 * $Date: 2005/05/19 11:20:42 $ 
 * $Revision: 1.2 $
 *
 */


#ifndef _H_pic18f4620_h
#define _H_pic18f4620_h


#include <timers.h>

#define TOSH_ASSIGN_PIN(name, port, bit) \
static inline void TOSH_SET_##name##_PIN() {LAT##port##bits_LAT##port##bit=1;} \
static inline void TOSH_CLR_##name##_PIN() {LAT##port##bits_LAT##port##bit=0;} \
static inline uint8_t TOSH_READ_##name##_PIN() {return PORT##port##bits_R##port##bit;} \
static inline void  TOSH_WRITE_##name##_PIN(uint8_t value) {LAT##port##bits_LAT##port##bit=value;} \
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
 *      1. declaration of a dummy variable, e.g. "int asm nop" in the
 *		   header pic18f4620.h	 
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
 * Here are some wait functions                          	
 *--------------------------------------------------------------------------*/

void TOSH_wait(void)
{
        asm_nop = 1;                    // One instruction cycle consists of four oscillator periods		
	  		                // Thus 40 MHz external clock at OSC1 == 1 cycle per 100 n_sec	
                                        // See PIC Datasheet, §4.5, page 39
}

#define TOSH_CYCLE_TIME_NS 100        



void TOSH_uwait(uint8_t u_sec)          // Wait for some time in u_sec + 3 µsec offset caused by function overhead
{                                       // -> if usec == 3 you will wait 6µsec

  asm_nop = 1; 
  while(u_sec--!=0){
    asm_nop = 1;
  }
} 

void TOSH_mswait(uint16_t m_sec)        // Wait for some time in ms_sec
{
   
	while(m_sec--!=0){
	TOSH_uwait(255);
   	TOSH_uwait(255);
	TOSH_uwait(255);
	TOSH_uwait(219);	
	}
}


/*----------------------------------------------------------------------------
 * Here comes the sleep-routine
 *
 *   For the EnOcean platform we choose a power management method which is 
 *   similar to Telos. In the TOSH_sleep ()-function the peripheral modules 
 *   which add delta current (ADC)are checked whether they are running or not. 
 *   If no peripheral module is running we turn off the radio receiver and 
 *   the ad-converter and enter the low power sleep mode. 
 *   The PIC wake-up time is 2 ms plus 1024 clock 
 *   cycles. That is why in the case of our platform sleep mode will not be 
 *   entered as often as in the case of a MSP430 based platform and thus 
 *   resulting in increased power consumption.                        	
 *--------------------------------------------------------------------------*/

bool SleepMode_disabled = FALSE;        // change to TRUE if sleep should be disabled

bool VrefSleep_enabled = FALSE;         // change to TRUE if you want to turn the voltage reference off during sleep
                                        // be aware that  it takes 5.25 ms to get a stable Vref after turning the reference on after wake-up

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
  uint8_t oldRxAntStatus;
  uint8_t oldADCStatus;
  uint8_t oldRBIEStatus;
  uint8_t oldSerTxStatus;

  fInterruptFlags = __nesc_atomic_start(); 
  
  if ((SleepMode_disabled) || (TOSH_sched_full != TOSH_sched_free)) {
    __nesc_atomic_end(fInterruptFlags);
    return;
  }
  else {
    if((ReadTimer1()<0xffAf) 
       && ADCON0bits_GO == 0             // check if ad-coversion is running
       && SSPCON1bits_SSPEN == 0         // check if mssp (i2c,spi) is active
       && T1CONbits_T1OSCEN == 1         // ensure that timer 1 is active and we have a wake-up source
       && T1CONbits_TMR1ON ==1 
       && PIE1bits_TMR1IE == 1){

      oldRxAntStatus = PORTDbits_RD6;    // save old rx_ant-status
      oldRxStatus = PORTCbits_RC2;       // save old rx-status
      oldADCStatus = ADCON0bits_ADON;    // save old ADCON0-status
      oldRBIEStatus = INTCONbits_RBIE;   // save old RBIE status
      oldSerTxStatus = TRISCbits_TRISC6; // save old Ser-Tx pin status
 
      if(VrefSleep_enabled){
	LATDbits_LATD5 = 0;               // turn off the voltage reference
      }
      INTCONbits_RBIE = 0x0;             // disable the radio interrupt
      LATDbits_LATD6 = 0x0;               // switch off rx-antenna
      LATCbits_LATC2 = 0X1;               // switch off receiver

      ADCON0bits_ADON = 0;               // switch off the adc
   
      TRISCbits_TRISC6 =0x1;             // make SER_TX INPUT to save energy in sleep
      
      __nesc_atomic_end(fInterruptFlags);
 
      asm_sleep = 1;                     // enter sleep mode, becomes modified by perl script to sleep command

      if(VrefSleep_enabled){
      	LATDbits_LATD5 = 1;               // if sleep mode is enabled we have to power up the voltage reference and wait unitl Vref is stable
	TOSH_mswait(5);                  // -> Vref needs 750 us to reach a peak value of 4.2 V  and from that point additional 4.5 ms until 
	TOSH_uwait(250);                 //    stable Vref = 4.096 V are reached
                                         // -> so wait 5,25 ms until Vref is stable  
      }

      TRISCbits_TRISC6 = oldSerTxStatus; // old Ser-Tx pin status
      LATDbits_LATD6 = oldRxAntStatus;    // old rx-ant-status
      LATCbits_LATC2 = oldRxStatus;       // old rx-status
      ADCON0bits_ADON = oldADCStatus;    // old ADCON0-status
      INTCONbits_RBIE= oldRBIEStatus;    // old RBIE status
    }
    else __nesc_atomic_end(fInterruptFlags); 
  }
}




#endif // _Hpic18f4620_h



