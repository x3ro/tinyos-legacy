/* 
 * Author: 
 * Inception Date: 
 *
 * This software is copyrighted by Mike Chen and the Regents of
 * the University of California.  The following terms apply to all
 * files associated with the software unless explicitly disclaimed in
 * individual files.
 * 
 * The authors hereby grant permission to use this software without
 * fee or royalty for any non-commercial purpose.  The authors also
 * grant permission to redistribute this software, provided this
 * copyright and a copy of this license (for reference) are retained
 * in all distributed copies.
 *
 * For commercial use of this software, contact the authors.
 * 
 * IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY
 * DERIVATIVES THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.  THIS SOFTWARE
 * IS PROVIDED ON AN "AS IS" BASIS, AND THE AUTHORS AND DISTRIBUTORS HAVE
 * NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 */


//package ;

import java.applet.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.geom.*;
import java.awt.image.*;
import java.io.*;
import java.util.*;
import java.util.regex.*;


/**
 * <code>aggregate</code> opens a serial port for mote packets, creates a grid
 * for maintaining mote readings, processes packets, and aggregates reported
 * sensor reading to a weighted center of mass.
 *
 * @author Cory Sharp
 *   (<a href="mailto:cssharp@eecs.berkeley.edu">cssharp@eecs.berkeley.edu</a>)
 * @version $Revision: 1.2 $$Date: 2003/02/05 23:09:22 $
 */
