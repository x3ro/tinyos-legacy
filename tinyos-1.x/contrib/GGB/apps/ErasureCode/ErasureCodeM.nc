// $Id: ErasureCodeM.nc,v 1.3 2006/11/30 23:59:21 binetude Exp $

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
/*
 *
 * Authors:		Sukun Kim
 * Date last modified:  11/30/06
 *
 */

/**
 * @author Sukun Kim
 */

module ErasureCodeM {
	provides {
		interface StdControl;
		interface ErasureCode;
	}
}
implementation {
	uint8_t gf_exp[TwoPowerQ];
	uint8_t gf_log[TwoPowerQ];

	uint8_t M, P;
	uint8_t A[MaxM * MaxM];
	uint8_t *D;
	uint8_t *CN;


	inline uint8_t left(uint8_t vector);
	inline uint8_t right(uint8_t vector);
	inline uint8_t combine(uint8_t left_scalar, uint8_t right_scalar);
	uint8_t mul(uint8_t left_arg, uint8_t right_arg);
	uint8_t mul2(uint8_t scalar_arg, uint8_t vector_arg);
	void computeGF();

	uint8_t pick_row(uint8_t k);
	void row_exchange(uint8_t k, uint8_t l);
	void normalize(uint8_t k);
	void subtract(uint8_t k);
	void dumpA() {
		uint8_t i, j;
		dbg(DBG_USR2, "A\n");
		for (i = 0; i < M; i++) {
			for (j = 0; j < M; j++) {
				dbg(DBG_USR2, "%d\t", A[i * M + j]);
			}
			dbg(DBG_USR2, "\n");
		}
		dbg(DBG_USR2, "\n");
	}
	command result_t StdControl.init() {
		computeGF();
		return SUCCESS;
	}
	command result_t StdControl.start() {
		return SUCCESS;
	}
	command result_t StdControl.stop() {
		return SUCCESS;
	}


	command result_t ErasureCode.setMsg(uint8_t numofMsg, uint8_t sizeofPkt,
		uint8_t *msg) {
		M = numofMsg; P = sizeofPkt; D = msg;
		return SUCCESS;
	}
	command result_t ErasureCode.encode() { return SUCCESS; }
	command result_t ErasureCode.getCode(uint8_t *code, uint8_t codeNum) {
		uint8_t j, k;
		uint8_t gen;
		if (codeNum >= MaxN) return FAIL;

		if (codeNum < M) {
			for (k = 0; k < P; k++)
				code[k] = D[codeNum * P + k];
		} else {
			for (k = 0; k < P; k++)
				code[k] = 0;

			gen = codeNum + 1;
			for (j = 0; j < M; j++) {
				for (k = 0; k < P; k++) {
					if (Q == 4) {
						code[k] ^= mul2(gen, D[j * P + k]);
					} else if (Q == 8) {
						code[k] ^= mul(gen, D[j * P + k]);
					}
				}
				gen = mul(gen, codeNum + 1);
			}
		}
		return SUCCESS;
	}

	command result_t ErasureCode.setCode(uint8_t numofMsg, uint8_t sizeofPkt,
		uint8_t *code, uint8_t *codeNum) {
		M = numofMsg; P = sizeofPkt; D = code; CN = codeNum;
		return SUCCESS;
	}
	command result_t ErasureCode.decode() {
		uint8_t i, j;
		uint8_t gen;
		for (i = 0; i < M; i++) {
			if (CN[i] < M) {
				for (j = 0; j < M; j++) {
					A[i * M + j] = 0;
				}
				A[i * M + CN[i]] = 1;
			} else {
				gen = CN[i] + 1;
				for (j = 0; j < M; j++) {
					A[i * M + j] = gen;
					gen = mul(gen, CN[i] + 1);
				}
			}
		}
		//dumpA();
		for (i = 0; i < M; i++) {
			j = pick_row(i);
			if (j == M) return FAIL;
			row_exchange(i, j);
			normalize(i);
			subtract(i);
			//dumpA();
		}
		return SUCCESS;
	}
	command result_t ErasureCode.getMsg(uint8_t *msg, uint8_t msgNum) {
		int k;
		if (msgNum >= M) return FAIL;

		for (k = 0; k < P; k++)
			msg[k] = D[msgNum * P + k];
		return SUCCESS;
	}


	inline uint8_t left(uint8_t vector) {
		return (vector & 0xf0) >> 4; }
	inline uint8_t right(uint8_t vector) {
		return vector & 0x0f; }
	inline uint8_t combine(uint8_t left_scalar, uint8_t right_scalar) {
		return left_scalar << 4 | right_scalar; }
	uint8_t mul(uint8_t left_arg, uint8_t right_arg) {
		if ((left_arg == 0) || (right_arg == 0)) return 0;
		else return gf_exp[(gf_log[left_arg] + gf_log[right_arg])
			% (TwoPowerQ - 1)];
	}
	uint8_t mul2(uint8_t scalar_arg, uint8_t vector_arg) {
			return combine(
					mul(scalar_arg, left(vector_arg)),
					mul(scalar_arg, right(vector_arg)));
	}
	void computeGF() {
		uint8_t k;
		uint8_t mask;
		mask = 1;
		gf_exp[Q] = 0;
		for (k = 0; k < Q; k++) {
			gf_exp[k] = mask;
			gf_log[gf_exp[k]] = k;
			if (PrimePoly & mask)
				gf_exp[Q] ^= mask;
			mask <<= 1;
		}
		gf_log[gf_exp[Q]] = Q;

		mask = 1;
		for (k = 0; k < Q - 1; k++)
			mask <<= 1;
		for (k = Q + 1; k < TwoPowerQ - 1; k++) {
			if (gf_exp[k - 1] >= mask)
				gf_exp[k] = gf_exp[Q] ^ ((gf_exp[k - 1] ^ mask) << 1);
			else
				gf_exp[k] = gf_exp[k - 1] << 1;
			gf_log[gf_exp[k]] = k;
		}
		gf_log[0] = TwoPowerQ - 1;
		gf_exp[TwoPowerQ - 1] = 0;
	}

	uint8_t pick_row(uint8_t k) {
		uint8_t i;
		for (i = k; i < M; i++)
			if (A[i * M + k]) break;
		//if (i == M) dbg(DBG_USR2, "### Singular Matrix\n");
		return i;
	}
	void row_exchange(uint8_t k, uint8_t l) {
		uint8_t j;
		uint8_t temp;
		if (k == l) return;

		for (j = 0; j < M; j++) {
			temp = A[k*M+j]; A[k*M+j] = A[l*M+j]; A[l*M+j] = temp;
		}
		for (j = 0; j < P; j++) {
			temp = D[k*P+j]; D[k*P+j] = D[l*P+j]; D[l*P+j] = temp;
		}
	}
	void normalize(uint8_t k) {
		uint8_t j;
		uint8_t pivot;
		if (A[k * M + k] == 1) return;

		pivot = gf_exp[TwoPowerQ - 1 - gf_log[A[k * M + k]]];
		for (j = k; j < M; j++) {
			A[k * M + j] = mul(pivot, A[k * M + j]);
		}
		for (j = 0; j < P; j++) {
			if (Q == 4) {
				D[k * P + j] = mul2(pivot, D[k * P + j]);
			} else if (Q == 8) {
				D[k * P + j] = mul(pivot, D[k * P + j]);
			}
		}
	}
	void subtract(uint8_t k) {
		uint8_t i, j;
		uint8_t factor;
		for (i = 0; i < M; i++) {
			if ((i == k) || (A[i * M + k] == 0)) continue;

			factor = A[i * M + k];
			for (j = k; j < M; j++) {
				A[i * M + j] ^= mul(factor, A[k * M + j]);
			}
			for (j = 0; j < P; j++) {
				if (Q == 4) {
					D[i * P + j] ^= mul2(factor, D[k * P + j]);
				} else if (Q == 8) {
					D[i * P + j] ^= mul(factor, D[k * P + j]);
				}
			}
		}
	}
}

