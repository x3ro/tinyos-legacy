
import java.awt.*;
import java.awt.geom.*;
import java.util.*;


/**
 * A <code>MoteVector</cod> manages a vector of <code>Mote</code> instances.
 * Also contains the member function <code>funny_average</code> to perform some
 * sort of weighted average across the data points (that part is kind of hackey
 * and could be parameterized or moved out of this code).
 *
 * @author Cory Sharp
 *   (<a href="mailto:cssharp@eecs.berkeley.edu">cssharp@eecs.berkeley.edu</a>)
 * @version $Revision: 1.1 $$Date: 2003/02/05 23:11:04 $
 */
public class MoteVector extends Vector
{
  /**
   */
  Mote get_mote( int n )
  {
    return (Mote)get(n);
  }

  /**
   */
  Mote get_mote_by_id( int id )
  {
    int n = get_n_from_id( id );
    return (n == -1) ? null : get_mote(n);
  }

  /**
   */
  public int get_n_from_id( int id )
  {
    for( int i=0; i<size(); i++ )
    {
      if( get_mote(i).id == id )
	return i;
    }
    return -1;
  }


  /**
   */
  public Mote get_maxmag_mote( double timeold )
  {
    Mote max = null;

    for( int n=0; n<size(); n++ )
    {
      Mote mote = get_mote(n);
      if( (mote.mag.get_value_time() > timeold)
	  && ( (max == null)
	       || (mote.mag.get_value() > max.mag.get_value())
	     )
	)
      {
	max = mote;
      }
    }

    return max;
  }


  /**
   * Calculate a funny, weighted average of the data points.
   * @return some sort of center of mass
   */
  public Point2D.Double mag_average( double timeout )
  {
    double current_time = LatchData.get_current_time();
    double sum = 0;
    Point2D.Double pp = new Point2D.Double( 0, 0 );

    double mid_time = timeout;
    double end_time = timeout;

    for( int n=0; n<size(); n++ )
    {
      Mote mote = get_mote(n);
      double age = current_time - mote.mag.get_value_time();

      if( (0 <= age) && (age < end_time) )
      {
	double weight = Math.sqrt( mote.mag.get_value() );

	if( mid_time < age )
	  weight *= (end_time - age) / (end_time - mid_time);

	pp.x += weight * mote.xpos;
	pp.y += weight * mote.ypos;
	sum += weight;
      }
    }

    if( sum > 0 )
    {
      pp.x /= sum;
      pp.y /= sum;
      return pp;
    }

    return null;
  }
}

