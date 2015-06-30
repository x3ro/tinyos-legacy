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

/* Author:  Robert Szewczyk
 *
 * $Id: pqueue_test.c,v 1.2 2003/10/07 21:45:34 idgay Exp $
 */


#include <stdlib.h>
#include <stdio.h>
typedef unsigned char uint8_t ;
#define FAIL 0
#define SUCCESS 1
typedef int result_t ;
#include "pqueue.h"

char compare(int i, int j) {
    if (i>j)
	return 1;
    else if (j == i)
	return 0;
    else 
	return -1;
}




int main(int argc, char ** argv) {
    int nElements, i, q, j;
    struct {
	char (*compare) (pq_element, pq_element);
	uint8_t size;
	uint8_t n_elements;
	pq_element heap[10];
    } pqt;
    
    nElements = argc -1;
    pqueue_init(&pqt, 10, compare);
    for (j=0; j < 10; j++) {
	pqt.heap[j] = -1;
    }
    for (i=0; i < nElements; i++) {
	q = atoi(argv[i+1]);
	printf("%d %d\n", q, pqueue_enqueue(&pqt, q));
	for (j=0; j < 10; j++) {
	    printf("%d ", pqt.heap[j]);
	}
	printf("\n");
    }
    for (i=0; i < nElements; i++) {
    printf("%d\n", pqueue_dequeue(&pqt));
    }
    for (j=0; j < 10; j++) {
	printf("%d ", pqt.heap[j]);
    }
    printf("\n");
}
