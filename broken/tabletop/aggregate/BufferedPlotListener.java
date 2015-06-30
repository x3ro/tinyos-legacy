
import java.awt.*;


/**
 * A <code>BufferedPlotListener</code> responds to events from an instance of
 * <code>BufferedPlot</code>.
 *
 * @author Cory Sharp
 *   (<a href="mailto:cssharp@eecs.berkeley.edu">cssharp@eecs.berkeley.edu</a>)
 * @version $Revision: 1.2 $$Date: 2003/02/05 23:06:54 $
 */
public interface BufferedPlotListener
{
  /**
   * The <code>BufferedPlot</code> has new dimensions.
   * @param plot the <code>BufferedPlot</code> that resized
   * @param g2 the resized off-screen drawing surface
   */
  public void plot_resized( BufferedPlot plot, Graphics2D g2 );

  /**
   * The <code>BufferedPlot</code> is preparing to render on-screen and needs
   * the clients to render to the off-screen surface.
   * @param plot the <code>BufferedPlot</code> that is about to display
   * @param g2 the off-screen drawing surface to render to
   */
  public void render_to_plot( BufferedPlot plot, Graphics2D g2 );
}

