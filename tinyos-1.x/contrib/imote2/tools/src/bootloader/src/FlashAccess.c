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
#include <pxa27xhardware.h>
#include <HPLInit.h>
#include <FlashAccess.h>
#include <string.h>
#include <Leds.h>

uint8_t FlashPartitionState[FLASH_PARTITION_COUNT];
uint8_t init = 0, programBufferSupported = 2, currBlock = 0;

/**
 * FlashAccess_Init
 *
 * Intialize the internal states of the blocks and the partitions.
 * The fuction also defines the global variables for the
 * inline assembly codes of certain functions.
 *
 * @return SUCCESS | FAIL
 */
result_t FlashAccess_Init() 
{
  int i = 0;
  if(init != 0)
    return SUCCESS;
  init = 1;
  for(i = 0; i < FLASH_PARTITION_COUNT; i++)
    FlashPartitionState[i] = FLASH_STATE_READ_INACTIVE;
    
  asm volatile(
       ".equ FLASH_READARRAY,(0x00FF);           \
        .equ FLASH_CFIQUERY,(0x0098);            \
        .equ FLASH_READSTATUS,(0x0070);	         \
        .equ FLASH_CLEARSTATUS,(0x0050);         \
        .equ FLASH_PROGRAMWORD,(0x0040);         \
        .equ FLASH_PROGRAMBUFFER,(0x00E8);       \
        .equ FLASH_ERASEBLOCK,(0x0020);          \
        .equ FLASH_DLOCKBLOCK,(0x0060);          \
        .equ FLASH_PROGRAMBUFFERCONF,(0x00D0);	 \
        .equ FLASH_LOCKCONF,(0x0001);	         \
        .equ FLASH_UNLOCKCONF,(0x00D0);          \
	.equ FLASH_LOCKDOWNCONF,(0x002F);          \
        .equ FLASH_ERASECONF,(0x00D0);	         \
        .equ FLASH_OP_NOT_SUPPORTED,(0x10);");
  //flash_op_not_supported needs to be LSL 1 to be the correct value of 0x100
  return SUCCESS;
}

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
		uint8_t prebyte, uint8_t postbyte)
{
  uint32_t i = 0, j = 0, k = 0;
  uint16_t status;
  uint16_t buffer[FLASH_PROGRAM_BUFFER_SIZE];
    
  if(numBytes == 0)
    return FAIL;
    
  if(addr % 2 == 1)
  {
    status = __Flash_Program_Word(addr - 1, prebyte | (data[i] << 8));
    i++;
    if(status != 0x80)
      return FAIL;
  }
    
  if(addr % 2 == numBytes % 2)
  {
    if(programBufferSupported == 1)
    {
      for(; i < numBytes; i = k)
      {
        for(j = 0, k = i; k < numBytes && j < FLASH_PROGRAM_BUFFER_SIZE; j++, k+=2)
          buffer[j] = data[k] | (data[k + 1] << 8);
        status = __Flash_Program_Buffer(addr + i, buffer, j - 1);
        if(status != 0x80)
          return FAIL;
      }
    }
    else
    {
      for(; i < numBytes; i+=2)
      {
        status = __Flash_Program_Word(addr + i, (data[i + 1] << 8) | data[i]);
        if(status != 0x80)
          return FAIL;
      }
    }
  }
  else
  {
    if(programBufferSupported == 1)
    {
      for(; i < numBytes - 1; i = k)
      {
        for(j = 0, k = i; k < numBytes - 1 && j < FLASH_PROGRAM_BUFFER_SIZE; 
                         j++, k+=2)
          buffer[j] = data[k] | (data[k + 1] << 8);
        status = __Flash_Program_Buffer(addr + i, buffer, j - 1);
        if(status != 0x80)
          return FAIL;
      }
    }
    else
    {
      for(; i < numBytes - 1; i+=2)
      {
        status = __Flash_Program_Word(addr + i, (data[i + 1] << 8) | data[i]);
        if(status != 0x80)
          return FAIL;
      }
    }
    status = __Flash_Program_Word(addr + i, data[i] | (postbyte << 8));
    if(status != 0x80)
      return FAIL;
  }
  return SUCCESS;
}


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
void Write_Exit_Helper(uint32_t addr, uint32_t numBytes)
{
  uint32_t i = 0;
  for(i = addr / FLASH_PARTITION_SIZE; 
            i < (numBytes + addr) / FLASH_PARTITION_SIZE; i++)
    FlashPartitionState[i] = FLASH_STATE_READ_INACTIVE;
}

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
result_t Flash_Write(uint32_t addr, uint8_t* data, uint32_t numBytes)
{
  uint32_t i;
  uint16_t status;
  uint8_t blocklen;
  uint32_t blockAddr = (addr / FLASH_BLOCK_SIZE) * FLASH_BLOCK_SIZE;

  if (addr + numBytes > 0x02000000) //not in the flash memory space
    return FAIL;

  for (i = 0; i < FLASH_PARTITION_COUNT; i++)
    if (i != addr / FLASH_PARTITION_SIZE && 
               FlashPartitionState[i] != FLASH_STATE_READ_INACTIVE && 
               FlashPartitionState[i] != FLASH_STATE_READ_ACTIVE)
      return FAIL;

  for(i = addr / FLASH_PARTITION_SIZE;
       	    i < (numBytes + addr) / FLASH_PARTITION_SIZE; i++)
    if(FlashPartitionState[i] != FLASH_STATE_READ_INACTIVE)
      return FAIL;

  for(i = addr / FLASH_PARTITION_SIZE; 
            i < (numBytes + addr) / FLASH_PARTITION_SIZE; i++)
    FlashPartitionState[i] = FLASH_STATE_PROGRAM;

  {
  __nesc_atomic_t atomic = __nesc_atomic_start();
    for(blocklen = 0, i = blockAddr; i < addr + numBytes; 
                              i += FLASH_BLOCK_SIZE, blocklen++)
      Flash_Unlock(i);

    if(programBufferSupported == 2)
    {
      uint16_t testBuf[1];
      if(addr % 2 == 0)
      {
        testBuf[0] = data[0] | ((*((uint8_t *)(addr + 1))) << 8);
        status = __Flash_Program_Buffer(addr, testBuf, 1 - 1);
      }
      else
      {
        testBuf[0] = *((uint8_t *)(addr - 1)) | (data[0] << 8);
        status = __Flash_Program_Buffer(addr - 1, testBuf, 1 - 1);
      }      
      if(status == FLASH_NOT_SUPPORTED)
        programBufferSupported = 0;
      else 
        programBufferSupported = 1;
    }
  __nesc_atomic_end (atomic);
  }

  if(blocklen == 1)
  {
    /*atomic*/ status = Write_Helper(addr,data,numBytes,0xFF,0xFF);
    if(status == FAIL)
    {
      Write_Exit_Helper(addr, numBytes);
      return FAIL;
    }
  }
  else
  {
    uint32_t bytesLeft = numBytes;
    /*atomic*/ status = Write_Helper(addr,data, 
                    blockAddr + FLASH_BLOCK_SIZE - addr,0xFF,0xFF);
    if(status == FAIL)
    {
      Write_Exit_Helper (addr, numBytes);
      return FAIL;
    }
    bytesLeft = numBytes - (FLASH_BLOCK_SIZE - (addr - blockAddr));
    for(i = 1; i < blocklen - 1; i++)
    {
      /*atomic*/ status = Write_Helper(blockAddr + i * FLASH_BLOCK_SIZE, 
                      (uint8_t *)(data + numBytes - bytesLeft), 
                      FLASH_BLOCK_SIZE,0xFF,0xFF);
      bytesLeft -= FLASH_BLOCK_SIZE;
      if(status == FAIL)
      {
        Write_Exit_Helper(addr, numBytes);
        return FAIL;
      }
    }
    /*atomic*/ status = Write_Helper(blockAddr + i * FLASH_BLOCK_SIZE, data + 
                             (numBytes - bytesLeft), bytesLeft, 0xFF,0xFF);
    if(status == FAIL)
    {
      Write_Exit_Helper(addr, numBytes);
      return FAIL;
    }
  }
    
  Write_Exit_Helper(addr, numBytes);
  return SUCCESS;
}

