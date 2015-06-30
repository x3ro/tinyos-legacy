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
 *
 * Authors:		Phil Buonadonna
 * Date last modified:  $Id: HPLTWI.h,v 1.1 2003/10/31 22:38:27 idgay Exp $
 */

// define TWI device status codes. 
enum {
  TWS_BUSERROR		= 0x00,
  TWS_START		= 0x08,
  TWS_RSTART		= 0x10,
  TWS_MT_SLA_ACK	= 0x18,
  TWS_MT_SLA_NACK	= 0x20,
  TWS_MT_DATA_ACK	= 0x28,
  TWS_MT_DATA_NACK	= 0x30,
  TWS_M_ARB_LOST	= 0x38,
  TWS_MR_SLA_ACK	= 0x40,
  TWS_MR_SLA_NACK	= 0x48,
  TWS_MR_DATA_ACK	= 0x50,
  TWS_MR_DATA_NACK	= 0x58,
  TWS_SR_SLA_ADDR     	= 0x60,
  TWS_S_ARB_LOST      	= 0x68,
  TWS_SR_SLA_GEN_ADDR 	= 0x70,
  TWS_S_ARB_LOST_GEN  	= 0x78,
  TWS_SR_DATA_ACK     	= 0x80,
  TWS_SR_DATA_NACK    	= 0x88,
  TWS_SR_GEN_DATA_ACK 	= 0x90,
  TWS_SR_GEN_DATA_NACK	= 0x98,
  TWS_SR_STOP_RSTART  	= 0xA0,
  TWS_ST_SLA_ADDR     	= 0xA8,
  TWS_ST_ARB_LOST     	= 0xB0,
  TWS_ST_DATA_ACK     	= 0xB8,
  TWS_ST_DATA_NACK    	= 0xC0,
  TWS_ST_DATA_END     	= 0xC8
};


