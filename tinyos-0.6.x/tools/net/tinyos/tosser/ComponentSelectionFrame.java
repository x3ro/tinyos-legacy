package net.tinyos.tosser;

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import javax.swing.*;
import javax.swing.event.*;

public class ComponentSelectionFrame extends JFrame {

    private ComponentAddListener listener;
    private File tosDir;
    private JButton addButton;
    private ComponentListPanel lPanel;
    private boolean valid = false;

    public ComponentSelectionFrame(File tosDir, ComponentAddListener listener) {
	super("TinyOS Component Library");
	valid = TOS.isValidTOSDir(tosDir);
	this.listener = listener;
	this.tosDir = tosDir;
	
	if (valid) {
	    lPanel = new ComponentListPanel(tosDir);
	    addButton = new JButton("Add Component");
	    addButton.addActionListener(new CompActionListener(this));
	    getContentPane().setLayout(new BoxLayout(getContentPane(), BoxLayout.Y_AXIS));
	    getContentPane().add(lPanel);
	    getContentPane().add(addButton);
	    pack();
	    setVisible(true);
	}
    }


    protected  TOSComponent addSelectedComponent() {
	if (valid) {
	    TOSComponent comp = lPanel.getSelectedComponent();
	    if (comp == null) {
		System.out.println("No component selected.");
	    }
	    else if (listener == null) {
		System.out.println("No listener registered, would have added " + comp.getName());
	    }
	    else {
		listener.addComponent(comp);
	    }

	    return comp;
	}
	else {
	    return null;
	}
    }
     
    private class CompActionListener implements ActionListener {
	private ComponentSelectionFrame frame;

	public CompActionListener(ComponentSelectionFrame frame) {
	    this.frame = frame;
	}

	public void actionPerformed(ActionEvent e) {
	    TOSComponent comp = frame.addSelectedComponent();
	}
	
    }

    public static void main(String[] args) {
	File file = new File(args[0]);
	ComponentSelectionFrame frame = new ComponentSelectionFrame(file, null);
	
    }
    
}
