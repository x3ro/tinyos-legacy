package net.tinyos.tosser;

import java.awt.*;
import java.awt.event.*;
import java.io.*;
import java.util.*;
import javax.swing.*;


public class ComponentListPanel extends JPanel {

    private ComponentList components;
    private JList list;
    private JScrollPane scrollPane;

    public ComponentListPanel(File tosDir) {
	super();
	this.components = new ComponentList(tosDir);
	this.list = makeJList(components);
	
	this.scrollPane = new JScrollPane(list);
	add(scrollPane);

	setVisible(true);
	scrollPane.setPreferredSize(new Dimension(200, 600));
    }
    
    public ComponentListPanel(ComponentList components) {
	super();
	this.components = components;
	this.list = makeJList(components);

	this.scrollPane = new JScrollPane(list);
	add(scrollPane);

	setVisible(true);
	scrollPane.setPreferredSize(new Dimension(200, 600));
    }

    public TOSComponent getSelectedComponent() {
	int index = list.getSelectedIndex();
	System.out.println("Selected: " + index);

	return (TOSComponent)list.getSelectedValue();
    }


    private JList makeJList(ComponentList comps) {
	JList newList = new JList(comps.componentList());
	FlowLayout layout = new FlowLayout(FlowLayout.LEFT);
	newList.setLayout(layout);
	
	newList.setCellRenderer(new ComponentCellRenderer());

	return newList;
    }
    
    private class ComponentCellRenderer implements ListCellRenderer {

	public Component getListCellRendererComponent(JList list, Object value, int index, boolean isSelected, boolean cellHasFocus) {
	    TOSComponent comp = (TOSComponent)value;
	    return new ComponentEntry(comp, isSelected, cellHasFocus);
	}
    }

    private class ComponentEntry extends JPanel {
	private JLabel label;
	private ImageIcon icon;

	public ComponentEntry(TOSComponent component, boolean selected, boolean hasFocus) {
	    super();
	    FlowLayout layout = new FlowLayout(FlowLayout.LEFT);
	    setLayout(layout);
	    addMouseListener(new EntryMouseListener(this));
	    
	    if (component.isCompound()) {
		icon = new ImageIcon("net/tinyos/tosser/cchip.gif");
	    }
	    else {
		icon = new ImageIcon("net/tinyos/tosser/chip.gif");
	    }
	    
	    label = new JLabel(component.getName(), icon, JLabel.LEFT);
	    if (hasFocus || selected) {
		label.setForeground(Color.yellow);
	    }
	    add(label);
	}

	protected void hilight(boolean is) {
	    if (is) {
		label.setForeground(Color.yellow);
		label.repaint();
	    }
	    else {
		label.setForeground(Color.black);
		label.repaint();
	    }
	}
    }

    private class EntryMouseListener implements MouseListener {
	private ComponentEntry entry;
	
	public EntryMouseListener(ComponentEntry entry) {
	    this.entry = entry;
	}
	
	public void mouseClicked(MouseEvent e) {
	    System.out.println("Clicked!");
	}

	
	public void mouseEntered(MouseEvent e) {
	    entry.hilight(true);
	}
	
	public void mouseExited(MouseEvent e) {
	    entry.hilight(false);
	}
	
	public void mousePressed(MouseEvent e) {}
	public void mouseReleased(MouseEvent e) {}
	
    }

    
}
