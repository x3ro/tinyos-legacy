// $Id: RadioModelGuiPlugin.java,v 1.3 2003/11/24 01:04:12 mikedemmer Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Nelson Lee
 * Date:        December 11 2002
 * Desc:        UI specific parts of the radio model manipulation plugin
 *
 */

/**
 * @author Nelson Lee
 * @author Michael Demmer
 */


package net.tinyos.sim.plugins;

import java.lang.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import java.text.DecimalFormat;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;

public class RadioModelGuiPlugin extends GuiPlugin implements SimConst {

  private RadioModelPlugin radioModelPlugin;
  private JTextField scalingFactorTextField;
  private JCheckBox cbOutEdges;
  private boolean outEdges = true;
  private DecimalFormat df = new DecimalFormat();

  public void handleEvent(SimEvent event) {
    // Events are mostly handled by the non gui RadioModelPlugin
    if (event instanceof OptionSetEvent) {
      OptionSetEvent ose = (OptionSetEvent)event;
      if (ose.name.equals("radioscaling")) {
	scalingFactorTextField.setText(ose.value);
      }
    }
  }

  public void register() {
    PluginManager pluginManager = driver.getPluginManager();
    
    radioModelPlugin =
      (RadioModelPlugin)pluginManager.getPlugin("RadioModelPlugin");
    
    if (radioModelPlugin == null) {
      System.err.println("RADIOMODEL: Can't find RadioModelPlugin.");
      System.exit(1);
    }

    // make sure the actual radio model is registered first
    if (! radioModelPlugin.isRegistered()) {
      pluginManager.register(radioModelPlugin);
    }
    
    df.applyPattern("#.###");

    JPanel parameterPane = new JPanel();
    parameterPane.setLayout(new GridLayout(2,2));

    // Create the out edge checkbox	
    cbOutEdges = new JCheckBox("Out Edges", outEdges);
    cbOutEdges.addItemListener(new cbListener());
    cbOutEdges.setFont(tv.labelFont);

    // Create radius constant text field and label
    JLabel scalingFactorLabel = new JLabel("Distance scaling factor");
    scalingFactorLabel.setFont(tv.defaultFont);
    scalingFactorTextField = new JTextField("1", 5);
    scalingFactorTextField.setFont(tv.smallFont);
    scalingFactorTextField.setEditable(true);
    scalingFactorTextField.addActionListener(new ScalingListener());
    parameterPane.add(scalingFactorLabel);
    parameterPane.add(scalingFactorTextField);

    // Create button to update radio model
    JButton updateButton = new JButton("Update");
    updateButton.addActionListener(new UpdateListener());
    updateButton.setFont(tv.defaultFont);

    // Create combo box for different Propagation models
    JComboBox cb = new JComboBox();
    cb.addActionListener(new ComboBoxListener());

    Enumeration e = radioModelPlugin.getModels();
    while (e.hasMoreElements()) {
      cb.addItem(e.nextElement());
    }
    cb.setSelectedItem(radioModelPlugin.getCurModel());
    
    //pluginPanel.setLayout(new BorderLayout());
    pluginPanel.add(parameterPane);
    pluginPanel.add(updateButton);
    pluginPanel.add(cbOutEdges);
    pluginPanel.add(cb);
    pluginPanel.revalidate();
  }

  public void draw(Graphics graphics) {
    Iterator selectedMotes = state.getSelectedMoteSimObjects().iterator();
    while (selectedMotes.hasNext()) {
      MoteSimObject selMote = (MoteSimObject)selectedMotes.next();
      Iterator motes = state.getMoteSimObjects().iterator();
      while (motes.hasNext()) {
	MoteSimObject mote = (MoteSimObject)motes.next();
	if (selMote != mote) {
	  MoteCoordinateAttribute selMoteCoord = selMote.getCoordinate();
	  MoteCoordinateAttribute moteCoord = mote.getCoordinate();
	  int x1 = (int)cT.simXToGUIX(selMoteCoord.getX());
	  int y1 = (int)cT.simYToGUIY(selMoteCoord.getY());
	  int x2 = (int)cT.simXToGUIX(moteCoord.getX());
	  int y2 = (int)cT.simYToGUIY(moteCoord.getY());
	  double prob;
	  if (outEdges) {
	    prob = radioModelPlugin.getLossRate(selMote, mote);
	    if (prob < 1.0) {
	      graphics.setColor(getColor(1-prob));
	      Arrow.drawArrow(graphics, x2, y2, x1, y1, Arrow.SIDE_TRAIL);
	    }
	  }
	  else {
	    prob = radioModelPlugin.getLossRate(mote, selMote);
	    if (prob < 1.0) {
	      graphics.setColor(getColor(1-prob));
	      Arrow.drawArrow(graphics, x1, y1, x2, y2, Arrow.SIDE_TRAIL);
	    }
	  }

	  if (prob < 1.0) {

	    int xMidPoint = x1 + (x2-x1)/2;
       	    int yMidPoint = y1 + (y2-y1)/2;

	    graphics.drawString(new String(df.format((1-prob)*100)), xMidPoint, yMidPoint);
       	  }
	}
      }
    }
  }

  public static Color getColor(double value) {
    if (value < 0.0) return Color.gray;
    if (value > 1.0) value = 1.0;
    int red = Math.min(255,(int)(512.0 - (value * 512.0)));
    int green = Math.min(255,(int)(value * 512.0));
    int blue = 0;
    return new Color(red, green, blue);
  }

  public void deregister() {}

  public String toString() {
    return "Radio model";
  }

  class UpdateListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      radioModelPlugin.updateModel();
      radioModelPlugin.publishModel();
      motePanel.refresh();	    
    }
  }

  class cbListener implements ItemListener {
    public void itemStateChanged(ItemEvent e) {
      outEdges = (e.getStateChange() == e.SELECTED);
      motePanel.refresh();
    }
  }

  class ComboBoxListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      JComboBox cb = (JComboBox)e.getSource();
      PropagationModel pm = (PropagationModel)cb.getSelectedItem();
      radioModelPlugin.setCurModel(pm);
      radioModelPlugin.updateModel();
      motePanel.refresh();
    }
  }

  class ScalingListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      double scalingFactor = Double.parseDouble(scalingFactorTextField.getText());
      radioModelPlugin.setScalingFactor(scalingFactor);
    }
  }
}


