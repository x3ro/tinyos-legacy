/* "Copyright (c) 2001 and The Regents of the University
* of California.  All rights reserved.
*
* Permission to use, copy, modify, and distribute this software and its
* documentation for any purpose, without fee, and without written agreement is
* hereby granted, provided that the above copyright notice and the following
* two paragraphs appear in all copies of this software.
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
* Authors:   Kamin Whitehouse <kamin@cs.berkeley.edu>
* History:   created 7/22/2001
*/

package net.tinyos.moteview.Dialog.Panel;

              //this file is used for visually creating the panel using VCafe,
              //it is then inserted into another class as an inner class and edited
import javax.swing.*;
import Surge.*;
import Surge.Dialog.*;
import Surge.PacketAnalyzers.*;
import java.awt.event.*;
import javax.swing.event.*;
import java.beans.*;
import java.awt.*;

public class ObjectMaintainerPropertiesPanel extends ActivePanel
{

	public ObjectMaintainerPropertiesPanel()
	{

		tabTitle = "Display Properties";
		modal= true;
		//{{INIT_CONTROLS
		setLayout(null);
		Insets ins = getInsets();
		setSize(286,264);
		add(nodeExpire);
		nodeExpire.setBounds(36,12,156,52);
		NodeExpireLabel.setText("label1");
		add(NodeExpireLabel);
		NodeExpireLabel.setBounds(204,12,47,52);
		nodeExpireSlider.setMinimum(100);
		nodeExpireSlider.setMaximum(10000);
		nodeExpireSlider.setToolTipText("The time before this node is deleted, since it last seen.");
		//nodeExpireSlider.setBorder(bevelBorder1);
		nodeExpireSlider.setValue(100);
		add(nodeExpireSlider);
		nodeExpireSlider.setBounds(60,48,192,24);
		nodeInitialPersistance.setText("Node Initial Persistance:");
		add(nodeInitialPersistance);
		nodeInitialPersistance.setBounds(36,60,156,52);
		nodeInitialPersistanceLabel.setText("label2");
		add(nodeInitialPersistanceLabel);
		nodeInitialPersistanceLabel.setBounds(204,60,47,52);
		nodeInitialPersistanceSlider.setMinimum(100);
		nodeInitialPersistanceSlider.setMaximum(10000);
		nodeInitialPersistanceSlider.setToolTipText("The time before a node is deleted, since it was first seen.");
		//nodeInitialPersistanceSlider.setBorder(bevelBorder1);
		nodeInitialPersistanceSlider.setOpaque(false);
		nodeInitialPersistanceSlider.setValue(100);
		add(nodeInitialPersistanceSlider);
		nodeInitialPersistanceSlider.setForeground(java.awt.Color.lightGray);
		nodeInitialPersistanceSlider.setBounds(60,96,192,24);
		edgeExpire.setText("Edge Expire Time:");
		add(edgeExpire);
		edgeExpire.setBounds(36,108,156,52);
		edgeExpireLabel.setText("label3");
		add(edgeExpireLabel);
		edgeExpireLabel.setBounds(204,108,47,52);
		edgeExpireSlider.setMinimum(100);
		edgeExpireSlider.setMaximum(10000);
		edgeExpireSlider.setToolTipText("The time before an edge is deleted, since it was last seen");
		//edgeExpireSlider.setBorder(bevelBorder1);
		edgeExpireSlider.setValue(100);
		add(edgeExpireSlider);
		edgeExpireSlider.setBounds(60,144,192,24);
		edgeInitialPersistance.setText("Edge Initial Persistance:");
		add(edgeInitialPersistance);
		edgeInitialPersistance.setBounds(36,156,156,52);
		edgeInitialPersistanceLabel.setText("label4");
		add(edgeInitialPersistanceLabel);
		edgeInitialPersistanceLabel.setBounds(204,156,47,52);
		edgeInitialPersistanceSlider.setMinimum(100);
		edgeInitialPersistanceSlider.setMaximum(10000);
		edgeInitialPersistanceSlider.setToolTipText("The time before an edge is deleted, since it was first seen.");
		//edgeInitialPersistanceSlider.setBorder(bevelBorder1);
		edgeInitialPersistanceSlider.setValue(100);
		add(edgeInitialPersistanceSlider);
		edgeInitialPersistanceSlider.setForeground(java.awt.Color.lightGray);
		edgeInitialPersistanceSlider.setBounds(60,192,192,24);
		expirationCheckRate.setText("Expiration Check Rate");
		add(expirationCheckRate);
		expirationCheckRate.setBounds(36,204,159,51);
		expirationCheckRateLabel.setText("label5");
		add(expirationCheckRateLabel);
		expirationCheckRateLabel.setBounds(204,204,48,51);
		JLabel1.setToolTipText("1 second is 1000 milliseconds");
		expirationCheckRateSlider.setValue(100);
		JLabel1.setText("Note: all times are in milliseconds");
		add(JLabel1);
		JLabel1.setForeground(java.awt.Color.blue);
		JLabel1.setBounds(48,0,219,21);
		expirationCheckRateSlider.setMinimum(100);
		expirationCheckRateSlider.setMaximum(10000);
		expirationCheckRateSlider.setToolTipText("The rate at which the Object Maintainer goes through all the objects and deletes old ones.  ");
		//expirationCheckRateSlider.setBorder(bevelBorder1);
		add(expirationCheckRateSlider);
		expirationCheckRateSlider.setBackground(new java.awt.Color(204,204,204));
		expirationCheckRateSlider.setForeground(java.awt.Color.lightGray);
		expirationCheckRateSlider.setBounds(60,240,192,24);
		add(ApplyButton);
		ApplyButton.setBounds(0,0,0,0);
		add(CancelButton);
		CancelButton.setBounds(0,0,0,0);

		nodeExpire.setText("Node Expire Time:");
		//$$ bevelBorder1.move(0,306);
		//}}

		//{{REGISTER_LISTENERS
		SymChange lSymChange = new SymChange();
		nodeExpireSlider.addChangeListener(lSymChange);
		nodeInitialPersistanceSlider.addChangeListener(lSymChange);
		edgeExpireSlider.addChangeListener(lSymChange);
		edgeInitialPersistanceSlider.addChangeListener(lSymChange);
		expirationCheckRateSlider.addChangeListener(lSymChange);
		//}}
	}

