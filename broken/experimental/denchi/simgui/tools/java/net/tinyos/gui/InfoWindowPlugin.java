package net.tinyos.gui;

import java.util.*;
import java.awt.*;
import java.awt.event.*;

import net.tinyos.gui.event.*;

/**
 * Dependent on BaseGUI.
 *
 */

public class InfoWindowPlugin implements SimEventListener {

    private DoubleBufferPanel panel;
    private InfoMouseHandler mouse;
    private Vector openDialogs;


    public InfoWindowPlugin () {
	this.panel = SimDriver.display.getPanel();
	this.mouse = new InfoMouseHandler (panel, this);
	panel.addMouseListener(mouse);
	panel.addMouseMotionListener(mouse);
	openDialogs = new Vector();
    }

    public void dialogClosed(InfoDialog dialog) {
	System.err.println (dialog.getID() + " closing panel");
	openDialogs.remove(dialog);
    }

    public boolean addDialogBox(InfoDialog dialog) {
	if (!openDialogs.contains(dialog)) {
	    openDialogs.addElement(dialog);
	    return true;
	}
	else
	    return false;
    }

    class InfoDialog extends javax.swing.JDialog {

	int moteID;
	InfoWindowPlugin plugin;
	
	javax.swing.JLabel packetLabel;

	InfoDialog (int moteID, InfoWindowPlugin plugin) {
	    this.plugin = plugin;
	    this.moteID = moteID;
	    setDefaultCloseOperation(javax.swing.JFrame.DISPOSE_ON_CLOSE);
	    setModal(false);
	    setTitle("Info Dialog for " + moteID);
	    getContentPane().setLayout(null);
	    // dchi
	    setSize(400,220);
	    setVisible(false);

	    addWindowListener(new java.awt.event.WindowAdapter() {
		    public void windowClosed(WindowEvent e) {
			this_windowClosed(e);
		    }
		});
	    packetLabel = new javax.swing.JLabel("label");
	    getContentPane().add(packetLabel);
	    packetLabel.setBounds (5, 5, 200, 100);
	}

	public int getID () {
	    return moteID;
	}

	public void setLabel(String packet) {
	    packetLabel.setText(packet);
	}

	void this_windowClosed(WindowEvent e) {
	    Object object = e.getSource();
	    
	    if (object == InfoDialog.this) {
		InfoDialog td = (InfoDialog)object;
		td.plugin.dialogClosed(this);
	    }
	}
	
	public boolean equals(Object obj) {
	    if (obj instanceof InfoDialog) {
		InfoDialog dialog = (InfoDialog)obj;
		return (dialog.getID() == this.getID());
	    }
	    else {
		return false;
	    }
	}
    }
    
    class InfoMouseHandler implements MouseListener, MouseMotionListener {
	private DoubleBufferPanel panel;
	private InfoWindowPlugin plugin;

	InfoMouseHandler (DoubleBufferPanel panel, InfoWindowPlugin plugin) {
	    this.panel = panel;
	    this.plugin = plugin;
	}

	public void mouseClicked(MouseEvent e) {
	    System.err.println("Info Mouse clicked.");
	    
	    if ((e.getModifiers() & MouseEvent.BUTTON3_MASK) != 0) {
		Mote m = panel.getMote(e.getX(), e.getY());	
		if (m == null)
		    return;
		
		
		InfoDialog dialog = new InfoDialog (m.getID(), plugin);
	        if (plugin.addDialogBox(dialog))
		    dialog.show();
		else
		    System.err.println ("Dialog box already exists for " + m.getID());
		//do something
	    }
	}

	public void mousePressed(MouseEvent e) {}

	public void mouseReleased(MouseEvent e) {}

	public void mouseEntered(MouseEvent e) {/* do nothing */}
	
	public void mouseExited(MouseEvent e) {/* do nothing */}
	
	public void mouseDragged(MouseEvent e) {} 

	public void mouseMoved(MouseEvent e) { }
    }

    public void handleEvent (SimEvent event) {
	if (event instanceof SimPacketReceivedEvent) {
	    System.err.println ("SimBase: received event");
	    SimPacketReceivedEvent spr = (SimPacketReceivedEvent)event;
	
	    InfoDialog dialog = new InfoDialog (spr.getPacket().moteID(), this);
	    
	    int index = openDialogs.indexOf(dialog);
	    if (index != -1) 
		dialog = (InfoDialog) (openDialogs.get(index));
	    else
		return;
	    
	    dialog.setLabel(new String(spr.getPacket().data()));
	    
	}
	
    }
}
