/* 
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1 $
 * $Date: 2005/10/19 14:09:56 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

 /* Dump status of ServiceDiscovery as a PSStatusMsg via serial */
 /* This is only for testing (duplicated code with PSBrokerM)   */
module PSServiceDiscoveryDumpM {
  uses {
    interface PSServiceDiscovery;
    interface Leds;
    interface BareSendMsg as SendStatusMsg;
  }
}
implementation {

  /***********************************************************************
   * StatusMessages
   * 
   * Nodes can send out StatusMessages to report about their internal state  
   * (debug messages). StatusMessages are only activated if the macro
   * PS_STATUS_MSG_ON is defined (see PS.h). If StatusMessages are not
   * activated, ALL relevant code gets COMPLETELY optimized away.
   * Why not have a Status-Message component and let nesC optimize
   * the calls away when not wired to it instead of the macro below ?
   * Because varargs commands and events are not supported
   * by nesC.    
   ***********************************************************************/

  TOS_Msg m_statusMsg;
  bool m_statusMsgLock = FALSE;
  uint16_t m_statusMsgSeqNum;

  bool getStatusMsgLock()
  {
    bool old;
    atomic {
      old = m_statusMsgLock;
      m_statusMsgLock = TRUE;
    }
    return !old;
  }

  inline void releaseStatusMsgLock()
  {
    m_statusMsgLock = FALSE;
  }

  ps_result_t dropStatusMsg(uint8_t statusID, char *msg, ...)
  {
    ps_status_msg_t *statusMsgPtr = (ps_status_msg_t *) m_statusMsg.data;
    va_list ap;
    char *p, *dstart, *dend,tmp;
    uint16_t i, val;
    
    if (getStatusMsgLock()){
      statusMsgPtr->seqNum = m_statusMsgSeqNum;
      statusMsgPtr->statusID = statusID;
      statusMsgPtr->sourceAddress = TOS_LOCAL_ADDRESS;
      va_start(ap,msg);
      for (p=msg, i=0; *p && i<TOSH_DATA_LENGTH; p++){
        if (*p != '%'){
          statusMsgPtr->msg[i++] = *p;
          continue;
        }
        switch(*++p)
        {
          case 'd':
            val = va_arg(ap, uint16_t);
            dstart = (char *) &statusMsgPtr->msg[i];
            while (i<TOSH_DATA_LENGTH) {
              statusMsgPtr->msg[i++] = '0' + val % 10;
              val /= 10;
              if (!val)
                break;
            }
            dend = (char *) &statusMsgPtr->msg[i-1];
            while (dstart < dend){
              // swapping
              tmp = *dstart;
              *dstart = *dend;
              *dend = tmp;
              dstart++;
              dend--;
            }
            break;
          default:
            break;
        }
      }
      va_end(ap);
      statusMsgPtr->length = i;
      m_statusMsg.length = statusMsgPtr->length + sizeof(ps_status_msg_t);
      m_statusMsg.group = TOS_AM_GROUP;
      m_statusMsg.type = AM_PS_STATUS_MSG;
      m_statusMsg.addr = TOS_UART_ADDR;
      //m_statusMsg.s_addr = TOS_LOCAL_ADDRESS;
      m_statusMsgSeqNum++;
      return call SendStatusMsg.send(&m_statusMsg);
    }
    m_statusMsgSeqNum++;
    return FAIL;
  }
  
  event result_t SendStatusMsg.sendDone(TOS_MsgPtr msg, result_t success)
  {
    releaseStatusMsgLock();
    return SUCCESS;
  }

  void task dump()
  {
    ps_attr_ID_t *buffer;
    uint8_t num = call PSServiceDiscovery.getAttributeList(&buffer);
    STATUSMSG(SERVICE_DISCOVERY, "Num Attribs: %d", num);
  }

  event void PSServiceDiscovery.updated()
  {
    post dump();
  }

}


