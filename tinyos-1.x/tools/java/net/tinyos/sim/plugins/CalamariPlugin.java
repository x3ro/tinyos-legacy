// $Id: CalamariPlugin.java,v 1.7 2004/10/21 22:26:37 selfreference Exp $

/* This plugin sets the rssi value of each mote based on their
 * locations in the mote window. Motes can read their rssi values from the
 * ADC, using ADC Channel PORT_RSSI (Defined below).
 */

package net.tinyos.sim.plugins;

import java.lang.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import net.tinyos.message.*;
import net.tinyos.sim.*;
import net.tinyos.sim.event.*;
import net.tinyos.matlab.*;

public class CalamariPlugin extends GuiPlugin implements SimConst {

    public static final byte X_POS_ADC_CHANNEL = (byte) 112;
    public static final byte Y_POS_ADC_CHANNEL = (byte)113;
    public static final byte X_STDV_ADC_CHANNEL = (byte)114;
    public static final byte Y_STDV_ADC_CHANNEL = (byte)115;
    public static final byte TXR_COEFF_O_ADC_CHANNEL = (byte)116;
    public static final byte TXR_COEFF_1_ADC_CHANNEL = (byte)117;
    public static final byte RXR_COEFF_O_ADC_CHANNEL = (byte)118;
    public static final byte RXR_COEFF_1_ADC_CHANNEL = (byte)119;

    public static final byte PORT_RSSI = (byte) 131;
    public static final byte PORT_RSSI_STDV = (byte) 132;

    /* Mapping from coordinate axis to location ADC value */
    private Hashtable locationEstimates = new Hashtable();
    private JTextField xscalingFactorTextField;
    private JTextField yscalingFactorTextField;
    private JTextField maxRangeTextField;
    private JTextField maxErrorTextField;
    public double NOISE_LEVEL= 30;//30 cm error in ranging
    public double MAX_RANGE= 300;//3 meters ranging distance
    public double X_SCALE = 2000;//20 meters
    public double Y_SCALE = 2000;//20 meters

