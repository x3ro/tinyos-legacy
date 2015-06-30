// $Id: CodecNone.nc,v 1.1 2004/03/04 20:14:35 weiyeisi Exp $

/* Copyright (c) 2002 the University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 */
/* Authors:	Wei Ye
 * Date created: 1/21/2003
 *
 *   Since the Chipcon 1000 radio does Manchester coding internally,
 * this component does nothing in software.
 *
 */

/**
 * @author Wei Ye
 */



module CodecNone
{
   provides {
      interface StdControl;
      interface RadioEncoding as Codec;
   }
}

implementation
{
   
   command result_t StdControl.init()
   {
      return SUCCESS;
   }
   
   
   command result_t StdControl.start()
   {
      return SUCCESS;
   }
   
   
   command result_t StdControl.stop()
   {
      return SUCCESS;
   }
   
   
   async command result_t Codec.decode(char data)
   {
      signal Codec.decodeDone(data, 0);
      return SUCCESS;
   }
   
   
   async command result_t Codec.encode_flush()
   {
      return SUCCESS;
   }


   async command result_t Codec.encode(char data)
   {
      signal Codec.encodeDone(data);
      return SUCCESS;
   }


} // end of implementation
