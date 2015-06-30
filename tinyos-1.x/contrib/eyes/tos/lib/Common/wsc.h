/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2005, Technische Universitaet Berlin
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
 * - Description ---------------------------------------------------------
 * Calculate weighted sum code (instead of crc)
 * See: A. J. McAuley: Weigthed Sum Codes for error detection and their
 * comparison with existing codes. In: IEEE/ACM Transactions on Networking,
 * Vol. 2, No. 1, February 1994
 *
 * not sure, whether I understood everything correctly, though...
 * - Revision -------------------------------------------------------------
 * Author: Andreas Koepke <koepke@tkn.tu-berlin.de>
 * ========================================================================
 */

#define TEST_MASK_X 0x80
#define MOD_POLY 0x11

typedef union 
{
    uint16_t crc;
    struct 
    {
        uint8_t p1;
        uint8_t p0;
    };
} poly_t;

uint16_t wscByte(uint16_t fcs, uint8_t c)
{
    register poly_t p;
    p.crc = fcs;
    p.p0 ^= c;  
    p.p1 ^= c;
    if(p.p1 & TEST_MASK_X) p.p1 ^= MOD_POLY;
    p.p1 <<= 1;
    return p.crc;
}
