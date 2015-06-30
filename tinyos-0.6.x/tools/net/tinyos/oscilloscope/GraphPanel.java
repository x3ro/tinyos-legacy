/*
 * "Copyright (c) 2001 and The Regents of the University
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * $\Id$
 */

/**
 * File: GraphPanel.java
 *
 * Description:
 * Displays data coming from the apps/oscilloscope application.
 * 
 * Requires that the SerialForwarder is already started.
 *
 * @author Jason Hill and Eric Heien
 */

package net.tinyos.oscilloscope;

import net.tinyos.util.*;


import java.io.*;
import java.util.*;
import java.awt.*;
import java.applet.Applet;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.sql.Time;

class V2 extends Vector{
	void chop(int number){
		removeRange(0, number);
	}
}

class Point2D {
	double x, y;

	Point2D( double newX, double newY ) {
		x = newX;
		y = newY;
	}

	double getX() {
		return x;
	}

	double getY() {
		return y;
	}

	public String toString() {
		return x+", "+y;
	}
}


public class GraphPanel extends Panel
    implements Runnable, MouseListener, MouseMotionListener, PacketListenerIF {	

	//set the number of channels to display and the number of readings
	// per packet.  2 channels and 4 reading means 2 readings per packet
	// per channel.
	int num_channels = 10;
	int num_readings = 10;


    boolean debug = false;
    boolean sliding = false;
    boolean legend = true;
    boolean connectPoints = true;
    boolean valueTest = false;
    int testChannel = -1,valueX,valueY;
    oscilloscope graph;
    
    //output stream for logging the data to.
    PrintWriter os;

    double bottom, top;
    int start, end;
    V2 cutoff; 
    V2 data[];
    String dataLegend[];
    boolean legendActive[];
    Color plotColors[];
    int moteNum[];  // Maps channel # to mote #
    int streamNum[];  // Maps channel # to mote stream #
    int lastPacketNum[];  // Last packet # for channel
    double xScaling=200, yScaling=75;
    Point highlight_start, highlight_end;

    GraphPanel(oscilloscope graph) {
	setBackground(Color.white);
 	addMouseListener(this);
 	addMouseMotionListener(this);
	cutoff = new V2();
	//create an array to hold the data sets.
	data = new V2[num_channels];
	for(int i = 0; i < num_channels; i ++) data[i] = new V2();
	dataLegend = new String[num_channels];
	legendActive = new boolean[num_channels];
	lastPacketNum = new int[num_channels];
	for( int i=0;i<num_channels;i++ ) lastPacketNum[i] = -1;
	streamNum = new int[num_channels];
	for( int i=0;i<num_channels;i++ ) streamNum[i] = -1;
	moteNum = new int[num_channels];
	for( int i=0;i<num_channels;i++ ) moteNum[i] = -1;
	plotColors = new Color[num_channels];
	for( int i=0;i<num_channels;i++ ) dataLegend[i] = "";
	dataLegend[0] = "Light";
	for( int i=0;i<num_channels;i++ ) legendActive[i] = false;
	for( int i=0;i<1;i++ ) legendActive[i] = true;
	plotColors[0] = Color.green;
	plotColors[1] = Color.red;
	plotColors[2] = Color.blue;
	plotColors[3] = Color.magenta;
	plotColors[4] = Color.orange;
	plotColors[5] = Color.yellow;
	plotColors[6] = Color.cyan;
	plotColors[7] = Color.pink;
	plotColors[8] = Color.green;
	plotColors[9] = Color.white;

	try{
		//create a file for logging data to.
		FileOutputStream f = new FileOutputStream("log");
		os = new PrintWriter(f);
	}catch(Exception e){
	 	e.printStackTrace();
	}
 	this.graph = graph;
	bottom = 00;
	top = 1024.00;
	start = -400; end = 5000;
	Thread t = new Thread(this);
	t.start();
	


    }
    int big_filter;
    int sm_filter;
    int db_filter;



    void add_point(Point2D val, int place){
	if(place >= data.length) return;
	data[place].add(val);
	if(val != null && sliding && ((val.getX() > (end - 20)) || (val.getX() < start)) && place == 0) {
		int diff = end - start;
		end = (int)val.getX() + 20;
		start = end - diff;
	}
	int max_length = 0x3fff;
	for(int i = 0; i < num_channels; i ++){
		//if(data[i].size() > max_length & start > 2000) {
		if(data[i].size() > max_length) {
			synchronized(data[i]){data[i].chop(max_length/10);
			}
		}
	}
	if( val != null )
		os.println(""+val.toString() + ", " + place);
	repaint(100);
    }

    void read_data(){
	int	counter = 0;

	try{
		FileInputStream fin = new FileInputStream("data");	
	byte[] readings = new byte[7];
	int cnt = 0;
	while(fin.read(readings) == 7){
		String s = new String(readings);
		add_point(new Point2D(counter,new Double(s).doubleValue()), 0);
		counter++;
	}	
	}catch(Exception e){
	}
/*
	try{
	for(counter = 1; counter > 0;counter ++){
	for(int j = 0; j < 3000000; j ++){
		add_point(new Point2D(j & 0xffff , 750*Math.sin((float)j/190)), 0);
		Thread.sleep( 1);
	}
	}}catch(Exception e){}*/
    } // end of read_data()

    public void packetReceived(byte[] readings){
	int moteID, msgType, packetNum, channelID, val, channel=-1, i;
	int defaultMsgType = 10;

	int packetLoss=0; 
	int diagRespMsgType = 91; 
	boolean foundPlot = false;
	if(check_crc(readings) == false) return;

	for( i=0;i<readings.length;i++ )
		System.out.print( readings[i]+" " );
	System.out.println( "" );
	//process the packet
	// Read mote id, channel number here, turn on corresponding graph if necessary
	moteID = readings[5] << 8;
	moteID |= readings[4] & 0x0ff;

	msgType = readings[2];

	    if (msgType == defaultMsgType ) {	
	packetNum = (readings[7] << 8) & 0xff00;
	packetNum |= readings[6] & 0x0ff;
	channelID = readings[9] << 8;
	channelID |= readings[8] & 0x0ff;
	}
	else if (msgType == diagRespMsgType) {		 
		channelID =1; 
		// sequenceNum 
		packetNum = (readings[7] << 8) & 0xff00;
		packetNum |= readings[6] & 0x0ff;
//System.out.println("packetNum="+packetNum);
	}
	else {
		System.out.println( "Ignoring packet of msgType "+msgType );
		return;
	}

	for( i=0;i<num_channels;i++ ) {
		if( moteNum[i] == moteID && streamNum[i] == channelID ) {
			foundPlot = true;
			legendActive[i] = true;
			channel = i;
			i = num_channels+1;
		}
	}

	if( !foundPlot ) {
		for( i=0;i<num_channels&&moteNum[i]!=-1;i++ );
		channel = i;
		moteNum[i] = moteID;
		streamNum[i] = channelID;
		lastPacketNum[i] = packetNum;
		legendActive[i] = true;
				if (msgType == diagRespMsgType) 
			dataLegend[i] = "Packet Loss for Mote "+moteID;			
		else dataLegend[i] = "Mote "+moteID+" Chan "+channelID;
	}

	if( channel < 0 ) {
		System.out.println( "All data streams full.  Please clear data set." );
		return;
	}

	if( lastPacketNum[channel] == -1 )
		lastPacketNum[channel] = packetNum;

	packetLoss = packetNum-lastPacketNum[channel]-1;
//System.out.println("last packetNum="+lastPacketNum[channel]); 
//System.out.println("packetLoss="+packetLoss);
		
	for( int j=0; j<packetLoss; j++ )
	{
		for( i=0;i<num_readings;i++ )  // Add "num_readings" blank points for each lost packet
			add_point(null, channel);
	}
	lastPacketNum[channel]= packetNum;
	for( i = 10; i < 10+num_readings * 2;i +=2){
		Point2D newPoint;
 
		if (msgType == diagRespMsgType) 
		   val = packetLoss;
		else {			
			val = readings[i + 1] << 8;
			val |= readings[i] & 0x0ff;	// Convert endian
		}
		//System.out.println( "Read "+val );
		//System.out.println( "xVal "+packetNum );
		newPoint = new Point2D( ((double)(packetNum+(i/2)-10)), val );
		//System.out.println( newPoint );
		add_point( newPoint, channel);
	}
}// end of packetReceived()

    public void run() {
	read_data();
	SerialForwarderStub r = new SerialForwarderStub("127.0.0.1", 9000);
	try{
		r.Open();
		r.registerPacketListener(this);
		r.Read();
	}catch(Exception e){
		e.printStackTrace();
	}
    }


    public void mouseEntered(MouseEvent e) {
    }

    public void mouseExited(MouseEvent e) {
    }

    public void mouseDragged(MouseEvent e) {
    	Dimension d = getSize();

	if( valueTest ) {
		valueX = (int)(start+((float)end-(float)start)*(((float)e.getX())/((float)d.width)));
		if( valueX < 0 ) valueX = 0;
		if( valueX >= data[testChannel].size() )
			valueX = data[testChannel].size()-1;
		valueY = (int)((Point2D)data[testChannel].get( valueX )).getY();
	} else if( highlight_start != null ) {
		highlight_end.x = e.getX();
		highlight_end.y = e.getY();
	}
	repaint(100);
	e.consume();
    }

    public void mouseMoved(MouseEvent e) {
    }
    public void mouseClicked(MouseEvent e) {
    }
    public void mouseReleased(MouseEvent e) {
	removeMouseMotionListener(this);
	if( highlight_start != null )
		set_zoom();
	valueTest = false;
	testChannel = -1;
	highlight_start = null;
	highlight_end = null;
	e.consume();
	repaint(100);
    }
    public void mousePressed(MouseEvent e) {
	addMouseMotionListener(this);

	// Check to see if mouse clicked near plot
    	Dimension d = getSize();
	double  xVal,yVal;
	xVal = start+((float)end-(float)start)*(((float)e.getX())/((float)d.width));
	yVal = top+(bottom-top)*(((float)e.getY())/((float)d.height));
	// System.out.println( xVal+" "+yVal );
	for( int i=0;i<num_channels;i++ ) {
		if( !(xVal < 0 || (int)xVal > data[i].size()) ) {
		    if( Math.abs( ((Point2D)data[i].get( (int)xVal )).getY() - yVal ) < (top-bottom)/40 ) {
			valueTest = true;
			testChannel = i;
			valueX = (int)xVal;
			valueY = (int)((Point2D)data[i].get( valueX )).getY();
		    }
		}
	}

	if( !valueTest ) {
		highlight_start = new Point();
		highlight_end = new Point();
		highlight_start.x = e.getX();
		highlight_start.y = e.getY();
		highlight_end.x = e.getX();
		highlight_end.y = e.getY();
	}
	repaint(100);
	e.consume();
    }

    public void start() {
    }

    public void stop() {
    }

    //double buffer the graphics.
    Image offscreen;
    Dimension offscreensize;
    Graphics offgraphics;


    public synchronized void update(Graphics g) {
	//get the size of the window.
    	Dimension d = getSize();
	//get the end value o fthe window.
	int end = this.end;
	
    	graph.time_location.setMaximum(Math.max(end, data[0].size()));
    	graph.time_location.setValue(end);

	//create the offscreen image if necessary (only done once)
    	if ((offscreen == null) || (d.width != offscreensize.width) || (d.height != offscreensize.height)) {
        	offscreen = createImage(d.width, d.height);
        	offscreensize = d;
        	if (offgraphics != null) {
            		offgraphics.dispose();
        	}
        	offgraphics = offscreen.getGraphics();
        	offgraphics.setFont(getFont());
    	}
	//blank the screen.
    offgraphics.setColor(Color.black);
    offgraphics.fillRect(0, 0, d.width, d.height);

    // Draw axes
    int  xPos,yPos,i,numLines=100,xOff=0,yOff=0;
    double xTicSpacing=d.width/25.03,yTicSpacing=d.height/13.7; // change #s?
    Color xColor,yColor;
    xColor = Color.white;
    yColor = Color.white;
    xPos = d.width*start/(start-end);
    yPos = (int)(((float)(d.height*top))/((float)(top-bottom)));

    if( xPos < 30 ) {
	//xPos = 30;
	while( xPos < 30 ) {
		xPos += xTicSpacing;
		xOff++;
	}

        yColor = yColor.darker();
    }
    if( yPos < 30 ) {
	//yPos = 30;
	while( yPos < 30 ) {
		yPos += yTicSpacing;
		yOff++;
	}

        xColor = xColor.darker();
    }
    if( xPos > d.width-30 ) {
	//xPos = d.width-30;
	while( xPos > d.width-30 ) {
		xPos -= xTicSpacing;
		xOff--;
	}

        yColor = yColor.darker();
    }
    if( yPos > d.height-30 ) {
	//yPos = d.height-30;
	while( yPos > d.height-30 ) {
		yPos -= yTicSpacing;
		yOff--;
	}

        xColor = xColor.darker();
    }

    drawGridLines( offgraphics, numLines, xPos, yPos, xTicSpacing, yTicSpacing );

    drawAxisAndTics( offgraphics, numLines, xPos, yPos, start, end, top, bottom, xTicSpacing, yTicSpacing, xColor, yColor, xOff, yOff );

    //draw the highlight box if there is one.
    draw_highlight(offgraphics);

    //draw the input channels.
    for(i = 0; i < num_channels; i ++) {
        offgraphics.setColor(plotColors[i]);
	if( legendActive[i] )
		draw_data(offgraphics, data[i], start, end);
    }
    
    offgraphics.setColor(Color.white);
    // Draw the value tester line if needed
    if( valueTest ) {
	double h_step_size = (double)d.width / (double)(end - start);
	double v_step_size = (double)getSize().height / (double)(top-bottom);
	offgraphics.drawLine( (int)(h_step_size*(valueX-start)), 0, (int)(h_step_size*(valueX-start)), d.height );
	offgraphics.drawRect( (int)(h_step_size*(valueX-start))-3, (int)(v_step_size*(top-valueY))-3, 6, 6 );
	offgraphics.drawString( (new Integer(valueX)).toString()+", "+(new Integer(valueY)).toString(),
		35,d.height-35 );
    }

    drawLegend( offgraphics );
 
    //transfer the constructed image to the screen.
    g.drawImage(offscreen, 0, 0, null); 
  }

  void drawGridLines( Graphics offgraphics, int numLines, int xPos, int yPos,
			double xTicSpacing, double yTicSpacing ) {
    // Draw the grid lines
    offgraphics.setColor( Color.darkGray );
    for( int i=-numLines;i<numLines;i++ ) {
	offgraphics.drawLine( 0,(int)(yPos-i*yTicSpacing),getSize().width,(int)(yPos-i*yTicSpacing) );
	offgraphics.drawLine( (int)(xPos-i*xTicSpacing),0,(int)(xPos-i*xTicSpacing),getSize().height );
    }
  }

  void drawAxisAndTics( Graphics offgraphics, int numLines, int xPos, int yPos, int start,
			int end, double top, double bottom, double xTicSpacing, double yTicSpacing,
			Color xColor, Color yColor, int xOff, int yOff ) {
    int i;

    // Draw axis lines
    offgraphics.setColor(xColor);
    offgraphics.drawLine( 0, yPos, getSize().width, yPos );
    offgraphics.setColor(yColor);
    offgraphics.drawLine( xPos, 0, xPos, getSize().height );

    //xPos = getSize().width*start/(start-end);
    //yPos = (int)(((float)(getSize().height*top))/((float)(top-bottom)));

    // Draw the tic marks
    offgraphics.setColor(yColor);
    for( i=-numLines;i<numLines;i++ )
	offgraphics.drawLine( xPos-5,(int)(yPos-i*yTicSpacing),xPos+5,(int)(yPos-i*yTicSpacing) );

    offgraphics.setColor(xColor);
    for( i=-numLines;i<numLines;i++ )
	offgraphics.drawLine( (int)(xPos-i*xTicSpacing),yPos-5,(int)(xPos-i*xTicSpacing),yPos+5 );

    // Draw numbers on tics
    offgraphics.setFont( new Font( "Default", Font.PLAIN, 10 ) );
    offgraphics.setColor(yColor);
    for( i=-numLines;i<numLines;i+=2 ) {
	double curPos = i-(yOff);
	offgraphics.drawString( (new Double(curPos*yScaling)).toString(),xPos-25,(int)(yPos-i*yTicSpacing)-2 );
    }

    offgraphics.setColor(xColor);
    for( i=-numLines;i<numLines;i+=2 ) {
	double curPos = -i+(xOff);
	offgraphics.drawString( (new Double(curPos*xScaling)).toString(),(int)(xPos-i*xTicSpacing)-15,yPos+15 );
    }
  }

  void drawLegend( Graphics offgraphics ) {
    int i;

    // Draw the legend
    if( legend ) {
	int activeChannels=0,curChan=0;
	for( i=0;i<num_channels;i++ )
	    if( legendActive[i] )
		activeChannels++;

	if( activeChannels == 0 )
		return;

	offgraphics.setColor(Color.black);
	offgraphics.fillRect( getSize().width-20-130, getSize().height-20-20*activeChannels, 130, 20*activeChannels );
	offgraphics.setColor(Color.white);
	offgraphics.drawRect( getSize().width-20-130, getSize().height-20-20*activeChannels, 130, 20*activeChannels );

	for( i=num_channels-1;i>=0;i-- ) {
		if( legendActive[i] ) {
			offgraphics.setColor(Color.white);
			offgraphics.drawString( dataLegend[i], getSize().width-20-100, getSize().height-30-17*curChan );
        		offgraphics.setColor(plotColors[i]);
			offgraphics.fillRect( getSize().width-20-120, getSize().height-38-17*curChan, 10, 10 );
			curChan++;
		}
	}
    }
  }

    //return the difference between the two input vectors.

    V2 diff(Iterator a, Iterator b){
	V2 vals = new V2();
	while(a.hasNext() && b.hasNext()){
	  	vals.add(new Double((((Double)b.next()).doubleValue() - ((Double)a.next()).doubleValue())));
	}
	return vals;
    }

    //draw the highlight box.
    void draw_highlight(Graphics g){
    	if(highlight_start == null) return;
	int x, y, h, l;
	x = Math.min(highlight_start.x, highlight_end.x);
	y = Math.min(highlight_start.y, highlight_end.y);
	l = Math.abs(highlight_start.x - highlight_end.x);
	h = Math.abs(highlight_start.y - highlight_end.y);
	g.setColor(Color.white);
	g.fillRect(x,y,l,h);
    }


    void draw_data(Graphics g, V2 data, int start, int end){
    	draw_data(g,data, start, end, 1);
    }

    void draw_data(Graphics g, V2 data, int start, int end, int scale){
	int x1=0, y1=0, x2=0, y2=0;
	boolean noplot=true;  // Used for line plotting
	//scale multiplies a signal by a constant factor.

	//determine the step sizes
	double h_step_size = (double)getSize().width / (double)(end - start);
	double v_step_size = (double)getSize().height / (double)(top-bottom);
	if(end > data.size()) end = data.size();
	int base = getSize().height;
	for(int i = 0; i < data.size(); i ++){
		//map each point to a x,y position on the screen.
	     if( data.get(i) != null ) {
	     	x1 = (int)((((Point2D)data.get(i)).getX() * (double)scale - start) * h_step_size);
	     	y1 = (int)((((Point2D)data.get(i)).getY() * (double)scale - bottom) * v_step_size);
	     	y1 = base - y1;
	     	if( x1 > 0 && x1 < getSize().width ) {
		    if( connectPoints && !noplot )
	     		g.drawLine(x2, y2, x1, y1);
		    else if( !connectPoints )
	     		g.drawRect(x1, y1, 1, 1);

		    if( noplot )
			noplot = false;
		} else {
		    noplot = true;
		}
	     }
	     x2 = x1;
	     y2 = y1;
	}
    }

	//functions for controlling zooming.
    void move_up(){
	double height = top - bottom;
	bottom += height/4;
	top += height/4;

    }

    void move_down(){
	double height = top - bottom;
	bottom -= height/4;
	top -= height/4;

    }

    void move_right(){
	int width = end - start;
	start += width/4;
	end += width/4;

    }

    void move_left(){
	int width = end - start;
	start -= width/4;
	end -= width/4;

    }

    void zoom_out_x(){
	int width = end - start;
	start -= width/2;
	end += width/2;
	xScaling *= 2;

    }

    void zoom_out_y(){
	double height = top - bottom;
	bottom -= height/2;
	top += height/2;
	yScaling *= 2;

    }

    void zoom_in_x(){
	int width = end - start;
	start += width/4;
	end -= width/4;
	xScaling /= 2;

    }

    void zoom_in_y(){
	double height = top - bottom;
	bottom += height/4;
	top -= height/4;
	yScaling /= 2;

    }

    void reset(){
	bottom = 00;
	top = 1024.00;
	start = -400; end = 5000;
	xScaling = 200;
	yScaling = 75;

    }

    void clear_data() {
	int i;


	// Reset all motes
	SerialForwarderStub rw = new SerialForwarderStub("localhost", 9000);
	byte [] packet = new byte[SerialForwarderStub.PACKET_SIZE];
	short TOS_BCAST_ADDR = (short) 0xffff;

	// Assign packet contents
	packet[0] = (byte) ((TOS_BCAST_ADDR >> 8) & 0xff);
	packet[1] = (byte) (TOS_BCAST_ADDR & 0xff);
	packet[2] = 32;  // Reset request
	packet[3] = 125; //group_id;

	try {
		rw.Open();
		rw.Write( packet );
		Thread.sleep(100);
	        rw.Close();
	} catch (IOException e) {
		System.out.println( e );
	} catch (java.lang.InterruptedException e){
		e.printStackTrace();
	}
	data = new V2[10];
	for( i=0;i<num_channels;i++ ) data[i] = new V2();
	for( i=0;i<num_channels;i++ ) dataLegend[i] = "";
	for( i=0;i<num_channels;i++ ) legendActive[i] = false;
	for( i=0;i<num_channels;i++ ) lastPacketNum[i] = -1;
	for( i=0;i<num_channels;i++ ) streamNum[i] = -1;
	for( i=0;i<num_channels;i++ ) moteNum[i] = -1;
    }

    // Currently non-functional b/c of switch to 2D point data
    void load_data(){
	JFileChooser	file_chooser = new JFileChooser();
	File		loadedFile;
	FileReader	dataIn;
	String		lineIn;
	int		retval,chanNum,numSamples;
	boolean		keepReading;

	retval = file_chooser.showOpenDialog(null);
	if( retval == JFileChooser.APPROVE_OPTION ) {
		try {
			loadedFile = file_chooser.getSelectedFile();
			System.out.println( "Opened file: "+loadedFile.getName() );
			dataIn = new FileReader( loadedFile );
			keepReading = true;
			chanNum = numSamples = -1;
			while( keepReading ) {
				lineIn = read_line( dataIn );
				if( lineIn == null )
					keepReading = false;
				else if( !lineIn.startsWith( "#" ) ) {
					if( chanNum == -1 ) {
						try {
							chanNum = Integer.parseInt( lineIn.substring(0,lineIn.indexOf(" ")) );
							numSamples = Integer.parseInt( lineIn.substring(lineIn.indexOf(" ")+1,lineIn.length()) );
							data[chanNum] = new V2();
						System.out.println( ""+chanNum+" "+numSamples+"\n" );
						} catch (NumberFormatException e) {
							System.out.println("File is invalid." );
							System.out.println(e);
						}
					} else {
						try {
							//add_point(new Point2D(lineIn), chanNum);
							numSamples--;
							if( numSamples <= 0 )
								numSamples = chanNum = -1;
						} catch (NumberFormatException e) {
							System.out.println("File is invalid." );
							System.out.println(e);
						}
					}
				}
			}
			dataIn.close();
		} catch( IOException e ) {
			System.out.println( e );
		}
	}

    }

    String read_line( FileReader dataIn ) {
        StringBuffer lineIn = new StringBuffer();
	int		c,readOne;

	try {
	while( true ) {
		c = dataIn.read();
		if( c == -1 || c == '\n' ) {
			if( lineIn.toString().length() > 0 )
				return lineIn.toString();
			else
				return null;
		}
		else
			lineIn.append((char)c);
	}
	} catch ( IOException e ) {
	}
	return lineIn.toString();
    }

    void save_data(){
	JFileChooser	file_chooser = new JFileChooser();
	File		savedFile;
	FileWriter	dataOut;
	int		retval,i,n;

	retval = file_chooser.showSaveDialog(null);
	if( retval == JFileChooser.APPROVE_OPTION ) {
		try {
			savedFile = file_chooser.getSelectedFile();
			System.out.println( "Saved file: "+savedFile.getName() );
			dataOut = new FileWriter( savedFile );
			dataOut.write( "# Test Data File\n" );
			dataOut.write( "# "+(new Date())+"\n" );
			for( i=0;i<10;i++ ) {
				if( data[i].size() > 0 ) {
					dataOut.write( "# Channel "+i+"\n" );
					dataOut.write( "# "+data[i].size()+" samples\n" );
					dataOut.write( ""+i+" "+data[i].size()+"\n" );
					for( n=0;n<data[i].size();n++ ) {
						dataOut.write( ((Double)data[i].get(n)).toString() );
						dataOut.write( "\n" );
					}
				}
			}
			dataOut.close();
		} catch( IOException e ) {
			System.out.println( e );
		}
	}

    }

    void set_zoom(){
	double h_step_size = (double)getSize().width / (double)(end - start);
	double v_step_size = (double)getSize().height / (double)(top-bottom);	
	int base = getSize().height;
	int x_start = Math.min(highlight_start.x, highlight_end.x);
	int x_end = Math.max(highlight_start.x, highlight_end.x);
	int y_start = Math.min(base - highlight_start.y, base - highlight_end.y);
	int y_end = Math.max(base - highlight_start.y, base - highlight_end.y);
	
	if(Math.abs(x_start - x_end) < 10) return;
	if(Math.abs(y_start - y_end) < 10) return;
	
	end = start + (int)((double)x_end / h_step_size); 
	start = start + (int)((double)x_start / h_step_size); 
	top = bottom + (double)((double)y_end / v_step_size);
	bottom = bottom + (double)((double)y_start / v_step_size);
	xScaling = (end-start)/25;
	yScaling = (top-bottom)/13.65333;
    }


    boolean check_crc(byte[] packet){
	int len = packet.length;
	packet[0] = (byte) 0xff;
	packet[1] = (byte) 0xff;
	int crc = calcrc(packet, len - 2);
	int check   = ((packet[len - 1] * 256) & 0xff00) + (packet[len - 2] & 0xff);
	System.out.print(crc + " ");
	System.out.print(check + " ");
	System.out.println(len);
	if(check == 0) return true;
	return check == crc;
    }

public int calcrc(byte[] packet, int count)
{
    int crc=0, index=0;
    int i;

    while (count > 0)
    {
        crc = crc ^ (int) packet[index] << 8;
        index++;
        i = 8;
        do
        {
            if ((crc & 0x8000) == 0x8000)
                crc = crc << 1 ^ 0x1021;
            else
                crc = crc << 1;
        } while(--i != 0);
        count --;
    }
    return (crc & 0xffff);
}


}
