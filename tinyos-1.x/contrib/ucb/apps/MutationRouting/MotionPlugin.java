
package net.tinyos.sim.plugins;
import java.lang.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.event.MouseInputAdapter;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.plugins.CalamariPlugin;
import net.tinyos.sim.event.*;
import net.tinyos.matlab.*;

public class MotionPlugin extends GuiPlugin implements SimConst, MouseListener, MouseMotionListener {

    /* Mapping from coordinate axis to location ADC value */
    private JTextField xPositionLabel;
    private JTextField yPositionLabel;
    private JTextField velocityLabel;
    private JTextField momentumLabel;
    private JTextField angleLabel;
    private JComboBox whichAngleType;
    protected Color color;
    private JCheckBox move;
    private double time=0;
    private double xPosition;
    private double yPosition;
    private double velocity;
    private double angle;
    private boolean radians;
    private double momentum;
    private double nodeWidth;//=0.02*cT.getMoteScaleWidth(); //in percentage of screen size
    private double nodeHeight;//=0.02*cT.getMoteScaleHeight(); //in percentage of screen size
    private boolean registered;
    //private ScreenWatcher screenWatcher;
    private boolean isClicked;
    protected byte leaderAdcChannel;

    public JPanel parameterPane;

    //private MagMotionPlugin mag = null;

    private double degToRad = Math.PI/180;
    private double radToDeg = 180/Math.PI;

    public byte getLeaderAdcChannel() {
        return leaderAdcChannel;
    }

   public boolean isRegistered() {
        return registered;
    }

    public Color getColor() {
        return color;
    }

    public double getXPosition() {
        return xPosition;
    }

    public double getYPosition() {
        return yPosition;
    }


    public void handleEvent(SimEvent event) {
//        if(event instanceof TossimEvent){// only the following three events actually have correct time.
//       if( (event instanceof TossimInitEvent) || (event instanceof RadioMsgSentEvent) || (event instanceof UARTMsgSentEvent) ){
        if ( (event instanceof RadioMsgSentEvent) || (event instanceof UARTMsgSentEvent) ){
	    TossimEvent te = (TossimEvent) event;

            if(!isClicked && move.isSelected())
                move();
	    /*
	    if (mag != null)
		mag.changeMagStrength();
	    */
        }
    }

