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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Greatest Common divisor routines
 * Algorithms from:
 * D.E. Knuth: The Art of Computer Programming,
 * Vol. 2: Seminumerical algorithms, 3rd edition, Stanford: 1998,
 * Addison-Wesley 
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

#ifndef GCD_H
#define GCD_H


/**
 * Helper function for better readability
 */
bool isEven(uint16_t t) 
{
    return !(t & 1);
}

/**
 * Binary gcd algorithm
 * Limits:
 *  - can only compute gcd from unsigned values that can fit into
 *    15 bits (sign is needed in this algorithm)
 *  - it does not check input values
 */

uint16_t gcd(uint16_t u, uint16_t v) 
{
    uint16_t k;
    int16_t t;
    for(k = 0; isEven(u) && isEven(v); k++) {
        u >>= 1;
        v >>= 1;
    }
    
    if(u & 1) t = -v; else t = u;
    
    while(t != 0) {
        if(isEven(t)) {
            t >>= 1;
        } else {
            if(t > 0)  u = t; else v = -t;
            t = u - v;
        }
    }
    return (u << k);
}

/**
 * Compute the gcd for a set of integers
 */

uint16_t gcdOfSet(uint16_t array[], uint16_t len) 
{
    uint16_t k = len-1;
    uint16_t d = array[k];
    while((d != 1) && (k > 0)) {
        d = gcd(array[--k], d);
    }
    return d;
}

#endif
