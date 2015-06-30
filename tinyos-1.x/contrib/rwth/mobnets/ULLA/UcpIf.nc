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
 * @brief Modified version of ullalu.h to be used in TinyOS
 * This file contains the interfaces to the ULLA Command Processing.
 *
<p>
 * @modified Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/

includes Lu;
includes ulla;
includes msg_type;

interface UcpIf {

  /**
   * @ingroup ucp
   * @brief Send synchronous commands to Link Provider through ULLA
   * This method allows a linkUser to request a single command to be executed on a specific link. The command call
   * is synchronous, i.e. the doCmd() function returns only on command completion.
   *
   * @param luId the identifier of the calling linkUser, as assigned by registerLu()
   * @param cmddescr the command description
   *
   * @return ULLA_OK if the command has been succesfully executed.
   *
   */
  command uint8_t doCmd(LuId_t luId, CmdDescrPtr cmddescr);
  event result_t doCmdDone(CmdDescrPtr cmddescr);

  /**
   *
   * @ingroup ucp
   * @brief Send asynchronous commands to Link Provider through ULLA.
   * This method can be called by a linkUser to request a command to be executed asynchronously on a specific link.
   * The command can be issued multiple times in a periodic fashion; the parameter rcdescr must be specified for this purpose.
   * Periodic command remain in force until they expire or they are explicitly canceled through cancelCmd().
   * Upon completion of each command execution, the callback specified within the rcdescr parameter is called.
   *
   * @param luId the identifier of the calling linkUser, as assigned by registerLu()
   * @param cmddescr the command description
   * @param rcdescr the asynchronous request parameters, containing the callback pointer and the command request count and period.
   * @param cmdId the returned identifier for the current command request
   *
   * @return ULLA_OK if succesful,
   * ULLA_OUT_OF_MEMORY_ERROR if the async command queue is full,
   * ULLA_SYNTAX_ERROR if the command string is incorrect,
   * ULLA_UNSUPPORTED_FEATURE_ERROR if the requested command is not supported by the linkProvider.
   *
   *
   */
  command uint8_t requestCmd(LuId_t luId, CmdDescr_t* cmddescr, RcDescr_t *rcdescr, CmdId_t *cmdId);


  /**
   * @ingroup ucp
   * @brief Cancel a previously requested asynchronous command.
   *
   * The cancelCmd() method allows an application to cancel an asynchronous command call
   * previously requested with requestCmd().
   *
   * @param luId the identifier of the calling linkUser, as assigned by registerLu()
   * @param cmdId the numeric identifier of the command to be canceled, as returned by requestCmd()
   *
   * @return ULLA_OK if succesful,
   * ULLA_INVALID_PARAMETER_ERROR if the command with the requested cmdId does not exist, has already been canceled or
   * has already expired.
   */
  command uint8_t cancelCmd(LuId_t luId, CmdId_t cmdId);


   /**
   * @ingroup ucp
   * @brief
   *
   *
   * @param luId
   * @param paramDescr the descriptor of the parameter to be set
   *
   * @return
   */
  command uint8_t setParam(LuId_t luId, AttrDescr_t paramDescr);
}
