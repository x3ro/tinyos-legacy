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

// Authors: Cory Sharp
// $Id: CameraPointer.nc,v 1.3 2003/01/27 21:30:12 cssharp Exp $

includes CameraPointer;

configuration CameraPointer
{
}
implementation
{
  components Main
           , CameraPointerM
	   , NestArchStdControlC
	   , RoutingC
	   , PTZCameraWorldC
	   , LedsC as Leds
	   ;

  Main -> CameraPointerM.StdControl;
  Main -> NestArchStdControlC.StdControl;

  CameraPointerM -> Leds.Leds;
  CameraPointerM -> PTZCameraWorldC.PTZCameraWorld;
  CameraPointerM -> PTZCameraWorldC.StdControl;
  CameraPointerM -> RoutingC.RoutingReceive[ PROTOCOL_CAMERA_POINTER ];
}