    public void register() {
	/* find MagMotionPlugin */
	/*
	Plugin plugins[] = tv.getSimDriver().getPluginManager().plugins();
	for (int i = 0; i < plugins.length; i++) {
	    if (plugins[i] instanceof MagMotionPlugin) {
		mag = (MagMotionPlugin)plugins[i];
		break;
	    }
	}
	*/

        isClicked=false;
        tv.getMotePanel().addMouseListener(this);//screenWatcher);
        tv.getMotePanel().addMouseMotionListener(this);//screenWatcher);
        registered=true;
        momentum=.95;
        angle=Math.random()*Math.PI*2;
	radians = true;
        velocity=1;
        time=-1;
        nodeWidth=0.02*cT.getMoteScaleWidth(); //in percentage of screen size
        nodeHeight=0.02*cT.getMoteScaleHeight(); //in percentage of screen size
        JTextArea ta = new JTextArea(2, 50);
        ta.setFont(tv.defaultFont);
        ta.setEditable(false);
        ta.setBackground(color);
        ta.setLineWrap(true);
        ta.setText("The current position is indicated by a square this color.");
        pluginPanel.add(ta);

        parameterPane = new JPanel();
        parameterPane.setLayout(new GridLayout(7,2,1,1));

        // Create radius constant text field and label
        JLabel xscalingFactorLabel = new JLabel("X Position (units)");
        xscalingFactorLabel.setFont(tv.defaultFont);
        xPositionLabel = new JTextField(Double.toString(Math.random()*cT.getMoteScaleWidth()), 5);
        xPositionLabel.setFont(tv.smallFont);
        xPositionLabel.setEditable(false);
        parameterPane.add(xscalingFactorLabel);
        parameterPane.add(xPositionLabel);

        // Create radius constant text field and label
        JLabel yscalingFactorLabel = new JLabel("Y Position (units)");
        yscalingFactorLabel.setFont(tv.defaultFont);
        yPositionLabel = new JTextField(Double.toString(Math.random()*cT.getMoteScaleHeight()), 5);
        yPositionLabel.setFont(tv.smallFont);
        yPositionLabel.setEditable(false);
        parameterPane.add(yscalingFactorLabel);
        parameterPane.add(yPositionLabel);

        JLabel maxRangeLabel = new JLabel("Velocity (units/sec)");
        maxRangeLabel.setFont(tv.defaultFont);
        velocityLabel = new JTextField(Double.toString(velocity), 5);
        velocityLabel.setFont(tv.smallFont);
        velocityLabel.setEditable(true);
        parameterPane.add(maxRangeLabel);
        parameterPane.add(velocityLabel);

        JLabel maxErrorLabel = new JLabel("Momentum [0,1]");
        maxErrorLabel.setFont(tv.defaultFont);
        momentumLabel = new JTextField(Double.toString(momentum), 5);
        momentumLabel.setFont(tv.smallFont);
        momentumLabel.setEditable(true);
        parameterPane.add(maxErrorLabel);
        parameterPane.add(momentumLabel);

        JLabel angleNameLabel = new JLabel("Angle (0 cw on x-axis)");
        angleNameLabel.setFont(tv.defaultFont);
        angleLabel = new JTextField(Double.toString(angle), 5);
        angleLabel.setFont(tv.smallFont);
        angleLabel.setEditable(true);
        parameterPane.add(angleNameLabel);
        parameterPane.add(angleLabel);

        // Create button to update radio model
        JButton updateButton = new JButton("Update");
        updateButton.addActionListener(new MotionPlugin.UpdateListener());
        updateButton.setFont(tv.defaultFont);

	String[] angles = {"[0,2Pi)", "[0,360)"};
	whichAngleType = new JComboBox(angles);
	whichAngleType.setSelectedIndex(0);
	whichAngleType.addItemListener(new MotionPlugin.UpdateWhichAngle());
        whichAngleType.setFont(tv.defaultFont);

        move = new JCheckBox("Move");
        move.setFont(tv.labelFont);
        move.setSelected(true);
        parameterPane.add(move);

	JPanel parameterPane2 = new JPanel();
        parameterPane2.setLayout(new GridLayout(2,1,1,1));
	parameterPane2.add(updateButton);
	parameterPane2.add(whichAngleType);

        //pluginPanel.setLayout(new BorderLayout());
        pluginPanel.add(parameterPane);
        //pluginPanel.add(updateButton);
	pluginPanel.add(parameterPane2);
        pluginPanel.revalidate();

        update();


    }

    public void deregister
            () {
        registered=false;
    }

    public void update() {
        xPosition= Double.parseDouble(xPositionLabel.getText());
        if(xPosition>cT.getMoteScaleWidth()-nodeWidth){
            xPosition=cT.getMoteScaleWidth()-nodeWidth;
            xPositionLabel.setText(Double.toString(xPosition));
        }
        else if(xPosition<0){
            xPosition=0;
            xPositionLabel.setText(Double.toString(xPosition));
        }

        yPosition= Double.parseDouble(yPositionLabel.getText());
        if(yPosition>cT.getMoteScaleHeight()-nodeHeight){
            yPosition=cT.getMoteScaleHeight()-nodeHeight;
            yPositionLabel.setText(Double.toString(yPosition));
        }
        else if(yPosition<0){
            yPosition=0;
            yPositionLabel.setText(Double.toString(yPosition));
        }

        velocity= Double.parseDouble(velocityLabel.getText());
        if(velocity>Math.max(cT.getMoteScaleHeight()-nodeHeight,cT.getMoteScaleWidth()-nodeWidth)){
            velocity=Math.max(cT.getMoteScaleHeight()-nodeHeight,cT.getMoteScaleWidth()-nodeWidth);
            velocityLabel.setText(Double.toString(velocity));
        }
        else if(velocity<0){
            velocity=0;
            velocityLabel.setText(Double.toString(velocity));
        }

        momentum= Double.parseDouble(momentumLabel.getText());
        if(momentum>1){
            momentum=1;
            momentumLabel.setText(Double.toString(momentum));
        }
        else if(momentum<0){
            momentum=0;
            momentumLabel.setText(Double.toString(momentum));
        }

	angle = Double.parseDouble(angleLabel.getText());
	if (!radians) {
	    angle = angle * degToRad;
	}
	if(angle>Math.PI*2){
	    angle=Math.PI*2;
	    if (radians) {
		angleLabel.setText(Double.toString(angle));
	    }
	    else {
		angleLabel.setText(Double.toString(angle*radToDeg));
	    }
	}
	else if(angle<0){
	    angle=0;
	    angleLabel.setText(Double.toString(angle));
	}
	else {
	    if (radians) {
		angleLabel.setText(Double.toString(angle));
	    }
	    else {
		angleLabel.setText(Double.toString(angle*radToDeg));
	    }
	}
    }

