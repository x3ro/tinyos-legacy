/*
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
package net.tinyos.task.taskviz;

import java.awt.*;
import java.awt.image.*;
import java.awt.event.*;
import java.awt.geom.*;
import javax.swing.*;
import java.util.*;
import java.io.File;
import java.io.IOException;
import javax.swing.border.*;

import edu.umd.cs.jazz.*;
import edu.umd.cs.jazz.component.*;
import edu.umd.cs.jazz.event.*;
import edu.umd.cs.jazz.util.*;

import net.tinyos.task.taskapi.*;
import net.tinyos.task.taskviz.sensor.SensorMotes;
import net.tinyos.task.taskviz.sensor.SensorMote;
import net.tinyos.task.taskviz.sensor.SensorLine;

/**
 * This class is a visualization of environmental data: heat and light, along with network route information. 
 * The visualization reads the data from the database at a regular interval (every 60 seconds) and updates 
 * the display. Temperature and light can be visualized as transparent circles: temperature varying between
 * blue and red, light with shades of gray; or they can be visualized as a gradient map. Routing information
 * between sensor nodes are shown with a red line between a node and its parent and a green line between a node
 * and any other node it can communicate with.
 */
public class TASKVisualization implements TASKResultListener {

  /**
   * Route information
   */
  public static final String ROUTE = "Route";

  /**
   * Pan mode for interaction
   */
  public static final int PAN_MODE = 1;

  /**
   * Put the visualization in no interaction mode
   */
  public static final int NO_MODE = 2;

  /**
   * Select mode for interaction
   */
  public static final int SELECT_MODE = 3;

  /**
   * Width of the scrolling pane
   */
  public static final int SCROLL_WIDTH = 750;

  /**
   * Height of the scrolling pane
   */
  public static final int SCROLL_HEIGHT = 500;

    static float MIN_VAL = 0;
    static float MAX_VAL = 100;
    static final int STEP_SIZE = 25;
    Color fromColor = new Color(0f,0f,1.0f,1.0f);
    Color toColor = new Color(1.0f,0f,0f,1.0f);
    
    public ZGroup gradientGroup;

  public int sensorType;
  private GregorianCalendar cal;
  private ZEventHandler currentEventHandler = null;
  private ZPanEventHandler panEventHandler = null;
  private ZoomEventHandler zoomEventHandler = null;
  private MoveEventHandler2 moveEventHandler = null;
  private ZCompositeSelectionHandler selectionHandler = null;

//  private ToolBarButton pan, select;

  private JToggleButton pan, select;

  ZImageCanvas canvas = null;
  JScrollPane scrollPane, scrollPane2;
  JMenu viz, sensor;
  ZLayerGroup layer;
  ZGroup routeGroup;
  SensorMotes motes = new SensorMotes();
  private Configuration config;
  int imageWidth, imageHeight;

  private TASKClient client;
  private int healthQueryId;
  private int sensorQueryId;
  public int healthSamplePeriod;
  private JRadioButtonMenuItem[] sensorItems = new JRadioButtonMenuItem[20];
  private int sensorIndex = -1;

  private DefaultListModel unknownNodesModel;
  private JList unknownNodesList;
    
    private boolean doGradient = false;

  java.util.Timer timer;

  private JFrame parentFrame;
  private JPanel parentPanel;
  private TASKVisualizer parent;

    private ZRectangle gRects[][] = null;
    
    private JPanel mainPanel;
    private SpringLayout layout;

    SpringLayout.Constraints toolbarCons;

  /**
   * Constructor for the sensor network visualization using default TASK Server port
   *
   * @param host TASKServer host
   */
  public TASKVisualization(JFrame parentFrame, TASKVisualizer parent, TASKClient client, JPanel parentPanel) {


    this.parentFrame = parentFrame;
    this.parent = parent;
    this.client = client;
    this.parentPanel = parentPanel;
    layout = new SpringLayout();
    mainPanel = new JPanel(layout);
    parentPanel.addComponentListener(new ComponentAdapter() {
	    public void componentResized(ComponentEvent event) {
//  		int wid = event.getComponent().getWidth();
//  		int hgt = event.getComponent().getHeight();
		
//  		System.out.println("Width = " + wid + ", Height = " + hgt);
//  		mainPanel.resize(wid,hgt);
//  		if (scrollPane != null) {
//  		    scrollPane.resize(wid-100,hgt-100);
//  		}
		//  		if (config != null) preparePanel(config);
	    }
	});
    
    mainPanel.setMinimumSize(new Dimension(200,200));
    mainPanel.setMaximumSize(new Dimension(1000,1000));
    mainPanel.setPreferredSize(new Dimension(parentFrame.getWidth(),
    					     parentFrame.getHeight()));
    
    parentPanel.add(mainPanel);

    
  }


