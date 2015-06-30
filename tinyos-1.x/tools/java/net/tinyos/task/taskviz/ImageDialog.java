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

import javax.swing.*;
import javax.swing.event.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;

import edu.umd.cs.jazz.*;
import edu.umd.cs.jazz.component.*;
import edu.umd.cs.jazz.event.*;
import edu.umd.cs.jazz.util.*;

// AKD - not working:
//	1) (minor) some flickering around border when using real image and changing magnification

/**
 * This class is a dialog that allows a user to register the background image with a real world 
 * coordinate system.
 */
public class ImageDialog extends JDialog implements ActionListener, AddEventListener, MoveEventListener {

  /**
   * Diameter of the circle being drawn
   */
  private final static int CIRCLE_DIAMETER = 5;

  /**
   * Width of the scroll window
   */
  private final static int SCROLL_WIDTH = 600;

  /**
   * Height of the scroll window
   */
  private final static int SCROLL_HEIGHT = 600;

  /**
   * Add mode: clicks add motes to the image
   */
  private final static int ADD_MODE = 0;

  /**
   * Pan mode: click and drags pan the image
   */
  private final static int PAN_MODE = 1;

  private JTextField minX, minY, maxX, maxY;
  private JRadioButton min, max;
  private JLabel pixelX, pixelY, instructions;
  
  private boolean minDone = false;
  private boolean maxDone = false;
  private int pixelMinX = 0;
  private int pixelMinY = 0;
  private int pixelMaxX = 0;
  private int pixelMaxY = 0;
  private BufferedImage newImage;
  private boolean validData = false;

  private boolean started = false;
  private int imageWidth = 0;
  private int imageHeight = 0;
  private Configuration config;

  private ZEventHandler currentEventHandler = null;
  private ZPanEventHandler panEventHandler = null;
  private ZoomEventHandler zoomEventHandler = null;
  private AddEventHandler addEventHandler = null;
  private MoveEventHandler moveEventHandler = null;
  private ZImageCanvas canvas = null;