    public void move() {
        boolean done=false;
        double newAngle = Math.random()*Math.PI*2;
        double xdelta=1;
        double ydelta=0;
        double newTime=tv.getTosTime();
        if(time==-1) {time=newTime; return;}
        if(time==newTime) return;
        if(move.isSelected()==false) return;
        while(!done){
            xdelta=(momentum*Math.cos(angle)*velocity + (1-momentum)*Math.cos(newAngle)*velocity)*(newTime-time);
            if( (xPosition+xdelta >= cT.getMoteScaleWidth()-nodeWidth) || (xPosition+  xdelta<=0))
                xdelta = -xdelta;
            if( (xPosition + xdelta< cT.getMoteScaleWidth()-nodeWidth) && (xPosition + xdelta >0)){
                xPosition= xPosition + xdelta;
                xPositionLabel.setText(Double.toString(xPosition));
                done=true;
            }
        }
        done=false;
        while(!done){
            ydelta=(momentum*Math.sin(angle)*velocity + (1-momentum)*Math.sin(newAngle)*velocity)*(newTime-time);
            if( (yPosition+ydelta >= cT.getMoteScaleHeight()-nodeHeight) || (yPosition+  ydelta<=0))
                ydelta = -ydelta;
            if( (yPosition + ydelta< cT.getMoteScaleHeight()-nodeHeight) && (yPosition + ydelta >0)){
                yPosition= yPosition + ydelta;
                yPositionLabel.setText(Double.toString(yPosition));
                done=true;
            }
        }
        time=newTime;
        angle=Math.atan(ydelta/Math.abs(xdelta));
        if(xdelta<0) angle=Math.PI-angle;
        if(xdelta==0){
            if(ydelta>0) angle = Math.PI/2;
            else if(ydelta<0) angle = -Math.PI/2;
        }
        if(angle<0) angle=2*Math.PI+angle;
	if (radians) {
	    angleLabel.setText(Double.toString(angle));
	}
	else {
	    angleLabel.setText(Double.toString(angle*radToDeg));
	}
        motePanel.refresh();
    }

    public void move(double angle) {
        boolean done=false;
        double newAngle = angle;
        double xdelta=1;
        double ydelta=0;
        double newTime=tv.getTosTime();
	//System.out.println("bar");
        if(time==-1) {time=newTime; return;}
	//System.out.println("asfd");
        if(time==newTime) return;
	//System.out.println("foo");
        while(!done){
            xdelta=(momentum*Math.cos(angle)*velocity + (1-momentum)*Math.cos(newAngle)*velocity)*(newTime-time);
            if( (xPosition+xdelta >= cT.getMoteScaleWidth()-nodeWidth) || (xPosition+  xdelta<=0))
                xdelta = -xdelta;
            if( (xPosition + xdelta< cT.getMoteScaleWidth()-nodeWidth) && (xPosition + xdelta >0)){
                xPosition= xPosition + xdelta;
                xPositionLabel.setText(Double.toString(xPosition));
                done=true;
            }
        }
        done=false;
        while(!done){
            ydelta=(momentum*Math.sin(angle)*velocity + (1-momentum)*Math.sin(newAngle)*velocity)*(newTime-time);
            if( (yPosition+ydelta >= cT.getMoteScaleHeight()-nodeHeight) || (yPosition+  ydelta<=0))
                ydelta = -ydelta;
            if( (yPosition + ydelta< cT.getMoteScaleHeight()-nodeHeight) && (yPosition + ydelta >0)){
                yPosition= yPosition + ydelta;
                yPositionLabel.setText(Double.toString(yPosition));
                done=true;
            }
        }
        time=newTime;
        angle=Math.atan(ydelta/Math.abs(xdelta));
        if(xdelta<0) angle=Math.PI-angle;
        if(xdelta==0){
            if(ydelta>0) angle = Math.PI/2;
            else if(ydelta<0) angle = -Math.PI/2;
        }
        if(angle<0) angle=2*Math.PI+angle;
	if (radians) {
	    angleLabel.setText(Double.toString(angle));
	}
	else {
	    angleLabel.setText(Double.toString(angle*radToDeg));
	}
        motePanel.refresh();
    }

