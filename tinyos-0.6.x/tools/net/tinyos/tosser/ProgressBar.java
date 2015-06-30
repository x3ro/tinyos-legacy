package net.tinyos.tosser;

import java.awt.*;
import javax.swing.*;
import javax.swing.event.*;

public class ProgressBar extends JPanel {
    private JSlider slider;
    private JLabel label;
    
    
    public ProgressBar() {
	super();
	slider = new JSlider(0, 10000000, 1);
	label = new JLabel("         1");

	slider.addChangeListener(new SliderChangeListener(label));

	this.setLayout(new BoxLayout(this, BoxLayout.X_AXIS));

	add(label);
	add(slider);
    }

    public void setMaximum(int max) {
	slider.setMaximum(max);
    }

    public void setCurrent(int curr) {
	slider.setValue(curr);
    }
    
    private class SliderChangeListener implements ChangeListener {
	private JLabel label;
	
	public SliderChangeListener(JLabel label) {
	    this.label = label;
	}
	
	public void stateChanged(ChangeEvent e) {
	    JSlider slider = (JSlider)e.getSource();
	    String val = "" + slider.getValue();
	    while(val.length() < 10) {
		val = " " + val;
	    }
	    label.setText(val);
	}
    }


}
