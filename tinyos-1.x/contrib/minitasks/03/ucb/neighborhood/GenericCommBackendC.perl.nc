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
// $Id: GenericCommBackendC.perl.nc,v 1.4 2003/05/06 16:12:59 cssharp Exp $


configuration ${Neighborhood}CommBackendC
{
  provides interface NeighborhoodCommBackend;
  provides interface StdControl;
}
implementation
{
  components ${Neighborhood}CommBackendM, GenericComm;

  NeighborhoodCommBackend = ${Neighborhood}CommBackendM.NeighborhoodCommBackend;
  StdControl = ${Neighborhood}CommBackendM.StdControl;

  ${Neighborhood}CommBackendM.SendMsg -> GenericComm.SendMsg[${CommProtocol}];
  ${Neighborhood}CommBackendM.ReceiveMsg -> GenericComm.ReceiveMsg[${CommProtocol}];
}

