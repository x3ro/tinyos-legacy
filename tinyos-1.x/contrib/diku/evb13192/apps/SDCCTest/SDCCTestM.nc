/*
    ConsoleTest program - tests Console module somewhat.
    Copyright (C) 2002 Mads Bondo Dydensborg <madsdyd@diku.dk>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/



/**
 * This module tests the Console implementation.
 * 
 * <p>The Console module is debug tool only and should _NOT_ be used in
 * serious applications. It breaks the async. command/event model of
 * tinyos and is ugly in general.</p> */
module SDCCTestM { 
	provides {
		interface StdControl;
	}
	uses {
		interface Leds as Leds;
		//interface Timer as Timer;
	}
}
implementation {

	void count();

  command result_t StdControl.init() {
    //dbg(DBG_USR1, "Initializing ......\n");
    return call Leds.init();
  }

  command result_t StdControl.start() {
 	uint16_t i;
    call Leds.greenToggle();
    while(1) {
		count();
	}
	//call Leds.greenToggle();
    //return call Timer.start(TIMER_REPEAT, 500);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    //dbg(DBG_USR1, "Stopping ......\n");
    return SUCCESS;
  }

  void count() {
    uint32_t i;
    for(i=0;i<120000;i++) {
      	asm("nop");
    }
    call Leds.yellowToggle();
  }

/*  event result_t Timer.fired() {
    call Leds.greenToggle();
  }*/
}
