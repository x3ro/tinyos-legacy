/*									tab:4
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
 * @file  PXA27XUDCRegAddrs.h
 * @author:		Josh Herbach
 * Revision:	1.0
 * Date:		09/02/2005
 */

#ifndef __UDCREGADDRS_H
#define __UDCREGADDRS_H

#define _udccr ((volatile unsigned long * const) 0x40600000)
#define _udcicr0 ((volatile unsigned long * const) 0x40600004)
#define _udcicr1 ((volatile unsigned long * const) 0x40600008)
#define _udcisr0 ((volatile unsigned long * const) 0x4060000C)
#define _udcisr1 ((volatile unsigned long * const) 0x40600010)
#define _udcfnr ((volatile unsigned long * const) 0x40600014)
#define _udcotgicr ((volatile unsigned long * const) 0x40600018)
#define _udcotgisr ((volatile unsigned long * const) 0x4060001C)
#define _up2ocr ((volatile unsigned long * const) 0x40600020)
#define _up3ocr ((volatile unsigned long * const) 0x40600024)
#define _udccsr0 ((volatile unsigned long * const) 0x40600100)
#define _udccsra ((volatile unsigned long * const) 0x40600104)
#define _udccsrb ((volatile unsigned long * const) 0x40600108)
#define _udccsrc ((volatile unsigned long * const) 0x4060010C)
#define _udccsrd ((volatile unsigned long * const) 0x40600110)
#define _udccsre ((volatile unsigned long * const) 0x40600114)
#define _udccsrf ((volatile unsigned long * const) 0x40600118)
#define _udccsrg ((volatile unsigned long * const) 0x4060011C)
#define _udccsrh ((volatile unsigned long * const) 0x40600120)
#define _udccsri ((volatile unsigned long * const) 0x40600124)
#define _udccsrj ((volatile unsigned long * const) 0x40600128)
#define _udccsrk ((volatile unsigned long * const) 0x4060012C)
#define _udccsrl ((volatile unsigned long * const) 0x40600130)
#define _udccsrm ((volatile unsigned long * const) 0x40600134)
#define _udccsrn ((volatile unsigned long * const) 0x40600138)
#define _udccsrp ((volatile unsigned long * const) 0x4060013C)
#define _udccsrq ((volatile unsigned long * const) 0x40600140)
#define _udccsrr ((volatile unsigned long * const) 0x40600144)
#define _udccsrs ((volatile unsigned long * const) 0x40600148)
#define _udccsrt ((volatile unsigned long * const) 0x4060014C)
#define _udccsru ((volatile unsigned long * const) 0x40600150)
#define _udccsrv ((volatile unsigned long * const) 0x40600154)
#define _udccsrw ((volatile unsigned long * const) 0x40600158)
#define _udccsrx ((volatile unsigned long * const) 0x4060015C)
#define _udcbcr0 ((volatile unsigned long * const) 0x40600200)
#define _udcbcra ((volatile unsigned long * const) 0x40600204)
#define _udcbcrb ((volatile unsigned long * const) 0x40600208)
#define _udcbcrc ((volatile unsigned long * const) 0x4060020C)
#define _udcbcrd ((volatile unsigned long * const) 0x40600210)
#define _udcbcre ((volatile unsigned long * const) 0x40600214)
#define _udcbcrf ((volatile unsigned long * const) 0x40600218)
#define _udcbcrg ((volatile unsigned long * const) 0x4060021C)
#define _udcbcrh ((volatile unsigned long * const) 0x40600220)
#define _udcbcri ((volatile unsigned long * const) 0x40600224)
#define _udcbcrj ((volatile unsigned long * const) 0x40600228)
#define _udcbcrk ((volatile unsigned long * const) 0x4060022C)
#define _udcbcrl ((volatile unsigned long * const) 0x40600230)
#define _udcbcrm ((volatile unsigned long * const) 0x40600234)
#define _udcbcrn ((volatile unsigned long * const) 0x40600238)
#define _udcbcrp ((volatile unsigned long * const) 0x4060023C)
#define _udcbcrq ((volatile unsigned long * const) 0x40600240)
#define _udcbcrr ((volatile unsigned long * const) 0x40600244)
#define _udcbcrs ((volatile unsigned long * const) 0x40600248)
#define _udcbcrt ((volatile unsigned long * const) 0x4060024C)
#define _udcbcru ((volatile unsigned long * const) 0x40600250)
#define _udcbcrv ((volatile unsigned long * const) 0x40600254)
#define _udcbcrw ((volatile unsigned long * const) 0x40600258)
#define _udcbcrx ((volatile unsigned long * const) 0x4060025C)
#define _udcdr0 ((volatile unsigned long * const) 0x40600300)
#define _udcdra ((volatile unsigned long * const) 0x40600304)
#define _udcdrb ((volatile unsigned long * const) 0x40600308)
#define _udcdrc ((volatile unsigned long * const) 0x4060030C)
#define _udcdrd ((volatile unsigned long * const) 0x40600310)
#define _udcdre ((volatile unsigned long * const) 0x40600314)
#define _udcdrf ((volatile unsigned long * const) 0x40600318)
#define _udcdrg ((volatile unsigned long * const) 0x4060031C)
#define _udcdrh ((volatile unsigned long * const) 0x40600320)
#define _udcdri ((volatile unsigned long * const) 0x40600324)
#define _udcdrj ((volatile unsigned long * const) 0x40600328)
#define _udcdrk ((volatile unsigned long * const) 0x4060032C)
#define _udcdrl ((volatile unsigned long * const) 0x40600330)
#define _udcdrm ((volatile unsigned long * const) 0x40600334)
#define _udcdrn ((volatile unsigned long * const) 0x40600338)
#define _udcdrp ((volatile unsigned long * const) 0x4060033C)
#define _udcdrq ((volatile unsigned long * const) 0x40600340)
#define _udcdrr ((volatile unsigned long * const) 0x40600344)
#define _udcdrs ((volatile unsigned long * const) 0x40600348)
#define _udcdrt ((volatile unsigned long * const) 0x4060034C)
#define _udcdru ((volatile unsigned long * const) 0x40600350)
#define _udcdrv ((volatile unsigned long * const) 0x40600354)
#define _udcdrw ((volatile unsigned long * const) 0x40600358)
#define _udcdrx ((volatile unsigned long * const) 0x4060035C)
#define _udccra ((volatile unsigned long * const) 0x40600404)
#define _udccrb ((volatile unsigned long * const) 0x40600408)
#define _udccrc ((volatile unsigned long * const) 0x4060040C)
#define _udccrd ((volatile unsigned long * const) 0x40600410)
#define _udccre ((volatile unsigned long * const) 0x40600414)
#define _udccrf ((volatile unsigned long * const) 0x40600418)
#define _udccrg ((volatile unsigned long * const) 0x4060041C)
#define _udccrh ((volatile unsigned long * const) 0x40600420)
#define _udccri ((volatile unsigned long * const) 0x40600424)
#define _udccrj ((volatile unsigned long * const) 0x40600428)
#define _udccrk ((volatile unsigned long * const) 0x4060042C)
#define _udccrl ((volatile unsigned long * const) 0x40600430)
#define _udccrm ((volatile unsigned long * const) 0x40600434)
#define _udccrn ((volatile unsigned long * const) 0x40600438)
#define _udccrp ((volatile unsigned long * const) 0x4060043C)
#define _udccrq ((volatile unsigned long * const) 0x40600440)
#define _udccrr ((volatile unsigned long * const) 0x40600444)
#define _udccrs ((volatile unsigned long * const) 0x40600448)
#define _udccrt ((volatile unsigned long * const) 0x4060044C)
#define _udccru ((volatile unsigned long * const) 0x40600450)
#define _udccrv ((volatile unsigned long * const) 0x40600454)
#define _udccrw ((volatile unsigned long * const) 0x40600458)
#define _udccrx ((volatile unsigned long * const) 0x4060045C)

#endif