    public static void setComponentSizes(Container parent, int pad) {
        SpringLayout layout = (SpringLayout) parent.getLayout();
        Component[] components = parent.getComponents();
        Spring maxHeightSpring = Spring.constant(0);
	Spring topSpring;

        SpringLayout.Constraints pCons = layout.getConstraints(parent);
        //Set the container's max X to the max X
        //of its rightmost component + padding.
        Component rightmost = components[components.length - 1];
        SpringLayout.Constraints rCons =
                layout.getConstraints(rightmost);
	rCons.setConstraint(SpringLayout.EAST,
			     Spring.sum(Spring.constant(pad),
					pCons.getConstraint(SpringLayout.EAST)));


	maxHeightSpring = Spring.sum(Spring.constant(pad), pCons.getConstraint(SpringLayout.SOUTH));
	topSpring = pCons.getConstraint(SpringLayout.NORTH);

        for (int i = 0; i < components.length; i++) {
	    SpringLayout.Constraints cons =
		layout.getConstraints(components[i]);
	    cons.setConstraint(SpringLayout.SOUTH,
				maxHeightSpring);
	    cons.setConstraint(SpringLayout.NORTH,
				topSpring);

		
        }


    }

    public static void setContainerSize(Container parent,
                                        int pad) {
        SpringLayout layout = (SpringLayout) parent.getLayout();
        Component[] components = parent.getComponents();
        Spring maxHeightSpring = Spring.constant(0);
        SpringLayout.Constraints pCons = layout.getConstraints(parent);

        //Set the container's max X to the max X
        //of its rightmost component + padding.
        Component rightmost = components[components.length - 1];
        SpringLayout.Constraints rCons =
                layout.getConstraints(rightmost);
        pCons.setConstraint(
                SpringLayout.EAST,
                Spring.sum(Spring.constant(pad),
                           rCons.getConstraint(SpringLayout.EAST)));

        //Set the container's max Y to the max Y of its tallest
        //component + padding.
        for (int i = 0; i < components.length; i++) {
            SpringLayout.Constraints cons =
                layout.getConstraints(components[i]);
            maxHeightSpring = Spring.max(maxHeightSpring,
                                         cons.getConstraint(
                                                SpringLayout.SOUTH));
        }
        pCons.setConstraint(
                SpringLayout.SOUTH,
                Spring.sum(Spring.constant(pad),
                           maxHeightSpring));
   }


