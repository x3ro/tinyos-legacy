/*
  Program to test the LedDebug component.

  Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>

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


module TestLedDebugM {
  provides {
    interface StdControl;
  }
  uses {
    interface LedDebugI as Debug;
  }
}

implementation {
  /**
   * Delay approximately 0.5 sec.
   *
   * <p>This function loops a number of times, doing <code>nop</code>. This is
   * used after crashing, so we can not use the clock or interrupts. */
  static void delay() {
    long j;
    for (j=0 ; j<=1356648/2 ; j++) {//app 0.5 s at 7 Mhz
      asm volatile ("nop"::);
    }
  }

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    int i;
    for (i = 0; i < 16; i++) {
      call Debug.debug(i);
      delay();
    }
    call Debug.fail4(1, 2, 4, 8);
    return SUCCESS;
  }

  /** Empty stop. */
  command result_t StdControl.stop() {
    return SUCCESS;
  }
}


