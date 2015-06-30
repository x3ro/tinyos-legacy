/*
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Author:	Tom Parker
 * This module provides the encoding interface for the conversion of messages 
 * going to/coming from the radio
 */

module RadioCodedM
{
	provides
	{
		interface RadioCoding as RC;
		interface StdControl as SC;
	}
	uses
	{
		interface RadioEncoding as Encode;
		interface StdControl as CSC; // codec std control
	}
}

implementation
{
	command result_t SC.start()
	{
		return call CSC.start();
	}
	
	command result_t SC.stop()
	{
		return call CSC.stop();
	}
	
	command result_t SC.init()
	{
		return call CSC.init();
	}
	
	async command result_t RC.encode_flush()
	{
		return call Encode.encode_flush();
	}

	async command result_t RC.encode(uint8_t data)
	{
		return call Encode.encode(data);
	}

	async command result_t RC.decode(uint8_t data)
	{
		return call Encode.decode(data);
	}

	async event result_t Encode.decodeDone(char data, char error)
	{
		signal RC.decodeDone(data, error);
		return SUCCESS;
	}

	async event result_t Encode.encodeDone(char data)
	{
		signal RC.encodeDone(data);
		return SUCCESS;
	}
}
