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
 * Interface for Network Communication
<p>
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
 
includes UllaQuery;

interface Transceiver {

 /**
  * Broadcast a query message containing part of a query to the neighbors
	* @param msg The message to send
	* @return errorSendFailed if message failed to transmit
  **/
  command UllaError sendQuery(TOS_MsgPtr msg);
  
 /**
  * Signalled when a query message has been sent
  * @param msg The sent message
  * @param success SUCCESS if the message sent successfully, FAIL otherwise
  **/
  event result_t sendQueryDone(TOS_MsgPtr msg, result_t rs);

/**
  * Broadcast a data message to the neighbors to reach the root node
	* @param msg The message to send
	* @return errorSendFailed if message failed to transmit
  **/
  command UllaError sendData(TOS_MsgPtr msg);

 /**
  * Signalled when a data message has been sent
  * @param msg The sent message
  * @param success SUCCESS if the message sent successfully, FAIL otherwise
  **/
  event result_t sendDataDone(TOS_MsgPtr msg, result_t rs);

/**
  * Broadcast a command messageto the neighbors
	* @param msg The message to send
	* @return errorSendFailed if message failed to transmit
  **/
  command UllaError sendCommand(TOS_MsgPtr msg);
  
 /**
  * Signalled when a command message has been sent
  * @param msg The sent message
  * @param success SUCCESS if the message sent successfully, FAIL otherwise
  **/
  event result_t sendCommandDone(TOS_MsgPtr msg, result_t rs);
  
/**
  * Broadcast a debug message to the neighbors
	* @param msg The message to send
	* @return errorSendFailed if message failed to transmit
  **/
  command UllaError sendDebug(TOS_MsgPtr msg);
  
 /**
  * Signalled when a debug message has been sent
  * @param msg The sent message
  * @param success SUCCESS if the message sent successfully, FAIL otherwise
  **/
  event result_t sendDebugDone(TOS_MsgPtr msg, result_t rs);

 /**
  * Broadcast a result message to the neighbors
	* @param msg The message to send
	* @return errorSendFailed if message failed to transmit
  **/
  command UllaError sendResult(TOS_MsgPtr msg);

 /**
  * Signalled when a result message has been sent
  * @param msg The sent message
  * @param success SUCCESS if the message sent successfully, FAIL otherwise
  **/
  event result_t sendResultDone(TOS_MsgPtr msg, result_t rs);

 /**
  * Broadcast a multihop message to the neighbors
	* @param msg The message to send
	* @return errorSendFailed if message failed to transmit
  **/
  command UllaError sendMHop(TOS_MsgPtr msg);

 /**
  * Signalled when a multihop message has been sent
  * @param msg The sent message
  * @param success SUCCESS if the message sent successfully, FAIL otherwise
  **/
  event result_t sendMHopDone(TOS_MsgPtr msg, result_t rs);
  
  /**
  * Broadcast a multihop debug message to the neighbors
	* @param msg The message to send
	* @return errorSendFailed if message failed to transmit
  **/
  command UllaError sendMHopDebug(TOS_MsgPtr msg);

 /**
  * Signalled when a multihop debug message has been sent
  * @param msg The sent message
  * @param success SUCCESS if the message sent successfully, FAIL otherwise
  **/
  event result_t sendMHopDebugDone(TOS_MsgPtr msg, result_t rs);

 /**
  * Signalled when receive a query from the radio
  * @param msg The received query message.
  * @return TOS_MsgPtr
  **/
  event TOS_MsgPtr receiveQuery(TOS_MsgPtr msg);
  
 /**
  * Signalled when receive a data from the radio
  * @param msg The received data message.
  * @return TOS_MsgPtr
  **/
  event TOS_MsgPtr receiveData(TOS_MsgPtr msg);
  
 /**
  * Signalled when receive a command from the radio
  * @param msg The received command message.
  * @return TOS_MsgPtr
  **/
  event TOS_MsgPtr receiveCommand(TOS_MsgPtr msg);
  
 /**
  * Signalled when receive a debug message from the radio
  * @param msg The received debug message.
  * @return TOS_MsgPtr
  **/
  event TOS_MsgPtr receiveDebug(TOS_MsgPtr msg);

 /**
  * Signalled when receive a result message from the radio
  * @param msg The received result message.
  * @return TOS_MsgPtr
  **/
  event TOS_MsgPtr receiveResult(TOS_MsgPtr msg);
  
 /**
  * Signalled when receive a multihop message from the radio
  * @param msg The received result message.
  * @return TOS_MsgPtr
  **/
  event TOS_MsgPtr receiveMHop(TOS_MsgPtr msg);
  
 /**
  * Signalled when receive a multihop debug message from the radio
  * @param msg The received result message.
  * @return TOS_MsgPtr
  **/
  event TOS_MsgPtr receiveMHopDebug(TOS_MsgPtr msg);
}


