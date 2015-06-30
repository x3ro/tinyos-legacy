// $Id: Stream.nc,v 1.2 2004/07/17 00:08:29 jhellerstein Exp $

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
/*
 * Authors:	Wei Hong
 *              Design by Sam Madden, Wei Hong, and Joe Hellerstein
 * Date last modified:  7/14/04
 *
 *
 */

/**
 * @author Wei Hong
 * @author Design by Sam Madden
 * @author Wei Hong
 * @author and Joe Hellerstein
 */

#include "Tuple.h"

interface Stream {
	// open the stream
	command result_t open(StreamDef stream, StreamDesc streamDesc);

	// split-phase open
	// streamDesc allocated by open
	event result_t openDone(StreamDescPtr streamDesc, result_t status);

	// return the tuple descriptor the stream
	command TupleDescPtr getTupleDesc(StreamDescPtr streamDesc);

	// fetch the next complete tuple in stream
	command result_t fetchTuple(
				StreamDescPtr streamDesc,
				uint32_t fieldMask, // bitmap of which fields to fetch
				TupleStructPtr tuple // OUT, allocated by caller
				);

	// XXX may need other fancier fetch commands later

	// entire tuple's fetch is done.  Common case for SmgrStream.
	event result_t fetchTupleDone(TupleStructPtr tuple, bool endOfStream);

	// close the stream
	// streamDesc will be freed
	command result_t close(StreamDescPtr streamDesc);

	// split-phase close
	event result_t closeDone();
}
