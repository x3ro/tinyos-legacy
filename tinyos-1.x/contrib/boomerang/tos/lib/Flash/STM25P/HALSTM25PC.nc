// $Id: HALSTM25PC.nc,v 1.1.1.1 2007/11/05 19:11:27 jpolastre Exp $

/*									tab:4
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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

#include "crc.h"
#include "HALSTM25P.h"

configuration HALSTM25PC {
  provides {
    interface StdControl;
    interface HALSTM25P[volume_t volume];
  }
}

implementation {
  components MainSTM25PC;
  components HALSTM25PM, HPLSTM25PC, LedsC as Leds, TimerC;
  components new STM25PResourceC() as CmdRequestC;
  components new STM25PResourceC() as CmdWriteSRC;
  components new STM25PResourceC() as CmdTimerC;
  components STM25PArbiterC as ArbiterC;

  StdControl = HALSTM25PM;
  StdControl = HPLSTM25PC;
  HALSTM25P = HALSTM25PM;

  HALSTM25PM.HPLSTM25P -> HPLSTM25PC;
  HALSTM25PM.Leds -> Leds;
  HALSTM25PM.Timer -> TimerC.Timer[unique("Timer")];
  HALSTM25PM.CmdRequest -> CmdRequestC;
  HALSTM25PM.CmdWriteSR -> CmdWriteSRC;
  HALSTM25PM.CmdTimer -> CmdTimerC;
  HALSTM25PM.ResourceValidate -> ArbiterC;
}

