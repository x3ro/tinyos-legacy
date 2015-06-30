// $Id: AttrNewAccel.nc,v 1.2 2004/07/20 17:45:15 ammbot Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/* 
 * Authors:  Alan Mainwaring
 *           Intel Research Berkeley Lab
 * Date:     7/14/2004
 *
 */
// component to expose Accelerometer readings as an attribute

/**
 * @author Alan Mainwaring
 * @author Intel Research Berkeley Lab
 */

#if defined(BOARD_MEP401)
#define PRESENT
#endif

configuration AttrNewAccel
{
  provides 
  {
    interface StdControl;
  }
}

implementation
{
  components 
#ifdef PRESENT
  Accel, 
#endif
  AttrNewAccelM, Attr, LedsC;

#ifdef PRESENT
  AttrNewAccelM.AccelX -> Accel.ADC[1];
  AttrNewAccelM.AccelY -> Accel.ADC[2];
  AttrNewAccelM.AccelControl -> Accel;

#endif

  StdControl = AttrNewAccelM;
  AttrNewAccelM.AttrNewAccelX -> Attr.Attr[unique("Attr")];
  AttrNewAccelM.AttrNewAccelY -> Attr.Attr[unique("Attr")];
}
