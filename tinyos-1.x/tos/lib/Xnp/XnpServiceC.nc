// $Id: XnpServiceC.nc,v 1.3 2003/10/07 21:46:27 idgay Exp $

/* "Copyright (c) 2000-2002 The Regents of the University of California.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 */

configuration XnpServiceC
{
  provides interface StdControl as XnpRequiredControl;
  provides interface StdControl as XnpServiceControl;
}
implementation
{
  components XnpServiceM, XnpC, TimedLedsC, TimerC;

  XnpRequiredControl = XnpServiceM.XnpRequiredControl;
  XnpServiceControl = XnpServiceM.XnpServiceControl;

  XnpServiceM.Xnp -> XnpC;
  XnpServiceM.XnpControl -> XnpC;
  XnpServiceM.TimedLeds -> TimedLedsC;
  XnpServiceM.Timer -> TimerC.Timer[unique("Timer")];
}

