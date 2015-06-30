#ifndef TOS_SIM_ADJACENCYLIST_HH
#define TOS_SIM_ADJACENCYLIST_HH

#include <tossim/public.hh>
#include <ext/slist>
#include <vector>
#include <stdint.h>

namespace tos {
namespace sim {

namespace impl {

using std::vector;
using __gnu_cxx::slist;

/**
 * @brief  A graph's adjacency list 
 *
 * @author Nelson Lee  Original C adjacency list
 * @author Ion         C++ port.
 *
 * Adjacency lists represent connectivity of network graphs simulated in Tos.Sim.
 * An abstraction for allocating and de-allocating adjacency list chains is provided
 * so that smart memory allocation techniques can be implemented.
 *
 * @note FIXME: Can this be replaced or enhanced by Boost.Graph?
 */

class AdjacencyList
{
public:                         // Constants
  // XXX: If we use ext::slist then this isn't necessary.
  // We'll let the slist handle its own memory.
  static const unsigned DEFAULT_N_ALLOCATED_NODES = 200;

public:                         // Types
  /** @brief Contains information about adjacent motes. */
  struct Link
  {
    Link();

    Mote mote;
    double data;
    uint8_t bit;
  };

public:                         // Methods
  AdjacencyList();
 ~AdjacencyList();

  Link * allocate(const Mote& mote);
  void deallocate(Link * link);

private:                        // Types
  typedef slist<Link> Links;

private:                        // Methods
  void _grow();

private:                        // Fields
  Links _links;
  unsigned _n_free_links;
}; // class AdjacencyList

} // namespace impl

using impl::AdjacencyList;

} // namespace sim
} // namespace tos

#endif // TOS_SIM_ADJACENCYLIST_HH