/**
 * Flash_Param_Partition_Erase
 *
 * The top most partition of the flash is configured as
 * parameter partition.
 *
 * @param addr Starting address of a block that has to be erased.
 * @return SUCCESS | FAIL
 */
result_t Flash_Param_Partition_Erase (uint32_t addr)
{
  uint16_t status;
  if(addr > 0x02000000) //not in the flash memory space
    return FAIL;
  //addr = (addr / FLASH_BLOCK_SIZE) * FLASH_BLOCK_SIZE;

  {
  __nesc_atomic_t atomic = __nesc_atomic_start();	
    Flash_Unlock(addr);
    status = __Flash_Erase(addr);
  __nesc_atomic_end (atomic);
  }
  if(status != 0x80)
    return FAIL;

  return SUCCESS;
}

/**
 * Flash_Erase
 *
 * Erase the entire block in which the first parameter is located.
 * 
 * @param addr Starting Address of a flash block.
 * @return SUCCESS | FAIL
 */
result_t Flash_Erase (uint32_t addr)
{
  uint16_t status, i;
  uint32_t j;
  if(addr > 0x02000000) //not in the flash memory space
    return FAIL;

  addr = (addr / FLASH_BLOCK_SIZE) * FLASH_BLOCK_SIZE;

  for(i = 0; i < FLASH_PARTITION_COUNT; i++)
    if(i != addr / FLASH_PARTITION_SIZE && 
             FlashPartitionState[i] != FLASH_STATE_READ_INACTIVE && 
             FlashPartitionState[i] != FLASH_STATE_READ_ACTIVE)
      return FAIL;
    
  if(FlashPartitionState[addr / FLASH_PARTITION_SIZE] != 
                                     FLASH_STATE_READ_INACTIVE)
    return FAIL;
    
  FlashPartitionState[addr / FLASH_PARTITION_SIZE] = FLASH_STATE_ERASE;
    
  for(j = 0; j < FLASH_BLOCK_SIZE; j++)
  {
    uint32_t tempCheck = *(uint32_t *)(addr + j);
    if(tempCheck != 0xFFFFFFFF)
      break;
    if(j == FLASH_BLOCK_SIZE - 1)
    {
      FlashPartitionState[addr / FLASH_PARTITION_SIZE] = FLASH_STATE_READ_INACTIVE;
      return SUCCESS;
    }
  }

  {
  __nesc_atomic_t atomic = __nesc_atomic_start();	
    Flash_Unlock(addr);
    //      status = eraseFlash(addr);
    status = __Flash_Erase(addr);
  __nesc_atomic_end (atomic);
  }
  FlashPartitionState[addr / FLASH_PARTITION_SIZE] = FLASH_STATE_READ_INACTIVE;
  if(status != 0x80)
    return FAIL;

  return SUCCESS;
}

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
uint16_t Flash_Unlock(uint32_t addr)
{
  addr = (addr / FLASH_BLOCK_SIZE) * FLASH_BLOCK_SIZE;

  asm volatile(
       "ldr r1,=FLASH_DLOCKBLOCK;     \
        ldr r2,=FLASH_READARRAY;      \
        ldr r3,=FLASH_UNLOCKCONF;     \
        ldr r4,=FLASH_CLEARSTATUS;    \
        b _goUnlockCacheLine;	      \
       .align 5;		      \
        _goUnlockCacheLine:	      \
        strh r4,[r3];		      \
        strh r1,[%0];		      \
        strh r3,[%0];		      \
        strh r2,[%0];		      \
        ldrh r2,[%0];		      \
        nop;			      \
        nop;			      \
        nop;"
        :/*no output info*/
        :"r"(addr)
        : "r1", "r2", "r3", "r4", "memory");
        return SUCCESS;
}

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
uint16_t Flash_Lockdown(uint32_t addr)
{
  addr = (addr / FLASH_BLOCK_SIZE) * FLASH_BLOCK_SIZE;

  asm volatile(
       "ldr r1,=FLASH_DLOCKBLOCK;     \
        ldr r2,=FLASH_READARRAY;      \
        ldr r3,=FLASH_LOCKDOWNCONF;     \
        ldr r4,=FLASH_CLEARSTATUS;    \
        b _goUnlockCacheLine1;	      \
       .align 5;		      \
        _goUnlockCacheLine1:	      \
        strh r4,[%0];		      \
        strh r1,[%0];		      \
        strh r3,[%0];		      \
        strh r2,[%0];		      \
        ldrh r2,[%0];		      \
        nop;			      \
        nop;			      \
        nop;"
        :/*no output info*/
        :"r"(addr)
        : "r1", "r2", "r3", "r4", "memory");
        return SUCCESS;
}

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
uint16_t Program_Buffer(uint32_t addr, uint16_t data[], 
		uint8_t datalen)
{
  uint16_t status;

  datalen -= 1;
  asm volatile("mov r1, %1;                 \
                mov r2, %2;                 \
                 mov r3, %3;                \
		 bl __Flash_Program_Buffer; \
		 mov %0, r0;"		 
		 :"=r"(status)
		 :"r"(addr), "r"(data),"r"(datalen)//, "r"(programBufferCommands)
		 : "r0", "r1", "r2", "r3", "r14", "memory");
	return status;
}

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
uint16_t Program_Word(uint32_t addr, uint16_t data)
{
  uint16_t status;

  asm volatile(
   "mov r1, %1;                    \
    mov r2, %2;			\
    bl __Flash_Program_Word;        \
    mov %0, r0;"
    :"=r"(status)
    :"r"(addr), "r"(data)//,"r"(temp)
    : "r0", "r1", "r2", "r3", "memory");
  return status;
}
  
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
uint16_t Erase_Flash(uint32_t addr)
{
	uint16_t status;
	asm volatile (
		"mov r1, %1;                   \
		bl __Flash_Erase;              \
		mov %0, r0;"
		:"=r"(status)
		:"r"(addr)//, "r"(temp)
		: "r0", "r1", "r2", "memory");
	return status;
}

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
result_t Flash_Read (uint32_t Addr, uint32_t Length, uint8_t* buff)
{
  uint32_t curPtr = 0;
  uint32_t address = Addr;
  uint32_t data = 0;
  while (curPtr < Length)
  {
    data = (*((uint32_t *)address));
    memcpy ((buff + curPtr), &data, 2);
    curPtr = curPtr + 2;
    address += 2;
  }
  return SUCCESS;
}
