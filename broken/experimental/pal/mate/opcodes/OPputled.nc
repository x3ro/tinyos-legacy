/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*									tab:4
 *									
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 *  By downloading, copying, installing or using the software you
 *  agree to this license.  If you do not agree to this license, do
 *  not download, install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */

/*
 * Authors:   Philip Levis <pal@cs.berkeley.edu>
 * History:   Apr 11, 2003         Inception.
 *
 */

includes Bombilla;
includes BombillaMsgs;

module OPputled {
  provides interface BombillaBytecode;
  uses {
    interface BombillaStacks;
    interface BombillaTypes;
    interface Leds;
  }
}

implementation {

  command result_t BombillaBytecode.execute(uint8_t instr,
					    BombillaContext* context,
					    BombillaState* state) {
    uint16_t val;
    BombillaStackVariable* arg = call BombillaStacks.popOperand(context);
    if (!call BombillaTypes.checkTypes(context, arg, BOMB_VAR_V)) {
      return FAIL;
    }
    else {
      uint8_t op;
      uint8_t led;

      val = arg->value.var;
      op = (val >> 3) & 3;
      led = val & 7;
      dbg(DBG_USR1, "VM (%i): Executing OPputled with op %i and led %i.\n", (int)context->which, (int)op, (int)led);
      
      switch (op) {
      case 0:			/* set */
	if (led & 1) call Leds.redOn();
	else call Leds.redOff();
	if (led & 2) call Leds.greenOn();
	else call Leds.greenOff();
	if (led & 4) call Leds.yellowOn();
	else call Leds.yellowOff();
	break;
      case 1:			/* OFF 0 bits */
	if (!(led & 1)) call Leds.redOff();
	if (!(led & 2)) call Leds.greenOff();
	if (!(led & 4)) call Leds.yellowOff();
	break;
      case 2:			/* on 1 bits */
	if (led & 1) call Leds.redOn();
	if (led & 2) call Leds.greenOn();
	if (led & 4) call Leds.yellowOn();
	break;
      case 3:			/* TOGGLE 1 bits */
	if (led & 1) call Leds.redToggle();
	if (led & 2) call Leds.greenToggle();
	if (led & 4) call Leds.yellowToggle();
	break;
      default:
	dbg(DBG_ERROR, ("VM: LED command had unknown operations.\n"));
	return FAIL;
      }
    }
    return SUCCESS;
  }
}
