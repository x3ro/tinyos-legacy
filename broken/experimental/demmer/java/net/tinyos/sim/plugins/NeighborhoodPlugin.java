// $Id: NeighborhoodPlugin.java,v 1.2 2003/10/20 22:35:57 mikedemmer Exp $


package net.tinyos.sim.plugins;

import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

public class NeighborhoodPlugin extends GuiPlugin implements SimConst {
  private static final int numberLinksToRemember = -1;
  private LinkHolder chosenEdges = new LinkHolder(numberLinksToRemember, "chosenEdges");
  private LinkHolder fixedEdges = new LinkHolder(numberLinksToRemember, "fixedEdges");
  private LinkHolder invalidEdges = new LinkHolder(numberLinksToRemember, "invalidEdges");

  public void handleEvent(SimEvent event) {
    if (event instanceof DebugMsgEvent) {
      DebugMsgEvent dme = (DebugMsgEvent)event;

      if (dme.getMessage().indexOf("YaoNeighborhoodM: getNeighbors called") != -1 ||
	  dme.getMessage().indexOf("YaoRegionM: getNodes called") != -1 ||
	  dme.getMessage().indexOf("YaoRegionM: initialize") != -1 ||
	  dme.getMessage().indexOf("KNRegionM: initialize") != -1) {

	fixedEdges.removeFrom(dme.getMoteID());
	chosenEdges.removeFrom(dme.getMoteID());
	invalidEdges.removeFrom(dme.getMoteID());
	motePanel.refresh();

      } else if (dme.getMessage().indexOf("NeighborhoodM: calcEdgesTask running") != -1 ||
	  dme.getMessage().indexOf("RegionM: calcEdgesTask running") != -1) {
	fixedEdges.removeFrom(dme.getMoteID());
	chosenEdges.removeFrom(dme.getMoteID());
	invalidEdges.removeFrom(dme.getMoteID());
	motePanel.refresh();

      } else if (dme.getMessage().indexOf("YaoNeighborhoodM: getNeighbors:") != -1 ||
	  dme.getMessage().indexOf("YaoRegionM: getNodes:") != -1 ||
	  dme.getMessage().indexOf("KNRegionM: getNodes:") != -1) {
	StringTokenizer st = new StringTokenizer(dme.getMessage());
	String skip;
	skip = st.nextToken();
	skip = st.nextToken();
	skip = st.nextToken();
	skip = st.nextToken();
	String nbr = st.nextToken();
	int nbr_addr;
	try {
	  nbr_addr = Integer.parseInt(nbr);
	} catch (Exception e) {
	  return;
	}
	nbLink link = new nbLink(dme.getMoteID(), nbr_addr);
	fixedEdges.addLink(link);
	tv.getMotePanel().refresh();

      } else if (dme.getMessage().indexOf("NeighborhoodM: Edge") != -1 ||
	  dme.getMessage().indexOf("YaoRegionM: Edge") != -1) {
	// For edge crossing messages
	//System.err.println(dme.getMessage());

      } else if (dme.getMessage().indexOf("NeighborhoodM: Choosing edge") != -1 ||
	  dme.getMessage().indexOf("YaoRegionM: Choosing edge") != -1) {
	StringTokenizer st = new StringTokenizer(dme.getMessage());
	String skip;
	skip = st.nextToken();
	skip = st.nextToken();
	skip = st.nextToken();
	String fs = st.nextToken();
	skip = st.nextToken();
	String ts = st.nextToken();
	int from_addr, to_addr;
	try {
	  from_addr = Integer.parseInt(fs);
	  to_addr = Integer.parseInt(ts);
	} catch (Exception e) {
	  return;
	}
	nbLink link = new nbLink(from_addr, to_addr);
	chosenEdges.addLink(link);
	tv.getMotePanel().refresh();

      } else if (dme.getMessage().indexOf("NeighborhoodM: Invalidating") != -1 ||
	  dme.getMessage().indexOf("RegionM: Invalidating") != -1) {
	StringTokenizer st = new StringTokenizer(dme.getMessage());
	String skip;
	skip = st.nextToken();
	skip = st.nextToken();
	String fs = st.nextToken();
	skip = st.nextToken();
	String ts = st.nextToken();
	int from_addr, to_addr;
	try {
	  from_addr = Integer.parseInt(fs);
	  to_addr = Integer.parseInt(ts);
	} catch (Exception e) {
	  return;
	}
	nbLink link = new nbLink(from_addr, to_addr);
	invalidEdges.addLink(link);
	motePanel.refresh();
      }
    } else if (event instanceof AttributeEvent) {
      AttributeEvent attributeEvent = (AttributeEvent)event;
      switch (attributeEvent.getType()) {
	case ATTRIBUTE_CHANGED:
	  if (attributeEvent.getAttribute() instanceof MoteCoordinateAttribute)
	    motePanel.refresh();
      }
    } 
  }

