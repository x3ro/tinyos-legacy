package	edu.mit.mers.localization;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.io.*;

/**
 * The DisplayPanel draws the locations of the anchor nodes and the base node.
 * The panel also allows new anchors to be added by clicking on the desired
 * location, and displays the distance that each anchor thinks it is from the
 * base node.
 */
public class DisplayPanel extends JPanel implements MouseListener {
	
    private final static int NODE_RADIUS = 4;
    
	/**
	 * The location core for this display panel.
	 */
	private LocationCore core;
	

        private Image background = null, originalBackground = null;

    // Image scaling results.  Tell us how to offset background image and how wide it should be. (derived)
    private int xOff, yOff, actWidth, actHeight;
    private double limScale;

    // Image coordinates for the real-world coordinates (LOAD FROM DB!)
    private int img1x, img1y, img2x, img2y;
    // Real world coordinates for those image coordinates. (LOAD FROM DB!)
    private double rea1x, rea1y, rea2x, rea2y, reaDeltaX, reaDeltaY;

    // Image coordinates normalized to current screen coordinates, normalized for scaling (derived)
    private int scr1x, scr1y, scr2x, scr2y, scrDeltaX, scrDeltaY;

    // Maps hop distance to real-world distance. (LOAD FROM DB!)
    //  (specifically, we multiply the hop distance by this number to determine how much real-world
    //  distance it should represent (and also apply a per-anchor straightness correction.))
    private double unitDistanceScaleX = 12.5;
	private double unitDistanceScaleY = 15.0;

    private Image icons[];

	private boolean drawLocalization = true;

	/**
	 * Creates a new display panel that uses the specified core.
	 */
	public DisplayPanel(LocationCore core) {
	    super();
	    this.core = core;
	    addMouseListener(this);
	    this.setBackground(Color.white);

	   //setSize(originalBackground.getWidth(null), originalBackground.getHeight(null));
	    Toolkit toolkit = Toolkit.getDefaultToolkit();

	    icons = new Image[Node.NUM_TYPES];
	    icons[0] = toolkit.getImage("anchor.gif");
	    icons[1] = toolkit.getImage("substrate.gif");
	    icons[2] = null; // toolkit.getImage("relay.jpg");
	    icons[3] = toolkit.getImage("friend.gif");
	    icons[4] = toolkit.getImage("foe.gif");
	    icons[5] = toolkit.getImage("base.gif");
	}

    public void setCore(LocationCore core) {
	this.core = core;
    }

    public void initImage()
    {
	if((background == null) && (core != null) && (core.currentField != null))
	{
	    // load the background image
	    Toolkit toolkit = Toolkit.getDefaultToolkit();

	    originalBackground = toolkit.getImage(core.currentField.getBackgroundFile());	
	    background = originalBackground;
	}
    }

    public void setMoteFieldInfo(int img1x, int img1y, double rea1x, double rea1y,
				 int img2x, int img2y, double rea2x, double rea2y)
    {
	this.img1x = img1x;
	this.img1y = img1y;

	this.rea1x = rea1x;
	this.rea1y = rea1y;

	this.img2x = img2x;
	this.img2y = img2y;

	this.rea2x = rea2x;
	this.rea2y = rea2y;
    }

	public void toggleLocalizationDrawing()
	{
		drawLocalization = !drawLocalization;
	}

    private void scaleImage()
    {
	initImage();

	// first repaint the background image
	double xScale, yScale;
	xScale = (double)getWidth() / (double)background.getWidth(null);
	yScale = (double)getHeight() / (double)background.getHeight(null);
	
	limScale = Math.min(xScale, yScale);
	
	// int actWidth, actHeight;
	
	actWidth  = (int) Math.round(limScale * background.getWidth(null));
	actHeight = (int) Math.round(limScale * background.getHeight(null));
	
	int xLeftover, yLeftover;
	
	xLeftover = getWidth() - actWidth;
	yLeftover = getHeight() - actHeight;
	
	// int xOff, yOff;
	xOff = xLeftover / 2;
	yOff = yLeftover / 2;	

	// pre-calculate transform values
	reaDeltaX = rea2x - rea1x;
	reaDeltaY = rea2y - rea1y;

	scr1x = xOff + (int)Math.round(limScale * img1x);
	scr1y = yOff + (int)Math.round(limScale * img1y);

	scr2x = xOff + (int)Math.round(limScale * img2x);
	scr2y = yOff + (int)Math.round(limScale * img2y);

	scrDeltaX = scr2x - scr1x;
	scrDeltaY = scr2y - scr1y;

	//System.out.println("scr1x: " + scr1x + " scr1y: " + scr1y + " scr2x: " + scr2x + " scr2y: " + scr2y);
	//System.out.println("img1x: " + img1x + " img1y: " + img1y + " img2x: " + img2x + " img2y: " + img2y);
	//System.out.println("rea1x: " + rea1x + " rea1y: " + rea1y + " rea2x: " + rea2x + " rea2y: " + rea2y);
    }
	
