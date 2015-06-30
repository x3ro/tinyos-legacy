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
// $Id: ConfigurableAttributeC.perl.nc,v 1.4 2003/06/20 06:43:08 cssharp Exp $



configuration ${Attribute}C
{
  provides interface ${Attribute};
  provides interface StdControl;
}
implementation
{
  components ${Attribute}M, GenericComm, MsgBuffers;

  ${Attribute} = ${Attribute}M.${Attribute};
  StdControl = ${Attribute}M.StdControl;

  ${Attribute}.GetReceive->GenericComm.ReceiveMsg[${Get_AM}];
  ${Attribute}.SetReceive->GenericComm.ReceiveMsg[${Set_AM}];
  ${Attribute}.GetSend->GenericComm.SendMsg[${Get_AM}];
}

