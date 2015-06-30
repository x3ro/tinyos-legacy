/* $Id: sensorboard.h,v 1.1 2005/01/31 21:05:56 freefrag Exp $ */
/* lighttemp sensorboard header file.

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
 * lighttemp sensorboard header file.
 * 
 * @author Mads Bondo Dydensborg <madsdyd@diku.dk>
 */

/**
 * The number of portmappings, needed by the TinyOS ADC
 * infrastructure.
 */
enum {
  TOSH_ADC_PORTMAPSIZE = 2
};


/** 
 * Define mappings from the sensors to the ports of the evb13192 ADC,
 * as numbered in section 14.6.2 of the hcs08 data sheet. */
enum {
  TOSH_ACTUAL_LIGHT_PORT = 2, /* AD2 / PTB2 */
  TOSH_ACTUAL_TEMP_PORT  = 3  /* AD3 / PTB3 */
};

/**
 * Enable/disable the two ports.
 *
 * Note: This is a hack - we should not have machine code in here, I
 * think. 
 */
#define TOSH_LIGHT_PORT_ENABLE()  ATDPE_ATDPE2=1
#define TOSH_LIGHT_PORT_DISABLE() ATDPE_ATDPE2=0
#define TOSH_TEMP_PORT_ENABLE()   ATDPE_ATDPE3=1
#define TOSH_TEMP_PORT_DISABLE()  ATDPE_ATDPE3=0

/**
 * Define the port numbers we will be using internally in the ADC driver.
 * 
 * <p>Note: I believe you must number them from 0, and not use more
 * than TOSH_ADC_PORTMAPSIZE.</p>
 */
enum {
  TOSH_ADC_TEMP_PORT = 0,
  TOSH_ADC_LIGHT_PORT = 1
};

