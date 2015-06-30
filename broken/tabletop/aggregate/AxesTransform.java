
import java.awt.geom.*;


/** An <code>AxesTransform</code> maps to/from a pair of two-dimensional
 * coordinate systems.  Mapping may occur in either direction: from axes0 to
 * axes1, or vice-versa.  Any distinction between the two pairs of axes is left
 * to the user.
 *
 * <p>The option is provided to make one axes "square" (of equal proportions)
 * with respect to the other axes.  This is done by increasing the appropriate
 * dimension of the requested axes.
 *
 * @author Cory Sharp
 *   (<a href="mailto:cssharp@eecs.berkeley.edu">cssharp@eecs.berkeley.edu</a>)
 * @version $Revision: 1.2 $$Date: 2003/02/05 23:02:44 $
 */
public class AxesTransform
{
  Rectangle2D.Double a0;
  Rectangle2D.Double a1;

  /**
   * Constructs a new set of axes: both at (0,0) with 0 width and 0 height.
   */
  public AxesTransform()
  {
    a0 = new Rectangle2D.Double();
    a1 = new Rectangle2D.Double();
  }

  /**
   * Constructs a new set of axes each with the given dimensions.
   * @param _a0 dimensions of axes0
   * @param _a1 dimensions of axes1
   */
  public AxesTransform( Rectangle2D _a0, Rectangle2D _a1 )
  {
    a0 = new Rectangle2D.Double();
    a1 = new Rectangle2D.Double();
    set_axes0( _a0 );
    set_axes1( _a1 );
  }

  /**
   * Assign axes0 to the given rectangle.
   * @param _a0 dimensions of axes0
   */
  public void set_axes0( Rectangle2D _a0 ) { a0.setRect( _a0 ); }

  /**
   * Assign axes1 to the given rectangle.
   * @param _a1 dimensions of axes1
   */
  public void set_axes1( Rectangle2D _a1 ) { a1.setRect( _a1 ); } 

  /**
   * Return axes0, possibly for modification.
   * @return dimensions of axes0
   */
  public Rectangle2D.Double get_axes0() { return a0; } 

  /**
   * Return axes1, possibly for modification.
   * @return dimensions of axes1
   */
  public Rectangle2D.Double get_axes1() { return a1; } 

  /**
   * Convert an x-coordinate in the axes1 coordinate-frame to the axes0
   * coordinate-frame.
   * @param x1 x-coordinate in axes1
   * @return x-coordinate in axes0
   */
  public double to_x0( double x1 ) { return (x1 - a1.x) * a0.width  / a1.width  + a0.x; } 

  /**
   * Convert a y-coordinate in the axes1 coordinate-frame to the axes0
   * coordinate-frame.
   * @param y1 y-coordinate in axes1
   * @return y-coordinate in axes0
   */
  public double to_y0( double y1 ) { return (y1 - a1.y) * a0.height / a1.height + a0.y; } 

  /**
   * Convert an x-coordinate in the axes0 coordinate-frame to the axes1
   * coordinate-frame.
   * @param x0 x-coordinate in axes0
   * @return x-coordinate in axes1
   */
  public double to_x1( double x0 ) { return (x0 - a0.x) * a1.width  / a0.width  + a1.x; } 

  /**
   * Convert a y-coordinate from the axes1 coordinate-frame to the axes0
   * coordinate-frame.
   * @param y0 y-coordinate in axes0
   * @return y-coordinate in axes1
   */
  public double to_y1( double y0 ) { return (y0 - a0.y) * a1.height / a0.height + a1.y; }


  /**
   * Convert an x-coordinate in the axes1 coordinate-frame to the axes0
   * coordinate-frame.
   * @param x1 x-coordinate in axes1
   * @return x-coordinate in axes0 rounded to the nearest integer
   */
  public int to_int_x0( double x1 ) { return (int)( 0.5 + to_x0(x1) ); }

  /**
   * Convert a y-coordinate in the axes1 coordinate-frame to the axes0
   * coordinate-frame.
   * @param y1 y-coordinate in axes1
   * @return y-coordinate in axes0 rounded to the nearest integer
   */
  public int to_int_y0( double y1 ) { return (int)( 0.5 + to_y0(y1) ); }

  /**
   * Convert an x-coordinate in the axes0 coordinate-frame to the axes1
   * coordinate-frame.
   * @param x0 x-coordinate in axes0
   * @return x-coordinate in axes1 rounded to the nearest integer
   */
  public int to_int_x1( double x0 ) { return (int)( 0.5 + to_x1(x0) ); }

  /**
   * Convert a y-coordinate from the axes1 coordinate-frame to the axes0
   * coordinate-frame.
   * @param y0 y-coordinate in axes0
   * @return y-coordinate in axes1 rounded to the nearest integer
   */
  public int to_int_y1( double y0 ) { return (int)( 0.5 + to_y1(y0) ); }

  /**
   * Make axes0 square with respect to axes1 by increasing the appropriate
   * dimension of axes0.
   */
  public void square_axes0() { square_axes( a0, a1 ); } 

  /**
   * Make axes1 square with respect to axes0 by increasing the appropriate
   * dimension of axes1.
   */
  public void square_axes1() { square_axes( a1, a0 ); } 

  /**
   * Make the given axes0 square with respect to the given axes1 by increasing
   * the appropriate dimension of axes0.
   * @param axes0 axes to be modified
   * @param axes1 axes specifying the desired aspect ratio
   */
  public static void square_axes( Rectangle2D.Double axes0, Rectangle2D.Double axes1 )
  {
    double rw = axes0.width / axes1.width;
    double rh = axes0.height / axes1.height;
    if( rw < rh )
    {
      double d = axes1.width * rh;
      axes0.x -= (d - axes0.width) / 2;
      axes0.width = d;
    }
    else if( rh < rw )
    {
      double d = axes1.height * rw;
      axes0.y -= (d - axes0.height) / 2;
      axes0.height = d;
    }
  }
}

