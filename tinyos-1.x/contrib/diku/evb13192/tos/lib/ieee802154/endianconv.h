/* Copyright (c) 2006, Jan Flora <janflora@diku.dk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  - Neither the name of the University of Copenhagen nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
  @author Jan Flora <janflora@diku.dk>
*/

#ifndef _ENDIANCONV_H_
#define _ENDIANCONV_H_

	static inline void NTOUH64(uint8_t *src, uint8_t *dst)
	{
		dst[0] = src[7];
		dst[1] = src[6];
		dst[2] = src[5];
		dst[3] = src[4];
		dst[4] = src[3];
		dst[5] = src[2];
		dst[6] = src[1];
		dst[7] = src[0];
	}
	
	static inline void NTOUH32(uint8_t *src, uint8_t *dst)
	{
		dst[0] = src[3];
		dst[1] = src[2];
		dst[2] = src[1];
		dst[3] = src[0];
	}
	
	static inline void NTOUH16(uint8_t *src, uint8_t *dst)
	{
		dst[0] = src[1];
		dst[1] = src[0];		
	}
	
	static inline uint32_t _NTOUH32(uint32_t n)
	{
		char* base = (char*)&n;
		return (uint32_t)base[3] << 24 |
		       (uint32_t)base[2] << 16 |
		       (uint32_t)base[1] <<  8 |
		       (uint32_t)base[0];		
	}
	
	static inline uint16_t _NTOUH16(uint16_t n)
	{
		char* base = (char*)&n;
		return (uint16_t)base[1] << 8 |
		       (uint16_t)base[0];		
	}
	
#endif