    private int realToScreenX(double inx)
    {
	// Find our delta to the 1st point.
	double xdel = inx - rea1x;
	// Find relative distance between 2 points, range: [0.0, 1.0]
	double xrel = xdel / reaDeltaX;
	// Multiply relative distance between actual pixel distance.
	return (scr1x + (int)Math.round(xrel * scrDeltaX));
    }

    private int realToScreenY(double iny)
    {
	// Find our delta to the 1st point.
	double ydel = iny - rea1y;
	// Find relative distance between 2 points, range: [0.0, 1.0]
	double yrel = ydel / reaDeltaY;
	// Multiply relative distance between actual pixel distance.
	return (scr1y + (int)Math.round(yrel * scrDeltaY));
    }

    // Converts a real-world units distance to a screen-world units distance
    private int realToScreenDistX(double distx)
    {
	return (int)Math.round(distx * (scrDeltaX / reaDeltaX));
    }

    // Converts a real-world units distance to a screen-world units distance
    private int realToScreenDistY(double disty)
    {
	return (int)Math.round(disty * (scrDeltaY / reaDeltaY));
    }

	/**
	 * Paints the panel onto the specified graphics context. The anchor nodes
	 * are drawn as filled black circles, with a concentric circle indicating
	 * the distance from the anchor to the base node. The base node is drawn as
	 * a filled green circle. All nodes are labelled with their name.
	 */
	public void paint(Graphics g) {
	    super.paint(g);

	    if((core == null) || (core.currentField == null))
		return;

	    scaleImage();
	    
            g.drawImage(background, xOff, yOff, actWidth, actHeight, null);

	    int moteHalfX = realToScreenDistX(core.currentField.getMoteSize());
	    int moteHalfY = realToScreenDistY(core.currentField.getMoteSize());

	    // normalize, so things are square
	    moteHalfX = moteHalfY = Math.min(moteHalfX, moteHalfY);

	    int iconHalfX = realToScreenDistX(core.currentField.getIconSize());
	    int iconHalfY = realToScreenDistY(core.currentField.getIconSize());

	    iconHalfX = iconHalfY = Math.min(iconHalfX, iconHalfY);

		unitDistanceScaleX = core.currentField.getUnitDistanceScaleX();
		unitDistanceScaleY = core.currentField.getUnitDistanceScaleY();

	    FontMetrics fm = g.getFontMetrics();
	    int fontHeight = fm.getMaxAscent();

	    int trackThrow = Math.min(realToScreenDistX(core.currentField.getTrackThrow()),
				      realToScreenDistY(core.currentField.getTrackThrow()));
	    
	    double trackDelta = core.currentField.getTrackDelta();

           // then repaint everyone else

		
	    Node   n;
	    int x,y, lx, ly, rx, ry;
		
	    // Draw Nodes and distance-circles from anchors
	    Iterator iNodes = core.getNodes();
	    int curNodeNum  = 0;
	    int numNodes    = core.nodeCount();

	    // Draw Nodes
	    while(iNodes.hasNext()) {
		Node node = (Node)iNodes.next();
		if ((!core.isAnchor(node)) && node.isVisible())
		{
		    curNodeNum++;

		    Color nodeColor = Color.getHSBColor(((float)curNodeNum) / ((float)numNodes),
							node.isFound() ? 1.0f : 0.1f, 
							node.isFound() ? 0.7f : 0.7f);
		    g.setColor(nodeColor);			
		    x  = realToScreenX(node.getGroundX());
		    y  = realToScreenY(node.getGroundY());

		    //System.out.println("Mapping " + node.getGroundX() + "," + node.getGroundY() + 
		    //" to " + x + "," + y);
		
		    // Draw Node -- no longer scales...
		    g.fillOval(x-moteHalfX,y-moteHalfY,2*moteHalfX,2*moteHalfY);
		    //g.drawImage(icons[node.getMoteType()], x - moteHalfX, y - moteHalfY,
		    // moteHalfX * 2, moteHalfY * 2, null);
		    g.drawString(node.getIDasString(),x - (fm.stringWidth(node.getIDasString())/2),y-moteHalfY-1);
		    g.drawString(node.getName(),x - (fm.stringWidth(node.getName())/2),y+moteHalfY+1+fontHeight);

			if(drawLocalization)
			{

				// Draw Line to where they wish they think they are.
				lx = realToScreenX(node.getX());
				ly = realToScreenY(node.getY());
				
				g.drawOval(lx-moteHalfX,ly-moteHalfY,2*moteHalfX,2*moteHalfY);
	
				g.setColor(nodeColor.darker());
				g.drawLine(x, y, lx, ly);
	
				g.setColor(nodeColor);
				// Draw distance radii
				Iterator iAnchors = core.getAnchors();
				while(iAnchors.hasNext()) {
				Node anchor = (Node)iAnchors.next();
				
				// This _should_ account for straightness correction, but it does not.
				rx = realToScreenDistX(node.getDistance(anchor.getID()) * unitDistanceScaleX) + (node.getID() % realToScreenDistX(unitDistanceScaleX));
				ry = realToScreenDistY(node.getDistance(anchor.getID()) * unitDistanceScaleY) + (node.getID() % realToScreenDistX(unitDistanceScaleY));
	
				// In these cases x/groundX and y/groundY should be the same!
				x  = realToScreenX(anchor.getGroundX());
				y  = realToScreenY(anchor.getGroundY());
	
				g.drawOval(x-rx,y-ry,(2*rx),(2*ry));
				}
			}
		}
	    }

	    // Draw Anchors
	    Iterator iAnchors = core.getAnchors();
	    while(iAnchors.hasNext()) {
		Node anchor = (Node)iAnchors.next();
		g.setColor(Color.black);
		    
		x  = realToScreenX(anchor.getGroundX());
		y  = realToScreenY(anchor.getGroundY());

		g.fillOval(x-moteHalfX,y-moteHalfY,2*moteHalfX,2*moteHalfY);
		g.drawString(anchor.getIDasString(),x-(fm.stringWidth(anchor.getIDasString())/2),y-moteHalfY-1); 
	    }

	    // Draw Tags
	    int      curTagNum = 0;
	    int      numTags   = core.getNumTags();
	    Iterator iTags     = core.getTags();
	    while(iTags.hasNext()) {
		Tag tag = (Tag)iTags.next();
		g.setColor(Color.getHSBColor(((float)curTagNum) / ((float)numTags), 1.0f, 1.0f));
		curTagNum++;
		    
		x  = realToScreenX(tag.getX());
		y  = realToScreenY(tag.getY());

		g.drawImage(icons[tag.getTagType()], x - iconHalfX, y - iconHalfY,
			    iconHalfX * 2, iconHalfY * 2, null);
		g.drawString(tag.getName(),x-(fm.stringWidth(tag.getName())/2),y-iconHalfY-1);		    
		
		Iterator iObz = tag.getObservations();
		while (iObz.hasNext()) {
		    Map.Entry obs   = (Map.Entry)iObz.next();
		    Node node       = (Node)obs.getKey();
		    ArrayList obsRecs = (ArrayList)obs.getValue();
		    Iterator iObsRecs = obsRecs.iterator();
		    while (iObsRecs.hasNext()) {
			Tag.TagObservationRec rec = (Tag.TagObservationRec)iObsRecs.next();
			Date time = rec.time;
			double delta  = Tag.timeDelta(time);

			if (delta < 10.0) {
			    int trw = trackThrow - (int)(trackDelta * delta);
			    int trh = trackThrow - (int)(trackDelta * delta);
			    int tr = trackThrow - Math.min(realToScreenDistX(trackDelta * delta),
							   realToScreenDistY(trackDelta * delta));

			    x = realToScreenX(node.getGroundX());
			    y = realToScreenY(node.getGroundY());
			    
			    g.drawOval(x - tr, y - tr,(2*tr), (2*tr));
			}
		    }
		}
	    }
	}
	
