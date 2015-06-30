/**
 * Header file for ECC module.  
 *
 * @author  David Malan <malan@eecs.harvard.edu>
 *
 * @version 2.0
 *
 * Copyright (c) 2004
 *  The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *      may be used to endorse or promote products derived from this software
 *      without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */


////////////////////////////////////////////////////////////////////////////
// constants
////////////////////////////////////////////////////////////////////////////

// number of bits in key
#define NUMBITS 163

// maximal number of words required to store a bint;
// twice the space necessary to store a key, but allows
// for overflow during multiplication, albeit at a cost
// (in space and, to some degree, time)
#define NUMWORDS (2 * ((int) ((NUMBITS + 1)/ 8. + 0.5)))


////////////////////////////////////////////////////////////////////////////
// primitives 
////////////////////////////////////////////////////////////////////////////

// a type primarily for loops' indices
typedef int16_t index_t;

// a type for the mote's 8-bit words
typedef uint8_t word_t;

// a type for a mote's state
typedef uint8_t state_t;


////////////////////////////////////////////////////////////////////////////
// structures
////////////////////////////////////////////////////////////////////////////


// a finite field element from GF(2)[p], modulo some irreducible 
// polynomial, represented with a polynomial basis as 
// b_{p-1} x^{p-1} + b_{p-2} x^{p-2} + ... + b_1 x^1 + b_0
struct Elt
{
    // b_{p-1} o b_{p-2} o ... o b_1 o b_0;
    // words are stored as big endian, so b_{p-1} \in val[0] and
    // b_0 \in val[NUMWORDS-1]
    uint8_t val[NUMWORDS];
};
typedef struct Elt Elt;


// a curve over GF(2)[p] of the form
// y^2 + x y = x^3 + a_4 x^2 + a_6 
struct Curve
{
    // curve's coefficients
    Elt a4;
    Elt a6;

    // modulus for points on the curve
    uint8_t modulus[NUMWORDS];

    // number of bits necessary to represent modulus
    uint8_t bitlength;
};
typedef struct Curve Curve;


// a point, (x,y), on a curve
struct Point
{
    // point's coordinates
    Elt x;
    Elt y;
};
typedef struct Point Point;


// parameters for ECC
struct Params
{
    // curve over which ECC will be performed
    Curve E;

    // a point on E of order r
    Point G;

    // a positive, prime integer dividing the number of points on E
    uint8_t r[NUMWORDS];

    // a positive prime integer, s.t. k = #E/r
    uint8_t k[NUMWORDS];

    // field shall be GF(2)[p]
    uint16_t p;

    // coefficients for irreducible pentanomial,
    // x^m + x^k3 + x^k2 + x^k1 + 1
    uint8_t pentanomial_k1;
    uint8_t pentanomial_k2;
    uint8_t pentanomial_k3;
};
typedef struct Params Params;


// private key for ECC
struct PrivKey
{
    // the secret
    uint8_t s[NUMWORDS];
};
typedef struct PrivKey PrivKey;


// public key for ECC
struct PubKey
{
    // the point
    Point W;
};
typedef struct PubKey PubKey;


// format for debugging messages
struct DbgMsg
{
    uint32_t privKeyTime;
    uint32_t pubKeyTime;
    uint32_t secKeyTime;

} __attribute__ ((packed));
typedef struct DbgMsg DbgMsg;


// format for exchanging keys
struct KeyMsg
{
    // flag indicating whether coordinate in message is x in Bob's
    // public key, (x,y); if FALSE, it's Bob's y
    bool isX;

    // coordinate in message
    uint8_t coord[NUMWORDS/2];

} __attribute__ ((packed));
typedef struct KeyMsg KeyMsg;


// Active Message type for debugging messages
enum {
       AM_DBGMSG = 130,
       AM_KEYMSG = 131
     };


/* EOF */

