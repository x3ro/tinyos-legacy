#ifndef TOS_SIM_SPATIALMODEL_HH
#define TOS_SIM_SPATIALMODEL_HH

#include <tossim/public.hh>
#include <vector>

namespace tos {
namespace sim {

namespace impl {

using std::vector;

/** 
 *  @brief The interface used for spatial simulation.
 *
 *  @note A data pointer is provided so that large structures can be
 *    dynamically allocated. Otherwise, the simulation has to allocate
 *    the regions of memory for every model, even though only one is in use.
 */

class SpatialModel
{
public:                         // Types
  struct Point
  {
    double x;
    double y;
    double z;
  };

public:                         // Methods
  SpatialModel();
  virtual ~SpatialModel();

  virtual void get_position(int moteID, long long ftime, Point& storage) = 0;

}; // class SpatialModel


#define TOSNODES 90

/**
 *  @brief Implementation of a simple spatial model
 */

class SimpleSpatialModel : public SpatialModel
{
public:                         // Methods
  SimpleSpatialModel(const unsigned count = TOSNODES);
 ~SimpleSpatialModel();

  virtual void get_position(int moteID, long long ftime, Point& storage);

private:                        // Fields
  vector<Point>                 _points;
};

} // namespace impl

using impl::SpatialModel;
using impl::SimpleSpatialModel;

} // namespace sim
} // namespace tos

#endif // TOS_SIM_SPATIALMODEL_HH
