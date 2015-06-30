/*
 * Copyright (C) 2002-2003 Dennis Haney <davh@diku.dk>
 * Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
#ifndef BT_CACHE_H
#define BT_CACHE_H

//#include "bt.h"

static inline
void cache_init(struct cache_entry*c, int clk, int clk_frozen,
                enum fhsequence_t seq, int addr, enum tdd_state_t tdd,
                int nsr, int nmr, enum train_t trainType, int nfhs, int freq) {
     c->clk_ = clk;
     c->clk_frozen_ = clk_frozen;
     c->seq_ = seq;
     c->addr_ = addr;
     c->tdd_state_ = tdd;
     c->nsr_ = nsr;
     c->nmr_ = nmr;
     c->train_type_ = trainType;
     c->nfhs_ = nfhs;
     c->freq_ = freq;
}

static inline
freq_t cache_equaln(struct cache_entry*c, int clk, int clk_frozen, int addr,
                   enum tdd_state_t tdd, int nsr, int nmr,
                   enum train_t trainType, int nfhs) {
     if(c->clk_ == clk &&
        c->clk_frozen_ == clk_frozen &&
        c->addr_ == addr &&
        c->tdd_state_ == tdd &&
        c->nsr_ == nsr &&
        c->nmr_ == nmr &&
        c->train_type_ == trainType &&
        c->nfhs_ == nfhs)
          return c->freq_;
     return InvalidFreq;
}

static inline
freq_t cache_equal3(struct cache_entry*c, int clk, int addr) {
     if(c->clk_ == clk && c->addr_ == addr)
          return c->freq_;
     return InvalidFreq;
}

static inline
freq_t cache_equal4(struct cache_entry*c, int clk, int addr,
                    enum train_t train) {
     if(c->clk_ == clk &&
        c->addr_ == addr &&
        c->train_type_ == train)
          return c->freq_;
     return InvalidFreq;
}

static inline
int subBits(int bits, int start, int len, int left_shift) {
     assert((start + len) <= 32 && left_shift <= 32);
     return (((bits >> start)) & ((1 << len) - 1)) << left_shift;
}

// The INDEXed frequency is remapped to a register with even freqs listed before odd freqs. 
static inline
int mappedFreq(int ind) {
     if (ind < 40) {
          return ind * 2;
     }
     else {
          return ((ind - 39) * 2) - 1;
     }
}

static inline
int ADD_mod32(int ip1, int ip2) {
     return ((((((ip1 & 0x1f) + (ip2 & 0x1f))) % 32)) & 0x1f);
}

// IP2: E, IP3: F, IP4: Y2
static inline
int ADD_mod79(int ip1, int ip2, int ip3, int ip4) {
     //	return ((((((ip1 & 0x1f) + (ip2 & 0x7f) +
     //    (ip3 & 0x7f) + (ip4 & 0x7f))) % 79)) & 0x7f);
     return modulo((ip1 & 0x1f) + (ip2 & 0x7f) + (ip3 & 0x7f) + (ip4 & 0x3f), 79) & 0x7f;
}

static inline
int EXOR_5(int ip1, int ip2) {
     assert(ip1 >= 0  && ip2 >= 0);
     return (ip1 ^ ip2) & 0x1f;
}

static inline
int EXOR_9(int ip1, int ip2) {
     assert(ip1 >= 0  && ip2 >= 0);
     //uint ip1_c= ~ip1;
     //uint ip2_c= ~ip2;
     //return (((ip1 & ip2_c) | (ip1_c & ip2)) & 0x01ff);
     return (ip1 ^ ip2) & 0x01ff;
}

// If CTRL bit is on swap IP1 and IP2
static inline
void BFLY(int ctrl, int* ip1, int* ip2) {
     if ((ctrl & 0x01) == 1) {
          int temp = *ip1;
          *ip1 = *ip2;
          *ip2 = temp;
     }
     return;
}

// ip3 = D,
static inline
int PERM(int ip1, int ip2, int ip3) {
     int z[5], p[14], op;
     int i;

     assert(ip1 >= 0  && ip2 >= 0 && ip3 >= 0);

     for (i= 0; i < 5; i++)
          z[i] = (ip1 >> i) & 0x1;

     for (i= 0; i < 14; i++) {
          if (i < 9)
               p[i] = ((ip3 >> i) & 0x1);
          else
               p[i] = (ip2 >> (i-9)) & 0x1;
     }

     BFLY(p[13], &z[1], &z[2]);
     BFLY(p[12], &z[0], &z[3]);

     BFLY(p[11], &z[1], &z[3]);
     BFLY(p[10], &z[2], &z[4]);

     BFLY(p[9], &z[0], &z[3]);
     BFLY(p[8], &z[1], &z[4]);

     BFLY(p[7], &z[3], &z[4]);
     BFLY(p[6], &z[0], &z[2]);

     BFLY(p[5], &z[1], &z[3]);
     BFLY(p[4], &z[0], &z[4]);

     BFLY(p[3], &z[3], &z[4]);
     BFLY(p[2], &z[1], &z[2]);

     BFLY(p[1], &z[2], &z[3]);
     BFLY(p[0], &z[0], &z[1]);

     op = z[0];
     op = op + ((z[1] << 1) & 0x02);
     op = op + ((z[2] << 2) & 0x04);
     op = op + ((z[3] << 3) & 0x08);
     op = op + ((z[4] << 4) & 0x10);

     return (op);
}


#endif
