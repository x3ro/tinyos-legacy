/**
 *  @file Heap.cc
 *
 *  @author Ion Yannopoulos
 */

#include <tossim/util/private.hh>
#include <tossim/util/Heap.hh>

namespace tos {
namespace sim {
namespace util {

namespace impl {

const _HeapBase::Key INVALID_KEY = -1;

// ---------------------------------------------------------------------
// _TreeHeap::_Node

inline
_TreeHeap::_Node::_Node()
  : parent(NULL)
  , left(NULL)
  , right(NULL)
  , key(INVALID_KEY)
  , value(NULL)
{
}

inline
_TreeHeap::_Node::~_Node()
{
}

inline bool
_TreeHeap::_Node::is_root() const
{
  return (parent == NULL);
}

inline bool
_TreeHeap::_Node::is_leaf() const
{
  return ((left == NULL) && (right == NULL));
}

inline bool
_TreeHeap::_Node::is_left_child() const
{
  return (!is_root() && (this == parent->left));
}

inline bool
_TreeHeap::_Node::is_right_child() const
{
  return (!is_root() && (this == parent->right));  
}

inline bool
_TreeHeap::_Node::has_right_child() const
{
  return !(right == NULL);
}


// ---------------------------------------------------------------------
// _TreeHeap

void
_TreeHeap::push(const Key& key, Value * value)
{
  // If there are no free nodes, allocate a new one.
  // Note: This will never be freed until the destructor is called:
  // The heap reuses allocated nodes, to save on allocations.
  if (_free == NULL)
  {
    _free = new _Node();
  }

  _Node * newborn = _free;
  _free = newborn->parent;

  // FIXME: Is it really necessary to initialize the node twice?
  // new (newborn) _Node();
  newborn->key = key;
  newborn->value = value;

  if (is_empty())
  {
    _root = _last = newborn;
    newborn->parent = NULL;
    _size++;
  }
  else
  {
    _Node * first = _following(_last);
    if (first->left == NULL)
    {
      first->left = newborn;
    }
    else
    {
      first->right = newborn;
    }
    newborn->parent = first;

    _move_up(newborn);
    _last = newborn;
    _size++;
  }
}

_TreeHeap::Value *
_TreeHeap::pop(Key& key)
{
  Value * value = NULL;

  if (!is_empty())
  {
    key = _root->key;
    value = _root->value;

    // Move the root to the end to preserve heap structure,
    // and remove it
    _swap(_root, _last);
    _remove_last();

    // Unless there's only one node, the last node is unlikely to
    // be the new root, so move it down to its new position.
    if (_root != NULL)
    {
      _move_down(_root);
      _size--;
    }
    else
    {
      // XXX: This should be handled by a --_size.  Why the special case?
      _size = 0;
    }
  }

  return value;
}

void
_TreeHeap::_move_up(_Node * current)
{
  if (!current->is_root())
  {
    _Node *& parent = current->parent;

    // A parent with a larger key is transposed
    // with current, effectively moving current
    // up the heap.
    if (parent->key > current->key)
    {
      _swap(current, parent);
      _move_up(parent);
    }
  }
}

void
_TreeHeap::_move_down(_Node * current)
{
  // Can't move down if there are no children
  if (!current->is_leaf())
  {
    //.Which of the two children is smaller.
    _Node * smaller = NULL;

    // Only a left child.  It must be the smaller.
    if (!current->has_right_child())
    {
      smaller = current->left;
    }
    // Sibling rivalry
    else
    {
      smaller = (current->left->key < current->right->key)
        ? current->left : current->right;
    }

    // A child with a smaller key is transposed
    // with current, effectively moving current
    // down the heap.
    if (smaller->key < current->key)
    {
      _swap(current, smaller);
      _move_down(smaller);
    }
  }
}


void
_TreeHeap::_swap(_Node * first, _Node * second)
{
  // Note: Only the keys and the values should be swapped.
  _Node temp;

  temp.key = first->key;
  temp.value = first->value;

  first->key = second->key;
  first->value = second->value;

  second->key = temp.key;
  second->value = temp.value;
}

void
_TreeHeap::_remove_last()
{
  _last = _preceding(_last);

  if (_last->is_left_child())
  {
    _last->parent->left = NULL;
  }
  // XXX: That this is not an else 'suggests' that both can happen???
  if (_last->is_right_child())
  {
    _last->parent->right = NULL;
  }

  // Put this node on the free list
  _last->parent = _free;
  _free = _last;
}

_TreeHeap::_Node *
_TreeHeap::_preceding(_Node * current)
{
  if (!current->is_root())
  {
    // Travel up the chain of left children
    while (current->is_left_child())
    {
      current = current->parent;
    }
  }

  // Move to current's left sibling
  if (!current->is_root())
  {
    current = current->parent->left;
  }

  // Travel down the chain of right children
  while (current->right != NULL)
  {
    current = current->right;
  }

  return current;
}

_TreeHeap::_Node *
_TreeHeap::_following(_Node * current)
{
  if (!current->is_root())
  {
    // Travel up the chain of right children
    while (current->is_right_child())
    {
      current = current->parent;
    }
  }
  
  // Move to current's right sibling
  if (!current->is_root())
  {
    if (current->parent->right != NULL)
    {
      current = current->parent->right;
    }
    else
    {
      // Special case: 'current' has no right sibling, as it's
      // the last node in the heap.  Therefore its parent
      // is next.
      // FIXME: Is 'has no right sibling' equivalent to 'last'?
      current = current->parent;
    }
  }

  // Travel down the chain of left children
  while (current->left != NULL)
  {
    current = current->left;
  }

  return current;
}

void
_TreeHeap::_remove_all(_Node * current)
{
  if (current->left != NULL)
    _remove_all(current->left);
  else if (current->right != NULL)
    _remove_all(current->right);
  else
    delete current;
}


// ---------------------------------------------------------------------
// _ArrayHeap::_Node

inline
_ArrayHeap::_Node::_Node()
  : key(INVALID_KEY)
  , value(NULL)
{
}

inline
_ArrayHeap::_Node::~_Node()
{
}

// ---------------------------------------------------------------------
// _ArrayHeap

const size_t _ArrayHeap::_DEFAULT_SIZE = 511; //? Is this prime?

_ArrayHeap::_ArrayHeap()
  : _nodes(_DEFAULT_SIZE)
  , _size(_DEFAULT_SIZE)
{
}

void
_ArrayHeap::push(const Key& key, Value * value)
{
  if (size() == _nodes.size())
  {
    // As with the original implementation, this will oocasionally
    // double the vector size, and take linear time to do it.
    // (It's amortized constant time.)  A subtle difference (that should
    // not matter in practice) is that the heap size will double when
    // the vector's capacity() is reached -- which is not the same as size().
    _nodes.push_back(_Node());
  }

  _last()->key = key;
  _last()->value = value;

  _move_up(_nodes.size());
  _size++;
}

_ArrayHeap::Value *
_ArrayHeap::pop(Key& key)
{
  Value * value = _root()->value;
  key = _root()->key;

  _root()->value = _last()->value;
  _root()->key = _last()->key;

  _size--;
  _move_down(0);

  return value;
}

void
_ArrayHeap::_move_up(size_t current_i)
{
  if (current_i != 0)
  {
    int parent_i = (current_i - 1) / 2;
    _Node & current = _nodes[current_i];
    _Node & parent = _nodes[parent_i];

    if (parent.key > current.key)
    {
      _swap(parent_i, current_i);
      _move_up(parent_i);
    }
  }
}

void
_ArrayHeap::_move_down(size_t current_i)
{
  size_t left_i = (current_i * 2) + 1;
  size_t right_i = (current_i + 1) * 2;
  _Node & current = _nodes[current_i];
  _Node & left = _nodes[left_i];
  _Node & right = _nodes[right_i];

  // Two children
  if (right_i < size())
  {
    size_t smaller_i = (left.key < right.key) ? left_i : right_i;
    _Node & smaller = _nodes[smaller_i];

    if (smaller.key < current.key)
    {
      _swap(smaller_i, current_i);
      _move_down(smaller_i);
    }
  }
  // No children
  else if (left_i >= size())
  {
    // Do nothing
  }
  // Only a left child
  else
  {
    if (left.key < current.key)
    {
      _swap(current_i, left_i);
    }
  }
}

void
_ArrayHeap::_swap(size_t first_i, size_t second_i)
{
  _Node & first = _nodes[first_i];
  _Node & second = _nodes[second_i];
  _Node temp;

  temp.key = first.key;
  temp.value = first.value;

  first.key = second.key;
  first.value = second.value;

  second.key = temp.key;
  second.value = temp.value;
}

} // namespace impl

} // namespace util
} // namespace sim
} // namespace tos
