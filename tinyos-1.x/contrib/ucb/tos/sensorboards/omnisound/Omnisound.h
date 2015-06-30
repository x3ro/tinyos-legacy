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
enum{
	RECEIVING,
    NOT_RECEIVING
};

enum{
	AM_ATMEGA8RESET=190,
	AM_SENSITIVITYMSG=195,
	AM_TOF=196,
	AM_CHIRPMSG=197,
	AM_TRANSMITMODEMSG=199,
	AM_TIMESTAMPMSG=198
};

enum{
	LEN_SENSITIVITY=1,
	LEN_CHIRPMSG=2,
	LEN_TRANSMITMODEMSG=1,
	LEN_TIMESTAMPMSG=4
};

enum{TRANSMIT,RECEIVE};

typedef struct TransmitModeMsg{
	uint8_t mode;
} TransmitModeMsg;

typedef struct TimestampMsg{
	uint16_t transmitterId;
	uint16_t timestamp;
} TimestampMsg;

typedef struct ChirpMsg{
	uint16_t transmitterId;
} ChirpMsg;

typedef struct SensitivityMsg{
	uint8_t potLevel;
} SensitivityMsg;







