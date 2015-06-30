/*
 * Copyright (c) 2004, Technische Universitat Berlin
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
 * - Neither the name of the Technische Universitat Berlin nor the names
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
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.1.1 $
 * $Date: 2007/11/05 19:11:27 $ 
 * ======================================================================== 
 */
 
 /**
 * Resource interface.  
 * This interface is to be used by components for providing access to 
 * shared resources.  A component wishing to arbitrate the use of a shared 
 * resource should implement this interface in conjunction with the 
 * Resource interface.
 * <p>
 * For more information about this interface, please see TEP108.
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * @author Cory Sharp (info@moteiv.com)
 */

#include "Resource.h"

interface ResourceCmdAsync {
  /**
   * Request access to a shared resource. You must call release()
   * when you are done with it.
   * @return TRUE The request is deferred and granted() will be signaled
   *           for this request sometime in the future.
   *         FALSE The request has been immediately satisfied by signalling
   *           granted before returning from this request() call.
   */
  async command void request( uint8_t rh );
  /**
   * Request access to a shared resource urgently.  This gives the
   * system information that the request should receive priority over
   * other existing requests initiated through the <code>request</code>
   * interface.  Essentially a two-level priority queue.
   */
  async command void urgentRequest( uint8_t rh );
  /**
   * Request access to a shared resource immediately.  Upon return
   * from the function call, the resulting value is a resource handle.
   * The resource handle may not be valid if the resource is not 
   * available.  The user must check the handle using
   * <code>ResourceValidate</code> before using.
   */
  async command uint8_t immediateRequest( uint8_t rh );

  /**
   * You have received access to this resource. Note that this event
   * is NOT signaled when immediateRequest() succeeds. This event may
   * be signalled from within a call to request.
   */
  async event void granted( uint8_t rh );
   
  /**
   * Release a shared resource you previously acquired.
   */
  async command void release();
}

