/* "Copyright (c) 2000-2003 The Regents of the University of California.  
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
// $Id: UltrasoundReflectionC.perl.nc,v 1.8 2003/10/02 18:16:45 ckarlof Exp $


configuration ${Reflection}C
{
  provides interface ${Attribute}Reflection;
  provides interface ${Attribute}ReflectionSnoop;
  provides interface StdControl;
  provides interface RangingControl;
  provides interface AnchorInfoPropagation;
}
implementation
{
	components ${Reflection}M, ${Attribute}C, ${Neighborhood}C, MostRecentNeighborsC,
		DiagMsgC,
		LedsC,
		TransmitterC as UltrasoundRangingActuatorC,
		ReceiverC as UltrasoundRangingSensorC,
		TimerC,
		MsgBuffersC,
	        RandomLFSR;

  ${Attribute}Reflection = ${Reflection}M.${Attribute}Reflection;
  ${Attribute}ReflectionSnoop = ${Reflection}M.${Attribute}ReflectionSnoop;
  StdControl = ${Reflection}M.StdControl;
  StdControl			= UltrasoundRangingActuatorC;
  StdControl			= UltrasoundRangingSensorC;

  ${Reflection}M.${Attribute} -> ${Attribute}C.${Attribute};
  ${Reflection}M.PullComm -> ${Neighborhood}C.NeighborhoodComm[${PullProtocol}];
  ${Reflection}M.${Neighborhood} -> ${Neighborhood}C;
  ${Reflection}M.${Neighborhood}_private -> ${Neighborhood}C.${Neighborhood}_private;

  ${Reflection}M.addNeighbor -> MostRecentNeighborsC;
  ${Reflection}M.UltrasonicRangingTransmitter -> UltrasoundRangingActuatorC;
  ${Reflection}M.UltrasonicRangingReceiver    -> UltrasoundRangingSensorC;
  
  ${Reflection}M.DiagMsg   -> DiagMsgC;
  ${Reflection}M.Leds	-> LedsC;
  ${Reflection}M.Random	-> RandomLFSR;
  ${Reflection}M.Timer    -> TimerC.Timer[unique("Timer")];
  ${Reflection}M.MsgBuffers -> MsgBuffersC;
  ${Reflection}M.RangingControl = RangingControl;
  ${Reflection}M.AnchorInfoPropagation = AnchorInfoPropagation;

}
