/* $Id: DemoSensorC.nc,v 1.1 2005/01/31 21:05:55 freefrag Exp $ */
/* DemoSensor configuration, maps our light onto a demosensor, 
   for use with e.g. the Osc. applications.

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
 * DemoSensor - map Light onto DemoSensor.
 * 
 * @author Mads Bondo Dydensborg <madsdyd@diku.dk>
 */
configuration DemoSensorC {
  provides {
    interface ADC;
    interface StdControl;
  }
}
implementation {
  components Light;
  StdControl = Light;
  ADC = Light;
}
