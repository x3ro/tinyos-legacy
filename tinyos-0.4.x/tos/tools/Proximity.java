import java.awt.*;
import java.awt.event.*;
import java.awt.geom.*;
import java.awt.geom.AffineTransform;
import java.awt.image.BufferedImage;
import javax.swing.*;
import java.util.*;
import java.io.*;
import java.net.*;

public class Proximity extends JApplet implements Runnable {
    private Thread thread;
    private BufferedImage bimg;
    private double ss;
    private LinkedList my_packets;

    public Proximity(LinkedList p) {
        setBackground(Color.white);  
	my_packets = p;
    }


    public void Transform(int ss_pkt) {
	ss =  (double)ss_pkt/256;
    }

    public void drawProximityWidget(int w, int h, Graphics2D g2) {
	
	g2.setStroke(new BasicStroke(5.0f));
	
	// Draw 8 lines
	for (int i=1; i<=8; i++)
	    g2.draw(new Line2D.Double(0,((double)i/8.0)*h, w,((double)i/8.0)*h));

	// draw graph
	Rectangle2D rect = new Rectangle2D.Double(0.2*w,h-ss*h,0.2*w,ss*h);
	//	rect.setColor(Color.red);
	g2.draw(rect);
	g2.setColor(Color.red);
	g2.fill(rect);
	g2.setColor(Color.black);
    }
    
    public void paint(Graphics g) {
        Dimension d = getSize();
        Graphics2D g2 = createGraphics2D(d.width, d.height);
        drawProximityWidget(d.width, d.height, g2);
        g2.dispose();
        g.drawImage(bimg, 0, 0, this);
    }
    
    
    public Graphics2D createGraphics2D(int w, int h) {
        Graphics2D g2 = null;
        if (bimg == null || bimg.getWidth() != w || bimg.getHeight() != h) {
            bimg = (BufferedImage) createImage(w, h);
        } 
        g2 = bimg.createGraphics();
        g2.setBackground(getBackground());
        g2.clearRect(0, 0, w, h);
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                            RenderingHints.VALUE_ANTIALIAS_ON);
        return g2;
    }

    public void start() {
        thread = new Thread(this);
        thread.setPriority(Thread.MIN_PRIORITY);
        thread.start();
    }


    public synchronized void stop() {
        thread = null;
    }
    
    public void run() {
	Thread me = Thread.currentThread();

	while (thread == me) {
	    try {
		synchronized(my_packets) {
		    if (my_packets.size() != 0) {
			StringTokenizer str = new StringTokenizer(String.valueOf(my_packets.removeFirst()));
			Transform(Integer.valueOf(str.nextToken()).intValue());
			repaint();
		    }
		}
	    } catch (Exception e){}
	    try {
		thread.sleep(1);
	    } catch (InterruptedException e) { break; }
	}
	thread = null;
    }
}