    public void handleEvent(SimEvent event) {
        if (event instanceof AttributeEvent) {
            AttributeEvent ae = (AttributeEvent) event;
            if (ae.getType() == AttributeEvent.ATTRIBUTE_CHANGED) {
                if (ae.getOwner() instanceof MoteSimObject &&
                        ae.getAttribute() instanceof CoordinateAttribute) {
                    tv.getMotePanel().refresh();
                }
            }
        } else if (event instanceof TossimInitEvent) {
            locationEstimates.clear();
        } else if (event instanceof DebugMsgEvent) {
            DebugMsgEvent dme = (DebugMsgEvent) event;
            if (dme.getMessage().indexOf("LOCALIZATION:") != -1) {
                int nodeID = dme.getMoteID();
                MoteSimObject mote = state.getMoteSimObject(nodeID);
                if (mote == null) return;
                LocationEstimate loc;
         //       System.out.println("got a localization msg");
                if (locationEstimates.containsKey(new Integer(nodeID)))
                    loc = (LocationEstimate) locationEstimates.get(new Integer(nodeID));
                else {
                    loc = new LocationEstimate();
                    loc.nodeID = nodeID;
                }

                //dbg("Localization: is anchor")
                if (dme.getMessage().indexOf("is anchor") != -1) {
                    loc.isAnchor = true;
                    locationEstimates.put(new Integer(nodeID), loc);
     //               tv.setStatus("Observed " + mote.getID() + " is anchor");
                    return;
                }

                //dbg("Localization: is not anchor")
                if (dme.getMessage().indexOf("is not anchor") != -1) {
                    loc.isAnchor = false;
                    locationEstimates.put(new Integer(nodeID), loc);
  //                  tv.setStatus("Observed " + mote.getID() + " is not anchor");
                    return;
                }

                //dbg("Localization: x= X xStdv= XStdv y= Y y= YStdv")
                try {
                    StringTokenizer st = new StringTokenizer(dme.getMessage());
                    st.nextToken();
                    st.nextToken();
                    loc.x = (int)(Integer.parseInt(st.nextToken())/X_SCALE *cT.getMoteScaleWidth());
                    st.nextToken();
                    loc.xStdv = (int)(Integer.parseInt(st.nextToken())/X_SCALE *cT.getMoteScaleWidth());
                    st.nextToken();
                    loc.y = (int)(Integer.parseInt(st.nextToken())/Y_SCALE *cT.getMoteScaleHeight());
                    st.nextToken();
                    loc.yStdv = (int)(Integer.parseInt(st.nextToken())/Y_SCALE *cT.getMoteScaleHeight());
                    locationEstimates.put(new Integer(nodeID), loc);
                    tv.getMotePanel().refresh();
   //                 tv.setStatus("Observed location estimate of mote " + mote.getID() + " to (" + loc.x + "," + loc.y + ")");
                } catch (Exception e) {
                    tv.setStatus("Error parsing location estimate of mote " + mote.getID());
                }
            }
            else if (dme.getMessage().indexOf("ADC ATTR:") != -1) {
                    int nodeID = dme.getMoteID();
                    int channel;
                    try {
                        StringTokenizer st = new StringTokenizer(dme.getMessage());
                        st.nextToken();st.nextToken();st.nextToken();st.nextToken();st.nextToken(); //"ADC ATTR: reading from channel XX"
                        channel = Integer.parseInt(st.nextToken());
                    } catch (Exception e) {
                        tv.setStatus("Attr: parse error:   "+e.toString());
                        return;
                    }
                    MoteSimObject mote = state.getMoteSimObject(nodeID);
                    if (mote == null) {tv.setStatus(" No such mote");return;}
                    Integer value = null;
                    switch ((byte)channel) {
                        case X_POS_ADC_CHANNEL:
                            {
                                CoordinateAttribute coord = mote.getCoordinate();
                                int x = (int)(((coord.getX() * X_SCALE) / cT.getMoteScaleWidth()));
                                value = new Integer(x);
                                break;
                            }
                        case Y_POS_ADC_CHANNEL:
                            {
                                CoordinateAttribute coord = mote.getCoordinate();
                                int y = (int)(((coord.getY() * Y_SCALE) / cT.getMoteScaleHeight()));
                                value = new Integer(y);
                                break;
                            }
                        case X_STDV_ADC_CHANNEL:
                            {
                                value = new Integer(0);
                                break;
                            }
                        case Y_STDV_ADC_CHANNEL:
                            {
                                value = new Integer(0);
                                break;
                            }
                        case TXR_COEFF_O_ADC_CHANNEL:
                            {
                                value = new Integer(0);
                                break;
                            }
                        case TXR_COEFF_1_ADC_CHANNEL:
                            {
                                value = new Integer(0);
                                break;
                            }
                        case RXR_COEFF_O_ADC_CHANNEL:
                            {
                                value = new Integer(0);
                                break;
                            }
                        case RXR_COEFF_1_ADC_CHANNEL:
                            {
                                value = new Integer(1);
                                break;
                            }
                        default:
                            {
                                tv.setStatus("Unknown ADC port read from:" + Integer.toString(channel));
/*                      try {
                        MatlabControl matlab = new MatlabControl(true);
                            Object args[] = new Object[2];
                            args[0] = new Integer(nodeID);
                            args[1] = new Integer(channel);
                            value = (Integer) matlab.blockingFeval("getADCValue", args);
                        } catch (Exception e) {
                            tv.setStatus("ERROR reading from Matlab on ADC channel "+channel);
                        }*/
                            }
                    }
                    try {
                        if (value == null) return;
                        simComm.sendCommand(new SetADCPortValueCommand((short) mote.getID(), 0L,(short)channel, value.intValue()));
 //                       tv.setStatus("Setting Value for mote " + mote.getID() + " on ADC channel " + channel + " to " + value.toString());
                    } catch (Exception e) {
                        tv.setStatus("ERROR Setting Value for mote " + mote.getID() + " on ADC channel " + channel);
                    }
                }
            else if (dme.getMessage().indexOf("RSSI MSG:") != -1) {
                int rxrID = dme.getMoteID();
                int txrID;
                try {
                    StringTokenizer st = new StringTokenizer(dme.getMessage());
                    st.nextToken();st.nextToken();st.nextToken(); //"RSSI MSG: transmitter XX"
                    txrID = Integer.parseInt(st.nextToken());
                } catch (Exception e) {tv.setStatus("parse error"+ e.getMessage());tv.resume(); return; }
                MoteSimObject txr = state.getMoteSimObject(txrID), rxr = state.getMoteSimObject(rxrID);
                if (txr == null || rxr == null) {return;}
                CoordinateAttribute txrCoord = txr.getCoordinate(), rxrCoord = rxr.getCoordinate();
                int txrx = (int) (((txrCoord.getX() * X_SCALE) / cT.getMoteScaleWidth()));
                int txry = (int) (((txrCoord.getY() * Y_SCALE) / cT.getMoteScaleHeight()));
                int rxrx = (int) (((rxrCoord.getX() * X_SCALE) / cT.getMoteScaleWidth()));
                int rxry = (int) (((rxrCoord.getY() * Y_SCALE) / cT.getMoteScaleHeight()));
                int distance = (int) Math.sqrt(Math.pow(txrx - rxrx, 2) + Math.pow(txry - rxry, 2));
                try {
                    /*Object args[] = new Object[3];
                    args[0] = new Integer(txrID);
                    args[1] = new Integer(rxrID);
                    args[2] = new Integer(distance);
                    MatlabControl matlab = new MatlabControl(true);
                    Integer rssi = (Integer) matlab.blockingFeval("getRssiValue", args);*/
                    Integer rssi;
                    if(distance>MAX_RANGE)
                        rssi= new Integer(0);
                    else
                        rssi = new Integer(distance + (int)(NOISE_LEVEL*(SimRandom.random()*2-1)));
                    simComm.sendCommand(new SetADCPortValueCommand((short) rxr.getID(), 0L, PORT_RSSI, rssi.intValue()));
                    simComm.sendCommand(new SetADCPortValueCommand((short) rxr.getID(), 0L, PORT_RSSI_STDV, (int)NOISE_LEVEL));
//                    tv.setStatus("Setting RSSI for mote " + rxr.getID() + " to (" + rssi + ")" + "for msg from " + txr.getID());
                } catch (Exception e) {
                    tv.setStatus("ERROR Setting RSSI for mote " + rxr.getID() + "for msg from " + txr.getID()+": "+e.toString());
                }
            }
        }
    }