		//{{DECLARE_CONTROLS
	javax.swing.JLabel nodeExpire = new javax.swing.JLabel();
	javax.swing.JLabel NodeExpireLabel = new javax.swing.JLabel();
	javax.swing.JSlider nodeExpireSlider = new javax.swing.JSlider();
	javax.swing.JLabel nodeInitialPersistance = new javax.swing.JLabel();
	javax.swing.JLabel nodeInitialPersistanceLabel = new javax.swing.JLabel();
	javax.swing.JSlider nodeInitialPersistanceSlider = new javax.swing.JSlider();
	javax.swing.JLabel edgeExpire = new javax.swing.JLabel();
	javax.swing.JLabel edgeExpireLabel = new javax.swing.JLabel();
	javax.swing.JSlider edgeExpireSlider = new javax.swing.JSlider();
	javax.swing.JLabel edgeInitialPersistance = new javax.swing.JLabel();
	javax.swing.JLabel edgeInitialPersistanceLabel = new javax.swing.JLabel();
	javax.swing.JSlider edgeInitialPersistanceSlider = new javax.swing.JSlider();
	javax.swing.JLabel expirationCheckRate = new javax.swing.JLabel();
	javax.swing.JLabel expirationCheckRateLabel = new javax.swing.JLabel();
	javax.swing.JLabel JLabel1 = new javax.swing.JLabel();
	javax.swing.JSlider expirationCheckRateSlider = new javax.swing.JSlider();
	javax.swing.JButton ApplyButton = new javax.swing.JButton();
	javax.swing.JButton CancelButton = new javax.swing.JButton();
	//com.symantec.itools.javax.swing.borders.BevelBorder bevelBorder1 = new com.symantec.itools.javax.swing.borders.BevelBorder();
	//}}

              //---------------------------------------------------------------------
              //APPLY CHANGES
	public void ApplyChanges()
	{
		MainClass.objectMaintainer.SetNodeExpireTime(nodeExpireSlider.getValue());
		MainClass.objectMaintainer.SetEdgeExpireTime(edgeExpireSlider.getValue());
    	MainClass.objectMaintainer.SetEdgeInitialPersisistance(edgeInitialPersistanceSlider.getValue());
    	MainClass.objectMaintainer.SetNodeInitialPersisistance(nodeInitialPersistanceSlider.getValue());
    	MainClass.objectMaintainer.SetExpirationCheckRate(expirationCheckRateSlider.getValue());
	}
              //APPLY CHANGES
              //---------------------------------------------------------------------


