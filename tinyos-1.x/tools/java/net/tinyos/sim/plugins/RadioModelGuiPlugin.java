// $Id: RadioModelGuiPlugin.java,v 1.4 2004/06/14 21:30:35 mikedemmer Exp $

/*									tab:2
 *
 *
 * "Copyright (c) 2004 and The Regents of the University 
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
 * Authors:	Michael Demmer
 * Date:        January 9, 2004
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
  private JComboBox modelComboBox;
  private JButton updateButton;
  private JCheckBox autoPublishCb;
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
    radioModelPlugin.setGUI(this);
    
    df.applyPattern("#.###");

    JPanel parameterPane = new JPanel();
    parameterPane.setLayout(new GridLayout(2,2));

    // Create the out edge checkbox	
    cbOutEdges = new JCheckBox("Out Edges", outEdges);
    cbOutEdges.addItemListener(new outEdgesListener());
    cbOutEdges.setFont(tv.labelFont);

    // Create radius constant text field and label
    JLabel scalingFactorLabel = new JLabel("Distance scaling factor");
    scalingFactorLabel.setFont(tv.defaultFont);
    scalingFactorTextField = new JTextField("", 5);
    scalingFactorTextField.setFont(tv.smallFont);
    scalingFactorTextField.setEditable(true);
    parameterPane.add(scalingFactorLabel);
    parameterPane.add(scalingFactorTextField);

    // Create button to update radio model
    updateButton = new JButton("Update");
    updateButton.addActionListener(new UpdateListener());
    updateButton.setFont(tv.defaultFont);

    // Create checkbox for auto publish 
    autoPublishCb = new JCheckBox("Auto Update");
    autoPublishCb.addItemListener(new autoPublishListener());
    cbOutEdges.setFont(tv.labelFont);

    // Create combo box for different Propagation models
    modelComboBox = new JComboBox();

    Enumeration e = radioModelPlugin.getModels();
    while (e.hasMoreElements()) {
      modelComboBox.addItem(e.nextElement());
    }

    // update the GUI widgets to the current settings in the plugin
    // before adding the action listeners to avoid erroneous updates
    updatePluginSettings();
    System.out.println("adding listeners, model is " + radioModelPlugin.getCurModel());
    scalingFactorTextField.addActionListener(new ScalingListener());
    modelComboBox.addActionListener(new ModelComboBoxListener());
    
    //pluginPanel.setLayout(new BorderLayout());
    pluginPanel.add(parameterPane);
    pluginPanel.add(updateButton);
    pluginPanel.add(autoPublishCb);
    pluginPanel.add(cbOutEdges);
    pluginPanel.add(modelComboBox);
    pluginPanel.revalidate();
  }

  public void deregister() {
    radioModelPlugin.setGUI(null);
  }

  // when scripts change settings in the radio model, we need to
  // update our widgets to reflect those changes.
  public void updatePluginSettings() {
    // update the selected model
    modelComboBox.setSelectedItem(radioModelPlugin.getCurModel());

    // update the scaling factor
    String scalingFactorValue = Double.toString(radioModelPlugin.getScalingFactor());
    scalingFactorTextField.setText(scalingFactorValue);

    // update auto publish mode (and the update button)
    autoPublishCb.setSelected(radioModelPlugin.getAutoPublish());
    updateButton.setEnabled(!radioModelPlugin.getAutoPublish());
    
    System.out.println("update settings " + radioModelPlugin.getCurModel() + scalingFactorValue);
  }

  public void draw(Graphics graphics) {
    Iterator selectedMotes = state.getSelectedMoteSimObjects().iterator();
    while (selectedMotes.hasNext()) {
      MoteSimObject selMote = (MoteSimObject)selectedMotes.next();
      Iterator motes = state.getMoteSimObjects().iterator();
      while (motes.hasNext()) {
	MoteSimObject mote = (MoteSimObject)motes.next();
	if (selMote != mote) {
	  CoordinateAttribute selMoteCoord = selMote.getCoordinate();
	  CoordinateAttribute moteCoord = mote.getCoordinate();
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

  class outEdgesListener implements ItemListener {
    public void itemStateChanged(ItemEvent e) {
      outEdges = (e.getStateChange() == e.SELECTED);
      motePanel.refresh();
    }
  }

  class autoPublishListener implements ItemListener {
    public void itemStateChanged(ItemEvent e) {
      boolean autoPublish = (e.getStateChange() == e.SELECTED);
      radioModelPlugin.setAutoPublish(autoPublish);
      updateButton.setEnabled(!autoPublish);
      motePanel.refresh();
    }
  }

  class ModelComboBoxListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
      PropagationModel pm = (PropagationModel)modelComboBox.getSelectedItem();
      System.out.println("combo listener fired, curmodel " + pm);
      radioModelPlugin.setCurModel(pm);
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


