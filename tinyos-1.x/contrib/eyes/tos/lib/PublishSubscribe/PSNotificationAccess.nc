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
 * $Revision: 1.2 $
 * $Date: 2005/11/09 20:15:22 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

 /*
  * 
  * This interface can be used to create and access a
  * notification represented by a ps_notification_handle_t.
  * A notification consists of two parts: 
  * 
  * (1) attribute-value pairs that define the actual
  * notification
  * 
  * (2) additional constraints (subsequently called
  * "requests") on the local data collection process (often
  * empty)
  *
  * A ps_notification_handle_t MUST only be created or
  * accessed using the commands in this interface. 
  */ 
includes PS; 
interface PSNotificationAccess 
{ 
  /** 
    * 
    * Creates a new notification, completion will be
    * signalled in createDone().
    *
    * @param handlePtr Handle to notification (to be filled
    * in).
    *
    * @return Whether the request was successful: SUCCESS
    * means a createDone() event will be signalled,
    * otherwise not.
    */
  command ps_result_t create(ps_notification_handle_t
      *handlePtr);

  /**  
    *
    * The notification was created, it is initialized and
    * contains no attribute-value pairs or requests.  It
    * can be deallocated with free().     
    *
    * @param handlePtr Handle pointer to notification.
    * @param result PS_SUCCESS if created successfully,
    * otherwise not.
    */
  event void createDone(ps_notification_handle_t
      *handlePtr, ps_result_t result);

  /** 
    * 
    * Deallocates the notification, it may not be
    * referenced afterwards. Note: A handle cannot be
    * created and freed in the same task context (due to
    * TinyAlloc implementation details).
    *
    * @param handle The notification to be deallocated.
    *
    * @return PS_SUCCESS means the handle was freed,
    * otherwise not.
   */
  command ps_result_t free(ps_notification_handle_t handle);

  /** 
    * 
    * Creates an identical copy of a notification.
    *
    * @param originalHandle The notification to be cloned.
    * @param cloneHandlePtr Handle to clone (to be filled
    * in).
    *
    * @return Whether the request was successful:
    * PS_SUCCESS means a cloneDone() event will be signaled
    * later, otherwise not.
    */
  command ps_result_t clone(const ps_notification_handle_t
      originalHandle, ps_notification_handle_t
      *cloneHandlePtr);

  /**  
    * An identical copy of the notification was created. 
    *  
    * @param originalHandle The notification that was
    * cloned.  
    * @param cloneHandlePtr The clone. 
    * @param result PS_SUCCESS if cloned successfully,
    * otherwise not.
    */ 
  event void cloneDone(ps_notification_handle_t
      originalHandle, ps_notification_handle_t
      *cloneHandlePtr, ps_result_t result);

  /**  
    * Removes all attribute-value pairs and requests from
    * the notification.
    *
    * @param handle The notification.
    * 
    * @return PS_SUCCESS means the handle was freed,
    * otherwise not.
    */
  command ps_result_t reset(ps_notification_handle_t
      handle);
   
  /** 
    * Returns the number of attribute-value pairs in the
    * notification.
    * 
    * @param handle The handle representing the
    * notification.  
    * @param count The number of
    * attribute-value pairs (will be filled in).  
    * @return PS_SUCCESS if result is valid otherwise not.
 
    */
  command ps_result_t getAVPairCount(const
      ps_notification_handle_t handle, uint16_t *count);

  /** 
   * Allocates a new attribute-value pair within the
   * notification (non-split phase). The length of the
   * (*avpair)->value array is defined by valueLength.
   *
   * @param handle The handle representing the
   * notification.
   * @param avpair Points to a pointer that will reference
   * the allocated avpair (the *avpair will be modified).
   * @param valueLength Desired length of the
   * (*avpair)->value region.
   * @return PS_SUCCESS iff successfull.
   */
  command ps_result_t newAVPair(ps_notification_handle_t
      handle, ps_avpair_t **avpair, uint8_t valueLength);

  /** 
    * Returns an attribute-value pair in the notification
    * in read-only mode, it may not be accessed after the
    * notification has been deallocated.
    *
    * @param handle The handle representing the
    * notification.  
    * @param avpair Points to a pointer that will reference
    * the requested avpair (the *avpair will be modified).
    * @param num Number of the requested avpair, the first
    * one is 0; num must be < than the count determined by
    * getConstraintCount().
    * @param valueLength Length of the avpair->value field
    * (will be filled in).
    * @return PS_SUCCESS iff successfull.
    */
  command ps_result_t viewAVPair(const
      ps_notification_handle_t handle, const ps_avpair_t
      **avpair, uint16_t *valueLength, uint16_t num);

  /** 
    * Returns an attribute-value pair  in the notification
    * to be accessed in read or write mode, it may not be
    * accessed after the notification has been deallocated.
    *
    * @param handle The handle representing the
    * notification.  
    * @param avpair Points to a pointer that will reference
    * the requested avpair (the *avpair will be modified).
    * @param num Number of the requested avpair, the first
    * one is 0; num must be < than the count determined by
    * getConstraintCount().
    * @param valueLength Length of the avpair->value field
    * (will be filled in).
    * @return PS_SUCCESS iff successfull.
    */
  command ps_result_t getAVPair(ps_notification_handle_t
      handle, ps_avpair_t **avpair, uint16_t *valueLength,
      uint16_t num);
 
  /** 
   * Returns the number of requests (constraints) in the
   * notification.
   * 
   * @param handle The handle representing the
   * notification.  
   * @param count Number of requests will be stored here.
   * @param valueLength Length of the request->value field
   * (will be filled in).
   * @return PS_SUCCESS iff result is valid.
   */
  command ps_result_t getRequestCount(const
      ps_notification_handle_t handle, uint16_t *count);

  /** 
   *
   * Allocates a new request within the notification (non
   * split-phase).  The length of the (*request)->value[]
   * array is defined by "valueLength".
   *
   * @param handle The handle representing the
   * notification.
   * @param request Points to a pointer that will reference
   * the allocated request (the *request will be modified).
   * @param valueLength Desired length of the
   * (*request)->value region.
   * @return PS_SUCCESS iff result is valid.
   */
  command ps_result_t newRequest(ps_notification_handle_t
      handle, ps_request_t **request, uint16_t
      valueLength);

  /**
    * Returns a request (constraint) in the notification in
    * read-only mode, it may not be accessed after the
    * notification has been deallocated.
    *
    * @param handle The handle representing the
    * notification.  
    * @param request Points to a pointer that will
    * reference the request (the *request will be
    * modified).
    * @param num Number of the requested instruction, the
    * first is 0; num must be < than the count determined
    * by getRequestCount().
    * @param valueLength Length of the request->value field
    * (will be filled in).
    * @return PS_SUCCESS iff request is valid.
    */
  command ps_result_t viewRequest(const
      ps_notification_handle_t handle, const ps_request_t
      **request, uint16_t *valueLength, uint16_t num);

   /** 
    *
    * Returns a request (constraint)  in the notification
    * to be accessed in read or write mode, it may not be
    * accessed after the notification has been deallocated.
    *
    * @param handle The handle representing the
    * notification.  
    * @param request Points to a pointer that will
    * reference the request (the *request will be
    * modified).
    * @param num Number of the requested instruction, the
    * first is 0; num must be < than the count determined
    * by getRequestCount().
    * @param valueLength Length of the request->value field
    * (will be filled in).
    * @return PS_SUCCESS iff request is valid.
    */
  command ps_result_t getRequest(ps_notification_handle_t
      handle, ps_request_t **request, uint16_t
      *valueLength, uint16_t num);
}

