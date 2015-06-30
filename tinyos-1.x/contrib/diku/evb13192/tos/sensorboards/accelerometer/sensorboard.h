/* SARD sensorboard header file.

  Copyright (C) 2005 Marcus, <marcus@diku.dk>
  Copyright (C) 2004 Mads Bondo Dydensborg <madsdyd@diku.dk>

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
 * SARD sensorboard header file.
 * 
 * @author Marcus Chang<marcus@diku.dk>
 * @author Mads Bondo Dydensborg <madsdyd@diku.dk>
 */

/**
 * The number of portmappings, needed by the TinyOS ADC
 * infrastructure.
 */
enum {
  TOSH_ADC_PORTMAPSIZE = 3
};


/** 
 * Define mappings from the sensors to the ports of the evb13192 ADC,
 * as numbered in section 14.6.2 of the hcs08 data sheet. */
enum {
  TOSH_ACTUAL_XAXIS_PORT = 0, /* AD0 / PTB0 */
  TOSH_ACTUAL_YAXIS_PORT = 1, /* AD1 / PTB1 */
  TOSH_ACTUAL_ZAXIS_PORT = 7, /* AD7 / PTB7 */
};

/**
 * Enable/disable the three ports.
 *
 * Note: This is a hack - we should not have machine code in here, I
 * think. 
 */
#define TOSH_XAXIS_PORT_ENABLE()  ATDPE_ATDPE0=1
#define TOSH_XAXIS_PORT_DISABLE() ATDPE_ATDPE0=0
#define TOSH_YAXIS_PORT_ENABLE()  ATDPE_ATDPE1=1
#define TOSH_YAXIS_PORT_DISABLE() ATDPE_ATDPE1=0
#define TOSH_ZAXIS_PORT_ENABLE()  ATDPE_ATDPE7=1
#define TOSH_ZAXIS_PORT_DISABLE() ATDPE_ATDPE7=0


/**
 * Define the port numbers we will be using internally in the ADC driver.
 * 
 * <p>Note: I believe you must number them from 0, and not use more
 * than TOSH_ADC_PORTMAPSIZE.</p>
 */
enum {
  TOSH_ADC_XAXIS_PORT = 0,
  TOSH_ADC_YAXIS_PORT = 1,
  TOSH_ADC_ZAXIS_PORT = 2,
};

