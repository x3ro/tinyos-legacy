/*
 * @(#)pqueue.h
 *
 * "Copyright (c) 2003 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
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
 * Author:  Robert Szewczyk
 *
 * $Id: pqueue.h,v 1.1.1.2 2004/03/06 03:00:40 mturon Exp $
 */

#ifndef _PQUEUE_H
#define _PQUEUE_H 1

typedef int8_t  pq_element;

typedef struct {
    char (*compare) (pq_element, pq_element);
    uint8_t size;
    uint8_t n_elements;
    pq_element heap[0];
} pqueue_t;

void pqueue_init (pqueue_t * pq, uint8_t size, char (*compare) (pq_element, pq_element)) {
    pq->size = size;
    pq->n_elements = 0;
    pq->compare = compare;
}

result_t pqueue_enqueue(pqueue_t *pq, pq_element e) {
    int8_t ind, parent;
    if (pq->size <= pq->n_elements)
	return FAIL;
    ind = pq->n_elements++;
    parent = (ind -1) >> 1;
    while ((ind > 0) && 
	   (pq->compare(e, pq->heap[parent]) < 0)){
	pq->heap[ind] = pq->heap[parent];
	ind =parent;
	parent = (ind - 1) >> 1;
    }
    pq->heap[ind] = e;
    return SUCCESS;
}

pq_element pqueue_dequeue_idx(pqueue_t *pq, int8_t i) {
    pq_element ret,tmp;
    int8_t left_child;
    if (pq->n_elements == 0) {
	return -1;
    }
    ret = pq->heap[0];
    pq->n_elements--;
    tmp = pq->heap[pq->n_elements];
    while (i < (pq->n_elements>>1)) {
	left_child = (i << 1) + 1;
	
	if ((left_child < (pq->n_elements-1)) && 
	    (pq->compare(pq->heap[left_child], pq->heap[left_child+1]) > 0)) {
	    left_child++;
	}
	if (pq->compare(pq->heap[left_child], tmp) >= 0) 
	    break;
	pq->heap[i] = pq->heap[left_child];
	i = left_child;
    }
    pq->heap[i] = tmp;
    return ret;
}

pq_element pqueue_dequeue(pqueue_t *pq) {
    return pqueue_dequeue_idx(pq, 0);
}

pq_element pqueue_remove(pqueue_t * pq, pq_element e) {
    int8_t i;
    for (i = 0; i < pq->size; i++) {
	if (pq->heap[i] == e) {
	    return pqueue_dequeue_idx(pq, i);
	}
    }
    return -1;
}

pq_element pqueue_peek(pqueue_t *pq) {
    if (pq->n_elements == 0) {
	return -1;
    }
    return pq->heap[0];
}
#endif /* _PQUEUE_H */

