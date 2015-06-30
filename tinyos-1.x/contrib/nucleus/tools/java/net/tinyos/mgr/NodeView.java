import java.awt.*;
import java.awt.event.*;
import java.awt.geom.*;
import javax.swing.*;

public class NodeView extends JComponent {
  
  private Node node;
  private Point2D location;

  public static int NODE_WIDTH = 140;
  public static int NODE_HEIGHT = 78;

  private static int NODE_SPACE_TOP = 4;
  private static int NODE_SPACE_SIDE = 12;

  private static int ICON_SIZE = 24;
  private static int ICON_SPACE_TOP = 20;
  
  public NodeView(Node node) {
    this.node = node;
    this.location = new Point(0,0);
  }

  public Dimension getMinimumSize() {
    return new Dimension(NODE_WIDTH, NODE_HEIGHT);
  }

  public Dimension getPreferredSize() {
    return new Dimension(NODE_WIDTH, NODE_HEIGHT);
  }

  public int getWidth() {
    return NODE_WIDTH;
  }

  public int getHeight() {
    return NODE_HEIGHT;
  }

  public void setLocation(Point2D p) {
    location = p;
  }

  public void paintComponent(Graphics g) {
    Graphics2D g2 = (Graphics2D) g;
    g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, 
			RenderingHints.VALUE_ANTIALIAS_ON);
    
/*
    g2.draw(new Rectangle2D.Double(location.getX(),
				   location.getY(),
				   NODE_WIDTH,
				   NODE_HEIGHT));
*/

    g2.draw(new Ellipse2D.Double(location.getX() + ((NODE_WIDTH - ICON_SIZE) / 2), 
				 location.getY() + NODE_SPACE_TOP + ICON_SPACE_TOP,

				 ICON_SIZE, 
				 ICON_SIZE));

    if (node.isInactive()) {
      g2.setColor(new Color(200, 0, 0));
    } else {
      g2.setColor(new Color(128, 128, 255));
    }

    g2.fill(new Ellipse2D.Double(location.getX() + ((NODE_WIDTH - ICON_SIZE) / 2), 
				 location.getY() + NODE_SPACE_TOP + ICON_SPACE_TOP,
				 ICON_SIZE, 
				 ICON_SIZE));

    if (node.isBooting()) {

      g2.setColor(new Color(200, 0, 0));

      g2.draw(new Ellipse2D.Double(location.getX() + ((NODE_WIDTH - ICON_SIZE) / 2) - 2, 
				   location.getY() + NODE_SPACE_TOP + ICON_SPACE_TOP - 2,
				   
				   ICON_SIZE + 4, 
				   ICON_SIZE + 4));      
    }

    g2.setColor(Color.BLACK);

    g2.setFont(new Font("Arial", Font.PLAIN, 12));

    String addr = "" + node.getAddr();

    FontMetrics metrics = g2.getFontMetrics();
    int width = metrics.stringWidth( addr );
    int height = metrics.getHeight();
    int height12pt = height;

    g2.drawString( addr, 
		   (float)location.getX() + NODE_WIDTH/2 - width/2, 
		   (float)location.getY() + NODE_SPACE_TOP + ICON_SPACE_TOP 
		   + ICON_SIZE + height );

    if (node.getID() != null && !node.getID().equals("FF:FF:FF:FF:FF:FF:FF:FF")) {

      String id = "" + node.getID();

      g2.setFont(new Font("Arial", Font.PLAIN, 10));
      metrics = g2.getFontMetrics();
      height = metrics.getHeight();
      
      width = metrics.stringWidth( id );
      
      g2.drawString( id, 
		     (float)location.getX() + NODE_WIDTH/2 - width/2, 
		     (float)location.getY() + NODE_SPACE_TOP + ICON_SPACE_TOP 
		     + ICON_SIZE + height12pt + height );
    }

    String str = node.getRecentWatchableValue();
    width = metrics.stringWidth( str );

    g2.drawString( str,  
		   (float)location.getX() + NODE_WIDTH/2 - width/2, 
		   (float)location.getY() + NODE_SPACE_TOP + height );
    
/*

    for (int i = 1; i <= 3; i++) {

      g2.drawString( str, 
		     (float)location.getX() + NODE_WIDTH - NODE_SPACE_SIDE 
		     - width + 2,
		     (float)location.getY() + NODE_SPACE_TOP + i * height );
    }
*/
  }

}