    public void register() {
        JTextArea ta = new JTextArea(2, 50);
        ta.setFont(tv.defaultFont);
        ta.setEditable(false);
        ta.setBackground(Color.lightGray);
        ta.setLineWrap(true);
        ta.setText("Blue arrows are error vectors and circles at the end indicate uncertainty." +
                " Nodes with red circles around them are anchor nodes.");
        pluginPanel.add(ta);

        JPanel parameterPane = new JPanel();
        parameterPane.setLayout(new GridLayout(7,2,1,1));

        // Create radius constant text field and label
        JLabel xscalingFactorLabel = new JLabel("Field width (cm)");
        xscalingFactorLabel.setFont(tv.defaultFont);
        xscalingFactorTextField = new JTextField(Double.toString(X_SCALE), 5);
        xscalingFactorTextField.setFont(tv.smallFont);
        xscalingFactorTextField.setEditable(true);
        parameterPane.add(xscalingFactorLabel);
        parameterPane.add(xscalingFactorTextField);

        // Create radius constant text field and label
        JLabel yscalingFactorLabel = new JLabel("Field height (cm)");
        yscalingFactorLabel.setFont(tv.defaultFont);
        yscalingFactorTextField = new JTextField(Double.toString(Y_SCALE), 5);
        yscalingFactorTextField.setFont(tv.smallFont);
        yscalingFactorTextField.setEditable(true);
        parameterPane.add(yscalingFactorLabel);
        parameterPane.add(yscalingFactorTextField);

        JLabel maxRangeLabel = new JLabel("Maximum Distance (cm)");
        maxRangeLabel.setFont(tv.defaultFont);
        maxRangeTextField = new JTextField(Double.toString(MAX_RANGE), 5);
        maxRangeTextField.setFont(tv.smallFont);
        maxRangeTextField.setEditable(true);
        parameterPane.add(maxRangeLabel);
        parameterPane.add(maxRangeTextField);

        JLabel maxErrorLabel = new JLabel("Maximum Error(cm)");
        maxErrorLabel.setFont(tv.defaultFont);
        maxErrorTextField = new JTextField(Double.toString(NOISE_LEVEL), 5);
        maxErrorTextField.setFont(tv.smallFont);
        maxErrorTextField.setEditable(true);
        parameterPane.add(maxErrorLabel);
        parameterPane.add(maxErrorTextField);

        // Create button to update radio model
        JButton updateButton = new JButton("Update");
        updateButton.addActionListener(new CalamariPlugin.UpdateListener());
        updateButton.setFont(tv.defaultFont);

        //pluginPanel.setLayout(new BorderLayout());
        pluginPanel.add(parameterPane);
        pluginPanel.add(updateButton);
        pluginPanel.revalidate();

        update();

    }