  public void preparePanel(Configuration config) {
    this.config = config;

    mainPanel.removeAll();

    unknownNodesModel = new DefaultListModel();
    unknownNodesList = new JList(unknownNodesModel);
    scrollPane2 = new JScrollPane(unknownNodesList);

    motes = getSensorMotes();

    sensor = new JMenu("Sensor");
    sensor.setMnemonic(KeyEvent.VK_S);
    ButtonGroup group = new ButtonGroup();

    TASKQuery healthQuery = client.getHealthQuery();
    
    int i=0;
    if (healthQuery != null) {
      Vector v = healthQuery.getSelectEntries();

      for (i=0; i<v.size(); i++) {
        String fieldName = ((TASKAttrExpr)v.elementAt(i)).getAttrName();
        sensorItems[i] = new JRadioButtonMenuItem(fieldName);
        sensorItems[i].setActionCommand(String.valueOf(i));
        sensorItems[i].setToolTipText(fieldName);
        sensorItems[i].addActionListener(new ActionListener() {
          public void actionPerformed(ActionEvent ae) {
            JRadioButtonMenuItem item = (JRadioButtonMenuItem)ae.getSource();
            int command = Integer.parseInt(item.getActionCommand());
            int color = 0;
            if (command%4 == 0) {
              color = SensorMote.GRAY;
            }
            else if (command%4 == 1) {
              color = SensorMote.RED;
            }
            else if (command%4 == 2) {
              color = SensorMote.BLUE;
            }
            else {
              color = SensorMote.GREEN;
            }
            sensorType = command+1;
System.out.println("SWITCHING TO: healthType: "+sensorType+" with color: "+color);
            for (Enumeration e=motes.elements(); e.hasMoreElements(); ) {
              SensorMote sm = (SensorMote)e.nextElement();
              sm.setSensorToVisualize(sensorType);
              sm.setColorScheme(color, 1024);
            }
          }
        });
        group.add(sensorItems[i]);
        sensor.add(sensorItems[i]);
      }
    }

    sensorIndex = i;
    TASKQuery sensorQuery = client.getSensorQuery();
    if (sensorQuery != null) {
      Vector v = sensorQuery.getSelectEntries();

      for (int j=0; j<v.size(); j++) {
        String fieldName = ((TASKAttrExpr)v.elementAt(j)).getAttrName();
        sensorItems[j+i] = new JRadioButtonMenuItem(fieldName);
        sensorItems[j+i].setActionCommand(String.valueOf(j+i));
        sensorItems[j+i].setToolTipText(fieldName);
System.out.println("created sensor item: "+(j+i));
        sensorItems[j+i].addActionListener(new ActionListener() {
          public void actionPerformed(ActionEvent ae) {
            JRadioButtonMenuItem item = (JRadioButtonMenuItem)ae.getSource();
            int command = Integer.parseInt(item.getActionCommand());
            int color = 0;
            if (command%4 == 0) {
              color = SensorMote.GRAY;
            }
            else if (command%4 == 1) {
              color = SensorMote.RED;
            }
            else if (command%4 == 2) {
              color = SensorMote.BLUE;
            }
            else {
              color = SensorMote.GREEN;
            }
            sensorType = command+1;
System.out.println("SWITCHING TO: sensorType: "+sensorType+" with color: "+color);
            for (Enumeration e=motes.elements(); e.hasMoreElements(); ) {
              SensorMote sm = (SensorMote)e.nextElement();
              sm.setSensorToVisualize(sensorType);
              sm.setColorScheme(color, 1024);
            }
          }
        });

        group.add(sensorItems[j+i]);
        sensor.add(sensorItems[j+i]);
      }
    }   

    sensor.addSeparator();
    JCheckBoxMenuItem route = new JCheckBoxMenuItem(ROUTE, true);
    route.setActionCommand(ROUTE);
    route.setToolTipText(ROUTE);
    route.addItemListener(new ItemListener() {
      public void itemStateChanged(ItemEvent ie) {
        if (ie.getStateChange() == ItemEvent.SELECTED) {
          layer.addChild(routeGroup);
        }
        else if (ie.getStateChange() == ItemEvent.DESELECTED) {
          layer.removeChild(routeGroup);
        }
      }
    });
    sensor.add(route);

    JCheckBoxMenuItem showGradient = new JCheckBoxMenuItem("Show Gradient", false);
    showGradient.setActionCommand("Show Gradient");
    showGradient.setToolTipText("Show Gradient");
    showGradient.addItemListener(new ItemListener() {
      public void itemStateChanged(ItemEvent ie) {
        if (ie.getStateChange() == ItemEvent.SELECTED) {
	    System.out.println("GRADIENT ENABLED");
	    layer.addChild(gradientGroup);
	    layer.raiseTo(gradientGroup,canvas.getLeaf());
	    doGradient = true;
        }
        else if (ie.getStateChange() == ItemEvent.DESELECTED) {
	    System.out.println("GRADIENT DISABLED");
	    layer.removeChild(gradientGroup);
	    doGradient = false;
        }
      }
    });
    sensor.add(showGradient);

    JMenuItem sensorRange = new JMenuItem("Set Sensor Range...");
    sensorRange.addActionListener(new ActionListener() {
	    public void actionPerformed(ActionEvent e) {
		selectItemRange();
		recomputeGradient();
	    }
	});
    sensor.add(sensorRange);

    JMenuItem fromColorMenu = new JMenuItem("Set From Color...");
    fromColorMenu.addActionListener(new ActionListener() {
	    public void actionPerformed(ActionEvent e) {
		JColorChooser choose = new JColorChooser(fromColor);
		Color myColor= choose.showDialog(parentFrame, "Select Color for the Minimum Value",fromColor);
		if (myColor != null)
		    fromColor = myColor;
		recomputeGradient();
	    }
	});
    sensor.add(fromColorMenu);

    JMenuItem toColorMenu = new JMenuItem("Set To Color...");
    toColorMenu.addActionListener(new ActionListener() {
	    public void actionPerformed(ActionEvent e) {
		JColorChooser choose = new JColorChooser(toColor);
		Color myColor = choose.showDialog(parentFrame, "Select Color for the Maximum Value",toColor);
		if (myColor != null)
		    toColor = myColor;
		recomputeGradient();
	    }
	});
    sensor.add(toColorMenu);
    
    JToolBar toolBar = createToolBar();
    mainPanel.add(toolBar);
      toolbarCons = layout.getConstraints(toolBar);
      toolbarCons.setX(Spring.constant(5));    
      toolbarCons.setY(Spring.constant(5));

    
    parent.removeSensorMenu();
    parent.addSensorMenu(sensor);


    viewConfiguration();
    //setComponentSizes(mainPanel,5);
  }

  /**
   * Creates a toolbar to allow panning of the frame
   *
   * @return the created toolbar
   */ 
  private JToolBar createToolBar() {
    JToolBar toolbar = new JToolBar(JToolBar.VERTICAL);
    ButtonGroup group = new ButtonGroup();
    Insets margins = new Insets(0, 0, 0, 0);

/*    pan = new ToolBarButton("images/P.gif");
    pan.setSelectedIcon(new ImageIcon("images/P-selected.gif"));
*/
    pan = new JToggleButton("Pan view");
    pan.setToolTipText("Pan view");
    pan.setMargin(margins);
    pan.setActionCommand("pan");
    pan.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        setMode(PAN_MODE);
      }
    });
    toolbar.add(pan);
    group.add(pan);

