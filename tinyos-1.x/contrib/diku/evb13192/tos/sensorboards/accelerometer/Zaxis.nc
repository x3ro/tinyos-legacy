/* Configuration for using the Zaxis accelerometer sensor

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
 * Configuration for using the Zaxis accelerometer sensor.
 * 
 * @author Marcus Chang <marcus@diku.dk>
 * @author Mads Bondo Dydensborg <madsdyd@diku.dk>
 */

includes sensorboard;
configuration Zaxis {
  provides interface ADC as Zaxis;
  provides interface StdControl;
}
implementation {
  components ZaxisM, ADCC;
  
  StdControl = ZaxisM;

  /** Use an instance of an ADC for the Zaxis ADC */
  Zaxis = ADCC.ADC[TOSH_ADC_ZAXIS_PORT];

  /** And, map the ADCControl interface we use to the one provided by the ADCC */
  ZaxisM.ADCControl -> ADCC;
}
