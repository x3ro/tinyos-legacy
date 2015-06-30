/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 

/**
 *
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

includes Lu;
includes ulla;
includes msg_type;
includes UllaQuery;

interface UqpIf {

  command uint8_t requestInfo(QueryPtr gCurQuery, ullaResult_t *result);
  event result_t requestInfoDone(ResultTuple *result, uint8_t numBytes);
  command uint8_t requestNotification(/*IN*/ RnDescr_t* rndescr, 
				// handleNotification_t handler,  // callback
				/*OUT*/ RnId_t* rnId, 
				/*IN*/uint16_t validity); 

  command uint8_t cancelNotification(RnId_t rnId);
  
  command uint8_t clearResult();
	
	
	
	/*
	 * Result Tuple
	 */
	
	command ullaResultCode ullaResultNumFields(uint8_t res, uint8_t *num); 
	
	command ullaResultCode ullaResultNumTuples(ullaResult_t res, uint8_t *num);
	
	/*
	 * Removed size: name is uint8_t not string.
	 */
	command ullaResultCode ullaResultFieldName(ullaResult_t res, uint8_t fieldNo, uint8_t *name);
	
	command ullaResultCode ullaResultFieldNumber(ullaResult_t res, uint8_t fieldName, uint8_t *num);
	
	command ullaResultCode ullaResultValueLength(ullaResult_t res, uint8_t fieldNo, uint8_t *size);
	
	command ullaResultCode ullaResultValueType(ullaResult_t res, uint8_t fieldNo, BaseType_t *type);
	
	command ullaResultCode ullaResultNextTuple(ullaResult_t res);
	
	command ullaResultCode ullaResultIntValue(ullaResult_t res, uint8_t fieldNo, uint8_t *value);
	
	command ullaResultCode ullaResultRawDataValue(ullaResult_t res, uint8_t fieldNo, char *buf, uint8_t *size);

}
