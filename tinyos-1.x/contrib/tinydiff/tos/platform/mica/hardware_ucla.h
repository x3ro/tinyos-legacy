 /*                                                                      tab:4
 * 
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 *
 *
 */

#ifndef __HARDWARE_UCLA__
#define __HARDWARE_UCLA__

/* Timer/counter names
 * ITC_8	Internal 8bit timer/counter (timer 2 in mica)
 * ITC_16	Internal 16bit timer/counter (timer 1 in mica and rene)
 * ETC_8	External 8bit timer/counter (timer 0 in mica, 2 in rene
*/

#define ITC_8	3
#define ITC_16	2
#define ETC_8	1

/* Counter signals/registers definitions */
#define SIG_OUTPUT_COMPARE_ETC_8	SIG_OUTPUT_COMPARE0
#define SIG_OUTPUT_COMPARE_ITC_16A	SIG_OUTPUT_COMPARE1A
#define SIG_OUTPUT_COMPARE_ITC_16B	SIG_OUTPUT_COMPARE1B
#define SIG_OVERFLOW_ETC_8			SIG_OVERFLOW0
#define SIG_OVERFLOW_ITC_8			SIG_OVERFLOW2
#define SIG_OVERFLOW_ITC_16			SIG_OVERFLOW1

#define OCR_ITC_8		OCR2
#define OCIE_ITC_16A	OCIE1A
#define OCIE_ITC_16B	OCIE1B
#define OCR_ETC_8		OCR0
#define OCR_ITC_16AL	OCR1AL
#define OCR_ITC_16AH	OCR1AH
#define OCR_ITC_16BL	OCR1BL
#define OCR_ITC_16BH	OCR1BH
#define ICR_ITC_16L		ICR1L
#define ICR_ITC_16H		ICR1H
#define OCIE_ETC_8		OCIE0
#define OCIE_ITC_8		OCIE2
#define TOIE_ITC_16		TOIE1
#define TOIE_ITC_8		TOIE2
#define TOIE_ETC_8		TOIE0
#define TICIE_ITC_16	TICIE1
#define OCF_ITC_16A		OCF1A
#define OCF_ITC_16B		OCF1B
#define OCF_ITC_8		OCF2
#define TOV_ITC_8		TOV2
#define ICF_ITC_16		ICF1
#define TOV_ITC_16		TOV1
#define OCF_ETC_8		OCF0
#define TOV_ETC_8		TOV0
#define TCCR_ETC_8		TCCR0
#define TCCR_ITC_8		TCCR2
#define TCNT_ETC_8		TCNT0
#define TCNT_ITC_8		TCNT2
#define TCNT_ITC_16L	TCNT1L
#define TCNT_ITC_16H	TCNT1H
#define TCCR_ITC_16A	TCCR1A
#define TCCR_ITC_16B	TCCR1B

#define AS_ETC_8		AS0

#endif //__HARDWARE__