    public void draw(Graphics graphics) {
	graphics.setColor(color);
	graphics.fillRect((int) cT.simXToGUIX(xPosition) - (int)cT.simXToGUIX(nodeWidth)/2, (int)cT.simYToGUIY(yPosition) -(int)cT.simYToGUIY(nodeHeight)/2, (int)cT.simXToGUIX(nodeWidth), (int)cT.simYToGUIY(nodeHeight));
	/*
	// call draw function of LeaderElectionObservationPlugin
	Plugin plugins[] = tv.getSimDriver().getPluginManager().plugins();
        for(int i=0;i<plugins.length;i++){
            if(plugins[i] instanceof LeaderElectionObserverPlugin){
		if (((LeaderElectionObserverPlugin)plugins[i]).isRegistered()) {
		    ((LeaderElectionObserverPlugin)plugins[i]).draw(graphics);
		}
            }
        }
	*/
    }

    public String toString() {
        return "Motion";
    }

    class UpdateListener implements ActionListener {
	public void actionPerformed(ActionEvent e) {
	    update();
	    motePanel.refresh();
	}
    }
    
    class UpdateWhichAngle implements ItemListener {
	public void itemStateChanged(ItemEvent e) {
	    //System.out.println(e);
	    if (e.getStateChange() == ItemEvent.SELECTED) {
		//System.out.println(whichAngleType.getSelectedIndex());
		double angle = Double.parseDouble(angleLabel.getText());
		if (!radians) {
		    angle = angle * degToRad;
		}
		if (whichAngleType.getSelectedIndex() == 1) {
		    radians = false;
		    angle = angle * radToDeg;
		    angleLabel.setText(Double.toString(angle));
		}
		else {
		    radians = true;
		    angleLabel.setText(Double.toString(angle));
		}
		motePanel.refresh();
	    }
	}
    }
    /*
    class IsMoving implements ItemListener {
	public void itemStateChanged(ItemEvent e) {
	    System.out.println(e);
	}
    }
    */

    public void mouseDragged(MouseEvent e){
        if(isClicked){
            xPosition=cT.guiXToSimX(e.getX());
            yPosition=cT.guiYToSimY(e.getY());
            xPositionLabel.setText(Double.toString(xPosition));
            yPositionLabel.setText(Double.toString(yPosition));
        }

    }

    public void mousePressed(MouseEvent e){
        //System.out.println("pressing");
        if((e.getX()>(int) cT.simXToGUIX(xPosition-nodeWidth/2)) &&
                (e.getX()<(int) cT.simXToGUIX(xPosition+nodeWidth/2)) &&
            (e.getY()>(int) cT.simYToGUIY(yPosition-nodeHeight/2)) &&
                (e.getY()<(int) cT.simYToGUIY(yPosition+nodeHeight/2))){
            isClicked=true;
            //System.out.println("got clicked");
        }

    }

    public void mouseReleased(MouseEvent e){
        isClicked=false;
        //System.out.println("got un-clicked");
    }

    public void mouseEntered(MouseEvent e){}
    public void mouseExited(MouseEvent e){}
    public void mouseMoved(MouseEvent e){}
    public void mouseClicked(MouseEvent e){}
}