    public void deregister
            () {
    }

    public void update() {
        X_SCALE= Double.parseDouble(xscalingFactorTextField.getText());
        Y_SCALE= Double.parseDouble(yscalingFactorTextField.getText());
        MAX_RANGE= Double.parseDouble(maxRangeTextField.getText());
        NOISE_LEVEL= Double.parseDouble(maxErrorTextField.getText());
      }

    public void draw(Graphics graphics) {
        Enumeration estimates = locationEstimates.elements();
        while (estimates.hasMoreElements()) {
            LocationEstimate loc = (LocationEstimate) estimates.nextElement();
            MoteSimObject mote = state.getMoteSimObject(loc.nodeID);
            if (mote == null) continue;
            CoordinateAttribute coord = mote.getCoordinate();
            if (loc.isAnchor) {
                graphics.setColor(Color.red);
                graphics.setColor(Color.red);
                graphics.drawOval((int) cT.simXToGUIX(coord.getX()) - 10, (int) cT.simYToGUIY(coord.getY()) - 10, 20, 20);
            }
            else{
                if( (loc.xStdv * X_SCALE / cT.getMoteScaleWidth()>32000) || (loc.yStdv * Y_SCALE / cT.getMoteScaleHeight()>32000) ) continue;
                graphics.setColor(Color.blue);
                Arrow.drawArrow(graphics,(int) cT.simXToGUIX(loc.x), (int) cT.simYToGUIY(loc.y), (int) cT.simXToGUIX(coord.getX()), (int) cT.simYToGUIY(coord.getY()),Arrow.SIDE_TRAIL);
                graphics.setColor(Color.lightGray);
                graphics.drawLine((int) cT.simXToGUIX(loc.x), (int) cT.simYToGUIY(loc.y), (int) cT.simXToGUIX(loc.x+(loc.xStdv/2)), (int) cT.simYToGUIY(loc.y));
                graphics.drawLine((int) cT.simXToGUIX(loc.x), (int) cT.simYToGUIY(loc.y), (int) cT.simXToGUIX(loc.x-(loc.xStdv/2)), (int) cT.simYToGUIY(loc.y));
                graphics.drawLine((int) cT.simXToGUIX(loc.x), (int) cT.simYToGUIY(loc.y), (int) cT.simXToGUIX(loc.x), (int) cT.simYToGUIY(loc.y+(loc.yStdv/2)));
                graphics.drawLine((int) cT.simXToGUIX(loc.x), (int) cT.simYToGUIY(loc.y), (int) cT.simXToGUIX(loc.x), (int) cT.simYToGUIY(loc.y-(loc.yStdv/2)));
                graphics.drawOval((int) cT.simXToGUIX(loc.x-(loc.xStdv/2)), (int) cT.simYToGUIY(loc.y-(loc.yStdv/2)), (int) cT.simXToGUIX(loc.xStdv), (int) cT.simYToGUIY(loc.yStdv));
            }
        }
    }

    public String toString
            () {
        return "Calamari";
    }

    public class LocationEstimate {
        public int nodeID,x,y,xStdv,yStdv;
        public boolean isAnchor;

        LocationEstimate() {
            isAnchor = false;
        }
    }

    class UpdateListener implements ActionListener {
    public void actionPerformed(ActionEvent e) {
        update();
      motePanel.refresh();
    }
  }
}


