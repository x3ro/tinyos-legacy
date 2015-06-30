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
 * @file FlashAccess.h
 * @Author Josh Herbach
 *
 * Ported by: Junaith Ahemed Shahabdeen
 *
 * Higher level functions for Flash Access. The file provides a C 
 * abstraction for the assembly code in the flash.s file.
 * <I>The implementation is ported from the flash write module of
 * tinyos repository.</I>
 */
#ifndef __FLASH_ACCESS_H
#define __FLASH_ACCESS_H

#include <Flash.h>
#include <types.h>

/**
 * FlashAccess_Init
 *
 * Intialize the internal states of the blocks and the partitions.
 * The fuction also defines the global variables for the
 * inline assembly codes of certain functions.
 *
 * @return SUCCESS | FAIL
 */
result_t FlashAccess_Init();

/**
 * Flash_Write
 * 
 * The function provides a wrapper for the actual write word or
 * write buffer functions in flash.s. At the higher level the
 * function determines if a buffer write is possible in the 
 * given address, and falls back to word writes. The control
 * is passed to the write helper function after the above
 * test for placing the rest of the data in flash.
 *
 * @param addr Starting address to which the buffer has to be written.
 * @param data Pointer to the buffer that has to be written to the flash.
 * @param numBytes Length of the buffer.
 *
 * @return SUCCESS | FAIL
 */
result_t Flash_Write(uint32_t addr, uint8_t* data, uint32_t numBytes);

/**
 * Flash_Erase
 *
 * Erase the entire block in which the first parameter is located.
 * 
 * @param addr Starting Address of a flash block.
 * @return SUCCESS | FAIL
 */
result_t Flash_Erase (uint32_t addr);

/**
 * Flash_Read
 *
 * The function will read from a flash location and store
 * it in a buffer. The function does 16 bit reads till length.
 *
 * @param Addr Starting Flash Address to read from.
 * @param Length Number of bytes to read.
 * @param buff Pointer to the buffer where the data is stored.
 *
 * @return SUCCESS | FAIL
 */
result_t Flash_Read (uint32_t Addr, uint32_t Length, uint8_t* buff);

/**
 * Flash_Param_Partition_Erase
 *
 * The top most partition of the flash is configured as
 * parameter partition.
 *
 * @param addr Starting address of a block that has to be erased.
 * @return SUCCESS | FAIL
 */
result_t Flash_Param_Partition_Erase (uint32_t addr);


//result_t Flash_Parameter_Write(uint32_t addr, uint8_t* data, uint32_t numBytes);

/**
 * Flash_Unlock
 *
 * The function performs all the steps required to
 * unlock a flash block. The commands and steps are defined
 * in the memory subsystem data sheet for the processor.
 * The Block address has to be passed as a parameter to the
 * function.
 * 
 * @param addr Address of the block that has to be unlocked.
 *
 * @return status The status register value.
 */
uint16_t Flash_Unlock(uint32_t addr);

/**
 * Flash_Lockdown
 *
 * The function performs all the steps required to
 * lock down a flash block. The commands and steps are defined
 * in the memory subsystem data sheet for the processor.
 * The Block address has to be passed as a parameter to the
 * function.
 * 
 * @param addr Address of the block that has to be locked.
 *
 * @return status The status register value.
 */
uint16_t Flash_Lockdown(uint32_t addr);

/**
 * Flash_Lock
 *
 * The function performs all the steps required to
 * lock a flash block. The commands and steps are defined
 * in the memory subsystem data sheet for the processor.
 * The Block address has to be passed as a parameter to the
 * function.
 * 
 * @param addr Address of the block that has to be locked.
 *
 * @return status The status register value.
 */
uint16_t Flash_Lock(uint32_t addr);

/**
 * Erase_Flash
 *
 * The function performs all the steps required to
 * erase a flash block. The commands and steps are defined
 * in the memory subsystem data sheet for the processor.
 * The Block address has to be passed as a parameter to the
 * function.
 * 
 * @param addr Address of the block that has to be erased.
 *
 * @return status The status register value.
 * 
 */
