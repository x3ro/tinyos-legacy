/*
* Copyright (c) 2006 Stanford University.
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
* - Redistributions of source code must retain the above copyright
*   notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright
*   notice, this list of conditions and the following disclaimer in the
*   documentation and/or other materials provided with the
*   distribution.
* - Neither the name of the Stanford University nor the names of
*   its contributors may be used to endorse or promote products derived
*   from this software without specific prior written permission
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
* UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*/ 
/**
 * @author Brano Kusy (branislav.kusy@gmail.com)
 */ 

/* modified for Robbie's new SDRAM section
 * RMK
 */

 
#ifndef _SDRAM_H_
#define _SDRAM_H_

#define VGA_SIZE_RGB (640*480*3)

uint32_t base_f[VGA_SIZE_RGB] __attribute__((section(".sdram")));
uint32_t jpeg_f[VGA_SIZE_RGB] __attribute__((section(".sdram")));
uint32_t buf1_f[VGA_SIZE_RGB] __attribute__((section(".sdram")));
uint32_t buf2_f[VGA_SIZE_RGB] __attribute__((section(".sdram")));
uint32_t buf3_f[VGA_SIZE_RGB] __attribute__((section(".sdram")));

#define BASE_FRAME_ADDRESS	base_f
#define JPEG_FRAME_ADDRESS	jpeg_f
#define BUF1_FRAME_ADDRESS	buf1_f
#define BUF2_FRAME_ADDRESS	buf2_f
#define BUF3_FRAME_ADDRESS	buf3_f

#endif //_SDRAM_H_
