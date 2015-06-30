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
// $Id: CommandC.perl.nc,v 1.7 2003/06/20 06:43:08 cssharp Exp $


configuration ${Command}C
{
  provides interface ${Command};
  provides interface StdControl;
}
implementation
{
  components ${Command}M, ${Neighborhood}C, MsgBuffersC;

  ${Command} = ${Command}M.${Command};
  StdControl = ${Command}M.StdControl;

  ${Command}M.${Neighborhood}_private -> ${Neighborhood}C.${Neighborhood}_private;
  ${Command}M.CallComm -> ${Neighborhood}C.NeighborhoodComm[${CallProtocol}];
  ${Command}M.ReturnComm -> ${Neighborhood}C.NeighborhoodComm[${ReturnProtocol}];

  ${Command}M.MsgBuffers -> MsgBuffersC;
}

