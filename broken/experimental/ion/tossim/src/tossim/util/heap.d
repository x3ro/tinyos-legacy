/**
 *  @brief Simple priority heap for discrete event simulation.
 * 
 *  The heap is a proxy for one several implementations, and is
 *  templated on the implementation.  This is done instead of
 *  the more obvious inheritance-based implementation as an
 *  experiment in efficiency, and in D's template system.
 *
 *  It would be interesting to see if heap_t.node_t could also
 *  be made into a abstract type, but currently the methods
 *  of heap_t do not share enough implementation (see the
 *  Template Method pattern).
 *
 *  There are two (obvious) implementations:
 *    - Tree-based (@see tree_heap_t)
 *    - Array-based (@see array_heap_t)
 *
 *  The choice of implementation depends on circumstances but
 *  array-based heaps seem more common in practice.
 */

module tos.sim.heap;

import tos.sim.pool;

private alias MallocPool        _Pool;

/** 
 *  @brief
 *
 */
private struct heap_key_t
{
  static const heap_key_t       INVALID = { key: -1 };

  long                          opCast()
  {
    return key;
  }

public:
  long                          key;
}


/** 
 *  @brief
 */
struct                          heap_t
{
public:                         // Types
  alias long                    key_t;

public:                         // Constants
  const key_t                   INVALID_KEY = -1;

public:                         // Methods
  void                          initialize()
  {
  }

  int                           size()
  {
    return this.sizeof;
  }

  bool                          is_empty()
  {
    return false;
  }

  key_t                         minimum_key()
  {
    return 0L;
  }

  void *                        peek()
  {
    return null;
  }

  void                          push(in key_t key, void * data)
  {
  }

  void *                        pop(inout key_t key)
  {
    return null;
  }
}


/**
 *  @brief A heap implemented as a binary tree.
 */

struct                          tree_heap_t
{
public:                         // Types
  alias void T;

  alias heap_t.key_t            key_t;

public:                         // Methods
  void                          initialize()
  {
    this.root = this.free = this.last = null;
    this.actual_size = 0;
  }

  int                           size()
  {
    return this.actual_size;
  }

  bool                          is_empty()
  {
    return (this.actual_size == 0);
  }

  key_t                         minimum_key()
  {
    return this.root.key;
  }

  T *                           peek()
  {
    return this.root.data;
  }

  void                          push(in key_t key, T * data)
  {
    node_t * at, newborn;

    // Allocate a new node, only if the free list doesn't have any saved up.
    if (this.free == null)
    {
      this.free = _pool.allocate(1);
      this.free.initialize();
    }

    newborn = this.free;
    this.free = newborn.parent;

    newborn.initialize();
    newborn.key = key;
    newborn.data = data;

    if (this.is_empty())
    {
      this.root = this.last = newborn;
      newborn.parent = null;
      this.actual_size++;
    }
    else
    {
      at = this._next(this.last);
      if (at.left == null)
      {
        at.left = newborn;
      }
      else
      {
        at.right = newborn;
      }
      newborn.parent = at;

      this._move_up(newborn);
      this.last = newborn;
      this.actual_size++;
    }
  }

  T *                           pop(inout key_t key)
  {
    T * data;

    if (this.is_empty())
      goto end;

    key = this.root.key;
    data = this.root.data;

    this._swap(this.root, this.last);
    this._remove_last();

    if (this.root != null)
    {
      this._move_down(this.root);
      this.actual_size--;
    }
    else
    {
      this.actual_size = 0;
    }

  end:
    return data;
  }

  T *                           pop()
  {
    key_t discard;

    return this.pop(discard);
  }
  

private:                        // Methods
  void                          _move_up(node_t * node)
  {
    node_t * parent = node.parent;

    if (!node.is_root())
    {
      //+ if (compare(parent.key, node.key))
      if (parent.key > node.key)
      {
        this,_swap(node, parent);
        this._move_up(parent);
      }
    }
  }

  void                          _move_down(node_t * node)
  {
    node_t * minimum = null;

    // Don't move down if there's no children
    if (!node.is_leaf())
    {
      // Only a left child.  It must be the minimum
      if (node.right == null)
      {
        minimum = node.left;
      }
      else
      {
        minimum = (node.left.key < node.right.key)
          ? node.left : node.right;
      }

      if (node.key > minimum.key)
      {
        this._swap(node, minimum);
        this._move_down(minimum);
      }
    }
  }
  
  void                          _swap(node_t * first, node_t * second)
  {
    // Note: You can't just implement opAssign here.
    // Only the keys and values should be swapped.
    node_t temp;

    temp.key = first.key;
    temp.data = first.data;

    first.key = second.key;
    first.data = second.data;

    second.key = temp.key;
    second.data = temp.data;
  }

  void                          _remove_last()
  {
    this.last = this._prev(this.last);

    if (this.last.is_left_child())
    {
      this.last.parent.left = null;
    }
    // XXX: That this is not an 'else' suggests there are other cases???
    if (this.last.is_right_child())
    {
      this.last.parent.right = null;
    }

    // Put the freed node on the free list
    this.last.parent = this.free;
    this.free = this.last;
  }

