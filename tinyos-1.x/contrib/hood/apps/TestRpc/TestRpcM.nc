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
 * @author Kamin Whitehouse
 */

includes Rpc;

module TestRpcM {

  //items below that are marked with /** **/ are illegal @rpc commands
  //and should provide compile time errors if uncommented
  provides{
    interface StdControl @rpc();

    interface TestInterface1 @rpc();
    command void testCommand1() @rpc();
    command result_t testCommand3(uint8_t something) @rpc();
    command result_t* testCommand4(uint8_t something, uint16_t* data) @rpc();
    command RpcCommandMsg testCommand5(RpcCommandMsg data) @rpc();
    command RpcCommandMsg* testCommand6(RpcCommandMsg* data) @rpc();
    command void testCommand7(RpcCommandMsg data) @rpc();
    command RpcCommandMsg testCommand8() @rpc();
    event void testEvent1() @rpc();
    event result_t testEvent3(uint8_t something) @rpc();
    event result_t* testEvent4(uint8_t something, uint16_t* data) @rpc();
    event RpcCommandMsg testEvent5(RpcCommandMsg data) @rpc();
    event RpcCommandMsg* testEvent6(RpcCommandMsg* data) @rpc();
    event void testEvent7(RpcCommandMsg data) @rpc();
    event RpcCommandMsg testEvent8() @rpc();
    
    /** interface TestInterface2 as brokenInterface2 @rpc(); **/
    /** command void* brokenCommand1() @rpc(); **/
    /** command void brokenCommand2(void* param) @rpc(); **/
  }
  uses{
    interface IntOutput;

    interface TestInterface2 @rpc();

    /** interface TestInterface1 as brokenInterface1 @rpc(); **/
    /** command void brokenCommand3() @rpc(); **/
    /** event void brokenEvent() @rpc(); **/
  }
}
implementation {

  RpcCommandMsg m_rpcCommandMsg;

  command result_t StdControl.init() {
    return SUCCESS;
  }

  command result_t StdControl.start() {
    dbg(DBG_USR1,"TestRpc: StdControl.start\n");
    return SUCCESS;
  }

  command result_t StdControl.stop() {
    dbg(DBG_USR1,"TestRpc: StdControl.stop\n");
    return SUCCESS;
  }

  /** command void* brokenCommand1(){
    return 0;
  }
  command void brokenCommand2(void* param){
  } **/

  command void testCommand1(){
    call IntOutput.output(1);
  }
  command result_t testCommand3(uint8_t something){
    call IntOutput.output(3);
    return SUCCESS;
  }
  command result_t* testCommand4(uint8_t something, uint16_t* data){
    call IntOutput.output(4);
    return (result_t*)data;
  }
  command RpcCommandMsg testCommand5(RpcCommandMsg data){
    call IntOutput.output(5);
    return data;
  }
  command RpcCommandMsg* testCommand6(RpcCommandMsg* data){
    call IntOutput.output(6);
    m_rpcCommandMsg = *data;
    return &m_rpcCommandMsg;
  }
  command void testCommand7(RpcCommandMsg data){
    call IntOutput.output(7);
    m_rpcCommandMsg = data;
  }
  command RpcCommandMsg testCommand8(){
    call IntOutput.output(0);
    return m_rpcCommandMsg;
  }
  event void testEvent1(){
    call IntOutput.output(1);
  }
  event result_t testEvent3(uint8_t something){
    call IntOutput.output(3);
    return SUCCESS;
  }
  event result_t* testEvent4(uint8_t something, uint16_t* data){
    call IntOutput.output(4);
    return (result_t*)data;
  }
  event RpcCommandMsg testEvent5(RpcCommandMsg data){
    call IntOutput.output(5);
    return data;
  }
  event RpcCommandMsg* testEvent6(RpcCommandMsg* data){
    call IntOutput.output(6);
    m_rpcCommandMsg = *data;
    return &m_rpcCommandMsg;
  }
  event void testEvent7(RpcCommandMsg data){
    call IntOutput.output(7);
    m_rpcCommandMsg = data;
  }
  event RpcCommandMsg testEvent8(){
    call IntOutput.output(0);
    return m_rpcCommandMsg;
  }
  command void TestInterface1.testCommand1(){
    call IntOutput.output(1);
  }
  command result_t TestInterface1.testCommand3(uint8_t something){
    call IntOutput.output(3);
    return SUCCESS;
  }
  command result_t* TestInterface1.testCommand4(uint8_t something, uint16_t* data){
    call IntOutput.output(4);
    return (result_t*)data;
  }
  command RpcCommandMsg TestInterface1.testCommand5(RpcCommandMsg data){
    call IntOutput.output(5);
    return data;
  }
  command RpcCommandMsg* TestInterface1.testCommand6(RpcCommandMsg* data){
    call IntOutput.output(6);
    m_rpcCommandMsg = *data;
    return &m_rpcCommandMsg;
  }
  command void TestInterface1.testCommand7(RpcCommandMsg data){
    call IntOutput.output(7);
    m_rpcCommandMsg = data;
  }
  command RpcCommandMsg TestInterface1.testCommand8(){
    call IntOutput.output(0);
    return m_rpcCommandMsg;
  }
  event void TestInterface2.testEvent1(){
    call IntOutput.output(1);
  }
  event result_t TestInterface2.testEvent3(uint8_t something){
    call IntOutput.output(3);
    return SUCCESS;
  }
  event result_t* TestInterface2.testEvent4(uint8_t something, uint16_t* data){
    call IntOutput.output(4);
    return (result_t*)data;
  }
  event RpcCommandMsg TestInterface2.testEvent5(RpcCommandMsg data){
    call IntOutput.output(5);
    return data;
  }
  event RpcCommandMsg* TestInterface2.testEvent6(RpcCommandMsg* data){
    call IntOutput.output(7);
    m_rpcCommandMsg = *data;
    return &m_rpcCommandMsg;
  }
  event void TestInterface2.testEvent7(RpcCommandMsg data){
    call IntOutput.output(7);
    m_rpcCommandMsg = data;
  }
  event RpcCommandMsg TestInterface2.testEvent8(){
    call IntOutput.output(0);
    return m_rpcCommandMsg;
  }


  event result_t IntOutput.outputComplete(result_t success){
    return SUCCESS;
  }
}