              //---------------------------------------------------------------------
              //INITIALIZE DISPLAY VALUES
	public void InitializeDisplayValues()
	{
		NodeExpireLabel.setText(String.valueOf(MainClass.objectMaintainer.GetNodeExpireTime()));
		nodeExpireSlider.setValue((int)MainClass.objectMaintainer.GetNodeExpireTime());
		nodeInitialPersistanceLabel.setText(String.valueOf(MainClass.objectMaintainer.GetEdgeInitialPersisistance()));
		nodeInitialPersistanceSlider.setValue((int)MainClass.objectMaintainer.GetEdgeInitialPersisistance());
		edgeExpireLabel.setText(String.valueOf(MainClass.objectMaintainer.GetEdgeExpireTime()));
		edgeExpireSlider.setValue((int)MainClass.objectMaintainer.GetEdgeExpireTime());
		edgeInitialPersistanceLabel.setText(String.valueOf(MainClass.objectMaintainer.GetNodeInitialPersisistance()));
		edgeInitialPersistanceSlider.setValue((int)MainClass.objectMaintainer.GetNodeInitialPersisistance());
		expirationCheckRateLabel.setText(String.valueOf(MainClass.objectMaintainer.GetNodeInitialPersisistance()));
		expirationCheckRateSlider.setValue((int)MainClass.objectMaintainer.GetNodeInitialPersisistance());

		      //This function is called by a thread that runs in the background
		      //and updates the values of the Active Panels so they are always
		      //up to date.
	}
              //INITIALIZE DISPLAY VALUES
              //---------------------------------------------------------------------

	class SymChange implements javax.swing.event.ChangeListener
	{
		public void stateChanged(javax.swing.event.ChangeEvent event)
		{
			Object object = event.getSource();
			if (object == nodeExpireSlider)
				nodeExpireSlider_stateChanged(event);
			else if (object == nodeInitialPersistanceSlider)
				nodeInitialPersistanceSlider_stateChanged(event);
			else if (object == edgeExpireSlider)
				edgeExpireSlider_stateChanged(event);
			else if (object == edgeInitialPersistanceSlider)
				edgeInitialPersistanceSlider_stateChanged(event);
			else if (object == expirationCheckRateSlider)
				expirationCheckRateSlider_stateChanged(event);
		}
	}

	void nodeExpireSlider_stateChanged(javax.swing.event.ChangeEvent event)
	{
		// to do: code goes here.

		nodeExpireSlider_stateChanged_Interaction1(event);
	}

	void nodeExpireSlider_stateChanged_Interaction1(javax.swing.event.ChangeEvent event)
	{
		try {
			// convert int->class java.lang.String
			NodeExpireLabel.setText(java.lang.String.valueOf(nodeExpireSlider.getValue()));
		} catch (java.lang.Exception e) {
		}
	}

	void nodeInitialPersistanceSlider_stateChanged(javax.swing.event.ChangeEvent event)
	{
		// to do: code goes here.

		nodeInitialPersistanceSlider_stateChanged_Interaction1(event);
	}

	void nodeInitialPersistanceSlider_stateChanged_Interaction1(javax.swing.event.ChangeEvent event)
	{
		try {
			// convert int->class java.lang.String
			nodeInitialPersistanceLabel.setText(java.lang.String.valueOf(nodeInitialPersistanceSlider.getValue()));
		} catch (java.lang.Exception e) {
		}
	}

	void edgeExpireSlider_stateChanged(javax.swing.event.ChangeEvent event)
	{
		// to do: code goes here.

		edgeExpireSlider_stateChanged_Interaction1(event);
	}

	void edgeExpireSlider_stateChanged_Interaction1(javax.swing.event.ChangeEvent event)
	{
		try {
			// convert int->class java.lang.String
			edgeExpireLabel.setText(java.lang.String.valueOf(edgeExpireSlider.getValue()));
		} catch (java.lang.Exception e) {
		}
	}

	void edgeInitialPersistanceSlider_stateChanged(javax.swing.event.ChangeEvent event)
	{
		// to do: code goes here.

		edgeInitialPersistanceSlider_stateChanged_Interaction1(event);
	}

	void edgeInitialPersistanceSlider_stateChanged_Interaction1(javax.swing.event.ChangeEvent event)
	{
		try {
			// convert int->class java.lang.String
			edgeInitialPersistanceLabel.setText(java.lang.String.valueOf(edgeInitialPersistanceSlider.getValue()));
		} catch (java.lang.Exception e) {
		}
	}

	void expirationCheckRateSlider_stateChanged(javax.swing.event.ChangeEvent event)
	{
		// to do: code goes here.

		expirationCheckRateSlider_stateChanged_Interaction1(event);
	}

	void expirationCheckRateSlider_stateChanged_Interaction1(javax.swing.event.ChangeEvent event)
	{
		try {
			// convert int->class java.lang.String
			expirationCheckRateLabel.setText(java.lang.String.valueOf(edgeInitialPersistanceSlider.getValue()));
		} catch (java.lang.Exception e) {
		}
	}

}