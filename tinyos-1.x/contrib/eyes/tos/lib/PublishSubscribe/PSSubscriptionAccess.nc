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

/**
  * 
  * The PSSubscriptionAccess interface allows to create
  * and access a subscription represented by a
  * ps_subscription_handle_t. A subscription consists of
  * two parts: 
  * 
  * (1) constraints on attribute values that define the
  * actual subscription
  * 
  * (2) commands (subsequently called "instructions") that
  * include information about the process of data
  * collection or message dissemination  
  * 
  * A ps_subscription_handle_t MUST only be created or
  * accessed using the commands in this interface. 
  */ 
includes PS; 
interface PSSubscriptionAccess 
{ 
  /** 
    * 
    * Ceates a new subscription, completion will be
    * signalled in createDone().
    *
    * @param handlePtr Handle to subscription (to be
    * filled in).
    *
    * @return Whether the request was successful:
    * PS_SUCCESS means a createDone() event will be
    * signalled, otherwise not.
    */
  command ps_result_t create(ps_subscription_handle_t
      *handlePtr);

  /**  
    *
    * The subscription was created, it is initialized and
    * contains no constraints or instructions.  It can be
    * deallocated with free().     
    *
    * @param handlePtr Handle pointer to subscription.
    * @param result PS_SUCCESS if created successfully,
    * otherwise not.
    */
  event void createDone(ps_subscription_handle_t
      *handlePtr, ps_result_t result);

  /** 
    * 
    * Deallocates the subscription, it may not be
    * referenced afterwards. Note: A handle cannot be
    * created and freed in the same task context (due to
    * TinyAlloc implementation details).
    *
    * @param handle The subscription to be deallocated.
    *
    * @return PS_SUCCESS means the handle was freed,
    * otherwise not.
   */
  command ps_result_t free(ps_subscription_handle_t
      handle);

  /** 
    * 
    * Creates an identical copy of a subscription.
    *
    * @param originalHandle The subscription to be cloned.
    * @param cloneHandlePtr Handle to clone (to be filled
    * in).
    *
    * @return Whether the request was successful: PS_SUCCESS
    * means a cloneDone() event will be signaled later,
    * otherwise not.
    */
  command ps_result_t clone(const ps_subscription_handle_t
      originalHandle, ps_subscription_handle_t
      *cloneHandlePtr);

  /**  
    *
    * An identical copy of the subscription was created. 
    *  
    * @param originalHandle The subscription that was cloned.
    * @param cloneHandlePtr The clone.
    * @param result PS_SUCCESS if cloned successfully,
    * otherwise not.
    */ 
  event void cloneDone(const ps_subscription_handle_t originalHandle, 
                       ps_subscription_handle_t *cloneHandlePtr, 
                       ps_result_t result);

  /**  
    * Removes all constraints and instructions from the
    * subscription.
    *
    * @param handle The subscription.
    * 
    * @return PS_SUCCESS means the handle was freed,
    * otherwise not.
    */
  command ps_result_t reset(ps_subscription_handle_t
      handle);

  /** 
    * Returns the number of constraints in the
    * subscription.
    * 
    * @param handle The handle representing the
    * subscription.  
    * @param count The number of
    * constraints (will be filled in).  
    * @return PS_SUCCESS if result is valid otherwise not.
    */
  command ps_result_t getConstraintCount(const
      ps_subscription_handle_t handle, uint16_t *count);

  /** 
   * Allocates a new constraint within the subscription
   * (non-split phase). The length of the
   * (*constraint)->value array is defined by valueLength.
   *
   * @param handle The handle representing the
   * subscription.  
   * @param constraint Points to a pointer that will
   * reference the allocated constraint (the *constraint
   * will be modified).  
   * @param valueLength Desired length of the
   * (*constraint)->value region.  
   * @return PS_SUCCESS iff successfull.
   */
  command ps_result_t
    newConstraint(ps_subscription_handle_t handle,
        ps_constraint_t **constraint, uint8_t
        valueLength);

  /** 
    * Returns a constraint in the subscription in
    * read-only mode, it may not be accessed after the
    * subscription has been deallocated.
    *
    * @param handle The handle representing the
    * subscription.  
    * @param constraint Points to a pointer that will
    * reference the requested constraint (the *constraint
    * will be modified).
    * @param num Number of the requested constraint, the
    * first is 0; num must be < than the count determined
    * by getConstraintCount().
    * @param valueLength Length of the constraint->value
    * field (will be filled in).
    * @return PS_SUCCESS iff successfull.
    */
  command ps_result_t viewConstraint(const
      ps_subscription_handle_t handle, const
      ps_constraint_t **constraint, uint16_t *valueLength,
      uint16_t num);

