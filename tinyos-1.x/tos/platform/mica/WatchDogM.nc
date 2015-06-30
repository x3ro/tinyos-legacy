// $Id: WatchDogM.nc,v 1.4 2003/10/07 21:46:29 idgay Exp $

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
 * Authors:		Su Ping  <sping@intel-research.net>
 *
 */



/**
 * The Watch dog interface. 
 * When enabled, the watch dog will reset a mote at a specified time
 * @author Su Ping <sping@intel-research.net>
 **/
includes TosTime;
module WatchDogM {
    provides interface WatchDog;
    uses {
        interface AbsoluteTimer as AbsoluteTimer2;
        interface Random;
        interface TimeUtil;
    }
}

implementation {

    command result_t WatchDog.set(tos_time_t t ) {
        uint16_t delta = call Random.rand();
        delta = (delta>>8)|(delta & 0xFF); 
        // add a random delay ranging from 0 to 512 seconds
        t = call TimeUtil.addUint32(t, delta<<10);
        return call AbsoluteTimer2.set(t);
        
    }

    command result_t WatchDog.cancel() {
        
        return  call AbsoluteTimer2.cancel();
    }
    
    /** AbsoluteTimer event. Enable watch dog timer and 
     *  set its timeout period 34 ms
     **/  
    event result_t AbsoluteTimer2.fired() {
        TOSH_CLR_YELLOW_LED_PIN();
        wdt_enable(1);
        return SUCCESS ;
    }
}

