
import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;
import java.awt.geom.*;
import java.util.*;


/** A <code>BufferedPlot</code> maintains an off-screen drawing surface that
 * reacts to resize events. Clients that wish to draw to the surface register
 * as <code>BufferedPlotListeners</code>.  Clients are notified when the
 * dimensions of the drawing surface change.  Clients are also told when to
 * draw to the surface.
 *
 * @author Cory Sharp
 *   (<a href="mailto:cssharp@eecs.berkeley.edu">cssharp@eecs.berkeley.edu</a>)
 * @version $Revision: 1.2 $$Date: 2003/02/05 23:03:18 $
 */
public class BufferedPlot
  extends Canvas
  implements ComponentListener
{
  BufferedImage bi;
  Graphics2D big;
  boolean firstTime = true;
  Rectangle area;
  Vector clients;

  Color m_clear_color;


  /**
   * Constuct a new <code>BufferedPlot</code>.  It will resize the off-screen
   * drawing surface when placed into a Container, as well as when that
   * Container resizes.
   */
  public BufferedPlot()
  {
    area = new Rectangle();
    clients = new Vector();
    m_clear_color = Color.white;
    setBackground( Color.white );
    addComponentListener( this );
  }


  /**
   * Register a <code>BufferedPlotListener</code>.
   * @param client the client to receive events from the instance of this class
   */
  public void add_client( BufferedPlotListener client )
  {
    if( !clients.contains(client) )
      clients.add( client );
  }

  /**
   * Remove the given <code>BufferedPlotListener</code>.
   * @param client the client to remove from the list of clients to receive
   * events
   */
  public void remove_client( BufferedPlotListener client )
  {
    clients.remove( client );
  }


  /**
   * Tell all clients that the off-screen surface has been resized.
   */
  void tell_clients_plot_resized()
  {
    for( int ii=0; ii<clients.size(); ii++ )
      ((BufferedPlotListener)clients.get(ii)).plot_resized( this, big );
  }

  /**
   * Tell all clients to render to the off-screen surface.
   */
  void tell_clients_render_to_plot()
  {
    for( int ii=0; ii<clients.size(); ii++ )
      ((BufferedPlotListener)clients.get(ii)).render_to_plot( this, big );
  }


  /**
   *
   */
  public void set_clear_color( Color clear )
  {
    m_clear_color = clear;
  }


  /**
   * Call update(g).
   */
  public void paint( Graphics g )
  {
    update( g );
  }


  /**
   * Update the on-screen surface.  Initialize the off-screen surface if
   * necessary, clear it with white, tell the clients to render to it, then
   * draw it on-screen.
   */
  public void update( Graphics g )
  {
    Graphics2D g2 = (Graphics2D)g;

    if(firstTime)
    {
      set_graphic_size( getSize() );
      firstTime = false;
    } 

    // Clears the rectangle that was previously drawn.
    big.setTransform( new AffineTransform( 1, 0, 0, 1, 0, 0 ) );
    big.setColor( m_clear_color );
    big.fillRect( 0, 0, area.width, area.height );

    // have all the clients render
    tell_clients_render_to_plot();

    // Draws the buffered image to the screen.
    g2.drawImage( bi, 0, 0, this );
  }


  public void componentHidden( ComponentEvent e ) {}
  public void componentMoved( ComponentEvent e ) {}
  public void componentShown( ComponentEvent e ) {}
  public void componentResized( ComponentEvent e ) { set_graphic_size(getSize()); }


  /**
   * Explicitly set the size of the off-screen surface.  Note: the class
   * always responds to resize events.
   * @param dim desired dimensions of the offscreen graphic
   */
  public void set_graphic_size( Dimension dim )
  {
    int w = dim.width;
    int h = dim.height;

    if( w == 0 || h == 0 )
      return;

    if( (bi == null) || (w != bi.getWidth()) || (h != bi.getHeight()) )
    {
      area.setSize( w, h );
      bi = (BufferedImage)createImage( w, h );
      big = bi.createGraphics();

      big.setRenderingHint(
	  RenderingHints.KEY_ANTIALIASING,
	  RenderingHints.VALUE_ANTIALIAS_ON
	);
      
/*
      big.setRenderingHint(
	  RenderingHints.KEY_INTERPOLATION,
	  RenderingHints.VALUE_INTERPOLATION_BILINEAR
	  //RenderingHints.VALUE_INTERPOLATION_NEAREST_NEIGHBOR
	  //RenderingHints.VALUE_INTERPOLATION_BICUBIC
	);
*/
/*
      big.setRenderingHint(
	  RenderingHints.KEY_TEXT_ANTIALIASING,
	  RenderingHints.VALUE_TEXT_ANTIALIAS_ON
	);
*/

      tell_clients_plot_resized();
      repaint();
    }
  }
}

