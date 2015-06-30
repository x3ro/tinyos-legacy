// $Id: HPLSTM25PC.nc,v 1.1 2006/08/03 19:16:50 ayer1 Exp $

/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

includes HALSTM25P;

configuration HPLSTM25PC {
  provides {
    interface StdControl;
    interface HPLSTM25P;
  }
}

implementation {
  components 
    HPLSTM25PM, 
    BusArbitrationC, 
    HPLUSART0M,
    LedsC,
    Main;

  StdControl = HPLSTM25PM;
  HPLSTM25P = HPLSTM25PM;

  Main.StdControl -> BusArbitrationC;

  HPLSTM25PM.BusArbitration -> BusArbitrationC.BusArbitration[unique("BusArbitration")];
  HPLSTM25PM.Leds -> LedsC;
  HPLSTM25PM.USARTControl -> HPLUSART0M;
}