  public void register() {
    JTextArea ta = new JTextArea(3,40);
    ta.setFont(tv.defaultFont);
    ta.setEditable(false);
    ta.setBackground(Color.lightGray);
    ta.setLineWrap(true);
    ta.setText("Displays neighborhood relationships from the Neighborhood interface.");
    pluginPanel.add(ta);
  }
  public void deregister() {}
  public void reset() {
    chosenEdges = new LinkHolder(numberLinksToRemember, "chosenEdges");
    fixedEdges = new LinkHolder(numberLinksToRemember, "fixedEdges");
    invalidEdges = new LinkHolder(numberLinksToRemember, "invalidEdges");
    motePanel.refresh();
  }

  private void drawLine(Graphics g, 
      int x1, int y1, int x2, int y2, int lineWidth) {
    if (lineWidth == 1)
      g.drawLine(x1, y1, x2, y2);
    else {
      double angle;
      double halfWidth = ((double)lineWidth)/2.0;
      double deltaX = (double)(x2 - x1);
      double deltaY = (double)(y2 - y1);
      if (x1 == x2)
	angle=Math.PI;
      else
	angle=Math.atan(deltaY/deltaX)+Math.PI/2;
      int xOffset = (int)(halfWidth*Math.cos(angle));
      int yOffset = (int)(halfWidth*Math.sin(angle));
      int[] xCorners = { x1-xOffset, x2-xOffset+1,
	x2+xOffset+1, x1+xOffset };
	int[] yCorners = { y1-yOffset, y2-yOffset,
	  y2+yOffset+1, y1+yOffset+1 };
	  g.fillPolygon(xCorners, yCorners, 4);
    }
  }

  public void draw(Graphics graphics) {
    chosenEdges.draw(graphics, Color.gray);
    fixedEdges.draw(graphics, Color.green);
    invalidEdges.draw(graphics, Color.red);
  }

  public String toString() {
    return "Neighborhood graph";
  }

  private class nbLink {
    private int from;
    private int to;

    public nbLink(int from, int to) {
      this.from = from;
      this.to = to;
    }

    public int getFrom() {
      return from;
    }

    public int getTo() {
      return to;
    }

    public String toString() {
      return from+" -> "+to;
    }
  }

  private class LinkHolder {
    private Vector holder = new Vector();
    private int numLinks;
    private String name;

    public LinkHolder(int numLinks, String name) {
      this.numLinks = numLinks;
      this.name = name;
    }

    public Enumeration getLinks() {
      return holder.elements();
    }

    public void addLink(nbLink link) {
      if (holder.size() == numLinks) {
	holder.removeElementAt(0);
      }
      holder.add(link);
      //System.err.println(name+": Adding link: "+link+" size "+holder.size());
    }

    public void removeLink(nbLink link) {
      holder.remove(link);
    }

    public void removeFrom(int id) {
      Vector kill = new Vector();
      Enumeration enum = getLinks();
      while (enum.hasMoreElements()) {
	nbLink link = (nbLink)enum.nextElement();
	if (link.getFrom() == id) {
	  //System.err.println(name+": Removing link: "+link);
	  kill.addElement(link);
	}
      }
      holder.removeAll(kill);
    }

    public void draw(Graphics graphics, Color color) {
      Enumeration enum = getLinks();
      while (enum.hasMoreElements()) {
	nbLink link = (nbLink)enum.nextElement();
	//System.err.println(name+": Drawing link: "+link);
	int toaddr = link.getTo();
	int fromaddr = link.getFrom();

	try {
	  MoteSimObject moteFrom = state.getMoteSimObject(fromaddr);
	  MoteCoordinateAttribute moteFromCoordinate = moteFrom.getCoordinate();
	  MoteSimObject moteTo = state.getMoteSimObject(toaddr);
	  MoteCoordinateAttribute moteToCoordinate = moteTo.getCoordinate();
	  graphics.setColor(color);
	  drawLine(graphics,
	      (int)cT.simXToGUIX(moteFromCoordinate.getX()),
	      (int)cT.simYToGUIY(moteFromCoordinate.getY()),
	      (int)cT.simXToGUIX(moteToCoordinate.getX()),
	      (int)cT.simYToGUIY(moteToCoordinate.getY()), 4);
	} catch (NullPointerException e) {
	  // Ignore this link
	  continue;
	}
      }
    }
  }
}


