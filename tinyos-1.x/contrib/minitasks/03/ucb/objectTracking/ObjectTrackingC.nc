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

// Authors: Cory Sharp and Kamin Whitehouse

includes Neighborhood;
includes Routing;

configuration ObjectTrackingC
{
}
implementation
{
	components Main
		 , ObjectTrackingM
		 , LocalizationByAddressC
		 , ClockC
		 , ADCC
		 , LedsC
		 , GenericComm

		 , LocationAttrM
		 , LocationReflC
		 , AnchorHoodC
		 , SensorAttrM
		 , SensorReflC
		 , ObjectLocationAttrM
		 ;

	Main.StdControl->ObjectTrackingM;
	Main.StdControl->ClockC;
	Main.StdControl->GenericComm;
	Main.StdControl->LocalizationByAddressC;
	Main.StdControl->GenericComm;

	ObjectTrackingM.Clock->ClockC;
	ObjectTrackingM.Leds->LedsC;
	ObjectTrackingM.ADC->ADCC.ADC[2];

        ObjectTrackingM.SensorAttr->SensorAttrM;
        ObjectTrackingM.LocationAttr->LocationAttrM;
        ObjectTrackingM.ObjectLocationAttr->ObjectLocationAttrM;
        ObjectTrackingM.SensorRefl->SensorReflC;
        ObjectTrackingM.LocationRefl->LocationReflC;
        ObjectTrackingM.AnchorHood->AnchorHoodC;

        ObjectTrackingM.SensorAttrControl->SensorAttrM;
        ObjectTrackingM.ObjectLocationAttrControl->ObjectLocationAttrM;
        ObjectTrackingM.AnchorHoodControl->AnchorHoodC;

}

