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
// $Id: NeighborhoodC.perl.nc,v 1.9 2003/06/20 06:43:08 cssharp Exp $


configuration ${Neighborhood}C
{
  provides interface Neighborhood;
  provides interface NeighborhoodComm[ RoutingProtocol_t proto ];
  provides interface ${Neighborhood}_private;
  provides interface StdControl;
}
implementation
{
  components ${ReflectionComponentList} 
	     ${CommandComponentList}
             ${Neighborhood}M, ${Manager}C, ${Neighborhood}CommBackendC, MsgBuffersC;

  Neighborhood = ${Neighborhood}M.Neighborhood;
  NeighborhoodComm = ${Neighborhood}M.NeighborhoodComm;
  ${Neighborhood}_private = ${Neighborhood}M.${Neighborhood}_private;
  StdControl = ${Neighborhood}M.StdControl;

  ${Neighborhood}M.NeighborhoodManager -> ${Manager}C.NeighborhoodManager;
  ${Neighborhood}M.NeighborhoodCommBackend -> ${Neighborhood}CommBackendC.NeighborhoodCommBackend;
  ${Neighborhood}M.ManagerStdControl -> ${Manager}C.StdControl;
  ${Neighborhood}M.CommBackendStdControl -> ${Neighborhood}CommBackendC.StdControl;
  ${Neighborhood}M.MsgBuffers -> MsgBuffersC;

${ReflectionStdControlWiring}

${CommandStdControlWiring}
}