uint16_t Erase_Flash(uint32_t addr);

/**
 * Program_Word
 *
 * The function performs all the steps required to
 * write a word to flash. The commands and steps are defined
 * in the memory subsystem data sheet for the processor.
 *
 * @parma addr Flash Address in which the word has to be written.
 * @param data The Data that has to be written to the flash.
 *
 * @return status The status register value.
 */
uint16_t Program_Word(uint32_t addr, uint16_t data);

/**
 * Program_Buffer
 *
 * The function performs all the steps required to
 * write a buffer to flash. The commands and steps are defined
 * in the memory subsystem data sheet for the processor.
 *
 * <B>
 * NOTE;
 *   The address has to be aligned in 32 byte boundary for the
 *   buffered write to work.
 * </B>
 * 
 * @parma addr Flash Address in which the word has to be written.
 * @param data The Data that has to be written to the flash.
 * @param datalen Length of the data.
 *
 * @return status The status register value.
 */
uint16_t Program_Buffer(uint32_t addr, uint16_t data[], uint8_t datalen);

/**
 * Write_Helper
 *
 * This function is actually a continuation of the Flash_Write. It
 * picks up the data gathered by the Flash_Write function like if
 * a buffered write is possible in a given address location and
 * compeltes the flash write request.
 *
 * @parma addr Flash Address in which the data has to be written.
 * @param data The Data that has to be written to the flash.
 * @param numBytes Length of the data.
 * 
 * @return status The status register value.
 */
uint16_t Write_Helper(uint32_t addr, uint8_t* data, uint32_t numBytes,
		       uint8_t prebyte, uint8_t postbyte);

/**
 * Write_Exit_Helper
 * 
 * The funciton completes Flash_Write by changing all the internal
 * states of the affected blocks by Flash_Write to READ_INACTIVE.
 * This state change is puerly driver specific and not a HW
 * requirement.
 *
 * @parma addr Flash Address in which the data has to be written.
 * @param numBytes Length of the data.
 * 
 */
void Write_Exit_Helper(uint32_t addr, uint32_t numBytes);

/**
 * __Flash_Erase
 *
 * The function performs all the steps required to
 * erase a flash block. The commands and steps are defined
 * in the memory subsystem data sheet for the processor.
 * The Block address has to be passed as a parameter to the
 * function.
 * The function is implemented in flash.s.
 * 
 * @param addr Address of the block that has to be erased.
 *
 * @return status The status register value.
 * 
 */
extern uint8_t __Flash_Erase(uint32_t addr) __attribute__ ((noinline));

/**
 * __Flash_Program_Word
 *
 * The function performs all the steps required to
 * write a word to flash. The commands and steps are defined
 * in the memory subsystem data sheet for the processor.
 *
 * The function is implemented in flash.s.
 *
 * @parma addr Flash Address in which the word has to be written.
 * @param data The Data that has to be written to the flash.
 *
 * @return status The status register value.
 */
extern uint8_t __Flash_Program_Word (uint32_t addr, 
                                     uint16_t word) __attribute__ ((noinline));

/**
 * __Flash_Program_Buffer
 *
 * The function performs all the steps required to
 * write a buffer to flash. The commands and steps are defined
 * in the memory subsystem data sheet for the processor.
 *
 * <B>
 * NOTE;
 *   The address has to be aligned in 32 byte boundary for the
 *   buffered write to work.
 * </B>
 * 
 * @parma addr Flash Address in which the word has to be written.
 * @param data The Data that has to be written to the flash.
 * @param datalen Length of the data.
 *
 * @return status The status register value.
 */
extern uint8_t __Flash_Program_Buffer (uint32_t addr, 
                                       uint16_t *data, 
                                       uint8_t datalen) __attribute__ ((noinline));

extern uint32_t __Flash_Erase_true_end ();
extern uint32_t __Flash_Program_Word_true_end ();
extern uint32_t __Flash_Program_Buffer_true_end ();


#endif
