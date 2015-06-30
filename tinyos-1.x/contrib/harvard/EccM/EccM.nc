/**
 * Implementation of ECC module.
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


// include module's header file
includes Ecc;


////////////////////////////////////////////////////////////////////////////
// module
////////////////////////////////////////////////////////////////////////////

module EccM
{
    provides
    {
        interface StdControl;
    }
    uses
    {
        // for signaling various internal states
        interface Leds;

        // for generating secrets
        interface Random;

        // for receiving Bob's public key
        interface ReceiveMsg;

        // for transmitting debugging messages
        interface SendMsg as SendDbgMsg;

        // for transmitting key messages
        interface SendMsg as SendKeyMsg;

        // for clocking code's running time
        interface SysTime;

        // for triggering transmission of debugging message
        interface Timer as DbgTimer;

        // for triggering generation of keys
        interface Timer as GenTimer;

        // for triggering sending of keys
        interface Timer as SendTimer;
    }
}


////////////////////////////////////////////////////////////////////////////
// implementation
////////////////////////////////////////////////////////////////////////////

implementation
{
    // hard-coded domain parameters
    Params params;

    // Alice's private key
    PrivKey privKeyA;

    // Alice's public key
    PubKey pubKeyA;

    // Bob's public key
    PubKey pubKeyB;

    // Alice and Bob's shared secret
    Point secret;

    // envelope for debugging messages
    TOS_Msg dbg_envelope;

    // payload for debugging envelope
    DbgMsg * dbg_msg;

    // envelope for state messages
    TOS_Msg state_envelope;

    // envelope for key messages
    TOS_Msg key_envelope;

    // payload for state envelope
    KeyMsg * key_msg;

    // storage for timings
    uint32_t before;
    uint32_t after;

    // flag indicating whether Alice's public key has been generated
    bool havePubKeyA = FALSE;

    // flags indicating whether Bob's public key was received
    bool haveXB = FALSE;
    bool haveYB = FALSE;


    ////////////////////////////////////////////////////////////////////////
    // function prototypes
    ////////////////////////////////////////////////////////////////////////

    // bint routines
    inline index_t b_bitlength(uint8_t * a);
    inline void    b_clear(uint8_t * a);
    inline void    b_clearbit(uint8_t * a, index_t i);
    inline int8_t  b_compareto(uint8_t * a, uint8_t * b);
    inline void    b_copy(uint8_t * a, uint8_t * b);
    inline bool    b_isequal(uint8_t * a, uint8_t * b);
    inline bool    b_iszero(uint8_t * a);
    inline void    b_mod(uint8_t * remp, uint8_t * modp, int16_t lth);
    inline void    b_print(uint8_t * a);
    inline void    b_halfprint(uint8_t * a);
    inline void    b_setbit(uint8_t * a, index_t i);
    inline void    b_shiftleft(uint8_t * a, index_t i, uint8_t * b);
    inline void    b_shiftleft1(uint8_t * a, uint8_t * b);
    inline void    b_shiftleft2(uint8_t * a, uint8_t * b);
    inline void    b_sub(uint8_t *fromp, uint8_t *subp, int16_t lth);
    inline bool    b_testbit(uint8_t * a, index_t i);
    inline void    b_xor(uint8_t * a, uint8_t * b, uint8_t * c);
    
    // point routines
    inline void p_clear(Point * P0);
    inline void p_copy(Point * P0, Point * P1);
    inline bool p_iszero(Point * P0);
    inline void p_print(Point * P0);

    // curve routines
    inline void c_add(Point * P0, Point * P1, Point * P2);
    inline void c_mul(uint8_t * n, Point * P0, Point * P1);

    // field routines
    inline void f_add(uint8_t * a, uint8_t * b, uint8_t * c);
    inline void f_inv(uint8_t * a, uint8_t * d);
    inline void f_mod(uint8_t * a, uint8_t * b);
    inline void f_mul(uint8_t * a, uint8_t * b, uint8_t * c);


    ////////////////////////////////////////////////////////////////////////
    // bint
    // routines
    ////////////////////////////////////////////////////////////////////////

    /**
     * Clears bint.
     */
    inline void b_clear(uint8_t * a)
    {
        memset(a, 0, NUMWORDS);
    }


    /**
     * Prints bint in hexadecimal to debugging console.
     */
    inline void b_print(uint8_t * a)
    {
        // index variable
        index_t i;

        // iterate over bint's bytes, displaying each in hexadecimal
        for (i = 0; i < NUMWORDS; i++)
            dbg_clear(DBG_AM, "%02hhx ", *(a+i));
        dbg_clear(DBG_AM, "\n");
    }


    /**
     * Prints lower half of bint in hexadecimal to debugging console.
     */
    inline void b_halfprint(uint8_t * a)
    {
        // index variable
        index_t i;

        // iterate over bint's bytes, displaying each in hexadecimal
        for (i = 0; i < NUMWORDS/2; i++)
            dbg_clear(DBG_AM, "%02hhx ", *(a+i));
        dbg_clear(DBG_AM, "\n");
    }


    /**
     * Sets ith bit (where least significant bit is 0th bit) of bint.
     */
    inline void b_setbit(uint8_t * a, index_t i)
    {
        *(a + NUMWORDS - (i / 8) - 1) |= (1 << (i % 8));
    }


    /**
     * Clears ith bit (where least significant bit is 0th bit) of bint.
     */
    inline void b_clearbit(uint8_t * a, index_t i)
    {
        *(a + NUMWORDS - (i / 8) - 1) &= (0xffff ^ (1 << (i % 8)));
    }


    /**
     * Returns TRUE iff bint is zero.
     */
    inline bool b_iszero(uint8_t * a)
    {
        // index for loop
        index_t i;

        // determine whether bint is 0; loop ignores top half of a[], 
        // so it'd better be modulo dp.E.modulus already;
        // casting effectively unrolls loop a bit, saving us some cycles
        for (i = 0 + NUMWORDS/2, a = a + NUMWORDS - 2; i < NUMWORDS; i++, a-=2)
            if (*((uint16_t *) a))
                return FALSE;

        return TRUE;
    }


    /**
     * b = a.
     */
    inline void b_copy(uint8_t * a, uint8_t * b)
    {
        // index for loop
        index_t i;

        // copy a[] into b[]; casting effectively unrolls loop a bit, 
        // saving us some cycles
        for (i = 0; i < NUMWORDS; i += 2)
            *((uint16_t *) (b + i)) = *((uint16_t *) (a + i));
    }


    /**
     * c = a XOR b.
     */
    inline void b_xor(uint8_t * a, uint8_t * b, uint8_t * c)
    {
        // index for loop
        index_t i;

        // let c[] = a[] XOR b[]; casting effectively unrolls loop a bit, 
        // saving us some cycles
        for (i = 0; i < NUMWORDS; i += 2, a += 2, b += 2, c += 2)
            *((uint16_t *) c) = *((uint16_t *) a) ^ *((uint16_t *) b);
    }


    /**
     * Returns -1 if a < b, 0 if a == b, and 1 if a > b.  
     */
    inline int8_t b_compareto(uint8_t * a, uint8_t * b)
    {

        // index for loop
        uint8_t lth = NUMWORDS;

        // iterate over a[] and b[], looking for a difference
        while (lth && *a == *b)
        {
            a++;
            b++;
            lth--;
        }

        // if we reached end of a[] and b[], they're the same
        if (!lth) 
            return 0;

        // if the current byte in a[] is greater than that in b[],
        // a[] is bigger than b[]
        else if (*a > *b) 
            return 1;

        // else b[] is bigger than a[]
        else
            return -1;
    }


    /**
     * Shifts bint left by n bits, storing result in b.
     *
     * a and b are allowed to point to the same memory.
     */
    inline void b_shiftleft(uint8_t * a, index_t n, uint8_t * b)
    {
        // index variable
        index_t i;

        // storage for shift's magnitudes
        index_t bytes, bits;

        // determine how far to shift whole bytes
        bytes = n / 8;

        // determine how far to shift bits within bytes or across
        // pairs of bytes
        bits = n % 8;

        // shift whole bytes as appropriate
        if (bytes > 0)
        {
            for (i = bytes; i < NUMWORDS; i++)
                *(b + i-bytes) = *(a + i);
            for (i = NUMWORDS - bytes; i < NUMWORDS; i++)
                *(b + i) = (word_t) 0x00;
        }

        // else prepare just to shift bits
        else if (bytes == 0)
            b_copy(a, b);

        // shift bits as appropriate
        for (i = 1; i < NUMWORDS; i++)
            *(b + i - 1) = (*(b + i-1) << bits) | (*(b + i) >> (8 - bits));
         *(b + NUMWORDS-1) = (*(b + NUMWORDS-1) << bits);
    }


    /**
     * Shifts bint left by 1 bit.  Though a call to this
     * function is functionally equivalent to one to b_shiftleft(a, 1, b),
     * this version is meant to optimize a common case (shifts by 1).
     */
    inline void b_shiftleft1(uint8_t * a, uint8_t * b)
    {
        // index variable
        index_t i;

        if (a != b)
            b_copy(a, b);

        // shift bits as appropriate; loop is manually unrolled a bit
        // to save some cycles
        for (i = 1; i < NUMWORDS - 1; i++)
        {
            *(b + i-1) <<= 1;
            if (*(b + i) & 0x0080)
                *(b+ i-1) |= 0x0001;
            i++;
            *(b + i-1) <<= 1;
            if (*(b + i) & 0x0080)
                *(b+ i-1) |= 0x0001;
        }
        *(b + NUMWORDS-2) <<= 1;
        if (*(b + NUMWORDS-1) & 0x0080)
            *(b + NUMWORDS-2) |= 0x0001;
        *(b + NUMWORDS-1) <<= 1;
    }


    /**
     * Shifts bint left by 2 bits.  Though a call to this
     * function is functionally equivalent to one to b_shiftleft(a, 1, b),
     * this version is meant to optimize a common case (shifts by 2).
     */
    inline void b_shiftleft2(uint8_t * a, uint8_t * b)
    {
        // index variable
        index_t i;

        if (a != b)
            b_copy(a, b);


        // shift bits as appropriate
        for (i = 1; i < NUMWORDS; i++)
        {
            *(b + i-1) <<= 2;
            if (*(b + i) & 0x0040)
                *(b+ i-1) |= 0x0001;
            if (*(b + i) & 0x0080)
                *(b+ i-1) |= 0x0002;
        }
        *(b + NUMWORDS-1) <<= 2;
    }


    /**
     * Returns the number of bits in the shortest possible 
     * representation of this bint.
     */
    inline index_t b_bitlength(uint8_t * a)
    {
        // index variables;
        index_t i;

        // local storage
        uint8_t n, x, y;

        // iterate over other bytes, looking for most significant set bit;
        // algorithm from Henry S. Warren Jr., Hacker's Delight
        for (i = 0; i < NUMWORDS; i++)
        {
            x = *(a+i);
            if (x)
            {
                n = 8;
                y = x >> 4;  
                if (y != 0) {n = n - 4; x = y;}
                y = x >> 2;  
                if (y != 0) {n = n - 2; x = y;}
                y = x >> 1;  
                if (y != 0) 
                    return (NUMWORDS - i - 1) * 8 + (8 - (n - 2));

                return (NUMWORDS - i - 1) * 8 + (8 - (n - x));
            }
        }

        // if no bits are set, bint is 0
        return 0;
    }


    /**
     * Returns TRUE iff ith bit of bint (where index of least
     * significant bit is 0) is set.  Recall that bints
     * are big-endian.
     */
    inline bool b_testbit(uint8_t * a, index_t i)
    {
        return (*(a + NUMWORDS - (i / 8) - 1) & (1 << (i % 8)));
    }


    /**
     * Returns TRUE iff bints are equal.
     */
    inline bool b_isequal(uint8_t * a, uint8_t * b)
    {
        // index variable
        index_t i;

        // iterate over bints, looking for a difference
        for (i = 0; i < NUMWORDS; i++)
            if (*(a + NUMWORDS - 1 - i) != *(b + NUMWORDS - 1 - i))
                return FALSE;

        // if no difference found, bints are equal
        return TRUE;
    }


    /**
     * Function: Subtracts one string of unsigned bytes from another
     * Inputs: fromp points to MSByte of minuend
     *         subp points to MSbyte of subtrahend
     *         lth is number of bytes in subtrahend'
     * Output: difference in fromp
     * Procedure:
     *   Starting ta the LS end, FOR each byte in each string
     *   Save the minuend byte
     *   Subtract the subtrahend byte from the minuend byte
     *   If the minuend byte is bigger than it was before
     *   Borrow one from the prior byte and
     *   keep doing this WHILE that byte was 0
     *
     * Based on function from BBN Technologies' DHm, part of TinyPKI, by 
     * Jennifer Mulligan, 2003.
    **/
    inline void b_sub(uint8_t *fromp, uint8_t *subp, int16_t lth)
    {
        // local variables
        uint8_t *cp, tmp;

        /* step 1 */
        for (subp += lth - 1, fromp += lth - 1 ; lth--; subp--, fromp--)
        {
            tmp = *fromp;
            *fromp -= *subp;

            /* have to borrow */
            if (*fromp > tmp)   
            {
                cp = fromp;
                do
                {
                    cp--;
                    (*cp)--;
                }
                while(*cp == 0xff);
            }
        }
    }


    /**
     * Function: remodularizes by using long division
     * Inputs: remp points to MSB of number to be reduced (2*lth bytes)
     *         modp points to MSB of modulus (lth bytes)
     *         subprod points to the MSB of an array of lth + 1 bytes
     *         trials points to table of 2-byte array of shifts of MSB 
     *         of modulus
     *         lth is number of bytes in modulus
     * Outputs: remainder in remp
     * Procedure:
     *   1. WHILE remainder is bigger than modulus
     *      Subtract modulus from remainder
     *   2. Starting with MSB of modulus aligned with MSB of remainder
     *      FOR each position of the modulus, shifting right by 1 byte
     *      until LSB of modulus is beyond LSB of remainder
     *   3. Divide 2 MSBytes of remainder by MSB of modulus to get quotient
     *   4. WHILE quotient is bigger than 0xFF (should be rare)
     *      Subtract modulus from remainder
     *      Subtract 0x100 from quotient
     *      Set trial divisor to 1 less than quotient
     *   5. IF trial divisor > 0
     *      Multiply modulus by trial divisor to make subproduct
     *      WHILE the subproduct is greater than the remainder
     *        Subtract the modulus from the subproduct
     *        Subtract that product from remainder
     *   6. WHILE remainder MSB is > 0 OR remainder[1] > modulus
     *         Subtract modulus from remainder[1]
     *         Move 1 byte to right in remainder
     *
     * Based on function from BBN Technologies' DHm, part of TinyPKI, by 
     * Jennifer Mulligan, 2003.
     */
    inline void b_mod(uint8_t * remp, uint8_t * modp, int16_t lth)
    {
        uint8_t *chremp,    /* ptr to current MSB of remainder */
                *rtp, *mtp, /* tmp pointers for comparing */
                *dtp,       /* ptr for dividing */
        tdiv[2];
        uint16_t tmp, quot;
        int16_t tlth;       /* counter for main loop */
        uint8_t j;
        uint8_t trials[16];
        uint8_t subprod[1 + 96];
 
        memset(trials, 0, 16);
        modp += NUMWORDS / 2;
        *trials = *modp >> 1;
        *(trials + 1) = *modp << 7;
                                        /* step 1 */
        while (b_compareto(remp, modp) > 0) b_sub(remp, modp, lth);
                                    /* step 2 */
        for (chremp = remp, tlth = lth; tlth--; chremp++)
        {
                                    /* step 3 */
            *tdiv = *chremp;
            *(tdiv + 1) = *(chremp + 1);
            
            for (j = 8, dtp = trials, quot = 0; j--; dtp += 2)
            {
                quot <<= 1;
                if (*tdiv > *dtp || (*tdiv == *dtp && 
                    *(tdiv + 1) >= *(dtp + 1)))
                {
                    b_sub(tdiv, dtp, 2);
                    quot++;
                }
            }
                                    /* step 4 */
            while (quot > 0xFF) quot = 0xFF;
            *tdiv = quot - ((quot)? 1: 0);
                                        /* step 5 */
            if (*tdiv)
            {
                memset(subprod, 0, lth + 1);
                for (mtp = &modp[lth - 1], rtp = &subprod[lth], j = lth; j--; 
                     mtp--)
                {
                    tmp = *mtp * *tdiv;
                    tmp += *rtp;
                    *rtp-- = tmp & 0xFF;
                    *rtp = (tmp >> 8);
                }
                while (b_compareto(subprod, chremp) > 0)
                {
                    b_sub(&subprod[1], modp, lth);
                }
                b_sub(chremp, subprod, lth + 1);
            }
                                        /* step 6 */
            while(*chremp || b_compareto(&chremp[1], modp) > 0)
                b_sub(&chremp[1], modp, lth);
        }
    }



    ////////////////////////////////////////////////////////////////////////
    // point
    // routines
    ////////////////////////////////////////////////////////////////////////

    /**
     * Clears point.
     */
    inline void p_clear(Point * P0)
    {
        // clear each ordinate
        b_clear(P0->x.val);
        b_clear(P0->y.val);
    }


    /**
     * Returns TRUE iff P0 == (0,0).
     */

    inline bool p_iszero(Point * P0)
    {
	    return (b_iszero(P0->x.val) && b_iszero(P0->y.val));
    }


    /**
     * P1 = P0.
     */

    inline void p_copy(Point * P0, Point * P1)
    {
        // copy point's ordinates
        b_copy(P0->x.val, P1->x.val);
        b_copy(P0->y.val, P1->y.val);
    }


    /**
     * Prints point.
     */

    inline void p_print(Point * P0)
    {
        dbg_clear(DBG_AM, "x:\n");
        b_halfprint(P0->x.val+NUMWORDS/2);
        dbg_clear(DBG_AM, "y:\n");
        b_halfprint(P0->y.val+NUMWORDS/2);
    }



    ////////////////////////////////////////////////////////////////////////
    // curve
    // routines
    ////////////////////////////////////////////////////////////////////////

    /**
     * Multiplies P0 by n, storing result in P1.  P1 cannot be P0.
     *
     * Based on Algorithm IV.1 on p. 63 of "Elliptic Curves in Cryptography"
     * by I. F. Blake, G. Seroussi, N. P. Smart.
     */

    inline void c_mul(uint8_t * n, Point * P0, Point * P1) 
    {
        // index variable
        index_t i;

        // clear point
        p_clear(P1);

        // perform multiplication
        for (i = b_bitlength(n) - 1; i >= 0; i--)
        {
            c_add(P1, P1, P1);
            if (b_testbit(n, i))
                c_add(P1, P0, P1);
        }
    }



    /**
     * Q = P1 + P2.  Algorithm 7 in An Overview of Elliptic Curve Cryptography, 
     * Lopez and Dahab.
     *
     * P1, P2, and Q are allowed to reference the same memory. 
     */

    inline void c_add(Point * P1, Point * P2, Point * Q)
    {
        uint8_t lambda[NUMWORDS], numerator[NUMWORDS];
        Point T;
    
        // 1.  if P1 = 0
        if (p_iszero(P1))
        {
            // Q <-- P2
            p_copy(P2, Q);
            return;
        }

        // 2.  if P2 = 0
        if (p_iszero(P2))
        {
            // Q <-- P1
            p_copy(P1, Q);
            return;
        }

        // 3.  if x1 = x2
        if (b_isequal(P1->x.val, P2->x.val))
        {
            // if y1 = y2
            if (b_isequal(P1->y.val, P2->y.val))
            {
                // lambda = x1 + y1/x1
                f_inv(P1->x.val, lambda);
                f_mul(lambda, P1->y.val, lambda);
                f_add(lambda, P1->x.val, lambda);

                // x3 = lambda^2 + lambda + a
                f_mul(lambda, lambda, T.x.val);
                f_add(T.x.val, lambda, T.x.val);
                f_add(T.x.val, params.E.a4.val, T.x.val);
            }
            else
            {
                // Q <-- 0
                b_clear(T.x.val);
                b_clear(T.y.val);
            }
        }
        else
        {
            // lambda <-- (y2 + y1)/(x2 + x1)
            f_add(P2->y.val, P1->y.val, numerator);
            f_add(P2->x.val, P1->x.val, lambda);
            f_inv(lambda, lambda);
            f_mul(numerator, lambda, lambda);

            // x3 <-- lambda^2 + lambda + x1 + x2 + a
            f_mul(lambda, lambda, T.x.val);
            f_add(T.x.val, lambda, T.x.val);
            f_add(T.x.val, P1->x.val, T.x.val);
            f_add(T.x.val, P2->x.val, T.x.val);
            f_add(T.x.val, params.E.a4.val, T.x.val);
        }

        // y3 <-- lambda(x1 + x2) + x3 + y1
        f_add(P1->x.val, T.x.val, T.y.val);
        f_mul(T.y.val, lambda, T.y.val);
        f_add(T.y.val, T.x.val, T.y.val);
        f_add(T.y.val, P1->y.val, T.y.val);

        // return
        p_copy(&T, Q);
    }


    ////////////////////////////////////////////////////////////////////////
    // field
    // routines
    ////////////////////////////////////////////////////////////////////////

    /**
     * c = a + b.
     *
     * a, b, and/or c are allowed to point to the same memory.
     */
    inline void f_add(uint8_t * a, uint8_t * b, uint8_t * c)
    {
        b_xor(a, b, c);
    }


    /**
     * c = ab mod f
     *
     * Algorithm 4 from High-Speed Software Multiplication in F_{2^m}.
     *
     * a, b, and/or c are allowed to point to the same memory.
     */
    inline void f_mul(uint8_t * a, uint8_t * b, uint8_t * c)
    {
        // local variables
        index_t i, j, k;
        uint8_t T[NUMWORDS];

        // perform multiplication
        for (i = 0; i < NUMWORDS; i++)
            *(T+i) = 0x00;
        for (j = 7; j >= 0; j--)
        {
            for (i = 0; i <= NUMWORDS/2-1; i++)
                if (b_testbit(a, i*8+j))
                    for (k = 0; k <= NUMWORDS/2-1; k++)
                        *(T+(NUMWORDS-1)-(k+i)) ^= *(b+(NUMWORDS-1)-k);
            if (j != 0) b_shiftleft1(T, T);
        }

        // modular reduction
        f_mod(T, c);

    }


    /**
     * b = a (mod modulus).
     *
     * a and b are allowed to point to the same memory. 
     * Hardcoded at present with default curve's parameters to save cycles.
     */
    void f_mod(uint8_t * a, uint8_t * b)
    {
        // local variables
        index_t blr, shf;
        int8_t comp;
        uint8_t r[NUMWORDS];

        // clear bint
        b_clear(r);

        // modular reduction
        comp = b_compareto(a, params.E.modulus);
        if (comp < 0)
        {
            b_copy(a, b);
            return;
        }
        else if (comp == 0)
        {
            b_copy(r, b);
            return;
        }
        b_copy(a, r);
        while ((blr = b_bitlength(r)) >= params.E.bitlength)
        {
            shf = blr - params.E.bitlength;
            *(r + NUMWORDS - ((163+shf) / 8) - 1) ^= (1 << ((163+shf) % 8));
            *(r + NUMWORDS - ((7+shf) / 8) - 1) ^= (1 << ((7+shf) % 8));
            *(r + NUMWORDS - ((6+shf) / 8) - 1) ^= (1 << ((6+shf) % 8));
            *(r + NUMWORDS - ((3+shf) / 8) - 1) ^= (1 << ((3+shf) % 8));
            *(r + NUMWORDS - ((0+shf) / 8) - 1) ^= (1 << ((0+shf) % 8));
        }
        b_copy(r, b);
    }


    /**
     * d = a^-1.
     *
     * Algorithm 8 in "Software Implementation of Elliptic Curve Cryptography
     * Over Binary Fields", D. Hankerson, J.L. Hernandez, A. Menezes.
     *
     * a and d are allowed to point to the same memory.
     */
    inline void f_inv(uint8_t * a, uint8_t * d)
    {
        // local variables
        index_t i;
        int8_t j;
        uint8_t * ptr;
        uint8_t anonymous[NUMWORDS*5];
        uint8_t * b = anonymous + NUMWORDS;
        uint8_t * c = b + NUMWORDS;
        uint8_t * u = c + NUMWORDS;
        uint8_t * v = u + NUMWORDS;

        // 1.  b <-- 1, c <-- 1, u <-- a, v <-- f
        for (i = 0; i < NUMWORDS; i++)
        {
            *(b+i) = 0x00;
            *(c+i) = 0x00;
            *(v+i) = *(params.E.modulus+i);
        }
        *(b+NUMWORDS-1) = 0x01;
        f_mod(a, u);

        // 2.  While deg(u) != 0
        while (b_bitlength(u) > 1)
        {
            // 2.1  j <-- deg(u) - deg(v).
            j = (b_bitlength(u) - 1) - (b_bitlength(v) - 1);

            // 2.2  If j < 0 then:
            if (j < 0)
            {
                // u <--> v
                ptr = u;
                u = v;
                v = ptr;

                // b <--> c
                ptr = b;
                b = c;
                c = ptr;

                // j <-- -j
                j = -j;
            }

            // 2.3  u <-- u + x^jv
            switch (j)
            {
                case 0:
                    f_add(u, v, u);
                    f_add(b, c, b);
                    break;
                case 1:
                    b_shiftleft1(v, anonymous);
                    f_add(u, anonymous, u);
                    b_shiftleft1(c, anonymous);
                    f_add(b, anonymous, b);
                    break;
                case 2:
                    b_shiftleft2(v, anonymous);
                    f_add(u, anonymous, u);
                    b_shiftleft2(c, anonymous);
                    f_add(b, anonymous, b);
                    break;
                default:
                    b_shiftleft(v, j, anonymous);
                    f_add(u, anonymous, u);
                    b_shiftleft(c, j, anonymous);
                    f_add(b, anonymous, b);
                    break;
            }
        }
        b_copy(b, d);
    }


    ////////////////////////////////////////////////////////////////////////
    // tasks
    ////////////////////////////////////////////////////////////////////////

    /**
     * Generate shared secret, using Alice's private key and Bob's public.
     */
    void task generate_secret()
    {
        // signal state
        dbg(DBG_AM, "Generating shared secret,\n");
        dbg(DBG_AM, "with my private key:\n");
        b_halfprint(privKeyA.s+NUMWORDS/2);
        dbg(DBG_AM, "and Bob's public key:\n");
        p_print(&pubKeyB.W);

        call SysTime.get(&before);
        c_mul(privKeyA.s, &pubKeyB.W, &secret);
        call SysTime.get(&after);
        dbg_msg->secKeyTime = after - before;
    
        // signal state
        dbg(DBG_AM, "Generated shared secret in %d usec.\n", after - before);

        // print results
        dbg(DBG_AM, "OUR SHARED SECRET:\n");
        p_print(&secret);

        // schedule timer for transmitting debugging message
        call DbgTimer.start(TIMER_ONE_SHOT, 6144);
    }


    /**
     * Generates Alice's private key.
     */
    void task generate_privKeyA()
    {
        // index variable
        index_t i;

        // signal state
        dbg(DBG_AM, "Generating private key...\n");

        // privKeyA.s = random number in [0, 2^p);
        call SysTime.get(&before);
        for (i = NUMWORDS/2; i < NUMWORDS; i++)
            privKeyA.s[i] = (word_t) call Random.rand();

        // privKeyA.s = privKeyA.s (mod params.r)
        b_mod(privKeyA.s, params.r, NUMWORDS/2);
        call SysTime.get(&after);

        // log running time
        dbg_msg->privKeyTime = after - before;

        // signal state
        dbg(DBG_AM, "Generated private key.\n");

        // print key
        dbg(DBG_AM, "privKeyA.s:\n");
        b_halfprint(privKeyA.s+NUMWORDS/2);
    }


    /**
     * Generates Alice's public key.
     */
    void task generate_pubKey()
    {
        // signal state
        dbg(DBG_AM, "Generating public key...\n");

        // W = privKeyA.s * params.G; operation is timed
        call SysTime.get(&before);
        call Leds.yellowOn();
        c_mul(privKeyA.s, &params.G, &pubKeyA.W);
        call Leds.yellowOff();
        call SysTime.get(&after);
        havePubKeyA = TRUE;

        // signal state
        dbg(DBG_AM, "Generated public key in %d usec.\n", after - before);

        // print results
        dbg(DBG_AM, "My public key:\n");
        p_print(&pubKeyA.W);

        // log running time
        dbg_msg->pubKeyTime = after - before;

        // schedule timer for sending keys to Bob
        call SendTimer.start(TIMER_ONE_SHOT, 3072);

        // generate secret if we have everything
        atomic 
        {
            if (haveXB && haveYB && havePubKeyA)
                post generate_secret();
        }
    }


    ////////////////////////////////////////////////////////////////////////
    // StdControl
    ////////////////////////////////////////////////////////////////////////

    /**
     * Initialize module.
     */
    command result_t StdControl.init()
    {
        // overall result
        result_t result = SUCCESS;

        // initialize LEDs
        result = rcombine(call Leds.init(), result);

        // initialize PRNG
        result = rcombine(call Random.init(), result);

        // initialize clock
        result = rcombine(call SysTime.init(), result);

        // retain pointer to debugging payload
        dbg_msg = (DbgMsg *) dbg_envelope.data;

        // retain pointer to key payload
        key_msg = (KeyMsg *) key_envelope.data;

        // return result
        return result;
    }


    /**
     * Start module.
     */
    command result_t StdControl.start()
    {
        // signal state
        dbg(DBG_AM, "Started up.\n");

        // initialize storage for keys
        p_clear(&pubKeyA.W);
        p_clear(&pubKeyB.W);
        b_clear(privKeyA.s);

        // initialize storage for secret
        p_clear(&secret);
    
        // initialize modulus
        params.p = 163;
        params.pentanomial_k3 = 7;
        params.pentanomial_k2 = 6;
        params.pentanomial_k1 = 3;
        b_clear(params.E.modulus);
        b_setbit(params.E.modulus, 163);
        b_setbit(params.E.modulus, 7);
        b_setbit(params.E.modulus, 6);
        b_setbit(params.E.modulus, 3);
        b_setbit(params.E.modulus, 0);
        params.E.bitlength = 164;

        // initialize curve
        b_clear(params.E.a4.val);
        params.E.a4.val[NUMWORDS - 1] = (word_t) 0x01;
        b_clear(params.E.a6.val);
        params.E.a6.val[NUMWORDS - 1] = (word_t) 0x01;

        // initialize r
        params.r[NUMWORDS - 21] = (word_t) 0x04;
        params.r[NUMWORDS - 20] = (word_t) 0x00;
        params.r[NUMWORDS - 19] = (word_t) 0x00;
        params.r[NUMWORDS - 18] = (word_t) 0x00;
        params.r[NUMWORDS - 17] = (word_t) 0x00;
        params.r[NUMWORDS - 16] = (word_t) 0x00;
        params.r[NUMWORDS - 15] = (word_t) 0x00;
        params.r[NUMWORDS - 14] = (word_t) 0x00;
        params.r[NUMWORDS - 13] = (word_t) 0x00;
        params.r[NUMWORDS - 12] = (word_t) 0x00;
        params.r[NUMWORDS - 11] = (word_t) 0x02;
        params.r[NUMWORDS - 10] = (word_t) 0x01;
        params.r[NUMWORDS - 9] = (word_t) 0x08;
        params.r[NUMWORDS - 8] = (word_t) 0xa2;
        params.r[NUMWORDS - 7] = (word_t) 0xe0;
        params.r[NUMWORDS - 6] = (word_t) 0xcc;
        params.r[NUMWORDS - 5] = (word_t) 0x0d;
        params.r[NUMWORDS - 4] = (word_t) 0x99;
        params.r[NUMWORDS - 3] = (word_t) 0xf8;
        params.r[NUMWORDS - 2] = (word_t) 0xa5;
        params.r[NUMWORDS - 1] = (word_t) 0xef;   

        // initialize Gx
        params.G.x.val[NUMWORDS - 21] = (word_t) 0x02;
        params.G.x.val[NUMWORDS - 20] = (word_t) 0xfe;
        params.G.x.val[NUMWORDS - 19] = (word_t) 0x13;
        params.G.x.val[NUMWORDS - 18] = (word_t) 0xc0;
        params.G.x.val[NUMWORDS - 17] = (word_t) 0x53;
        params.G.x.val[NUMWORDS - 16] = (word_t) 0x7b;
        params.G.x.val[NUMWORDS - 15] = (word_t) 0xbc;
        params.G.x.val[NUMWORDS - 14] = (word_t) 0x11;
        params.G.x.val[NUMWORDS - 13] = (word_t) 0xac;
        params.G.x.val[NUMWORDS - 12] = (word_t) 0xaa;
        params.G.x.val[NUMWORDS - 11] = (word_t) 0x07;
        params.G.x.val[NUMWORDS - 10] = (word_t) 0xd7;
        params.G.x.val[NUMWORDS - 9] = (word_t) 0x93;
        params.G.x.val[NUMWORDS - 8] = (word_t) 0xde;
        params.G.x.val[NUMWORDS - 7] = (word_t) 0x4e;
        params.G.x.val[NUMWORDS - 6] = (word_t) 0x6d;
        params.G.x.val[NUMWORDS - 5] = (word_t) 0x5e;
        params.G.x.val[NUMWORDS - 4] = (word_t) 0x5c;
        params.G.x.val[NUMWORDS - 3] = (word_t) 0x94;
        params.G.x.val[NUMWORDS - 2] = (word_t) 0xee;
        params.G.x.val[NUMWORDS - 1] = (word_t) 0xe8;

        // initialize Gy
        params.G.y.val[NUMWORDS - 21] = (word_t) 0x02;
        params.G.y.val[NUMWORDS - 20] = (word_t) 0x89;
        params.G.y.val[NUMWORDS - 19] = (word_t) 0x07;
        params.G.y.val[NUMWORDS - 18] = (word_t) 0x0f;
        params.G.y.val[NUMWORDS - 17] = (word_t) 0xb0;
        params.G.y.val[NUMWORDS - 16] = (word_t) 0x5d;
        params.G.y.val[NUMWORDS - 15] = (word_t) 0x38;
        params.G.y.val[NUMWORDS - 14] = (word_t) 0xff;
        params.G.y.val[NUMWORDS - 13] = (word_t) 0x58;
        params.G.y.val[NUMWORDS - 12] = (word_t) 0x32;
        params.G.y.val[NUMWORDS - 11] = (word_t) 0x1f;
        params.G.y.val[NUMWORDS - 10] = (word_t) 0x2e;
        params.G.y.val[NUMWORDS - 9] = (word_t) 0x80;
        params.G.y.val[NUMWORDS - 8] = (word_t) 0x05;
        params.G.y.val[NUMWORDS - 7] = (word_t) 0x36;
        params.G.y.val[NUMWORDS - 6] = (word_t) 0xd5;
        params.G.y.val[NUMWORDS - 5] = (word_t) 0x38;
        params.G.y.val[NUMWORDS - 4] = (word_t) 0xcc;
        params.G.y.val[NUMWORDS - 3] = (word_t) 0xda;
        params.G.y.val[NUMWORDS - 2] = (word_t) 0xa3;
        params.G.y.val[NUMWORDS - 1] = (word_t) 0xd9;

        // initialize k
        b_clear(params.k);
        params.k[NUMWORDS - 1] = (word_t) 0x02;

        // schedule timer for generating keys
        call GenTimer.start(TIMER_ONE_SHOT, 3072);

        // return
        return SUCCESS;
    }


    /**
     * Stop module.
     */
    command result_t StdControl.stop()
    {
        return SUCCESS;
    }


    /////////////////////////////////////////////////////////////////////////
    // ReceiveMsg
    /////////////////////////////////////////////////////////////////////////

    /**
     * Event handler for receiving Bob's public key.
     *
     * @param m received message
     *
     * @return pointer to buffer to be used for next message received
     */
    event TOS_MsgPtr ReceiveMsg.receive(TOS_MsgPtr m)
    {
        if (((KeyMsg *) m->data)->isX)
        {
            // signal state
            dbg(DBG_AM, "Received x coordinate of Bob's public key.\n");

            memcpy(pubKeyB.W.x.val+NUMWORDS/2, ((KeyMsg *) m->data)->coord, NUMWORDS/2);
            haveXB = TRUE;

            // signal state
            dbg(DBG_AM, "x coordinate received from Bob:\n");
            b_halfprint(pubKeyB.W.x.val+NUMWORDS/2);
        }
        else
        {
            // signal state
            dbg(DBG_AM, "Received y coordinate of Bob's public key.\n");

            memcpy(pubKeyB.W.y.val+NUMWORDS/2, ((KeyMsg *) m->data)->coord, NUMWORDS/2);
            haveYB = TRUE;    

            // signal state
            dbg(DBG_AM, "y coordinate received from Bob:\n");
            b_halfprint(pubKeyB.W.y.val+NUMWORDS/2);
        }

        atomic
        {
            if (haveXB && haveYB && havePubKeyA)
                post generate_secret();
        }

        return m;
    }


    /////////////////////////////////////////////////////////////////////////
    // SendMsg
    /////////////////////////////////////////////////////////////////////////

    /**
     * Event handler called when debugging message has been sent to UART.
     *
     * @param msg       sent message
     * @param success   flag indicating whether send was successful
     */
    event result_t SendDbgMsg.sendDone(TOS_MsgPtr msg, result_t success)
    {
        // re-initialize storage 
        havePubKeyA = FALSE;
        haveXB = FALSE;
        haveYB = FALSE;
        p_clear(&pubKeyA.W);
        p_clear(&pubKeyB.W);
        b_clear(privKeyA.s);
        p_clear(&secret);
    
        // schedule timer for generating keys
        call GenTimer.start(TIMER_ONE_SHOT, 3072);

        // return result
        return success;
    }


    /**
     * Event handler called when state message has been sent to UART.
     *
     * @param msg       sent message
     * @param success   flag indicating whether send was successful
     */
    event result_t SendKeyMsg.sendDone(TOS_MsgPtr msg, result_t success)
    {
        if (key_msg->isX)
        {
            // signal state
            dbg(DBG_AM, "Sent x coordinate of public key.\n");

            // signal state
            dbg(DBG_AM, "Sending y coordinate of public key...\n");

            key_msg->isX = FALSE;
            memcpy(key_msg->coord, pubKeyA.W.y.val + NUMWORDS/2, NUMWORDS/2);
            call SendKeyMsg.send(TOS_BCAST_ADDR,
                                 sizeof(KeyMsg), &key_envelope);
        }
        else
        {
            // signal state
            dbg(DBG_AM, "Sent y coordinate of public key.\n");
        }

        // return result
        return success;
    }



    /////////////////////////////////////////////////////////////////////////
    // Timer
    /////////////////////////////////////////////////////////////////////////

    /**
     * Event handler for debugging timer.
     *
     * @return result
     */
    event result_t DbgTimer.fired()
    {
        // overall result
        result_t result = SUCCESS;

        // send!
        dbg(DBG_AM, "Logging running times to UART...\n");
        dbg(DBG_AM, "privKeyTime: %d\n", dbg_msg->privKeyTime);
        dbg(DBG_AM, "pubKeyTime: %d\n", dbg_msg->pubKeyTime);
        dbg(DBG_AM, "secKeyTime: %d\n", dbg_msg->secKeyTime);
        call SendDbgMsg.send(TOS_UART_ADDR,
                             sizeof(DbgMsg), &dbg_envelope);

        // start things over

        // return overall result
        return result;
    }


    /**
     * Event handler for key-generating timer.
     *
     * @return result
     */
    event result_t GenTimer.fired()
    {
        // generate private and public keys
        post generate_privKeyA();
        post generate_pubKey();

        // overall result
        return SUCCESS;
    }


    /**
     * Event handler for key-sending timer.
     *
     * @return result
     */
    event result_t SendTimer.fired()
    {
        // signal state
        dbg(DBG_AM, "Sending x coordinate of public key...\n");

        key_msg->isX = TRUE;
        memcpy(key_msg->coord, pubKeyA.W.x.val + NUMWORDS/2, NUMWORDS/2);
        b_halfprint(key_msg->coord);
        call SendKeyMsg.send(TOS_BCAST_ADDR,
                             sizeof(KeyMsg), &key_envelope);

        // overall result
        return SUCCESS;
    }
}


/* EOF */
