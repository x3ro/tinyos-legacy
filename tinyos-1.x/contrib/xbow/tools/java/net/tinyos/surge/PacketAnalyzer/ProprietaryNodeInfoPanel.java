// $Id: ProprietaryNodeInfoPanel.java,v 1.6 2004/02/24 23:41:39 jlhill Exp $

/*									tab:4
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


/**
 * @author Wei Hong
 */

package net.tinyos.surge.PacketAnalyzer;

import net.tinyos.surge.*;
import net.tinyos.surge.event.*;
import net.tinyos.message.*;
import net.tinyos.surge.util.*;
import java.util.*;
import java.lang.*;
import javax.swing.event.*;
import java.text.*;
import javax.swing.*;
import net.tinyos.surge.Dialog.*;
import java.awt.*;




    public class ProprietaryNodeInfoPanel extends net.tinyos.surge.Dialog.ActivePanel implements ChangeListener
    {
	NodeInfo nodeInfo;
	JCheckBox all_sensors = new JCheckBox("MTS310");
	JPanel accelx, accely, magx, magy, time;
	JLabel accelxLabel, accelyLabel, magxLabel, magyLabel;

	public void stateChanged(ChangeEvent e){
		if(all_sensors.isSelected()) show_graphs();
		else hide_graphs();
	}
	public ProprietaryNodeInfoPanel(NodeInfo pNodeInfo)

	{
	    nodeInfo = pNodeInfo;
	    nodeInfo.SetPanel(this);
	    tabTitle = "Node Information";
	    JPanel text = new JPanel();
	    setLayout(null);
	    text.setLayout(new GridLayout(6, 2));
	    text.add(new javax.swing.JLabel("Node Number:"));
	    text.add(NodeNumberLabel);
	    text.add(new javax.swing.JLabel("Messages Received:"));
	    text.add(CountLabel);
	    text.add(new javax.swing.JLabel("Current Parent:"));
	    text.add(ParentLabel);
	    text.add(new javax.swing.JLabel("Current Sequence Number:"));
	    text.add(SequenceLabel);	
	    //text.add(new javax.swing.JLabel("Sensor Reading:"));
	    //text.add(SensorLabel);
	    text.add(new javax.swing.JLabel("Hop Count:"));
	    text.add(DepthLabel);
	    text.add(all_sensors);
	    all_sensors.addChangeListener(this);
	
	    add(text);
	    text.setBounds(10, 0, 500, 100);
	    JLabel yieldLabel = new JLabel("Data Yield:");
	    int y_val = 100;
	    yieldLabel.setBounds(10, y_val, 200, 15);
	    //JPanel yield = new YieldInfoPanel(nodeInfo);
	    JPanel yield = new PlotStreamPanel("Yield", nodeInfo.yield_series, 100, 0);
	    yield.setBounds(10, y_val + 15, 480, 60);
	    add(yield);
	    add(yieldLabel);


	    y_val += 75;
	    JLabel tempLabel = new JLabel("Temperature Sensor Value:");
	    tempLabel.setBounds(10, y_val, 200, 15);
	    JPanel temp = new PlotStreamPanel("Temperature", nodeInfo.temp_series, 80, 0);
	    temp.setBounds(10, y_val + 15, 480, 60);
	    add(tempLabel);
	    add(temp);
	    y_val += 75;
	    JLabel lightLabel = new JLabel("Light Sensor Value:");
	    lightLabel.setBounds(10, y_val, 200, 15);
	    JPanel light = new PlotStreamPanel("Light", nodeInfo.light_series, 100, 0);
	    light.setBounds(10, y_val + 15, 480, 60);
	    add(lightLabel);
	    add(light);
	    y_val += 75;
	    JLabel batteryLabel = new JLabel("Battery Voltage Value:");
	    batteryLabel.setBounds(10, y_val, 200, 15);
	    JPanel battery = new PlotStreamPanel("Voltage", nodeInfo.batt_series, 4.0, 0);
	    battery.setBounds(10, y_val + 15, 480, 60);
	    add(batteryLabel);
	    add(battery);
	    y_val += 75;

	    accelxLabel = new JLabel("Accelerometer X:");
	    accelxLabel.setBounds(10, y_val, 200, 15);
	    accelx = new PlotStreamPanel("X-axis", nodeInfo.accelx_series, 100.0, 0);
	    accelx.setBounds(10, y_val + 15, 480, 60);
	    add(accelxLabel);
	    add(accelx);
	    y_val += 75;

	    accelyLabel = new JLabel("Accelerometer Y:");
	    accelyLabel.setBounds(10, y_val, 200, 15);
	    accely = new PlotStreamPanel("Y-axis", nodeInfo.accely_series, 100.0, 0);
	    accely.setBounds(10, y_val + 15, 480, 60);
	    add(accelyLabel);
	    add(accely);
	    y_val += 75;

	    magxLabel = new JLabel("Magnetometer X:");
	    magxLabel.setBounds(10, y_val, 200, 15);
	    magx = new PlotStreamPanel("X-axis", nodeInfo.magx_series, 100.0, 0);
	    magx.setBounds(10, y_val + 15, 480, 60);
	    add(magxLabel);
	    add(magx);
	    y_val += 75;

	    magyLabel = new JLabel("Magnetometer Y:");
	    magyLabel.setBounds(10, y_val, 200, 15);
	    magy = new PlotStreamPanel("Y-axis", nodeInfo.magy_series, 100.0, 0);
	    magy.setBounds(10, y_val + 15, 480, 60);
	    add(magyLabel);
	    add(magy);

	    y_val += 75;

	    time = new PlotTimePanel(nodeInfo.time_series);
	    time.setBounds(110, y_val + 5, 380, 14);
	    add(time);
  	    hide_graphs();

	}

	public void panelClosing() {
	    System.err.println ("SensorAnalyzer: updating panel = null");
	    nodeInfo.SetPanel(null);
	}
      
	javax.swing.JLabel YieldLabel = new javax.swing.JLabel();
	javax.swing.JLabel NodeNumberLabel = new javax.swing.JLabel();
	javax.swing.JLabel SensorLabel = new javax.swing.JLabel();
	javax.swing.JLabel ParentLabel = new javax.swing.JLabel();
	javax.swing.JLabel SequenceLabel = new javax.swing.JLabel();
	javax.swing.JLabel CountLabel = new javax.swing.JLabel();
	javax.swing.JLabel DepthLabel = new javax.swing.JLabel();

	public void ApplyChanges()//this function will be called when the apply button is hit
	{
	    nodeInfo.SetNodeNumber(Integer.getInteger(NodeNumberLabel.getText()));
	}

	public void InitializeDisplayValues()//this function will be called when the panel is first shown
	{
	    YieldLabel.setText("1");
	    NodeNumberLabel.setText(String.valueOf(nodeInfo.GetNodeNumber()));
	    SensorLabel.setText(String.valueOf(nodeInfo.GetSensorValue()));
		YieldLabel.setText(String.valueOf("-- %"));
	}
	void update_graphs(){
		show_graphs();
	}
	void show_graphs(){
	    time.setBounds(110, 690 + 15, 380, 14);
	    magyLabel.setVisible(true);
		magxLabel.setVisible(true);
		accelxLabel.setVisible(true);
		accelyLabel.setVisible(true);
		magy.setVisible(true);
		magx.setVisible(true);
		accelx.setVisible(true);
		accely.setVisible(true);
	}

	void hide_graphs(){
		magyLabel.setVisible(false);
		magxLabel.setVisible(false);
		accelxLabel.setVisible(false);
		accelyLabel.setVisible(false);
		magy.setVisible(false);
		magx.setVisible(false);
		accelx.setVisible(false);
		accely.setVisible(false);
	    	time.setBounds(110, 390 + 15, 380, 14);
	}
    }

