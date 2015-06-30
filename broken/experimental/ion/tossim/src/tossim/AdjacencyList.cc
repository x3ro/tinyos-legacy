#include <tossim/private.hh>
#include <tossim/AdjacencyList.hh>

namespace tos {
namespace sim {

namespace impl {

/**
 *  @note  The method in the C TOSSIM that this constructor is based on
 *    (@c allocate_link), is designed to use allocate a block of nodes,
 *    and, if they are all used, to allocate another block, and very
 *    straightforwardly integrate it back in.  I try to replicate
 *    this form using std::list.
 */

AdjacencyList::AdjacencyList()
  : _links()
{

}

AdjacencyList::~AdjacencyList()
{
}


AdjacencyList::Link *
AdjacencyList::allocate(const Mote& mote)
{
  Link link;

  link.mote = mote;

  _links.push_front(link);

  return 
}



AdjacencyList::Link::Link()
  : mote(-1)
  , data(0.0)
  , bit(0)
{
}


} // namespace impl

} // namespace sim
} // namespace tos