	/**
	 * Create a new anchor when the mouse is clicked. The location is set
	 * between 0 and 1, based on the coordinates of the click ([0,0] = top left of
	 * panel, [1,1] = bottom right of panel). The ID of the new anchor is
	 * requested and the command is passed to the core.
	 */
	public void mouseClicked(MouseEvent e) {
	    /*
	    float x = (float)e.getX()/getWidth();
	    float y = (float)e.getY()/getHeight();
	    String valueStr = JOptionPane.showInputDialog(null,"Please enter node ID","Add Anchor",JOptionPane.QUESTION_MESSAGE);
	    if (valueStr == null) {
		return;
	    }
	    int nodeID = 0;
	    try {
		nodeID = Integer.decode(valueStr).intValue();
	    } catch(NumberFormatException ex) {
		JOptionPane.showMessageDialog(null, "Please enter an integer greater than 0.","Get Distance",JOptionPane.WARNING_MESSAGE);
		return;
	    }
	    if (nodeID<0) {
		JOptionPane.showMessageDialog(null, "Please enter an integer greater than or equal to 0.","Get Distance",JOptionPane.WARNING_MESSAGE);
		return;
	    }
	    core.addAnchor(nodeID,x,y);
	    */
	}
	
	/**
	 * This mouse event is ignored.
	 */
	public void mousePressed(MouseEvent e) {
	}
	
	/**
	 * This mouse event is ignored.
	 */
	public void mouseReleased(MouseEvent e) {
	}
	
	/**
	 * This mouse event is ignored.
	 */
	public void mouseEntered(MouseEvent e) {
	}
	
	/**
	 * This mouse event is ignored.
	 */
	public void mouseExited(MouseEvent e) {
	}
}
