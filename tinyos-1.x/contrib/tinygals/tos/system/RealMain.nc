// $Id: RealMain.nc,v 1.1 2004/03/29 21:35:32 celaine Exp $

/* Copyright (C) 2003-2004 Palo Alto Research Center
 *
 * The attached "TinyGALS" software is provided to you under the terms and
 * conditions of the GNU General Public License Version 2 as published by the
 * Free Software Foundation.
 *
 * TinyGALS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with TinyGALS; see the file COPYING.  If not, write to
 * the Free Software Foundation, 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

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
 *
 * Authors:		Jason Hill, David Gay, Philip Levis, Elaine Cheong
 * Date last modified:  $Id: RealMain.nc,v 1.1 2004/03/29 21:35:32 celaine Exp $
 *
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 * @author Elaine Cheong
 */

// This RealMain is modified to call the TinyGALS scheduler.

module RealMain {
  uses {
    command result_t hardwareInit();
    interface StdControl;
    interface Pot;
  }
}
implementation
{
  int main() __attribute__ ((C, spontaneous)) {
    call hardwareInit();
    call Pot.init(10);
    TOSH_sched_init();

    GALSC_sched_init();  // initialize scheduler structures
    GALSC_sched_start(); // put tokens in port queues
    
    call StdControl.init();
    call StdControl.start();
    __nesc_enable_interrupt();

    while(1) {
        GALSC_run_task();
    }
  }
}