  /** 
    * Returns a constraint in the subscription to be
    * accessed in read or write mode, it may not be
    * accessed after the subscription has been
    * deallocated.
    *
    * @param handle The handle representing the
    * subscription.  
    * @param constraint Points to a pointer that will
    * reference the requested constraint (the *constraint
    * will be modified).
    * @param num Number of the requested constraint, the
    * first is 0; num must be < than determined
    * by getConstraintCount().
    * @param valueLength Length of the constraint->value
    * field (will be filled in).
    * @return PS_SUCCESS iff successfull.
    */
  command ps_result_t
    getConstraint(ps_subscription_handle_t handle,
        ps_constraint_t **constraint, uint16_t
        *valueLength, uint16_t num);

  /**
    * Turns the subscription into an un-subscription, i.e.
    * when the message is now send, it will cancel the
    * (previous) subscription.  
    * 
    * @param handle The handle representing the
    * subscription.
    * @return PS_SUCCESS iff successfull.
    */
  command ps_result_t
    markUnsubscribe(ps_subscription_handle_t handle);


  /**
    * Removes the unsubscribe marking.
    *
    * @param handle The handle representing the
    * subscription.  
    * @return PS_SUCCESS iff successfull.
    */
  command ps_result_t
    markSubscribe(ps_subscription_handle_t handle);


  /** 
   * Associates the subscription with a subscription ID.
   * Only subscription IDs that were returned by the
   * subscribeDone() event may be used (they were signalled
   * when the subscription was initially send by an agent).
   * For a new subscription the ID will be assigned by the
   * agent automatically.   
   * 
   * @param handle The handle representing the
   * subscription.  @param handle subscriptionID The
   * subscription ID.  @return PS_SUCCESS iff successfull.
   */
  command ps_result_t setID(ps_subscription_handle_t
      handle, ps_subscription_ID_t subscriptionID);

  /** 
   * Returns the number of instructions (commands) in the
   * subscription.
   * 
   * @param handle The handle representing the
   * subscription.  
   * @param count Number of instructions
   * (will be filled in).  
   * @return PS_SUCCESS iff result is valid.
   */
  command ps_result_t getInstructionCount(const
      ps_subscription_handle_t handle, uint16_t* count);

  /** 
   * Allocates a new instruction within the subscription
   * (non split-phase). The length of the
   * (*instruction)->value array is defined by valueLength.
   * 
   * @param handle The handle representing the
   * subscription.  
   * @param instruction Points to a pointer that will
   * reference the allocated instruction (the *instruction
   * will be modified).  
   * @param valueLength Desired
   * length of the (*instruction)->value region.
   * @return PS_SUCCESS iff result is valid.
   */ 
  command ps_result_t
    newInstruction(ps_subscription_handle_t handle,
        ps_instruction_t **instruction, uint16_t
        valueLength);

  /** 
   *
   * Returns an instruction in the subscription in
   * read-only mode, it may not be accessed after the
   * subscription has been deallocated.
   *
   * @param handle The handle representing the
   * subscription.  
   * @param instruction Points to a pointer that will
   * reference the requested instruction (the *instruction
   * will be modified).
   * @param num Number of the requested instruction, the
   * first is 0; num must be < than the count determined by
   * getInstructionCount().
   * @param valueLength Length of the instruction->value
   * field (will be filled in).  
   * @return PS_SUCCESS iff instruction is valid.
   */
  command ps_result_t viewInstruction(const
      ps_subscription_handle_t handle, const
      ps_instruction_t **instruction, uint16_t
      *valueLength, uint16_t num);

  /** 
   *
   * Returns an instruction in the subscription to be
   * accessed in read or write mode, it may not be accessed
   * after the subscription has been deallocated.
   *
   * @param handle The handle representing the
   * subscription.  
   * @param instruction Points to a pointer that will
   * reference the requested instruction (the *instruction
   * will be modified).
   * @param num Number of the requested instruction, the
   * first is 0; num must be < than the count determined by
   * getInstructionCount().
   * @param valueLength Length of the instruction->value
   * field (will be filled in).
   * @return PS_SUCCESS iff instruction is valid.
   */
  command ps_result_t
    getInstruction(ps_subscription_handle_t handle,
        ps_instruction_t **instruction, uint16_t
        *valueLength, uint16_t num);
}

