package net.tinyos.tosser;

import java.awt.*;
import javax.swing.*;
import javax.swing.event.*;

public class RateBar extends JPanel {
    private JSlider slider;
    private RateValues values;
    private JLabel label;

    public RateBar() {
	super();

	slider = new JSlider(0, 50, 1);
	label = new JLabel(" 1");
	values = new RateValues();
	
	slider.setMajorTickSpacing(10);
	slider.setMinorTickSpacing(1);
	slider.setLabelTable(slider.createStandardLabels(10));
	slider.setPaintTicks(true);
	slider.setPaintLabels(true);
	slider.setSnapToTicks(true);

	slider.addChangeListener(new SliderChangeListener(label));

	this.setLayout(new BoxLayout(this, BoxLayout.X_AXIS));
	
	add(label);
	add(new JLabel("  "));
	add(slider);
	add(new JLabel("       "));
	add(values);
    }

    private class SliderChangeListener implements ChangeListener {
	private JLabel label;
	
	public SliderChangeListener(JLabel label) {
	    this.label = label;
	}
	
	public void stateChanged(ChangeEvent e) {
	    JSlider slider = (JSlider)e.getSource();
	    String str = "" + slider.getValue();
	    Integer val = new Integer(str);

	    if (val.intValue() == 0) {
		slider.setValue(1);
		str = "" + slider.getValue();
	    }
	    if (str.length() == 1) {
		str = " " + val;
	    }
	    label.setText(str);

	}
    }

    public int getRate() {
	return slider.getValue();
    }

    public int getExecTicks() {
	return values.getExecTicks();
    }

    public int getIdleTicks() {
	return values.getIdleTicks();
    }
    
}
