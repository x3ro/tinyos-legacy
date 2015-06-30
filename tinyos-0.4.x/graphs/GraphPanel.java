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

public class GraphPanel extends Panel
    implements Runnable, MouseListener, MouseMotionListener, PacketListenerIF {	
    boolean debug = false;
    boolean sliding = true;
    oscilloscope graph;
    PrintWriter os;

    double bottom, top;
    int start, end;
    V2 cutoff; 
    V2 data[];
    V2 double_filter;
    V2 small_filter;
    V2 filter;
    V2 marker;
    Point highlight_start, highlight_end;

    GraphPanel(oscilloscope graph) {
	setBackground(Color.white);
 	addMouseListener(this);
 	addMouseMotionListener(this);
	cutoff = new V2();
	data = new V2[10];
	for(int i = 0; i < 10; i ++) data[i] = new V2();
	try{
	FileOutputStream f = new FileOutputStream("log");
	os = new PrintWriter(f);
	}catch(Exception e){
	 e.printStackTrace();
	}
	double_filter = new V2();
	small_filter = new V2();
	filter = new V2();
	marker = new V2();
 	this.graph = graph;
	bottom = 00;
	top = 1024.00;
	start = 0; end = 5000;
	Thread t = new Thread(this);
	t.start();
	


    }
    int big_filter;
    int sm_filter;
    int db_filter;



    void add_point(Double val, int place){
	if(place >= data.length) return;
	data[place].add(val);
	if(sliding && data[0].size() > end && place == 0) {
		start ++;
		end ++;
	}
	int max_length = 1000000;
	for(int i = 0; i < 10; i ++){
		if(data[i].size() > max_length & start > 2000){
			synchronized(data[i]){data[i].chop(max_length);
				end -= 2000;
				start -= 2000;
			}
		}
	}
	os.println(val.doubleValue() + ", " + place);
	repaint(100);
    }

    void read_data(){
	try{
		FileInputStream fin = new FileInputStream("data");	
	byte[] readings = new byte[7];
	int cnt = 0;
	while(fin.read(readings) == 7){
		String s = new String(readings);
		add_point(new Double(s), 0);
		//System.out.println(s);
	}	
	}catch(Exception e){
		e.printStackTrace();
	}
	for(int i = 0; i < 000; i ++){
		double val = 1000 + 10 * Math.sin((double)i * 3);
		if(i < 1128 && i > 1000) val += 5 * Math.sin((double)i * .25 / 32 * 3.14159);
		if(i < 2032 && i > 2000) val += 5 * Math.sin((double)i * 1 / 32 * 3.14159);
		if(i < 3064 && i > 3000) val += 5 * Math.sin((double)i * 2 / 32 * 3.14159);
		if(i < 4008 && i > 4000) val += 5 * Math.sin((double)i * 4 / 32 * 3.14159);
		if(i > 4700 && i < 4730) val += 5;
		val = 120;
		add_point(new Double(val), 0);
	}
    }
	int last_samp; //last sample 
	int max_bits = 0;
    public void packetReceived(byte[] readings){
	//process the packet
	//System.out.println();
	//for(int i = 0; i < readings.length; i ++) System.out.print(" " + (readings[i] & 0xff));
	//System.out.println();
	//if(readings[1] != 6) return;
	int channel = 0;
	int num_channels = 2;
	int num_readings = 4;
	for(int i = 5; i < 5+num_readings * 2;i +=2){
		int val = readings[i + 1] << 8;
		val |= readings[i] & 0x0ff;
		add_point(new Double(val), channel);
		channel ++;
		channel %= num_channels;
		last_samp = val;
	   }

	//try to reconstruct
		int val = readings[6] << 8;
		val |= readings[5] & 0xff;
	//System.out.println(val);
		int vals[] = new int[7];
		for(int i = 0; i < 3; i ++) {
			vals[2*i] = readings[7 + i] >> 4;
			vals[2*i + 1] = (readings[7 + i] & 0xf);
			if(vals[2*i + 1] > 7) vals[2*i + 1] |= 0xfffffff0;
		}
		//for(int i = 0; i < 3; i ++) vals[i] = 0;
		add_point(new Double(val + vals[0] + vals[1] + vals[3] - (0x70 <<2 )), 9);
		add_point(new Double(val + vals[0] + vals[1] - vals[3]  - (0x70 << 2)), 9);
		add_point(new Double(val + vals[0] - vals[1] + vals[4]  - (0x70 << 2)), 9);
		add_point(new Double(val + vals[0] - vals[1] - vals[4]  - (0x70 << 2)), 9);
		add_point(new Double(val - vals[0] + vals[2] + vals[5]  - (0x70 << 2)), 9);
		add_point(new Double(val - vals[0] + vals[2] - vals[5]  - (0x70 << 2)), 9);
		add_point(new Double(val - vals[0] - vals[2] + vals[6]  - (0x70 << 2)), 9);
		add_point(new Double(val - vals[0] - vals[2] - vals[6]  - (0x70 << 2)), 9);
		for(int i = 0; i < 8; i ++){
			add_point(new Double(val), 7);
		}
		for(int i = 0; i < 4; i ++){
			add_point(new Double(val + vals[0]), 8);
		}
		for(int i = 4; i < 8; i ++){
			add_point(new Double(val - vals[0]), 8);
		}
		//System.out.println(max_bits);
		//for(int i = 0; i < 7; i ++){
			//System.out.println(vals[i]);
		//}
	
    }

    public void run() {
	read_data();
	SerialForwarderReader r = new SerialForwarderReader("127.0.0.1", 9000);
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
	highlight_end.x = e.getX();
	highlight_end.y = e.getY();
	repaint(100);
	e.consume();
    }

    public void mouseMoved(MouseEvent e) {
    }
    public void mouseClicked(MouseEvent e) {
    }
    public void mouseReleased(MouseEvent e) {
	removeMouseMotionListener(this);
	set_zoom();
	highlight_start = null;
	highlight_end = null;
	e.consume();
	repaint(100);
    }
    public void mousePressed(MouseEvent e) {
	addMouseMotionListener(this);
	highlight_start = new Point();
	highlight_end = new Point();
	highlight_start.x = e.getX();
	highlight_start.y = e.getY();
	highlight_end.x = e.getX();
	highlight_end.y = e.getY();
	repaint(100);
	e.consume();
    }

    public void start() {
    }

    public void stop() {
    }
    Image offscreen;
    Dimension offscreensize;
    Graphics offgraphics;
    public synchronized void update(Graphics g) {
    	Dimension d = getSize();
	int end = this.end;
    	graph.time_location.setMaximum(Math.max(end, data[0].size()));
    	graph.time_location.setValue(end);
    	if ((offscreen == null) || (d.width != offscreensize.width) || (d.height != offscreensize.height)) {
        	offscreen = createImage(d.width, d.height);
        	offscreensize = d;
        	if (offgraphics != null) {
            		offgraphics.dispose();
        	}
        	offgraphics = offscreen.getGraphics();
        	offgraphics.setFont(getFont());
    	}
    offgraphics.setColor(Color.black);
    offgraphics.fillRect(0, 0, d.width, d.height);
    draw_highlight(offgraphics);
    int f_start = start - 10000;
    if(f_start < 0) f_start = 0;
    V2 low_pass_filter, high_pass_filter, band_pass_filter, mote_filter;
    V2 first_filter, second_filter; 
    int filter_channel = 0;
    synchronized(data[filter_channel]){
	    if(data[filter_channel].size() == 0) return;
	    low_pass_filter = smooth_filter(data[filter_channel], f_start, end, graph.low_pass.getValue());
	    high_pass_filter = diff(low_pass_filter.subList(0, low_pass_filter.size()).iterator(), data[filter_channel].subList(f_start, Math.min(end, data[filter_channel].size())).iterator());
    	    band_pass_filter = filter(high_pass_filter, 0, high_pass_filter.size(), graph.high_pass.getValue());
	    high_pass_filter = filter(low_pass_filter, 0, low_pass_filter.size(), graph.high_pass.getValue());
    	    //mote_filter2 = mote_filter(high_pass_filter, 0, high_pass_filter.size(), graph.high_pass.getValue());
    	    mote_filter = mote_filter(data[filter_channel], f_start, end, graph.high_pass.getValue());
	    first_filter = smooth_filter(data[filter_channel], f_start, end, 4);
	    second_filter = smooth_filter(first_filter, 0, first_filter.size(), 6);
    }
    offgraphics.setColor(Color.green);
    for(int i = 0; i < 2; i ++) {
	draw_data(offgraphics, data[i], start, end);
    	offgraphics.setColor(Color.red);
    }
    //draw_data(offgraphics, data[0], start, end);
    //draw_data(offgraphics, data[7], start, end);
    offgraphics.setColor(Color.white);
    //draw_data(offgraphics, data[8], start, end);
    //offgraphics.setColor(Color.yellow);
    //draw_data(offgraphics, data[9], start, end, 10);
    //offgraphics.setColor(Color.red);
    //draw_data(offgraphics, low_pass_filter, start - f_start, end - f_start);
    //offgraphics.setColor(Color.white);
    //draw_data(offgraphics, high_pass_filter, start - f_start, end - f_start);
    //offgraphics.setColor(Color.red);
    //draw_data(offgraphics, band_pass_filter, start - f_start, end - f_start, 40);
    //offgraphics.setColor(Color.orange);
    offgraphics.setColor(Color.red);
    //draw_data(offgraphics, first_filter, start - f_start, end - f_start);
    offgraphics.setColor(Color.yellow);
    //draw_data(offgraphics, second_filter, start - f_start, end - f_start);
    offgraphics.setColor(Color.blue);
    //draw_data(offgraphics, mote_filter, start - f_start, end - f_start);
    draw_data(offgraphics, const_filter(graph.cutoff.getValue(), 5000), 0, end -start );

    g.drawImage(offscreen, 0, 0, null); 
  }
  V2 const_filter(int val, int length){
	V2 newv = new V2();
	for(int i = 0; i < length; i ++){
		newv.add(new Double(val));
	}
	return newv;
  }
  V2 mote_filter(V2 data, int start, int end, int feedback){
	if(start < 0) start = 0;
	if(end > data.size()) end = data.size();
	Iterator vals = data.subList(start, end).iterator();
	V2 newv = new V2();
	//double filter_val = ((Double)data.get(start)).doubleValue();
	short first = 0;
	short second = 0;
	short diff = 0;
	while(vals.hasNext()){
		first -= first >> 3;
		first += (short)((Double)vals.next()).doubleValue();
		second -= second >> 3;
		second += first >> 3;
		int tmp = first - second;
		if(tmp < 0) tmp = -tmp;
		diff -= diff >> 3;
		diff += tmp >> 0;
		newv.add(new Double(diff));
	}
	/*while(vals.hasNext()){
		first -= first >> 4;
		first += (short)((Double)vals.next()).doubleValue();
		second -= second >> 6;
		second += first >> 6;
		int tmp = first - second;
		if(tmp < 0) tmp = -tmp;
		diff -= diff >> 5;
		diff += tmp >> 2;
		newv.add(new Double(diff));
	}*/
	//System.out.println(diff);
	return newv;
    }
  V2 smooth_filter(V2 data, int start, int end, int feedback){
	if(start < 0) start = 0;
	if(end > data.size()) end = data.size();
	Iterator vals = data.subList(start, end).iterator();
	V2 newv = new V2();
	double filter_val = ((Double)data.get(start)).doubleValue();
	while(vals.hasNext()){
		filter_val *= Math.pow((double)2, (double)feedback) - 1;
		filter_val += (int)((Double)vals.next()).doubleValue();
		filter_val /= Math.pow((double)2, (double)feedback);
		newv.add(new Double(filter_val));
	}
	return newv;
    }
    V2 filter(V2 data, int start, int end, int feedback){
	if(start < 0) start = 0;
	if(end > data.size()) end = data.size();
	Iterator vals = data.subList(start, end).iterator();
	V2 newv = new V2();
	int filter_val = (int)((Double)data.get(start)).doubleValue() << feedback;
	while(vals.hasNext()){
		filter_val -= filter_val >> feedback;
		filter_val += (int)((Double)vals.next()).doubleValue();
		newv.add(new Double(filter_val >> feedback));
	}
	return newv;
    }

    V2 diff(Iterator a, Iterator b){
	V2 vals = new V2();
	while(a.hasNext() && b.hasNext()){
	  	vals.add(new Double((((Double)b.next()).doubleValue() - ((Double)a.next()).doubleValue())));
	}
	return vals;
    }

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
	double h_step_size = (double)getSize().width / (double)(end - start);
	double v_step_size = (double)getSize().height / (double)(top-bottom);
	if(end > data.size()) end = data.size();	
	int base = getSize().height;
	for(int i = 0; i < end - start - 1; i ++){
	   int x1, y1, x2, y2;
	   if((start + i) >= 0){ 
	     x1 = (int)(h_step_size * (double)i);
	     y1 = (int)((((Double)(data.get(start + i))).doubleValue() * (double)scale - bottom) * v_step_size);
	     y1 = base - y1;
	     x2 = (int)(h_step_size * (double)(i + 1));
	     y2 = (int)((((Double)(data.get(start + i + 1))).doubleValue() * (double)scale - bottom) * v_step_size);
	     y2 = base - y2;
	     g.drawLine(x1, y1, x2, y2);
	   }
	}
    }
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

    }

    void zoom_out_y(){
	double height = top - bottom;
	bottom -= height/2;
	top += height/2;

    }

    void zoom_in_x(){
	int width = end - start;
	start += width/2;

    }

    void zoom_in_y(){
	double height = top - bottom;
	bottom += height/4;
	top -= height/4;

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
    }
	
}
