import java.util.*;
import java.awt.*;
import java.applet.Applet;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.sql.Time;

public class oscilloscope extends JPanel implements ActionListener, ItemListener, ChangeListener {

    Button timeout = new Button("Control Panel");
    Button move_up = new Button("^");
    Button move_down = new Button("v");
    Button move_right = new Button(">");
    Button move_left = new Button("<");
    Button zoom_out_x = new Button("Zoom Out X");
    Button zoom_in_x = new Button("Zoom In X");
    Button zoom_out_y = new Button("Zoom Out Y");
    Button zoom_in_y = new Button("Zoom In Y");
    Checkbox scrolling = new Checkbox("Scrolling", true);
    JSlider time_location = new JSlider(0, 5000, 5000);

    public JLabel high_pass_val= new JLabel("5");
    public JLabel low_pass_val = new JLabel("2");
    public JLabel cutoff_val = new JLabel("65");
    public JSlider high_pass= new JSlider(0, 30, 5);
    public JSlider low_pass = new JSlider(0, 30, 2);
    public JSlider cutoff = new JSlider(0, 4000, 65);

    GraphPanel panel;
    Panel controlPanel;

    public void init() {
        time_location.addChangeListener(this);
	setLayout(new BorderLayout());
	panel = new GraphPanel(this);
	add("Center", panel);
	controlPanel = new Panel();
	add("South", controlPanel);	
	Panel x_pan = new Panel();
	x_pan.setLayout(new GridLayout(2,1));
	x_pan.add(zoom_in_x);
	x_pan.add(zoom_out_x); 
	zoom_out_x.addActionListener(this);
	zoom_in_x.addActionListener(this);
	controlPanel.add(x_pan);
	Panel y_pan = new Panel();
	y_pan.setLayout(new GridLayout(2,1));
	y_pan.add(zoom_in_y);
	y_pan.add(zoom_out_y); 
	zoom_out_y.addActionListener(this);
	zoom_in_y.addActionListener(this);
	controlPanel.add(y_pan);

	Panel scroll_pan = new Panel();
	move_up.addActionListener(this);
	move_down.addActionListener(this);
	move_right.addActionListener(this);
	move_left.addActionListener(this);
	scroll_pan.setLayout(new GridLayout(2,2));
	scroll_pan.add(move_up);
	scroll_pan.add(move_left);
	scroll_pan.add(move_right);
	scroll_pan.add(move_down);
	controlPanel.add(scroll_pan);
	


	controlPanel.add(timeout); timeout.addActionListener(this);
	Panel p = new Panel();
	p.setLayout(new GridLayout(2, 1));
	p.add(scrolling); scrolling.addItemListener(this);
	p.add(time_location);
	controlPanel.add(p);

	panel.repaint();
	repaint();
    }

    public void destroy() {
        remove(panel);
        remove(controlPanel);
    }

    public void start() {
	panel.start();
    }

    public void stop() {
	panel.stop();
    }

    public void actionPerformed(ActionEvent e) {
	Object src = e.getSource();
	if (src == zoom_out_x) {
	  panel.zoom_out_x();
	  panel.repaint();
	} else if (src == zoom_in_x) {
	  panel.zoom_in_x();
	  panel.repaint();
	} else if (src == zoom_out_y) {
	  panel.zoom_out_y();
	  panel.repaint();
	} else if (src == zoom_in_y) {
	  panel.zoom_in_y();
	  panel.repaint();
	} else if (src == move_up) {
	  panel.move_up();
	  panel.repaint();
	} else if (src == move_down) {
	  panel.move_down();
	  panel.repaint();
	} else if (src == move_right) {
	  panel.move_right();
	  panel.repaint();
	} else if (src == move_left) {
	  panel.move_left();
	  panel.repaint();
	} else if (src == timeout) {
    JFrame sliders = new JFrame("Filter Controls");
	sliders.setSize(new Dimension(300,30));
	sliders.setVisible(true);
	Panel slp = new Panel();
	slp.setLayout(new GridLayout(3,3));
    	slp.add(new Label("high_pass:"));
    	slp.add(high_pass);
    	slp.add(high_pass_val);
    	slp.add(new Label("low_pass:"));
    	slp.add(low_pass);
    	slp.add(low_pass_val);
    	slp.add(new Label("cutoff:"));
    	slp.add(cutoff);
    	slp.add(cutoff_val);
    	high_pass.addChangeListener(this);
    	low_pass.addChangeListener(this);
    	cutoff.addChangeListener(this);
	sliders.getContentPane().add(slp);
	sliders.pack();
	sliders.repaint();
	}
    }


    public void itemStateChanged(ItemEvent e) {
	Object src = e.getSource();
	boolean on = e.getStateChange() == ItemEvent.SELECTED;
	if (src == scrolling) {
		panel.sliding = on;
	}
    }

    public void stateChanged(ChangeEvent e){
	Object src = e.getSource();
	if(src == time_location){
		panel.start -= panel.end - time_location.getValue();
		panel.end = time_location.getValue();
	}
	high_pass_val.setText("" + high_pass.getValue());
	cutoff_val.setText("" + cutoff.getValue());
	low_pass_val.setText("" + low_pass.getValue());
	panel.repaint();
    }

static oscilloscope app;
static Frame mainFrame;
public static void main(String[] args) {
    mainFrame = new Frame("Oscilloscope");
    app = new oscilloscope();
    app.init();
    mainFrame.setSize( app.getSize() );
    mainFrame.add("Center", app);
    mainFrame.show();
    mainFrame.repaint(1000);
    app.panel.repaint();
    mainFrame.addWindowListener
      (
        new WindowAdapter()
        {
          public void windowClosing    ( WindowEvent wevent )
          {
            System.exit(0);
          }
        }
      );
    app.start();
  }
    public Dimension getSize()
    {
	return new Dimension(600, 600);
    }

}

