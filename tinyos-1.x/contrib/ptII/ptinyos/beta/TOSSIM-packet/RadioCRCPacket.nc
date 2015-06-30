// $Id: RadioCRCPacket.nc,v 1.1 2005/04/19 00:35:10 celaine Exp $

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


/**
 * This is a drop-in replacement for TOSSIM's radio stack that operates at
 * the packet, rather than the bit, level. In preliminary testing it
 * performs about 100 times faster than the default bit-level radio stack.
 * Obviously it does not capture the subtleties and behavior of the
 * bit-level simulation, but, it is useful for testing and simulating large
 * networks. 
 *
 * To use this code, all you need to do is add the line
 *   PFLAGS = -I/path/to/tinyos/broken/experimental/mdw/tossim
 * to your application Makefile, then rebuild your application with 'make pc'.
 *
 * This packet-level simulation is compatible with TOSSIM's lossy radio
 * models, so if you are using "-r lossy" or setting link-level loss
 * probabilities with TinyViz, it will work.
 * 
 * Matt Welsh - mdw@eecs.harvard.edu
 */


configuration RadioCRCPacket {
  provides {
    interface StdControl as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
  }
}
implementation
{
  components TossimPacketM, Nido;

  Control = TossimPacketM;
  Receive = TossimPacketM;
  Send = Nido.RadioSendMsg;
  
  TossimPacketM.ReceiveMain -> Nido.RadioReceiveMsg;
}
