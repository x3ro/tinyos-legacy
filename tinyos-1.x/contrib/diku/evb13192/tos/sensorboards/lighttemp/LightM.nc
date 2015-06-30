/* $Id: LightM.nc,v 1.1 2005/01/31 21:05:56 freefrag Exp $ */
/* Module for using the Light sensor

  Copyright (C) 2004 Mads Bondo Dydensborg, <madsdyd@diku.dk>

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
 * Module for using the Light sensor.
 * 
 * @author Mads Bondo Dydensborg <madsdyd@diku.dk>
 */
includes sensorboard;
module LightM {
  provides interface StdControl;
  uses {
    interface ADCControl;
  }
}
implementation {
  /**
   * Initialize the hardware.
   *
   * @return SUCCESS if the ADCControl init function succeds, FAIL otherwise
   */
  command result_t StdControl.init() {
    /* We configure the ports we are going to use! */
    TOSH_LIGHT_PORT_ENABLE();
    call ADCControl.bindPort(TOSH_ADC_LIGHT_PORT, TOSH_ACTUAL_LIGHT_PORT);
    return call ADCControl.init();
  }

  /**
   * Start the hardware.
   *
   * <p>Note, the hardware is always on when the sensorboard is mounted!</p>
   *
   * @return SUCCESS always
   */
  command result_t StdControl.start() {
    return SUCCESS;
  }

  /**
   * Stop the hardware.
   *
   * <p>Note, the hardware is always on when the sensorboard is mounted!</p>
   *
   * @return SUCCESS always
   */
  command result_t StdControl.stop() {
    return SUCCESS;
  }

}
