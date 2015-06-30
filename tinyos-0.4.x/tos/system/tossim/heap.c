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
