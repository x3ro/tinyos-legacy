/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/10/19 14:00:59 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
module MultipleTimerM {
  provides interface Timer[uint8_t num];
  uses {
    interface Timer as Timer0;
    interface Timer as Timer1;
    interface Timer as Timer2;
    interface Timer as Timer3;
    interface Timer as Timer4;
    interface Timer as Timer5;
    interface Timer as Timer6;
    interface Timer as Timer7;
    interface Timer as Timer8;
    interface Timer as Timer9;
  }
}
implementation {

  command result_t Timer.start[uint8_t num](char type, uint32_t interval)
  {
    switch (num)
    {
      case 0: return call Timer0.start(type, interval); break;
      case 1: return call Timer1.start(type, interval); break;
      case 2: return call Timer2.start(type, interval); break;
      case 3: return call Timer3.start(type, interval); break;
      case 4: return call Timer4.start(type, interval); break;
      case 5: return call Timer5.start(type, interval); break;
      case 6: return call Timer6.start(type, interval); break;
      case 7: return call Timer7.start(type, interval); break;
      case 8: return call Timer8.start(type, interval); break;
      case 9: return call Timer9.start(type, interval); break;
    }
    return SUCCESS;
  }
  
  command result_t Timer.stop[uint8_t num]()
  {
    switch (num)
    {
      case 0: return call Timer0.stop(); break;
      case 1: return call Timer1.stop(); break;
      case 2: return call Timer2.stop(); break;
      case 3: return call Timer3.stop(); break;
      case 4: return call Timer4.stop(); break;
      case 5: return call Timer5.stop(); break;
      case 6: return call Timer6.stop(); break;
      case 7: return call Timer7.stop(); break;
      case 8: return call Timer8.stop(); break;
      case 9: return call Timer9.stop(); break;
    }
    return SUCCESS;
  }

  event result_t Timer0.fired(){ return signal Timer.fired[0]();}
  event result_t Timer1.fired(){ return signal Timer.fired[1]();}
  event result_t Timer2.fired(){ return signal Timer.fired[2]();}
  event result_t Timer3.fired(){ return signal Timer.fired[3]();}
  event result_t Timer4.fired(){ return signal Timer.fired[4]();}
  event result_t Timer5.fired(){ return signal Timer.fired[5]();}
  event result_t Timer6.fired(){ return signal Timer.fired[6]();}
  event result_t Timer7.fired(){ return signal Timer.fired[7]();}
  event result_t Timer8.fired(){ return signal Timer.fired[8]();}
  event result_t Timer9.fired(){ return signal Timer.fired[9]();}
}
