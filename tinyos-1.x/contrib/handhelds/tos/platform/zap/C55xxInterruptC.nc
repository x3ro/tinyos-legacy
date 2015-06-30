//$Id: C55xxInterruptC.nc,v 1.1 2005/07/29 18:29:30 adchristian Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Joe Polastre

configuration C55xxInterruptC
{
  provides interface C55xxInterrupt as Port10;
  provides interface C55xxInterrupt as Port11;
  provides interface C55xxInterrupt as Port12;
  provides interface C55xxInterrupt as Port13;
  provides interface C55xxInterrupt as Port14;
  provides interface C55xxInterrupt as Port15;
  provides interface C55xxInterrupt as Port16;
  provides interface C55xxInterrupt as Port17;
}
implementation
{
  components C55xxInterruptM;

  Port10 = C55xxInterruptM.Port10;
  Port11 = C55xxInterruptM.Port11;
  Port12 = C55xxInterruptM.Port12;
  Port13 = C55xxInterruptM.Port13;
  Port14 = C55xxInterruptM.Port14;
  Port15 = C55xxInterruptM.Port15;
  Port16 = C55xxInterruptM.Port16;
  Port17 = C55xxInterruptM.Port17;
}