  /**
   * Constructor for the dialog allowing a user to register the image with a real world coordinate
   * system
   *
   * @param aFrame Parent frame for the dialog
   * @param mode New or edit mode for the configuration
   * @param config Configuration being edited or created
   */
  public ImageDialog(Frame aFrame, String mode, Configuration config) {
    super(aFrame, true);
    this.config = config;
    if (mode.equals(TASKDeploy.NEW)) {
      setTitle("New Configuration Editor");
    }
    else {
      setTitle("Configuration Editor");
    }

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

    instructions = new JLabel("Select the minimum and maximum points on the image and enter their real world coordinates");
 
    if (mode.equals(TASKDeploy.NEW)) {
      minX = new JTextField("0.0", 5);
      minY = new JTextField("0.0", 5);
      maxX = new JTextField(String.valueOf(imageWidth), 5);
      maxY = new JTextField(String.valueOf(imageHeight), 5);
      minDone = true;
      maxDone = true;
      pixelMinX = 0;
      pixelMinY = 0;
      pixelMaxX = imageWidth;
      pixelMaxY = imageHeight;
    }
    else {
      minX = new JTextField(String.valueOf(config.getMinimumRealX()), 5);
      minY = new JTextField(String.valueOf(config.getMinimumRealY()), 5);
      maxX = new JTextField(String.valueOf(config.getMaximumRealX()), 5);
      maxY = new JTextField(String.valueOf(config.getMaximumRealY()), 5);
      minDone = true;
      maxDone = true;
      pixelMinX = config.getMinimumPixelX();
      pixelMinY = config.getMinimumPixelY();
      pixelMaxX = config.getMaximumPixelX();
      pixelMaxY = config.getMaximumPixelY();
    }

    JLabel stuff1 = new JLabel("          ");
    JLabel stuff2 = new JLabel("          ");
    JLabel stuff3 = new JLabel("          ");
    JLabel stuff4 = new JLabel("          ");
    JLabel xLabel = new JLabel("  X  ");
    JLabel yLabel = new JLabel("  Y  ");
    JLabel xLabel1 = new JLabel("  X  ");
    JLabel yLabel1 = new JLabel("  Y  ");
    JLabel pixelXLabel = new JLabel(" Pixel X ");
    JLabel pixelYLabel = new JLabel(" Pixel Y ");
    pixelX = new JLabel("  0  ");
    pixelY = new JLabel("  0  ");
    JButton ok = new JButton("OK");
    ok.addActionListener(this);
    JButton cancel = new JButton("Cancel");
    cancel.addActionListener(this);
    min = new JRadioButton("MIN", true);
    max = new JRadioButton("MAX");
    ButtonGroup group = new ButtonGroup();
    group.add(min);
    group.add(max);
	
    JPanel main = new JPanel(new BorderLayout());
    ZScrollPane scrollPane = new ZScrollPane(canvas);

    int w, h;
    if (imageWidth > 800) {
      w = 800;
    }
    else {
      w = imageWidth;
    }
    if (imageHeight > 800) {
      h = 800;
    }
    else {
      h = imageHeight;
    }

    scrollPane.setPreferredSize(new Dimension(w+20, h+20));
    main.add(scrollPane, BorderLayout.CENTER);

    JPanel points = new JPanel(new GridLayout(0,3));
    points.add(stuff1);
    points.add(pixelXLabel);
    points.add(pixelYLabel);
    points.add(stuff2);
    points.add(pixelX);
    points.add(pixelY);
    points.add(stuff3);
    points.add(xLabel);
    points.add(yLabel);
    points.add(min);
    points.add(minX);
    points.add(minY);
    points.add(stuff4);
    points.add(xLabel1);
    points.add(yLabel1);
    points.add(max);
    points.add(maxX);
    points.add(maxY);

    main.add(points, BorderLayout.EAST);
    main.add(instructions, BorderLayout.NORTH);
	
    JPanel buttons = new JPanel(new FlowLayout());
    buttons.add(ok);
    buttons.add(cancel);
    main.add(buttons, BorderLayout.SOUTH);

    JPanel top = new JPanel(new BorderLayout());
    top.add(createToolBar(), BorderLayout.NORTH);
    top.add(main, BorderLayout.SOUTH);

    getContentPane().add(top);

    panEventHandler = new ZPanEventHandler(canvas.getCameraNode());
    zoomEventHandler = new ZoomEventHandler(canvas.getCameraNode());
    addEventHandler = new AddEventHandler(canvas, this, imageWidth, imageHeight);
    moveEventHandler = new MoveEventHandler(canvas, this, imageWidth, imageHeight);
 
    zoomEventHandler.setActive(true);
    moveEventHandler.setActive(true);

    setMode(ADD_MODE);

    addEventHandler.setMin(pixelMinX, pixelMinY);
    addEventHandler.setMax(pixelMaxX, pixelMaxY);
  }

  /**
   * Event handler for the dialog box
   *
   * @param e Input event to be handled
   */
  public void actionPerformed(ActionEvent e) {
    String command = e.getActionCommand();
    if (command.equals("OK")) {
      if (validateData()) {
        setVisible(false);
      }
    }
    else if (command.equals("Cancel")) {
      setVisible(false);
    }
  }

