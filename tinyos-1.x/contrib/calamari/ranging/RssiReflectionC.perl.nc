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
// $Id: RssiReflectionC.perl.nc,v 1.1 2003/10/09 05:56:04 fredjiang Exp $


configuration ${Reflection}C
{
  provides interface ${Attribute}Reflection;
  provides interface ${Attribute}ReflectionSnoop;
  provides interface StdControl;
}
implementation
{
  components ${Reflection}M, ${Attribute}C, ${Neighborhood}C
			  ,${TxrCalibCoeffsAttr}C
			  ,${TxrCalibCoeffsRefl}C
			  ,${DistanceRefl}C
//			  ,${RssiRanging}C
			  ;

  ${Attribute}Reflection = ${Reflection}M.${Attribute}Reflection;
  ${Attribute}ReflectionSnoop = ${Reflection}M.${Attribute}ReflectionSnoop;
  StdControl = ${Reflection}M.StdControl;

  ${Reflection}M.${Attribute} -> ${Attribute}C.${Attribute};
  ${Reflection}M.DataComm -> ${Neighborhood}C.NeighborhoodComm[${DataProtocol}];
  ${Reflection}M.PullComm -> ${Neighborhood}C.NeighborhoodComm[${PullProtocol}];
  ${Reflection}M.${Neighborhood}_private -> ${Neighborhood}C.${Neighborhood}_private;
  ${Reflection}M.${TxrCalibCoeffsAttr}->${TxrCalibCoeffsAttr}C;
  ${Reflection}M.${TxrCalibCoeffsAttr}Reflection->${TxrCalibCoeffsRefl}C;
  ${Reflection}M.${DistanceAttr}Reflection->${DistanceRefl}C;
//  ${Reflection}M.Rssi->${RssiRanging}C;
}

