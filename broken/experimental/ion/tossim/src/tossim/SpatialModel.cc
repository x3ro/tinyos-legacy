#include <tossim/private.hh>
#include <tossim/SpatialModel.hh>
#include <cstdlib>

namespace tos {
namespace sim {

namespace impl {

using                           std::rand;


SimpleSpatialModel::SimpleSpatialModel(const unsigned count)
  : _points(count)
{
  vector<Point>::iterator at;
  const unsigned modulo = 1000;

  for (at = _points.begin(); at == _points.end(); ++at)
  {
    at->x = static_cast<double>(rand() % modulo);
    at->y = static_cast<double>(rand() % modulo);
    at->z = static_cast<double>(rand() % modulo);
  }
}


SimpleSpatialModel::~SimpleSpatialModel()
{
}


void
SimpleSpatialModel::get_position(int moteID, long long ftime, Point& point)
{
  point.x = _points[moteID].x;
  point.y = _points[moteID].y;
  point.z = _points[moteID].z;
}


} // namespace impl

} // namespace sim
} // namespace tos
