/*
 * Copyright (C) 2003-2005 the University of Southern California.
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 *
 * In addition to releasing this program under the LGPL, the authors are
 * willing to dual-license it under other terms. You may contact the authors
 * of this project by writing to Wei Ye, USC/ISI, 4676 Admirality Way, Suite 
 * 1001, Marina del Rey, CA 90292, USA.
 */
/* Authors: Wei Ye
 *
 * Since the Chipcon 1000 radio does Manchester coding internally,
 * this component does nothing in software.
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
   
   
   async command result_t Codec.decode(uint8_t data)
   {
      signal Codec.decodeDone(data, 0);
      return SUCCESS;
   }
   
   
   async command result_t Codec.encode_flush()
   {
      return SUCCESS;
   }


   async command result_t Codec.encode(uint8_t data)
   {
      signal Codec.encodeDone(data);
      return SUCCESS;
   }


} // end of implementation
