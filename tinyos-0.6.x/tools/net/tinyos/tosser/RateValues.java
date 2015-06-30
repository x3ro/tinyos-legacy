package net.tinyos.tosser;

import java.awt.*;
import javax.swing.*;

public class RateValues extends JPanel {
    private JTextField exec;
    private JTextField idle;
    private JLabel execLabel;
    private JLabel idleLabel;
    private ImageIcon execIcon;
    private ImageIcon idleIcon;

    public RateValues() {
	super();
	setLayout(new GridLayout(2,2));

	exec = new JTextField("1");
	exec.setColumns(2);
	idle = new JTextField("3");
	idle.setColumns(2);
	
	execIcon = new ImageIcon("net/tinyos/tosser/run.gif");
	idleIcon = new ImageIcon("net/tinyos/tosser/idle.gif");
	
	execLabel = new JLabel(execIcon);
	idleLabel = new JLabel(idleIcon);
	
	add(execLabel);
	add(idleLabel);
	add(exec);
	add(idle);
    }

    public int getExecTicks() {
        long val = 1;
        try {
            val = Long.parseLong(exec.getText());
        } finally {
            return (int)val;
        }
    }

    public int getIdleTicks() {
        long val = 3;
        try {
            val = Long.parseLong(idle.getText());
        } finally {
            return (int)val;
        }
    }
    
}