/*    select = new ToolBarButton("images/S.gif");
    select.setSelectedIcon(new ImageIcon("images/S-selected.gif"));
*/
    select = new JToggleButton("Select motes");
    select.setToolTipText("Select motes to graph");
    select.setMargin(margins);
    select.setActionCommand("select");
    select.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        setMode(SELECT_MODE);
      }
    });
    toolbar.add(select);
    group.add(select);

/*    ToolBarButton graph = new ToolBarButton("images/G.gif");
*/
    JToggleButton graph = new JToggleButton("Graph data");
    graph.setToolTipText("Graph data");
    graph.setMargin(margins);
    graph.setActionCommand("graph");
    graph.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        Vector v = new Vector();
        Component menuitems[] = sensor.getMenuComponents();
        for (int i=0; i<menuitems.length; i++) {
          if (menuitems[i] instanceof JMenuItem) {
            JMenuItem menuitem = (JMenuItem)menuitems[i];
            if (!menuitem.getText().equalsIgnoreCase("nodeid")) {
              v.addElement(menuitem.getText());
            }
          }
        }

        AttributeSelectDialog asd = new AttributeSelectDialog(parentFrame, v);
        asd.pack();
        asd.setLocationRelativeTo(parentFrame);
        asd.setVisible(true);
        if (asd.isDataValid()) {
          Vector attributes = asd.getSelectedAttributes();
          attributes.insertElementAt("nodeid",0);
          Collection c = selectionHandler.getSelectionModifyHandler().getCurrentSelection();
          if (c.size() > 0) {
            Vector nodes = new Vector();
            for (Iterator i=c.iterator(); i.hasNext(); ) {
              ZVisualComponent zvc = ((ZVisualLeaf)i.next()).getFirstVisualComponent();
              if (zvc instanceof Mote) {
                nodes.addElement(new Integer(((Mote)zvc).getId()));
              }
            }
            new ResultFrame(client, nodes, attributes);
          }
        }
      }
    });
    toolbar.add(graph);

    toolbar.setFloatable(true);
    toolbar.setMaximumSize(new Dimension(100,200));
    toolbar.setPreferredSize(new Dimension(100,200));
    toolbar.setMinimumSize(new Dimension(100,500));

    return toolbar;
  }

  /**
   * This method renders the configuration to the screen
   */  
  private void viewConfiguration() {
    // do view stuff here

// AKDNEW - shouldn't need this after testing
/*
    Vector hselects = new Vector();
    hselects.addElement("voltage");
    TASKQuery hquery = new TASKQuery(hselects, new Vector(), 1000, null);
    int hq = client.submitHealthQuery(hquery);
*/
    TASKQuery healthQuery = client.getHealthQuery();
    if (healthQuery != null) {
      healthQueryId = healthQuery.getQueryId();
    }

/*    Vector sselects = new Vector();
    sselects.addElement("temperature");
    TASKQuery squery = new TASKQuery(sselects, new Vector(), 1000, null);
    int sq = client.submitSensorQuery(squery);
*/
    TASKQuery sensorQuery = client.getSensorQuery();
    if (sensorQuery != null) {
      sensorQueryId = sensorQuery.getQueryId();
    }

    // render image
    if (config.useBlankImage()) {
      imageWidth = config.getImageWidth();
      imageHeight = config.getImageHeight();
      canvas = new ZImageCanvas(imageWidth, imageHeight);
    }
    else {
      ImageIcon icon = new ImageIcon(config.getImageName(), config.getImageName());
      Image base = icon.getImage();
      imageHeight = base.getHeight(null);
      imageWidth = base.getWidth(null);
      canvas = new ZImageCanvas(base);
    }

    // render surrounding rectangle
    layer = canvas.getLayer();
    ZLine line = new ZLine(config.getMinimumPixelX(), config.getMinimumPixelY(), 
                           config.getMaximumPixelX(), config.getMinimumPixelY());
    ZVisualLeaf leaf = new ZVisualLeaf(line);
    leaf.setSelectable(false);
    layer.addChild(leaf);

    line = new ZLine(config.getMinimumPixelX(), config.getMinimumPixelY(), 
                     config.getMinimumPixelX(), config.getMaximumPixelY());
    leaf = new ZVisualLeaf(line);
    leaf.setSelectable(false);
    layer.addChild(leaf);

    line = new ZLine(config.getMaximumPixelX(), config.getMinimumPixelY(), 
                     config.getMaximumPixelX(), config.getMaximumPixelY());
    leaf = new ZVisualLeaf(line);
    leaf.setSelectable(false);
    layer.addChild(leaf);

    line = new ZLine(config.getMinimumPixelX(), config.getMaximumPixelY(), 
                     config.getMaximumPixelX(), config.getMaximumPixelY());
    leaf = new ZVisualLeaf(line);
    leaf.setSelectable(false);
    layer.addChild(leaf);


    //render overlay
    int width = config.getMaximumPixelX() - config.getMinimumPixelX();
    int height = config.getMaximumPixelY() - config.getMinimumPixelY();
    int stepSize = STEP_SIZE;
    int stepsX = width/stepSize;
    int stepsY = height/stepSize;
    gRects = new ZRectangle[stepsX][stepsY];
    gradientGroup = new ZGroup();

    for (int i = 0; i < stepsX; i++) {
	for (int j = 0; j < stepsY; j++) {
	    Paint p = getPaintForPixel(i * stepSize, j * stepSize, width, height);
	    ZRectangle r = new ZRectangle((i * stepSize), (j * stepSize), stepSize, stepSize);
	    r.setFillPaint(p);
	    r.setPenWidth(0);
	    r.setPenPaint(new Color(0f,0f,0f,0f));
	    leaf = new ZVisualLeaf(r);
	    leaf.setSelectable(false);
	    gradientGroup.addChild(leaf);
	    gRects[i][j] = r;
	}
    }
    if (doGradient) layer.addChild(gradientGroup);

    // render motes
    for (Enumeration e=motes.elements(); e.hasMoreElements(); ) {
      SensorMote sm = (SensorMote)e.nextElement();
      leaf = new ZVisualLeaf(sm);
      layer.addChild(leaf);
      layer.raise(leaf);
    }


    routeGroup = new ZGroup();
    routeGroup.setSelectable(false);
    layer.addChild(routeGroup);

    //parentPanel.add(mainPanel);

    // add scroll pane
    int x=0, y = 0;
    if (imageWidth > SCROLL_WIDTH) {
      x = SCROLL_WIDTH;
    }
    else {
      x = imageWidth;
    }

    if (imageHeight > SCROLL_HEIGHT) {
      y = SCROLL_HEIGHT;
    }
    else {
      y = imageHeight;
    }

    
    scrollPane = new ZScrollPane(canvas);
    
    scrollPane.setMaximumSize(new Dimension(Integer.MAX_VALUE,Integer.MAX_VALUE));
    scrollPane.setPreferredSize(new Dimension(x+20,y+20));
    scrollPane.setMinimumSize(new Dimension(200,200));
    //scrollPane.setPreferredSize(new Dimension(400,400));

    mainPanel.add(scrollPane);
    SpringLayout.Constraints scrollCons = layout.getConstraints(scrollPane);
    scrollCons.setX(Spring.sum(Spring.constant(5), 
			       toolbarCons.getConstraint(SpringLayout.EAST)));
    scrollCons.setY(Spring.constant(5));
    
    JPanel unknownNodesPanel = new JPanel();
    Border b = BorderFactory.createBevelBorder(BevelBorder.LOWERED);
    unknownNodesPanel.setBorder(BorderFactory.createTitledBorder(b,"Unknown Nodes"));
    unknownNodesPanel.add(scrollPane2);
    unknownNodesPanel.setMaximumSize(new Dimension(150,200));
    unknownNodesPanel.setMinimumSize(new Dimension(150,200));
    unknownNodesPanel.setPreferredSize(new Dimension(150,200));


    mainPanel.add(unknownNodesPanel);
      SpringLayout.Constraints  cons = layout.getConstraints(unknownNodesPanel);
      cons.setX(Spring.sum(Spring.constant(5), 
  			 scrollCons.getConstraint(SpringLayout.EAST)));
      cons.setY(Spring.constant(5));

    // create event handlers
    panEventHandler = new ZPanEventHandler(canvas.getCameraNode());
    zoomEventHandler = new ZoomEventHandler(canvas.getCameraNode());
    moveEventHandler = new MoveEventHandler2(canvas, imageWidth, imageHeight, true);
    selectionHandler = new ZCompositeSelectionHandler(canvas.getCameraNode(), canvas, canvas.getLayer(), ZCompositeSelectionHandler.MODIFY);
    zoomEventHandler.setActive(true);
    moveEventHandler.setActive(true);

    if (healthQuery != null) {
      client.addHealthResultListener(this);
      if (timer != null) {
        timer.cancel();
      }
      timer = new java.util.Timer();
      healthSamplePeriod = healthQuery.getSamplePeriod();
      timer.schedule(new Task(), 0, 10*healthSamplePeriod);
    }
    if (sensorQuery != null) {
      client.addSensorResultListener(this);
    }

  }

    //set the min and max values for the attribute in the visualization
    public void selectItemRange() {
	String s = (String)JOptionPane.showInputDialog(mainPanel,
						       "Specify a maximum value:",
						       "Maximum Value",
						       JOptionPane.PLAIN_MESSAGE,
						       null, null, new Integer((int)MAX_VAL).toString());
						       
	if ((s != null) && (s.length() > 0)) {
	    try {
		MAX_VAL = (float)(new Integer(s).intValue());
	    } catch (NumberFormatException e) {
	    }
	}
	
	s = (String)JOptionPane.showInputDialog(mainPanel,
						"Specify a minimum value:",
						"Minimum Value",
						JOptionPane.PLAIN_MESSAGE,
						null, null, new Integer((int)MIN_VAL).toString());
						       
	if ((s != null) && (s.length() > 0)) {
	    try {
		MIN_VAL = (float)(new Integer(s).intValue());
	    } catch (NumberFormatException e) {
	    }
	}
    }

    public Paint getPaintForPixel(int x, int y, int width, int height) {
	//scan through each mote, computing it's weight on this point
	// then compute a "reading" for the point
	// the map that "reading" into a color
	// then construct a paint with the color and certain level of transparency
	
	long weights[] = new long[motes.size()];
	Color colors[] = new Color[motes.size()];
	if (x > width / 2) width -= (width-x);
	else width -= x;
	if (y > height / 2) height -= (height-y);
	else height -= y;
	long maxDist = (int)Math.sqrt((double)(width*width + height*height));
	long totalWeight = 0;
	float r=0f,g=0f,b=0f;
	int curi = -1;
	Enumeration e = motes.elements();

	while (e.hasMoreElements()) {
	    SensorMote m = (SensorMote)e.nextElement();
	    
	    curi++;
	    int xInt = (int)m.getX();
	    int yInt = (int)m.getY();
	    float sensorValue = (float)m.getSensorValue(m.getSensorToVisualize());
	    weights[curi] = maxDist-(int)distance(x,y,xInt,yInt);
	    weights[curi] *= weights[curi] * weights[curi];
	    if (sensorValue > MAX_VAL) sensorValue = MAX_VAL;
	    if (sensorValue < MIN_VAL) {
		sensorValue = MIN_VAL;
		weights[curi] = 0;
	    }
	    float curr=0,curg=0,curb=0;
	    
	    curr = (float)((float)fromColor.getRed()/255.0 * ((float)sensorValue - MIN_VAL)/(MAX_VAL-MIN_VAL));
	    curr += (float)toColor.getRed()/255.0 * (float)(MAX_VAL - sensorValue)/(MAX_VAL-MIN_VAL);
	    curg = (float)((float)fromColor.getGreen()/255.0 * ((float)sensorValue - MIN_VAL)/(MAX_VAL-MIN_VAL));
	    curg += (float)toColor.getGreen()/255.0 * (float)(MAX_VAL - sensorValue)/(MAX_VAL-MIN_VAL);
	    curb = (float)((float)fromColor.getBlue()/255.0 * ((float)sensorValue - MIN_VAL)/(MAX_VAL-MIN_VAL));
	    curb += (float)toColor.getBlue()/255.0 * (float)(MAX_VAL - sensorValue)/(MAX_VAL-MIN_VAL);
	    
	    colors[curi] = new Color(curr,curg,curb,1.0f);
	    
	    totalWeight += weights[curi];
	}
	
	for (int i = 0; i < motes.size(); i++) {
	    if (weights[i] > 0) {
		r += ((float)(((float)colors[i].getRed())/255f) * weights[i]) / (float)totalWeight;
		g += ((float)(((float)colors[i].getGreen())/255f) * weights[i]) / (float)totalWeight;
		b += ((float)(((float)colors[i].getBlue())/255f) * weights[i]) / (float)totalWeight;
	    }
	}
	//System.out.println("r = " + r + ", g = " + g + ", b = " +  b);
	if (r >= 1) r = .99f;
	if (g >= 1) g = .99f;
	if (b >= 1) b = .99f;
	try {
	    return new Color(r,g,b,Math.min(.7f,Math.max(Math.max(r,g),b)));
	} catch (IllegalArgumentException ex) {
	    System.out.println("Color out of bounds : " + r + ", " + g + ", " + b);
	    return Color.RED;
	}
    }

  /**
   * Retrieves the list of sensor motes from the given table
   *
   * @param table Table containing the sensor motes information
   * @return List of sensor motes 
   */
  public SensorMotes getSensorMotes() {
    SensorMotes sms = new SensorMotes();
    Vector mInfos = client.getAllMoteClientInfo(config.getName());
    for (int i=0; i<mInfos.size(); i++) {
      Mote m = new Mote((TASKMoteClientInfo)mInfos.elementAt(i));
// AKDNEW storing pixels not real      SensorMote sm = new SensorMote(new Integer(xConvertRealToPixel(config, m.getX())).doubleValue(), 
//                          new Integer(yConvertRealToPixel(config, m.getY())).doubleValue(),
      SensorMote sm = new SensorMote(m.getX(), m.getY(), m.getId()); 
      sms.addMote(sm);
      sm.setSensorToVisualize(sensorType);
      if (sensorType % 4 == 0) {
        sm.setColorScheme(SensorMote.GRAY, 1024);
      }
      else if (sensorType %4 == 1) {
        sm.setColorScheme(SensorMote.RED, 1024);
      }
      else if (sensorType %4 == 2) {
        sm.setColorScheme(SensorMote.BLUE, 1024);
      }
      else {
        sm.setColorScheme(SensorMote.GREEN, 1024);
      }
    }
    return sms;
  }

  /**
   * This method sets the mode of the interface
   * 
   * @param mode Mode to set the interface to
   */
  public void setMode(int mode) {
    if (currentEventHandler != null) {
      currentEventHandler.setActive(false);
    }

    switch (mode) {
      case PAN_MODE: currentEventHandler = panEventHandler;
                     canvas.setCursor(Cursor.getPredefinedCursor(Cursor.MOVE_CURSOR));
                     break;
      case SELECT_MODE: currentEventHandler = selectionHandler;
                     canvas.setCursor(Cursor.getPredefinedCursor(Cursor.DEFAULT_CURSOR));
                     break;
      case NO_MODE:  currentEventHandler = null;
                     canvas.setCursor(Cursor.getPredefinedCursor(Cursor.DEFAULT_CURSOR));
                     break;
    }

    if (currentEventHandler != null) {
      currentEventHandler.setActive(true);
    }
  }

  public static int xConvertRealToPixel(Configuration config, double x) {
    // xP = (x - xmaxR) / ((xmaxR - xminR)/(xmaxP - xminP)) + xmaxP
    return new Double((x - config.getMaximumRealX()) / ((config.getMaximumRealX() - config.getMinimumRealX())/(config.getMaximumPixelX() - config.getMinimumPixelX())) + config.getMaximumPixelX()).intValue();
  }

  public static int yConvertRealToPixel(Configuration config, double y) {
    // yP = (y - ymaxR) / ((ymaxR - yminR)/(ymaxP - yminP)) + ymaxP
    return new Double((y - config.getMaximumRealY()) / ((config.getMaximumRealY() - config.getMinimumRealY())/(config.getMaximumPixelY() - config.getMinimumPixelY())) + config.getMaximumPixelY()).intValue();
  }

  public static double xConvertPixelToReal(Configuration config, int x) {
    // x = xmaxR + (xP - xmaxP)*(xmaxR - xminR)/(xmaxP - xminP)
    return config.getMaximumRealX() + (x - config.getMaximumPixelX())*(config.getMaximumRealX() - config.getMinimumRealX())/(config.getMaximumPixelX() - config.getMinimumPixelX());
  }

  public static double yConvertPixelToReal(Configuration config, int y) {
    // y = ymaxR + (yP - ymaxP)*(ymaxR - yminR)/(ymaxP - yminP)
    return config.getMaximumRealY() + (y - config.getMaximumPixelY())*(config.getMaximumRealY() - config.getMinimumRealY())/(config.getMaximumPixelY() - config.getMinimumPixelY());
  }

  /**
   * This method calculates the distance between 2 points
   *
   * @param x X coordinate of first point
   * @param y Y coordinate of first point
   * @param x X coordinate of second point
   * @param y Y coordinate of second point
   * 
   * @returns distance between 2 points
   */
  public static double distance(int x, int y, int x1, int y1){
    return Math.sqrt( (x-x1)*(x-x1)+(y-y1)*(y-y1));
  }

  public void addResult(TASKResult qr) {
    if (qr.getQueryId() == healthQueryId) {
      addHealthResult(qr);
    }
    else {
      addSensorResult(qr);
    }
  }

  private void addHealthResult(TASKResult qr) {
// AKDNEW - attribute names
    Integer nd = (Integer)qr.getField("nodeId");
    if (nd == null)
      return;
    int node = nd.intValue();
    SensorMote mote = motes.getMote(node);
    if (mote == null) {
      String nodeString = Integer.toString(node);
      if (!unknownNodesModel.contains(nodeString)) {
        unknownNodesModel.addElement(nodeString);
      }
      return;
    }

    // get each data field and update in mote sensor value    
    for (int i=0; i<qr.getNumFields(); i++) {
      int value = 0;
      Object o = qr.getField(i);
      if (o instanceof Integer) {
        Integer tmp = (Integer)o;
        value = tmp == null ? 0 : tmp.intValue();
      }
      else if (o instanceof Byte) {
        Byte tmp = (Byte)o;
        value = tmp == null ? 0 : tmp.intValue();
      }        
      mote.setSensorValue(i+1, value, qr.getFieldInfo(i).name);
//System.out.println("HEALTH UPDATE: node "+node+", slot: "+i+", value: "+ value);
    }

    Integer tmp = (Integer)qr.getField("parent");
    int parent = tmp == null ? 0 : tmp.intValue();

    // routes: need to create SensorLine class, which subclass from ZLine
    // add a ZLine as needed, setting time
    double x = mote.getX();
    double y = mote.getY();
    SensorMote moteParent = motes.getMote(parent);
    if (moteParent != null) {

      // get rid of existing line to parent here
      for (int i=0; i<routeGroup.getNumChildren(); i++) {
        if (routeGroup.getChild(i) instanceof SensorLine) {
          SensorLine sl = (SensorLine)routeGroup.getChild(i);
          if ((sl.getX1() == x) && (sl.getY1() == y)) {
            routeGroup.removeChild(i);
            break;
          }
        }
      }

      double xn = moteParent.getX();
      double yn = moteParent.getY();
      SensorLine sl = new SensorLine(x,y,xn,yn);
      sl.setSelectable(false);
      routeGroup.addChild(sl);
    }
//System.out.println("HEALTH UPDATE: route: "+node+" to "+parent);
  }

    long lastTime = 0;

    
    private void recomputeGradient() {

	if (gRects == null || !doGradient) return;
	
	
	if (System.currentTimeMillis() - lastTime > 2000) {
	    int width = config.getMaximumPixelX() - config.getMinimumPixelX();
	    int height = config.getMaximumPixelY() - config.getMinimumPixelY();
	    int stepSize = STEP_SIZE;
	    int stepsX = width/stepSize;
	    int stepsY = height/stepSize;
	    
	    lastTime = System.currentTimeMillis();
	    
	    for (int i = 0; i < stepsX; i++) {
		for (int j = 0; j < stepsY; j++) {
		    Paint p = getPaintForPixel(i * stepSize, j * stepSize, width, height);
		    
		    ZRectangle r = gRects[i][j];
		    r.setFillPaint(p);
		}
	    }
	    scrollPane.repaint();
	}
	
    }

  private void addSensorResult(TASKResult qr) {
// AKDNEW - nodeId has to be last field
    Integer nd = ((Integer)qr.getField("nodeId"));
    if (nd == null)
      return;
    int node = nd.intValue();
    SensorMote mote = motes.getMote(node);
    if (mote == null) {
      String nodeString = Integer.toString(node);
      if (!unknownNodesModel.contains(nodeString)) {
        unknownNodesModel.addElement(nodeString);
      }
      return;
    }

    // get each data field and update in mote sensor value    
    for (int i=0; i<qr.getNumFields(); i++) {
      int value = 0;
      Object o = qr.getField(i);
      if (o instanceof Integer) {
        Integer tmp = (Integer)o;
        value = tmp == null ? 0 : tmp.intValue();
      }
      else if (o instanceof Byte) {
        Byte tmp = (Byte)o;
        value = tmp == null ? 0 : tmp.intValue();
      }        
      mote.setSensorValue(i+sensorIndex+1, value, qr.getFieldInfo(i).name);
//System.out.println("SENSOR UPDATE ("+sensorIndex+"): node "+node+", slot: "+(i+sensorIndex+1)+", value: "+ ((Integer)qr.getField(i)).intValue());
    }
    
    recomputeGradient();
    Integer tmp = (Integer)qr.getField("parent");
    if (tmp == null)
	return;
    int parent = tmp == null ? 0 : tmp.intValue();

    // routes: need to create SensorLine class, which subclass from ZLine
    // add a ZLine as needed, setting time
    double x = mote.getX();
    double y = mote.getY();
    SensorMote moteParent = motes.getMote(parent);
    if (moteParent != null) {

      // get rid of existing line to parent here
      for (int i=0; i<routeGroup.getNumChildren(); i++) {
        if (routeGroup.getChild(i) instanceof SensorLine) {
          SensorLine sl = (SensorLine)routeGroup.getChild(i);
          if ((sl.getX1() == x) && (sl.getY1() == y)) {
            routeGroup.removeChild(i);
            break;
          }
        }
      }

      double xn = moteParent.getX();
      double yn = moteParent.getY();
      SensorLine sl = new SensorLine(x,y,xn,yn);
      sl.setSelectable(false);
      routeGroup.addChild(sl);
    }
  }

  /**
   * Inner class containing the repeated task to run. This handles the removal of old parent information
   */
  class Task extends TimerTask {
    
    public void run() {
      for (int i=0; i<routeGroup.getNumChildren(); i++) {
        if (routeGroup.getChild(i) instanceof SensorLine) {
          SensorLine sl = (SensorLine)routeGroup.getChild(i);
          long time = new Date().getTime();
          if (time - sl.getTime() > 4*healthSamplePeriod) {
            routeGroup.removeChild(i);
            i--;
          }
        }
      }
    }
  }
}
