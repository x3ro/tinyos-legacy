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
 * $Date: 2005/10/19 14:00:59 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
 
generic module PSPublisherAgentM()
{
  provides {
   interface PSPublish;               // to send out notifications
  } uses {
   interface PSNotificationSend;
   interface PSMessageAccess;
  }

} implementation {
  bool m_lock = FALSE;

  ps_result_t setLock(ps_notification_handle_t handle)
  {
    bool locked;
    atomic {
      locked = m_lock;
      m_lock = TRUE;
    }
    if (locked)
      return PS_FAIL_BUSY;
    if (call PSMessageAccess.isLockedNotification(handle)){
      m_lock = FALSE;
      return PS_FAIL_MSG_LOCK;
    }
    call PSMessageAccess.setLockNotification(handle);
    return PS_SUCCESS;
  }

  inline void releaseLock(ps_notification_handle_t handle)
  {
    m_lock = FALSE;
    call PSMessageAccess.clearLockNotification(handle);
  }

  command ps_result_t PSPublish.publish(ps_notification_handle_t handle)
  { 
    ps_result_t result = setLock(handle);
    if (result == PS_SUCCESS)
      if ((result = call PSNotificationSend.send(handle)) != PS_SUCCESS)
        releaseLock(handle);
    return result;
 
  }

  event void PSNotificationSend.sendDone(ps_notification_handle_t handle, 
      ps_result_t result)
  {
    releaseLock(handle);
    signal PSPublish.publishDone(handle, result);
  }

  default event void PSPublish.publishDone(ps_notification_handle_t handle, ps_result_t result){} 
}
