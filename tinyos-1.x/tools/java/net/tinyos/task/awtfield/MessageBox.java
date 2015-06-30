package net.tinyos.task.awtfield;

import java.awt.*;
import java.io.*;
import java.awt.event.*;

public class MessageBox extends Dialog implements ActionListener, WindowListener {
    MessageBox(Frame parent, String title, String message) {
	super(parent, title, true);
	addWindowListener(this);
	setLayout(new GridBagLayout());

	GridBagConstraints c1 = new GridBagConstraints();
	c1.gridy = 0;
	add(new Label(message), c1);

	GridBagConstraints c2 = new GridBagConstraints();
	c2.gridy = 1;
	Button ok = new Button("Ok");
	add(ok, c2);
	ok.addActionListener(this);
	pack();
	show();
    }
    
    public void actionPerformed(ActionEvent e) {
	dispose();
    }

    public void windowClosing(WindowEvent e) {
	dispose();
    }

    public void windowClosed(WindowEvent e) { }
    public void windowActivated(WindowEvent e) { }
    public void windowIconified(WindowEvent e) { }
    public void windowDeactivated(WindowEvent e) { }
    public void windowDeiconified(WindowEvent e) { }
    public void windowOpened(WindowEvent e) { }
}