  node_t *                      _prev(node_t * node)
  {
    node_t * at = node;
    
    // Move up to the root
    if (!node.is_root())
    {
      // XXX: Why is_left_child()?  Why not is_root()?
      while (at.is_left_child())
      {
        at = at.parent;
      }
    }
    
    // XXX: How can 'at' not be at the root after the previous loop?
    if (!at.is_root())
    {
      at = at.parent.left;
    }
    
    // Move to the rightmost node before 'node'
    while(at.right != null)
    {
      at = at.right;
    }
    
    return at;
  }

  node_t *                      _next(node_t * node)
  {
    node_t * at = node;
    
    // Move up to the root
    if (!node.is_root())
    {
      // XXX: Why is_right_child()?  Why not is_root()?
      while (at.is_right_child())
      {
        at = at.parent;
      }
    }
    
    // XXX: How can 'at' not be at the root after the previous loop?
    if (!at.is_root())
    {
      at = at.parent.right;
    }
    
    // Move to the leftmost node after 'node'
    while(at.left != null)
    {
      at = at.left;
    }
    
    return at;
  }

public:                         // Fields
  node_t *                      root;
  node_t *                      last;
  node_t *                      free;
  int                           actual_size;

private:                        // Types
  struct                        node_t
  {
    void                        initialize()
    {
      this.parent = this.left = this.right = null;
      this.data = null;
      this.key = heap_t.INVALID_KEY;
    }

    bool                        is_root()
    {
      return (this.parent == null);
    }

    bool                        is_leaf()
    {
      return ((this.left == null) && (this.right == null));
    }

    bool                        is_left_child()
    {
      return (!this.is_root() && (this == this.parent.left));
    }

    bool                        is_right_child()
    {
      return (!this.is_root() && (this == this.parent.right));
    }

    node_t *                    parent;
    node_t *                    left;
    node_t *                    right;
    key_t                       key;
    T *                         data;
  }

private:                        // Constructors
  static this()
  {
    _pool = new _Pool!(node_t);
  }

  static ~this()
  {
    delete _pool;
  }

private:                        // Fields
  static _Pool!(node_t)         _pool;
}




/**
 *  @brief A heap implemented as an array. 
 *
 *  Array heaps are bounded in size by the length of the array -- but
 *  have no memory allocations to do and hence are faster than tree heaps.
 */
struct                          array_heap_t
{
public:                         // Types
  alias heap_t.key_t            key_t;

  alias void                    T;

public:                         // Methods
  void                          initialize()
  {
    this._nodes = null; // XXX
    this._size = 0;
    this._capacity = STARTING_SIZE;
  }

  int                           size()
  {
    return this._size;
  }

  bool                          is_empty()
  {
    return (this._size == 0);
  }

  key_t                         minimum()
  {
    if (this.is_empty())
    {
      return heap_t.INVALID_KEY;
    }
    else
    {
      this._root.key;
    }
  }

  T *                           peek()
  {
    if (this.is_empty())
    {
      return null;
    }
    else
    {
      this._root.data;      
    }
  }

  void                          push(key_t key, T * data)
  {
    if (this._size == this._capacity)
    {
      this._expand();
    }

    this._last.key = key;
    this._last.data = data;

    this._move_up(this._size);

    this._size++;
  }

  T *                           pop(inout key_t key)
  {
    T * data = this._root.data;

    key = this._root.key;

    this._root.data = this._last.data;
    this._root.key = this._last.key;

    this._size--;

    this._move_down(0);

    return data;
  }

  T *                           pop()
  {
    key_t discard;

    return this.pop(discard);
  }

private:                        // Types
  struct                        node_t
  {
    void                        initialize()
    {
      this.data = null;
      this.key = heap_t.INVALID_KEY;
    }

    T *                         data;
    key_t                       key;
  }

private:                        // Methods
  void                          _move_up(int current_i)
  {
    if (current_i != 0)
    {
      int parent_i = (current_i - 1) / 2;
      node_t * current = &this._nodes[current_i];
      node_t * parent = &this._nodes[parent_i];

      if (parent.key > current.key)
      {
        this._swap(parent, current);
        this._move_up(parent_i);
      }
    }
  }

  void                          _move_down(int current_i)
  {
    int left_i = (current_i * 2) + 1;
    int right_i = (current_i + 1) * 2;
    node_t * left = &this._nodes[left_i];
    node_t * right = &this._nodes[right_i];
    node_t * current = &this._nodes[current_i];

    if (right_i < this._size)
    {
      key_t min_i = (left.key < right.key) ? left_i : right_i;
      node_t * min = &this._nodes[min_i];

      if(min.key < current.key)
      {
        this._swap(min, current);
        this._move_down(min_i);
      }
    }
  }


  void                          _swap(node_t * first, node_t * second)
  {
    node_t temp;

    temp.key = first.key;
    temp.data = first.data;

    first.key = second.key;
    first.data = second.data;

    second.key = temp.key;
    second.data = temp.data;
  }

  void                          _expand()
  {
    int new_size = (this._capacity * 2) + 1;
    
  }

private:                        // Properties
  node_t *                      _root()
  {
    return &this._nodes[0];
  }

  node_t *                      _last()
  {
    return &this._nodes[this._size - 1];
  }  

  node_t *                      _free()
  {
    return &this._nodes[this._size];
  }

private:                        // Constants
  const uint                    STARTING_SIZE = 511;

private:                        // Fields
  node_t *                      _nodes;
  int                           _size;
  int                           _capacity;

  static _Pool!(node_t)         _pool;
}

