/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:             Philip Levis
 *
 */

/*
 *   FILE: heap.h
 * AUTHOR: Philip Levis <pal@cs.berkeley.edu>
 *   DESC: Simple priority heap for discrete event simulation.
 */

#include "heap.h"
#include <string.h> // For memcpy(3)
#include <stdlib.h> // for rand(3)
#include <stdio.h>  // For printf(3)

typedef struct node {
  struct node* parent;
  struct node* left;
  struct node* right;
  void* data;
  long long key;
} node_t;

void down_heap(node_t* node);
void up_heap(node_t* node);
void swap(node_t* first, node_t* second);
node_t* prev(node_t* node);
node_t* next(node_t* next);
int is_root(node_t* node);

void init_node(node_t* node) {
  node->parent = NULL;
  node->left = NULL;
  node->right = NULL;
  node->data = NULL;
  node->key = -1;
}

int is_right_child(node_t* node) {
  return (!is_root(node) && (node == (node->parent->right)));
}

int is_left_child(node_t* node) {
  return (!is_root(node) && (node == (node->parent->left)));
}

int is_root(node_t* node) {
  return node->parent == NULL;
}

int is_leaf(node_t* node) {
  return (node->left == NULL && node->right == NULL);
}

void init_heap(heap_t* heap) {
  heap->top = NULL;
  heap->free = NULL;
  heap->last = NULL;
  heap->size = 0;
}

int heap_size(heap_t* heap) {
  return heap->size;
}

int is_empty(heap_t* heap) {
  return heap->size == 0;
}

int heap_is_empty(heap_t* heap) {
  return is_empty(heap);
}

long long heap_get_min_key(heap_t* heap) {
  node_t* root = (node_t*)heap->top;
  return root->key;
}

void* heap_peek_min_data(heap_t* heap) {
  node_t* root = (node_t*)heap->top;
  return root->data;
}

void heap_remove_last_element(heap_t* heap) {
  node_t* last = (node_t*)heap->last;
  heap->last = prev(last);
  
  if (!is_root(last)) {
    if (last == last->parent->left) {last->parent->left = NULL;}
    if (last == last->parent->right) {last->parent->right = NULL;}
  }
  
  last->parent = heap->free;
  heap->free = last;
}

void* heap_pop_min_data(heap_t* heap, long long* key) {
  node_t* top;
  node_t* last;
  void* data;
  long long keyval;
  
  if (is_empty(heap)) {return NULL;}

  top = (node_t*)heap->top;
  last = (node_t*)heap->last;
  
  data = top->data;
  keyval = top->key;
  
  swap(top, last);
  heap_remove_last_element(heap);

  if (heap->top != NULL) {
    down_heap(heap->top);
    heap->size--;
  }
  else {
    heap->size = 0;
  }

  if (key != NULL) {*key = keyval;}
  return data;
}

void heap_insert(heap_t* heap, void* data, long long key) {
  node_t* next_node;
  node_t* new_node;
  
  if (heap->free == NULL) {
    heap->free = (void*) malloc(sizeof(node_t));
    init_node((node_t*)heap->free);
  }

  new_node = (node_t*)heap->free;
  heap->free = new_node->parent;

  init_node(new_node);
  new_node->key = key;
  new_node->data = data;
  
  if (is_empty(heap)) {
    heap->top = new_node;
    heap->last = new_node;
    new_node->parent = NULL;
    heap->size++;
    return;
  }
  
  next_node = next(heap->last);
  if (next_node->left == NULL) {
    next_node->left = new_node;
    new_node->parent = next_node;
  }
  else {
    next_node->right = new_node;
    new_node->parent = next_node;
  }

  up_heap(new_node);

  heap->last = new_node;
  
  heap->size++;
}

node_t* next(node_t* node) {
  node_t* next_node = node;

  if (!is_root(node)) {
    if (node->parent->right == NULL) {
      return node->parent;
    }

    while (is_right_child(next_node)) {
      next_node = next_node->parent;
    }
  }

  if (!is_root(next_node)) {
    next_node = next_node->parent->right;
  }
  
  while (!is_leaf(next_node)) {
    next_node = next_node->left;
  }
  return next_node;
}

node_t* prev(node_t* node) {
  node_t* next_node = node;
  
  if (!is_root(node)) {
    while (is_left_child(next_node)) {
      next_node = next_node->parent;
    }
  }

  if (!is_root(next_node)) {
    next_node = next_node->parent->left;
  }

  while (next_node->right != NULL) {
    next_node = next_node->right;
  }
  return next_node;
}

void swap(node_t* first, node_t* second) {
  node_t temp;
  temp.key = first->key;
  temp.data = first->data;

  first->key = second->key;
  first->data = second->data;
  second->key = temp.key;
  second->data = temp.data;
}

void down_heap(node_t* node) {
  long long key = node->key;
  node_t* left = node->left;
  node_t* right = node->right;
  node_t* min = NULL;

  // No children. Stop downheaping.
  if (is_leaf(node)) {return;}
  // Only a left child. It must be the min
  else if (right == NULL) {min = left;}

  else {
    long long left_key = left->key;
    long long right_key = right->key;
    min = (left_key < right_key)? left : right;
  }

  if (key > min->key) {
    swap(node, min);
    down_heap(min);
  }
  
}

void up_heap(node_t* node) {
  node_t* parent = node->parent;

  if (is_root(node)) {return;}

  if (parent->key > node->key) {
    swap(node, parent);
    up_heap(parent);
  }
}