public class aggregate
  extends Applet
  implements MotePacketListener, BufferedPlotListener, ImageObserver, KeyListener
{
  MotePacketSerialParser m_packet_reader;
  MoteVector m_motes;
  BufferedPlot m_plot;
  Point2D.Double m_average;
  double m_average_time;

  class Track
  {
    public Point2D.Double pos;
    public double time;
    public Track() { pos=new Point2D.Double(0,0); time=0; }
    public Track(double x, double y, double t) { pos=new Point2D.Double(x,y); time=t; }
  }

  LinkedList m_track_list;

  Repainter m_repainter;
  Image m_scan_image;
  Dimension m_image_dims;
  Rectangle2D m_plotrect;

  AxesTransform m_M2P_axes; // mote to image axes
  AxesTransform m_O2W_axes; // overlay to window axes
  double m_M2P_scale; // mote to pixel scaling, assuming the pixels are square
  double m_O2P_scale; // overlay to pixel scaling, assuming the pixels are square
  Rectangle2D.Double m_square_mote_bounds;
  Rectangle2D.Double m_square_overlay_bounds;

  AggregateHash m_props;


  /**
   *
   */
  class Repainter extends Thread
  {
    aggregate m_agg;
    boolean dorun;
    public Repainter( aggregate agg ) { m_agg = agg; }
    public void dontrun() { dorun=false; }
    public void run()
    {
      dorun = true;
      while(dorun)
      {
	double t0 = LatchData.get_current_time();
	m_agg.update_position_display();
	double dt = LatchData.get_current_time() - t0;
	double sl = dt - 1.0/30.0;
	try { Thread.sleep( (int)(1e3*dt), (int)(1e6*(1e3*dt-(int)1e3*dt)) ); }
	catch( InterruptedException e ) { }
      }
    }
  }



  /**
   * Construct with the given serial port name.
   * @param portName serial port name
   */
  public aggregate( String portName, String config_file )
    throws FileNotFoundException
  {
    m_props = new AggregateHash();

    m_props.put( "background color",              new Color(1,1,1) );
    m_props.put( "do fancy mark mote",            new Boolean(false) );
    m_props.put( "do mark trail estimate",        new Boolean(false) );
    m_props.put( "do mark mote",                  new Boolean(false) );
    m_props.put( "do mote leader lights",         new Boolean(false) );
    m_props.put( "do overlay",                    new Boolean(false) );
    m_props.put( "do pan image",                  new Boolean(true) );
    m_props.put( "do trail",                      new Boolean(false) );
    m_props.put( "image bounds",                  new Rectangle2D.Double(605,0,418,746) );
    m_props.put( "image filename",                new String("aggregate.jpg") );
    m_props.put( "initial applet bounds",         new Rectangle2D.Double(605,0,418,746) );
    m_props.put( "mark mote color",               new Color(1,1,1) );
    m_props.put( "mark mote radius",              new Double(1) );
    m_props.put( "mote base id",                  new Integer(0) );
    m_props.put( "mote bounds",                   new Rectangle2D.Double(0,0,1,1) );
    m_props.put( "nopan view bounds",             new Rectangle2D.Double(0,0,1,1) );
    m_props.put( "overlay background color",      new Color(1,1,1) );
    m_props.put( "overlay bounds",                new Rectangle2D.Double(0,0,1,1) );
    m_props.put( "overlay estimate color",        new Color(1,1,1) );
    m_props.put( "overlay estimate inner color",  new Color(1,1,1) );
    m_props.put( "overlay estimate inner radius", new Double(1) );
    m_props.put( "overlay estimate radius",       new Double(1) );
    m_props.put( "overlay meter dim color",       new Color(1,1,1) );
    m_props.put( "overlay meter leader color",    new Color(1,1,1) );
    m_props.put( "overlay meter radio color",     new Color(1,1,1) );
    m_props.put( "overlay meter sense color",     new Color(1,1,1) );
    m_props.put( "overlay meter size",            new Double(1) );
    m_props.put( "overlay mote color",            new Color(1,1,1) );
    m_props.put( "overlay mote radius",           new Double(1) );
    m_props.put( "overlay offset",                new Rectangle2D.Double(0,0,1,1) );
    m_props.put( "overlay shrink",                new Rectangle2D.Double(0,0,1,1) );
    m_props.put( "radio bar time",                new Double(1) );
    m_props.put( "sense timeout",                 new Double(1) );
    m_props.put( "smoothing time constant",       new Double(1) );
    m_props.put( "title",                         new String("Aggregate") );
    m_props.put( "trail color",                   new Color(1,1,1) );
    m_props.put( "trail estimate inner radius",   new Double(1) );
    m_props.put( "trail estimate radius",         new Double(1) );
    m_props.put( "trail time",                    new Double(5) );
    m_props.put( "trail width",                   new Double(10) );
    m_props.put( "view size",                     new Rectangle2D.Double(0,0,1,1) );

    // define all config options and their defaults ABOVE HERE

    m_motes = new MoteVector();
    m_average = new Point2D.Double();

    m_track_list = new LinkedList();

    m_M2P_axes = new AxesTransform();
    m_O2W_axes = new AxesTransform();
    m_square_mote_bounds = new Rectangle2D.Double();
    m_square_overlay_bounds = new Rectangle2D.Double();

    m_plotrect = new Rectangle(0,0,1,1);

    load_config_file( config_file );

    m_packet_reader = new MotePacketSerialParser( portName );
    m_packet_reader.add_packet_listener( this );

    m_image_dims = new Dimension(0,0);
    m_scan_image = getToolkit().createImage( m_props.getString("image filename") );
    m_scan_image.getWidth( this );
    m_scan_image.getHeight( this );

    m_repainter = new Repainter( this );
  }


  /**
   * Read a config file into the options map.
   */
  void load_config_file( String config_file )
  {
    try
    {
      BufferedReader is = new BufferedReader( new FileReader( config_file ) );
      int linenum = 0;
      int numerrors = 0;

      Pattern re_keyval = Pattern.compile( "^\\s*([^=]*[^=\\s])\\s*=\\s*(.*\\S)\\s*$" );
      Pattern re_comments = Pattern.compile( "(?:#|//).*" );
      Pattern re_blank_line = Pattern.compile( "^\\s*$" );

      Pattern re_spaces = Pattern.compile( "\\s+" );

      Pattern re_ishex = Pattern.compile( "^0x(\\S+)$" );

      Pattern re_bool_true = Pattern.compile( "^(yes|true|1)$", Pattern.CASE_INSENSITIVE );
      Pattern re_bool_false = Pattern.compile( "^(no|false|0)$", Pattern.CASE_INSENSITIVE );

      Pattern re_mote = Pattern.compile(
	"^id\\s+(\\S+)\\s+xpos\\s+(\\S+)\\s+ypos\\s+(\\S+)$",
	Pattern.CASE_INSENSITIVE
      );

      Pattern re_bounds = Pattern.compile(
	"^xmin\\s+(\\S+)\\s+ymin\\s+(\\S+)\\s+width\\s+(\\S+)\\s+height\\s+(\\S+)$",
	Pattern.CASE_INSENSITIVE
      );

      Pattern re_dims = Pattern.compile(
	"^width\\s+(\\S+)\\s+height\\s+(\\S+)$",
	Pattern.CASE_INSENSITIVE
      );

      Pattern re_color = Pattern.compile(
	"^(\\S+)\\s+(\\S+)\\s+(\\S+)(?:\\s+(\\S+))?$"
      );


      String line;
      while( (line = is.readLine()) != null )
      {
	Matcher mm;
	line = re_comments.matcher(line).replaceFirst("");
	linenum++;

	String errstr = null;

	if( re_blank_line.matcher(line).matches() )
	{
	  // skip blank lines, process what we recognize, error out on the rest
	}
	else if( (mm = re_keyval.matcher(line)).matches() )
	{
	  String key = re_spaces.matcher(mm.group(1)).replaceAll(" ").toLowerCase();
	  String val = mm.group(2);

	  Object prop = m_props.get( key );

	  if( prop == null )
	  {
	    if( "mote".equals(key) )
	    {
	      if( (mm = re_mote.matcher(val)).matches() )
	      {
		Matcher mmhex;
		int i = -1;
		if( (mmhex = re_ishex.matcher(mm.group(1))).matches() )
		  i = Integer.parseInt( mmhex.group(1), 16 );
		else
		  i = Integer.parseInt( mm.group(1) );

		double x = Double.parseDouble( mm.group(2) );
		double y = Double.parseDouble( mm.group(3) );
		m_motes.add( new Mote(i,x,y) );

		m_props.put( "mote base id", new Integer( i & (~0x0ff) ) );
	      }
	      else
	      {
		errstr = "expected form: mote = id ### xpos ### ypos ###";
	      }
	    }
	    else
	    {
	      errstr = "invalid keyword \""+key+"\"";
	    }
	  }
	  else if( prop instanceof Boolean )
	  {
	    if( re_bool_true.matcher(val).matches() )
	      m_props.put( key, new Boolean(true) );
	    else if( re_bool_false.matcher(val).matches() )
	      m_props.put( key, new Boolean(false) );
	    else
	      errstr = "expected form: "+key+" = [yes|true|1|no|false|0]";
	  }
	  else if( prop instanceof Color )
	  {
	    if( (mm = re_color.matcher(val)).matches() )
	    {
	      float r = Float.parseFloat( mm.group(1) );
	      float g = Float.parseFloat( mm.group(2) );
	      float b = Float.parseFloat( mm.group(3) );
	      float a = (mm.group(4) == null) ? 1.0f : Float.parseFloat( mm.group(4) );
	      m_props.put( key, new Color(r,g,b,a) );
	    }
	    else
	    {
	      errstr = "expected form: "+key+" = ### ### ###";
	    }
	  }
	  else if( prop instanceof Double )
	  {
	    m_props.put( key, Double.valueOf( val ) );
	  }
	  else if( prop instanceof Integer )
	  {
	    m_props.put( key, Integer.valueOf( val ) );
	  }
	  else if( prop instanceof Rectangle2D.Double )
	  {
	    if( (mm = re_bounds.matcher(val)).matches() )
	    {
	      double x = Double.parseDouble( mm.group(1) );
	      double y = Double.parseDouble( mm.group(2) );
	      double w = Double.parseDouble( mm.group(3) );
	      double h = Double.parseDouble( mm.group(4) );
	      m_props.put( key, new Rectangle2D.Double(x,y,w,h) );
	    }
	    else if( (mm = re_dims.matcher(val)).matches() )
	    {
	      double w = Double.parseDouble( mm.group(1) );
	      double h = Double.parseDouble( mm.group(2) );
	      m_props.put( key, new Rectangle2D.Double(0,0,w,h) );
	    }
	    else
	    {
	      errstr = "expected form: "+key+" = (xmin ### ymin ###) width ### height ###";
	    }
	  }
	  else if( prop instanceof String )
	  {
	    m_props.put( key, val );
	  }
	  else
	  {
	    errstr = "internal configuration error, unknown parameter type";
	  }
	}
	else
	{
	  errstr = "invalid line";
	}

	if( errstr != null )
	{
	  System.err.println( "ERROR, in config file, "+errstr );
	  System.err.println( "on line "+linenum+": "+line+"\n" );
	  numerrors++;
	}
      }

      if( numerrors != 0 )
      {
	System.err.println( "ABORTING, "+numerrors+" error"+(numerrors>1?"s":"")
	                    +" in config file\n" );
	System.exit(1);
      }

    }
    catch( IOException e )
    {
      System.err.println( "ERROR, could not read the config file:\n" + e.toString() );
      System.exit( 1 );
    }
  }



  /**
   *
   */
  public boolean imageUpdate( Image img, int infoflags, int x, int y, int width, int height ) 
  {
    if( (infoflags & ImageObserver.WIDTH) != 0 )
      m_image_dims.width = width;

    if( (infoflags & ImageObserver.HEIGHT) != 0 )
      m_image_dims.height = height;
    
    set_axes();

    return (m_image_dims.width == 0) || (m_image_dims.height == 0);
  }


  /**
   * Called when a complete mote packet is received -- this is where the object
   * position is calculated and filtered.  Accepts and decodes only
   * measurement packets from motes that fall within the mote grid.  Calculates
   * the object position and requests the BufferedPlot to repaint itself.
   * @param packet the complete mote packet
   */
  public void receive_packet( MotePacket packet )
  {
    if( packet.bytes.length != 36 )
      return;

    byte[] match = { 0x7e, 0x00, 0x04, (byte)0x86, 0x06, 0x00, 0x00, 0x00 };
    int n = match.length;

    for( int i=0; i<n; i++ )
      if( packet.bytes[i] != match[i] )
	return;

    int id = m_props.get_int("mote base id") + packet.bytes[n];
    int mag = (packet.bytes[n+1] & 0x0ff) | ((packet.bytes[n+2]&0x0ff)<<8);
    
    Mote mote = m_motes.get_mote_by_id( id );
    if( mote == null )
      return;

    mote.mag.set_value( mag );

    System.out.println( "    mag(0x" + Integer.toHexString(id) + ") = " + mag
       + "\t avg = ( " + (int)(1000*m_average.x)/1000.0 + ", "
       + (int)(1000*m_average.y)/1000.0 + " )"
     );
  }


  /**
   */
  public void update_position_display()
  {
    Point2D.Double avg_new = m_motes.mag_average( m_props.get_double("sense timeout") );

    if( avg_new != null )
    {
      Point2D.Double avg_old = m_average; // it's okay that it's just a reference not a copy
      double time_old = m_average_time;
      double time_new = LatchData.get_current_time();

      double w_old = Math.exp( Math.log(m_props.get_double("smoothing time constant"))
                               * (time_new - time_old) );
      double w_new = 1 - w_old;

      m_average.setLocation(
	  w_old * avg_old.x + w_new * avg_new.x,
	  w_old * avg_old.y + w_new * avg_new.y
	);
      m_average_time = time_new;

      m_track_list.addLast( new Track( m_average.x, m_average.y, m_average_time ) );
    }

    m_plot.repaint();
  }


  /**
   * Key listener methods
   */
  public void keyPressed( KeyEvent e )
  {
    switch( e.getKeyCode() )
    {
      case KeyEvent.VK_1:
        m_props.put_boolean( "do pan image",           false );
        m_props.put_boolean( "do overlay",             false );
        m_props.put_boolean( "do mark trail estimate", true );
        m_props.put_boolean( "do mark mote",           true );
        m_props.put_boolean( "do mote leader lights",  true );
        m_props.put_boolean( "do fancy mark mote",     true );
        m_props.put_boolean( "do trail",               true );
	break;

      case KeyEvent.VK_2:
        m_props.put_boolean( "do pan image",           true );
        m_props.put_boolean( "do overlay",             true );
        m_props.put_boolean( "do mark trail estimate", true );
        m_props.put_boolean( "do mark mote",           true );
        m_props.put_boolean( "do mote leader lights",  true );
        m_props.put_boolean( "do fancy mark mote",     false );
        m_props.put_boolean( "do trail",               true );
	break;

      case KeyEvent.VK_E:
        m_props.toggle_boolean( "do mark trail estimate" );
	break;

      case KeyEvent.VK_F:
        m_props.toggle_boolean( "do fancy mark mote" );
	break;

      case KeyEvent.VK_L:
        m_props.toggle_boolean( "do mote leader lights" );
	break;

      case KeyEvent.VK_M:
        m_props.toggle_boolean( "do mark mote" );
	break;

      case KeyEvent.VK_O:
        m_props.toggle_boolean( "do overlay" );
	break;

      case KeyEvent.VK_P:
        m_props.toggle_boolean( "do pan image" );
	break;

      case KeyEvent.VK_T:
        m_props.toggle_boolean( "do trail" );
	break;

      default:
	break;
    }
  }

  public void keyReleased( KeyEvent e ) 
  {
  }

  public void keyTyped( KeyEvent e ) 
  {
  }


  /**
   * Called when the off-screen buffer has been resized -- this is where the
   * axes are reconfigured.  (Well, actually in set_axes.)
   */
  public void plot_resized( BufferedPlot plot, Graphics2D g2 )
  {
    Dimension d = plot.getSize();
    m_plotrect = new Rectangle( 0, 0, d.width, d.height );
    set_axes();
  }


  /**
   * Configure the plot axes according to the size of the off-screen buffer.
   * @param plot bounds of the off-screen buffer
   */
  public void set_axes()
  {
    m_M2P_axes.set_axes0( m_props.getRect("mote bounds") );
    m_M2P_axes.set_axes1(
	new Rectangle2D.Double( 0, 0, m_image_dims.width-1, m_image_dims.height-1 )
      );

    AxesTransform axe = new AxesTransform();
    axe.set_axes0( m_M2P_axes.get_axes0() );
    axe.set_axes1( m_M2P_axes.get_axes1() );
    axe.square_axes0();
    m_square_mote_bounds.setRect( axe.get_axes0() );
    m_M2P_scale = axe.get_axes1().width / axe.get_axes0().width;

    Rectangle2D.Double overbou = m_props.getRect("overlay bounds");
    Rectangle2D.Double overoff = m_props.getRect("overlay offset");

    axe.set_axes0( overbou );
    axe.square_axes0();
    m_square_overlay_bounds.setRect( axe.get_axes0() );

    m_O2W_axes.set_axes0( m_square_overlay_bounds );
    m_O2W_axes.set_axes1( m_plotrect );
    m_O2W_axes.get_axes0().width  *= m_props.getRect("overlay shrink").width;
    m_O2W_axes.get_axes0().height *= m_props.getRect("overlay shrink").height;
    m_O2W_axes.square_axes1();
    m_O2W_axes.get_axes1().width  *= m_square_overlay_bounds.width  / overbou.width;
    m_O2W_axes.get_axes1().height *= m_square_overlay_bounds.height / overbou.height;

    axe.set_axes0( m_O2W_axes.get_axes0() );
    axe.set_axes1( m_O2W_axes.get_axes1() );
    axe.square_axes1();
    m_O2P_scale = axe.get_axes1().width / axe.get_axes0().width;

    double x0 = m_O2W_axes.to_x1( overbou.x + overbou.width  ) + m_O2P_scale * overoff.width;
    double y0 = m_O2W_axes.to_y1( overbou.y + overbou.height ) + m_O2P_scale * overoff.height;
    double x1 = m_plotrect.getX() + m_plotrect.getWidth();
    double y1 = m_plotrect.getY() + m_plotrect.getHeight();
    m_O2W_axes.get_axes1().x += x1 - x0;
    m_O2W_axes.get_axes1().y += y1 - y0;
  }


  /**
   * Called when the off-screen buffer wants an update -- this is when the
   * rendering of the visualization takes places.
   */
  public void render_to_plot( BufferedPlot plot, Graphics2D g2 )
  {
    double time_now = LatchData.get_current_time();
    Rectangle2D.Double mote_bounds = m_props.getRect("mote bounds");

    Mote maxmote = m_motes.get_maxmag_mote( time_now - m_props.get_double("sense timeout") );
    int maxmote_n = (maxmote == null) ? -1 : m_motes.get_n_from_id( maxmote.id );

    double avgx = m_M2P_axes.to_x1( m_average.x );
    double avgy = m_M2P_axes.to_y1( mote_bounds.height - m_average.y + 2*mote_bounds.y );

    double dw, dh, ax0, ay0;
    if( m_props.get_boolean("do pan image") )
    {
      dw  = m_props.getRect("view size").width;
      dh  = m_props.getRect("view size").height;
      ax0 = avgx;
      ay0 = avgy;
    }
    else
    {
      Rectangle2D.Double nopan_bounds = m_props.getRect("nopan view bounds");
      dw  = nopan_bounds.width;
      dh  = nopan_bounds.height;
      ax0 = m_M2P_axes.to_x1( nopan_bounds.x + dw/2 );
      ay0 = m_M2P_axes.to_y1( nopan_bounds.y + dh/2 );
    }

    double sx = (plot.getWidth()  * mote_bounds.width)  / (m_image_dims.width  * dw);
    double sy = (plot.getHeight() * mote_bounds.height) / (m_image_dims.height * dh);
    double k = sx < sy ? sx : sy;

    double tx = plot.getWidth()/2  - k*ax0;
    double ty = plot.getHeight()/2 - k*ay0;

    // draw the image

    g2.setTransform( new AffineTransform( k, 0, 0, k, tx, ty ) );
    g2.drawImage( m_scan_image, null, null );

    // draw mote positions on the image

    if( m_props.get_boolean("do mark mote") )
    {
      double mote_radius = m_props.get_double("mark mote radius");
      
      if( m_props.get_boolean("do fancy mark mote") )
      {
	for( int n=0; n<m_motes.size(); n++ )
	  render_mote( g2, m_motes.get_mote(n), time_now, mote_bounds, m_M2P_scale,
	               m_M2P_axes, mote_radius, (n == maxmote_n) );
      }
      else
      {
	g2.setColor( m_props.getColor("mark mote color") );
	for( int n=0; n<m_motes.size(); n++ )
	{
	  Mote mote = m_motes.get_mote(n);
	  double x = m_M2P_axes.to_x1( mote.xpos );
	  double y = m_M2P_axes.to_y1( mote_bounds.height - mote.ypos + 2*mote_bounds.y );
	  double r = m_M2P_scale * mote_radius;
	  g2.fill( new Arc2D.Double( x-r, y-r, 2*r, 2*r, 0, 360, Arc2D.OPEN ) );
	}
      }
    }

    // draw the tracked path on the image

    double trail_oldest = time_now - m_props.get_double("trail time");
    while( m_track_list.size() > 0 )
    {
      if( ((Track)m_track_list.getFirst()).time >= trail_oldest )
	break;
      m_track_list.removeFirst();
    }

    int num_trail = m_track_list.size();
    if( m_props.get_boolean("do trail") && (num_trail >= 2) )
    {
      g2.setStroke( new BasicStroke((float)m_props.get_double("trail width")) );
      g2.setColor( m_props.getColor("trail color") );

      GeneralPath path = new GeneralPath( GeneralPath.WIND_NON_ZERO, num_trail );
      ListIterator ii = m_track_list.listIterator(0);
      Point2D.Double pp = ((Track)ii.next()).pos;
      path.moveTo(
	(float)m_M2P_axes.to_x1(pp.x),
	(float)m_M2P_axes.to_y1(mote_bounds.height-pp.y+2*mote_bounds.y)
      );
      while( ii.hasNext() )
      {
	pp = ((Track)ii.next()).pos;
	path.lineTo(
	  (float)m_M2P_axes.to_x1(pp.x),
	  (float)m_M2P_axes.to_y1(mote_bounds.height-pp.y+2*mote_bounds.y)
	);
      }
      g2.draw( path );
    }

    // draw the trail estimate

    if( m_props.get_boolean("do mark trail estimate") )
    {
      double x0 = m_M2P_axes.to_x1( m_average.x );
      double y0 = m_M2P_axes.to_y1( mote_bounds.height - m_average.y + 2*mote_bounds.y );
      double ri = m_M2P_scale * m_props.get_double("trail estimate inner radius");
      double ro = m_M2P_scale * m_props.get_double("trail estimate radius");
      g2.setColor( m_props.getColor("overlay estimate color") );
      g2.fill( new Arc2D.Double( x0-ro, y0-ro, 2*ro, 2*ro, 0, 360, Arc2D.OPEN ) );
      g2.setColor( m_props.getColor("overlay estimate inner color") );
      g2.fill( new Arc2D.Double( x0-ri, y0-ri, 2*ri, 2*ri, 0, 360, Arc2D.OPEN ) );
    }

    // draw the overlay (bottom right)

    if( m_props.get_boolean("do overlay") )
    {
      g2.setTransform( new AffineTransform() );

      Rectangle2D.Double overlay_bounds = m_props.getRect("overlay bounds");
      double overlay_radius = m_props.get_double("overlay mote radius");

      double pad = m_O2P_scale * 1.25 * overlay_radius;
      double mx0 = m_O2W_axes.to_x1( overlay_bounds.x ) - pad;
      double my0 = m_O2W_axes.to_y1( overlay_bounds.y ) - pad;
      double mx1 = m_O2W_axes.to_x1( overlay_bounds.x + overlay_bounds.width  ) + pad;
      double my1 = m_O2W_axes.to_y1( overlay_bounds.y + overlay_bounds.height ) + pad;

      g2.setColor( m_props.getColor("overlay background color") );
      g2.fill( new Rectangle2D.Double( mx0, my0, mx1-mx0, my1-my0 ) );

      for( int n=0; n<m_motes.size(); n++ )
	render_mote( g2, m_motes.get_mote(n), time_now, overlay_bounds,
	             m_O2P_scale, m_O2W_axes, overlay_radius, (n == maxmote_n) );

      double x0 = m_O2W_axes.to_x1( m_average.x );
      double y0 = m_O2W_axes.to_y1( overlay_bounds.height - m_average.y + 2*overlay_bounds.y );
      double ri = m_O2P_scale * m_props.get_double("overlay estimate inner radius");
      double ro = m_O2P_scale * m_props.get_double("overlay estimate radius");
      g2.setColor( m_props.getColor("overlay estimate color") );
      g2.fill( new Arc2D.Double( x0-ro, y0-ro, 2*ro, 2*ro, 0, 360, Arc2D.OPEN ) );
      g2.setColor( m_props.getColor("overlay estimate inner color") );
      g2.fill( new Arc2D.Double( x0-ri, y0-ri, 2*ri, 2*ri, 0, 360, Arc2D.OPEN ) );
    }
  }

  /**
   * Precondition: g2's affine transform is the identity matrix
   */
  void render_mote( 
      Graphics2D g2,
      Mote mote,
      double timenow,
      Rectangle2D.Double bounds,
      double scale,
      AxesTransform axes,
      double radius,
      boolean is_leader
    )
  {
    double r = scale * radius;
    double x = axes.to_x1( mote.xpos );
    double y = axes.to_y1( bounds.height - mote.ypos + 2*bounds.y );
    
    g2.setColor( m_props.getColor("overlay mote color") );
    g2.fill( new Rectangle2D.Double( x-r, y-r, 2*r, 2*r ) );

    double radio_age = timenow - mote.mag.get_value_time();
    int n_radio = (int)(radio_age / m_props.get_double("radio bar time"));

    int n_sense = -1;
    if( radio_age < m_props.get_double("sense timeout") )
    {
      double sense_val = Math.log(mote.mag.get_value()) / Math.log(10);
      n_sense = (int)sense_val - 1;
    }

    double nn  = m_props.get_double("overlay meter size");
    double mx0 = x-r;
    double my0 = y-r;
    double dx  = 2*r / (4*nn+5);
    double dy  = 2*r / (4*nn+5);
    double ox1 = mx0 + dx;
    double ox2 = mx0 + r + dx/2;
    double oy  = my0 + dy;
    double ww  = r - 1.5*dx;
    double hh  = nn*dy;

    Color dim_color    = m_props.getColor("overlay meter dim color");
    Color radio_color  = m_props.getColor("overlay meter radio color");
    Color sense_color  = m_props.getColor("overlay meter sense color");
    Color leader_color = m_props.getColor("overlay meter leader color");
    boolean do_mote_leader_lights = m_props.get_boolean("do mote leader lights");

    Rectangle2D.Double rect = new Rectangle2D.Double( 0, 0, ww, hh );


    for( int ii=0; ii<4; ii++ )
    {
      rect.y = oy + ii*(dx+hh);

      g2.setColor( (n_radio <= ii) ? radio_color : dim_color );
      rect.x = ox1;
      g2.fill( rect );

      if( !do_mote_leader_lights )
      {
	g2.setColor( ((3-ii) <= n_sense) ? sense_color : dim_color );
	rect.x = ox2;
	g2.fill( rect );
      }
    }

    if( do_mote_leader_lights )
    {
      double rr = 0.5 * Math.min( ww, 2*hh+dx );
      double x0 = ox2 + 0.5*ww;
      double y0 = oy + hh + 0.5*dx;
      double y1 = oy + 3*hh + 2.5*dx;

      Arc2D.Double arc = new Arc2D.Double( x0-rr, y0-rr, 2*rr, 2*rr, 0, 360, Arc2D.OPEN );
      g2.setColor( is_leader ? leader_color : dim_color );
      g2.fill( arc );

      arc.y = y1-rr;
      g2.setColor( (n_sense != -1) ? sense_color : dim_color );
      g2.fill( arc );
    }
  }


  /**
   * Do some applet initialization.
   */
  public void init()
  {
    //Initialize the layout.
    setLayout( new BorderLayout() );
    m_plot = new BufferedPlot();
    m_plot.set_clear_color( m_props.getColor("background color") );
    m_plot.add_client( this );
    m_plot.addKeyListener( this );
    addKeyListener( this );
    add( m_plot );
  }


  /**
   * Command-line interface -- accept on the command-line the serial port name.
   * @param args command line arguments
   */
  public static void main(String args[])
    throws FileNotFoundException
  {
    String config_file = "aggregate_config.txt";
    String port = "";

    for( int i=0; i<args.length-1; i++ )
    {
      String opt = args[i];
      if( "-f".equals(opt) ) { config_file = args[++i]; }
      else { System.err.println("ERROR, unknown option " + opt); System.exit(1); }
    }
    
    if( args.length < 1 )
    {
      System.out.println( "usage: java aggregate [-f config.txt] [port]" );
      System.exit(0);
    }
    port = args[args.length-1];

    //System.out.println( "\nstarting aggregation" );
    aggregate self = new aggregate( port, config_file );

    // initialize the applet graphics components

    Frame f = new Frame( self.m_props.getString("title") );
    f.addWindowListener(
	new WindowAdapter() { public void windowClosing(WindowEvent e) {
	    System.out.println(
	        "On close, window size=" + e.getWindow().getSize()
		+ " location=" + e.getWindow().getLocation()
	      );
	    System.exit(0);
	  }
	}
      );

    f.add( "Center", self );
    f.addKeyListener( self );
    self.init();
    f.pack();
    f.setSize( new Dimension(
	(int)self.m_props.getRect("initial applet bounds").width,
	(int)self.m_props.getRect("initial applet bounds").height
      ) );
    f.setLocation( new Point(
        (int)self.m_props.getRect("initial applet bounds").x,
	(int)self.m_props.getRect("initial applet bounds").y
      ) );
    f.show();

    self.m_repainter.start();

    // Process mote packets
    try
    {
      self.m_packet_reader.printAllPorts();
      self.m_packet_reader.open();
      self.m_packet_reader.process_until_eof();
      self.m_repainter.dontrun();
    }
    catch( Exception e )
    {
      e.printStackTrace();
    }

    self.m_repainter.dontrun();
  }

}

