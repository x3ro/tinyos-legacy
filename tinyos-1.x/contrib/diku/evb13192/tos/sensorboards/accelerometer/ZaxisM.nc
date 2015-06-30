/* Module for using the Zaxis accelerometer sensor

  Copyright (C) 2005 Marcus Chang, <marcus@diku.dk>
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
 * Module for using the Zaxis accelerometer sensor.
 * 
 * @author Marcus Chang <marcus@diku.dk>
 * @author Mads Bondo Dydensborg <madsdyd@diku.dk>
 */
includes sensorboard;
module ZaxisM {
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
    TOSH_ZAXIS_PORT_ENABLE();

    call ADCControl.bindPort(TOSH_ADC_ZAXIS_PORT, TOSH_ACTUAL_ZAXIS_PORT);
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
