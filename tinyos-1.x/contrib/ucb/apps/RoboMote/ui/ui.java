import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.event.*;
import java.io.*;

public class ui {
	private static void createGUI() {

	    robot myRobot;
	    myRobot = new robot();

		JFrame.setDefaultLookAndFeelDecorated(true);

		JFrame frame = new JFrame("RoboMote UI");
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

		JLabel dragLabel = new JLabel("Drag Label ...");
		JLabel sliderLabel = new JLabel("Slider Label ...");

		JPanel labelPanel = new JPanel(new GridLayout());
		labelPanel.add(dragLabel);
		labelPanel.add(sliderLabel);

		JPanel panel = new JPanel(new BorderLayout());
		panel.add(labelPanel, BorderLayout.PAGE_START);

		JSlider steering = new JSlider(JSlider.HORIZONTAL, 0, 255, 127);
		steering.setName ("steering");
		JSlider throttle = new JSlider(JSlider.VERTICAL, 0, 255, 0);
		throttle.setName ("throttle");

		throttle.setMajorTickSpacing(127);
		throttle.setMinorTickSpacing(16);
		throttle.setPaintTicks(true);
		throttle.setPaintLabels(true);
		throttle.setValue(127);

		steering.setMajorTickSpacing(127);
		steering.setMinorTickSpacing(16);
		steering.setPaintTicks(true);
		steering.setPaintLabels(true);
		steering.setValue(127);

		SL sliderListener = new SL(sliderLabel, myRobot);
		steering.addChangeListener(sliderListener);
		throttle.addChangeListener(sliderListener);

		panel.add(throttle, BorderLayout.EAST);
		panel.add(steering, BorderLayout.PAGE_END);

		MM mousearea = new MM(dragLabel, throttle, steering);
		mousearea.setPreferredSize(new Dimension(256,256));
		mousearea.setBackground(Color.white);

		panel.add(mousearea, BorderLayout.CENTER);

		frame.getContentPane().add(panel);

		frame.pack();
		frame.setVisible(true);
	}

	public static void main(String[] args) {

		javax.swing.SwingUtilities.invokeLater(new Runnable() {
			public void run() {
				createGUI();
			}
		});
	}

}

class MM extends JPanel implements MouseInputListener {
	JSlider throttle_slider;
	JSlider steering_slider;
	JLabel updateLabel;

	static int press_x = 0;
	static int press_y = 0;

	public MM(JLabel label, JSlider thr, JSlider str) {
		updateLabel = label;
		throttle_slider = thr;
		steering_slider = str;

		addMouseListener(this);
		addMouseMotionListener(this);
	}
	
	public void mousePressed(MouseEvent e) {
		press_x = e.getX();
		press_y = e.getY();
	}

	public void mouseClicked(MouseEvent e) {
	}

	public void mouseEntered(MouseEvent e) {
	}

	public void mouseExited(MouseEvent e) {
	}
	
	public void mouseReleased(MouseEvent e) {
		updateLabel.setText ("X: " + (e.getX()) + "  Y: " + (e.getY()));

		throttle_slider.setValue (127);
		steering_slider.setValue (127);
	}

	public void mouseDragged(MouseEvent e) {
		updateLabel.setText ("X: " + (e.getX()) + "  Y: " + (e.getY()));

		throttle_slider.setValue (256 - e.getY());
		steering_slider.setValue (e.getX());
	}

	public void mouseMoved(MouseEvent e) {
	}
}

class SL implements ChangeListener {
	JLabel updateLabel;

	static int throttle_value;
	static int steering_value;

	
    static robot myRobot;

	public SL(JLabel label, robot Rbt) {
		updateLabel = label;
		myRobot = Rbt;
	}

	public void stateChanged(ChangeEvent e) {
		JSlider source = (JSlider)e.getSource();
		if (source.getName() == "throttle") {
			throttle_value = source.getValue();
			myRobot.setSpeed(throttle_value);
		}
		else if (source.getName() == "steering") {
			steering_value = source.getValue();
			myRobot.setSteering(steering_value);
		}
		updateLabel.setText ("S: " + steering_value + "  T: " + throttle_value);
	}
}