  /**
   * This method validates the data to make sure that all the data has been entered correctly
   *
   * @return whether the user input data is valid
   */
  private boolean validateData() {
    // make sure that data in each textfield isn't empty and contain valid floats/doubles
    String minXVal = minX.getText().trim();
    String minYVal = minY.getText().trim();
    String maxXVal = maxX.getText().trim();
    String maxYVal = maxY.getText().trim();
    double x1 = 0.0;
    double y1 = 0.0;
    double x2 = 0.0;
    double y2 = 0.0;
	
    boolean error = false;

    if ((minXVal.length() == 0) || (minYVal.length() == 0) || (maxXVal.length() == 0) || (maxYVal.length() == 0)) {
      JOptionPane.showMessageDialog(this, "You need to enter data into all 4 fields", "Error", JOptionPane.ERROR_MESSAGE);
      error = true;
    }
    else if ((!minDone) || (!maxDone)) {
      JOptionPane.showMessageDialog(this, "You need to select a minimum point and a maximum point", "Error", JOptionPane.ERROR_MESSAGE);
      error = true;
    }
    else {
      try {
        x1 = Double.parseDouble(minXVal);
        y1 = Double.parseDouble(minYVal);
        x2 = Double.parseDouble(maxXVal);
        y2 = Double.parseDouble(maxYVal);
      } catch (NumberFormatException nfe) {
          JOptionPane.showMessageDialog(this, "Invalid x,y data", "Error", JOptionPane.ERROR_MESSAGE);
          error = true;
      }
    }
	
    // put data in configuration object
    if (!error) {
      validData = true;
      config.setMinimumPixelX(pixelMinX);
      config.setMinimumPixelY(pixelMinY);
      config.setMaximumPixelX(pixelMaxX);
      config.setMaximumPixelY(pixelMaxY);
      config.setMinimumRealX(x1);
      config.setMinimumRealY(y1);
      config.setMaximumRealX(x2);
      config.setMaximumRealY(y2);
    }
    return !error;
  }

  /**
   * Indicates whether the data is valid or not
   *
   * @return whether the data is valid or not
   */
  public boolean isDataValid() {
    return validData;
  }

  /**
   * Creates a toolbar to allow user to move between ADD and PAN modes
   *
   * @return the created toolbar
   */ 
  private JToolBar createToolBar() {
    JToolBar toolbar = new JToolBar();
    ButtonGroup group = new ButtonGroup();

    JToggleButton set = new JToggleButton("Set");
    set.setToolTipText("Set min and max");
    set.setSelected(true);
    set.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        setMode(ADD_MODE);
      }
    });
    group.add(set);
    toolbar.add(set);

    JToggleButton pan = new JToggleButton("Pan");
    pan.setToolTipText("Pan");
    pan.setSelected(false);
    pan.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae) {
        setMode(PAN_MODE);
      }
    });
    group.add(pan);
    toolbar.add(pan);
    toolbar.setFloatable(false);
    return toolbar;
  }

  /**
   * Sets the mode to either ADD or PAN, setting the appropriate event handler active or inactive
   *
   * @param mode ADD or PAN mode
   */
  private void setMode(int mode) {
    if (currentEventHandler != null) {
      currentEventHandler.setActive(false);
    }
    
    switch (mode) {
      case ADD_MODE: currentEventHandler = addEventHandler;
                     canvas.setCursor(Cursor.getPredefinedCursor(Cursor.CROSSHAIR_CURSOR));
                     break;
      case PAN_MODE: currentEventHandler = panEventHandler;
                     canvas.setCursor(Cursor.getPredefinedCursor(Cursor.MOVE_CURSOR));
                     break;
    }

    if (currentEventHandler != null) {
      currentEventHandler.setActive(true);
    }
  }

  /**
   * Update the x pixel coordinate on the screen
   *
   * @param x x coordinate
   */
  public void setXPos(int x) {
    pixelX.setText(String.valueOf(x));
  }

  /**
   * Update the y pixel coordinate on the screen
   *
   * @param y y coordinate
   */
  public void setYPos(int y) {
    pixelY.setText(String.valueOf(y));
  }

  /**
   * Empty method to satisfy interface
   *
   * @param id Mote id
   */
  public void setId(int id) {
  }

  /**
   * Sets the information to pass on to the event handler: MIN or MAX
   *
   * @return information to pass to event handler
   */
  public Object getInfo() {
    if (min.isSelected()) {
      minDone = true;
      return AddEventHandler.MIN;
    }
    else {
      maxDone = true;
      return AddEventHandler.MAX;
    }
  }

  /**
   * Set the x (min or max) pixel
   *
   * @param x x coordinate
   */
  public void setPixelX(int x) {
    if (min.isSelected()) {
      pixelMinX = x;
    }
    else {
      pixelMaxX = x;
    }
  }

  /**
   * Set the y (min or max) pixel
   *
   * @param y y coordinate
   */
  public void setPixelY(int y) {
    if (min.isSelected()) {
      pixelMinY = y;
    }
    else {
      pixelMaxY = y;
    }
  }
}
