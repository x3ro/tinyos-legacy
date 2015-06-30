/* $Id: Temp.nc,v 1.1 2005/01/31 21:05:56 freefrag Exp $ */
/* Configuration for using the Temp sensor

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
 * Configuration for using the Temp sensor.
 * 
 * @author Mads Bondo Dydensborg <madsdyd@diku.dk>
 */

includes sensorboard;
configuration Temp {
  provides interface ADC as Temp;
  provides interface StdControl;
}
implementation {
  components TempM, ADCC;
  
  StdControl = TempM;
  /** Use an instance of an ADC for the Temp ADC */
  Temp = ADCC.ADC[TOSH_ADC_TEMP_PORT];
  /** And, map the ADCControl interface we use to the one provided by the ADCC */
  TempM.ADCControl -> ADCC;
}
