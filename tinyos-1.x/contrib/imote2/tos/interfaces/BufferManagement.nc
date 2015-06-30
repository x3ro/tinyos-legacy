/*									tab:4
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 */

/*
 * Author:	Lama Nachman	
 */

/**
 * General interface to support Buffer Management
 */
interface BufferManagement
{ 
  /**
   * Allocate Buffer
   * @param numBytes Number of bytes in the buffer
   * @return NULL if the allocation fails, otherwise, return a buffer pointer
   */
  command uint8_t *AllocBuffer(uint32_t numBytes);		

  /**
   * Release Buffer
   * @param buffer Previously allocated buffer
   * @return SUCCESS/FAIL 
   */
  command result_t ReleaseBuffer(uint8_t *buffer);		
}
