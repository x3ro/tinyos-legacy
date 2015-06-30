/*									tab:4
 * units.h
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:  Sam Madden

 Units for use in mote schemas.

 */

//"type" units
#define farenheight 0
#define celsius 1
#define amperes 2
#define volts 3
#define candela 4

//"energy" multipliers

#define mJ .001
#define uJ .000001
#define nJ .000000001
#define J 1

//"time" multipliers
#define ns .000000001
#define us .000001
#define ms .001
#define s 1

//available inputs
#define adc0 0
#define adc1 1
#define adc2 2
#define adc3 3
#define adc4 4
#define adc5 5
#define adc6 6
#define mio0 7
#define mio1 8
#define mio2 9
#define mio3 10
#define mio4 11
#define mio5 12
#define mio6 13

//possible data flow directions
#define ondemand 0
#define onchange 1
#define periodically 2
#define whenoutsiderange 3
