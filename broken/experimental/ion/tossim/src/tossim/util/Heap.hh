/**
 *  @file Heap.hh
 *
 *  @author Phil Levis
 *  @author Ion Yannopoulos
 */

#ifndef TOS_SIM_UTIL_HEAP_HH
#define TOS_SIM_UTIL_HEAP_HH

#include <tossim/util/public.hh>
#include <boost/array.hpp>
#include <boost/noncopyable.hpp>
#include <cstdlib>
#include <queue>
#include <vector>

namespace tos {
namespace sim {
namespace util {

namespace impl {

using boost::array;
using boost::noncopyable;
using std::priority_queue;
using std::size_t;
using std::vector;


// ---------------------------------------------------------------------
// Private types

/**
 *  
 */

class _HeapBase : private noncopyable
{
public:                         // Types
  typedef long long Key;
  typedef void Value;

public:                         // Constants
  static const Key INVALID_KEY;

protected:
  _HeapBase();
 ~_HeapBase();
};


// ---------------------------------------------------------------------
// Public types


/** 
 *  @brief A heap implemented as a binary tree.
 */

class _TreeHeap : public _HeapBase
{
public:                         // Constructors
  _TreeHeap();
 ~_TreeHeap();

public:                         // Methods
  size_t  size() const;
  bool    is_empty() const;
  Key     minimum_key() const;
  Value * peek();
  void    push(const Key& key, Value * value);
  Value * pop(Key& key);

private:                        // Types
  class _Node;

private:                        // Methods
  void    _move_up(_Node * node);
  void    _move_down(_Node * node);
  void    _swap(_Node * first, _Node * second);
  void    _remove_last();
  _Node * _preceding(_Node * node);
  _Node * _following(_Node * node);

  void    _remove_all(_Node * node);

private:                        // Fields
  _Node * _root;
  _Node * _last;
  _Node * _free;
  size_t  _size;
}; // class _TreeHeap


/**
 *
 */
// XXX: Why the explicit 'boost::" is needed here is not clear.
// XXX: GCC bug, Boost error, or subtle C++ gotcha?
class _TreeHeap::_Node : private boost::noncopyable
{
public:                         // Constructors
  _Node();
 ~_Node();

public:                         // Methods
  bool is_root() const;
  bool is_leaf() const;
  bool is_left_child() const;
  bool is_right_child() const;
  bool has_right_child() const;
  
public:                         // Fields
  _Node * parent;
  _Node * left;
  _Node * right;
  Key     key;
  Value * value;
}; // _TreeHeap::Node


/** 
 *  @brief A heap implemented as an array.
 *
 *  Array heaps are bounded in size by the length of the array -- but
 *  have no memory allocations to do and hence are faster than tree heaps.
 */

class _ArrayHeap : public _HeapBase
{
public:                         // Constructors
  _ArrayHeap();
 ~_ArrayHeap();

public:                         // Methods
  size_t  size() const;
  bool    is_empty() const;
  Key     minimum_key() const;
  Value * peek();
  void    push(const Key& key, Value * value);
  Value * pop(Key& key);

private:                        // Types
  class _Node;

private:                        // Constants
  static const size_t _DEFAULT_SIZE;

private:                        // Methods
  void _move_up(size_t current);
  void _move_down(size_t current);
  void _swap(size_t first, size_t second);
  void _expand();

private:                        // Properties
  _Node *       _root();
  const _Node * _root() const;
  _Node *       _last();
  const _Node * _last() const;

private:                        // Fields
  vector<_Node>  _nodes;
  size_t         _size;         // Note: NOT the same as _nodes.size()!
}; // class _ArrayHeap


/**
 *
 */
// XXX: Why the explicit 'boost::" is needed here is not clear.
// XXX: GCC bug, Boost error, or subtle C++ gotcha?
class _ArrayHeap::_Node // : private boost::noncopyable
{
public:                         // Constructors
  _Node();
 ~_Node();
  
public:                         // Fields
  Key key;
  Value * value;
};
  

/**
 * @brief An array heap using the C++ standard library priority queue.
 */

class _StandardHeap : public _HeapBase
{
public:                         // Constructors
  _StandardHeap();
 ~_StandardHeap();

public:                         // Methods
  size_t  size() const;
  bool    is_empty() const;
  Key     minimum_key() const;
  Value * peek();
  void    push(const Key& key, Value * value);
  Value * pop(Key& key);

private:                        // Types
  struct _Node;

private:                        // Fields
  priority_queue <_Node> _heap;
}; // class _StandardHeap


/**
 *
 */
// Unlike other node types this one must be copyable
// for std::priority_queue to work.
class _StandardHeap::_Node
{
public:                         // Constructors
  _Node(const Key& key, Value * value);
 ~_Node();

  bool operator<(const _Node& other) const;

public:                         // Fields
  Key key;
  Value * value;
};

// ---------------------------------------------------------------------
// Public types

/** 
 *  @brief The interface proxying for all heaps.
 *
 *  Any heap implementation should be accessed through Heap --
 *  and thus implement an interface without need for virtual methods.
 *
 *  @note Heap is typesafe, where it's implementations are not.
 */

template <typename _T, typename Impl_T>
class Heap : private noncopyable
{
public:                         // Types
  typedef Impl_T Internals;
  typedef typename Internals::Key Key;
  typedef _T Value;

public:                         // Constructors
  Heap();
 ~Heap();

public:                         // Methods
  size_t  size() const;
  bool    is_empty() const;
  Key     minimum_key() const;
  Value * peek();
  void    push(const Key& key, Value * value);
  Value * pop(Key& key);
  Value * pop();

private:                        // Fields
  Internals _heap;
}; // class Heap


// These should be template typedef's not subclasses.  Sigh.

template <typename _T>
class TreeHeap : public Heap<_T, _TreeHeap>
{
};

template <typename _T>
class ArrayHeap : public Heap<_T, _ArrayHeap>
{
};

template <typename _T>
class StandardHeap : public Heap<_T, _StandardHeap>
{
};


} // namespace impl

using impl::Heap;
using impl::TreeHeap;
using impl::ArrayHeap;
using impl::StandardHeap;

} // namespace util
} // namespace sim
} // namespace tos

#include <tossim/util/Heap.ii>

#endif // TOS_SIM_UTIL_HEAP_HH
