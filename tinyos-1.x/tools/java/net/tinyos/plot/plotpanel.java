// $Id: plotpanel.java,v 1.7 2003/10/07 21:46:02 idgay Exp $

/**
 *    Copyright(C) 2002 by Tom Pycke <Tom.Pycke@advalvas.be>
 *
 */

package net.tinyos.plot;

import net.tinyos.sim.TinyViz;

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;
import java.lang.*;
import java.util.*;

public class plotpanel extends JPanel {
	/*              BORDER_TY
	 *           ---------------
	 *           |             |
	 * BORDER_LX |             |  BORDER_RX
	 *           ---------------
	 *              BORDER_BY
	 */
	private int BORDER_LX = 40;
//    private int BORDER_RX = 23;
    private int BORDER_RX = 120;
	private int BORDER_TY = 19;
	private int BORDER_BY = 15;

	private final static RenderingHints AALIAS = new
	      RenderingHints(RenderingHints.KEY_ANTIALIASING, 
		                 RenderingHints.VALUE_ANTIALIAS_ON);

    private boolean antiAliasing;
    private boolean fitToScreen;
    private ArrayList functionList;
    private ArrayList colorList;
    private ArrayList descriptionList;

    private ArrayList completeFunctionList;
    private ArrayList completeColorList;
    private ArrayList completeDescriptionList;

	private double maxX, maxY, minX, minY;
	private int screenWidth, screenHeight;
	private double maxWidth, maxHeight;
	private double scale = 1.0;
	private int cursorX, cursorY;
	private Label cursorPosition;
	private Color bgColor = Color.white;
	private boolean printDescription = false;

	private int fontHeight;

    private TinyViz tv;
    public void setTv(TinyViz tv) {
        this.tv = tv;
    }

    private JComboBox cb; //the combo box in the control panel
    public void setCb(JComboBox cb) {
        this.cb = cb;
    }


    public void init(){
        functionList = new ArrayList();
        colorList = new ArrayList();
        descriptionList = new ArrayList();
        completeFunctionList = new ArrayList();
        completeColorList = new ArrayList();
        completeDescriptionList = new ArrayList();
        if(cb!=null) cb.removeAllItems();
        maxX = maxY = 5.0;
        minX = minY = -5.0;
        this.setDoubleBuffered(true);

    }
	/**
	 *    Constructor
	 */
	public plotpanel () {
        init();

		updateData();
        setLayout(null);
		cursorPosition = new Label("");
		add(cursorPosition);
		cursorPosition.setLocation(BORDER_LX, 0);
        cursorPosition.setVisible(false);
		cursorPosition.setSize (200,18);
		cursorPosition.setAlignment (Label.LEFT);
		
		addMouseListener ( new MouseAdapter() {
			public void mouseClicked(MouseEvent e) {
				double widthX = maxX - minX;
				double widthY = maxY - minY;
				if (cursorX > BORDER_LX && cursorX < screenWidth + BORDER_LX &&
				    cursorY > BORDER_TY && cursorY < screenHeight + BORDER_TY) {
					maxX += (Math.round((e.getX() - BORDER_LX)*100.0)/100.0 - screenWidth/2) * (widthX) / screenWidth;
					maxY += (Math.round((-e.getY() + BORDER_TY)*100.0)/100.0 + screenHeight/2) * (widthY) / screenHeight;
					minX += (Math.round((e.getX() - BORDER_LX)*100.0)/100.0 - screenWidth/2) * (widthX) / screenWidth;
					minY += (Math.round((-e.getY() + BORDER_TY)*100.0)/100.0 + screenHeight/2) * (widthY) / screenHeight;
				}
				repaint();
			}
		});
		addMouseMotionListener ( new MouseMotionAdapter() {
			public void mouseMoved(MouseEvent e) {
				cursorX = e.getX();
				cursorY = e.getY();
				if (cursorX > BORDER_LX && cursorX < screenWidth + BORDER_LX &&
				    cursorY > BORDER_TY && cursorY < screenHeight + BORDER_TY) {
				    setCursor (new Cursor(Cursor.CROSSHAIR_CURSOR));
                    cursorPosition.setText("(" + double2String(screenToWorldX(cursorX)) + ", " +
                                                 double2String(screenToWorldY(cursorY)) + ")");
                    cursorPosition.setVisible(true);
				} else {
                    cursorPosition.setVisible(false);
                    cursorPosition.setText("");
					setCursor (new Cursor(Cursor.DEFAULT_CURSOR));
				}
			}
		});
	}
	
	/**
	 *    Adds a function to the functionlist.
	 *
	 *    This appends Function <code>f</code> with Color <code>c</code> to
	 *    the to-plot list.
	 *
	 *    @param f An implementation of <code>Function</code>
	 *    @param c A <code>Color</code>
	 */
	public void addFunction (Function f, Color c) {
        addFunction(f, c, new String(""));
	}

    /**
     *    Adds a function to the functionlist.
     *
     *    This appends Function <code>f</code> with Color <code>c</code> to
     *    the to-plot list.
     *
     *    @param f An implementation of <code>Function</code>
     *    @param c A <code>Color</code>
     *    @param s The function's description
     */
    public void addFunction (Function f, Color c, String s) {
        if(!completeDescriptionList.contains(s)){
            functionList.add (f);
            colorList.add (c);
            descriptionList.add (s);
            completeFunctionList.add (f);
            completeColorList.add (c);
            completeDescriptionList.add (s);
            if(s.length()>0)
                cb.addItem(s);
        }
    }

    /**
     *    Removes a function from the functionlist.
     *
     *    This removes a Function <code>s</code> from
     *    the to-plot list.
     *
     *    @param s The function's description
     */
    public void removeFunction (String s) {
        int index = descriptionList.indexOf(s);
        if(index!=-1){
            functionList.remove(index);
            colorList.remove(index);
            descriptionList.remove(index);
        }
        repaint();
    }

    /**
     *    Gets a function from the completefunctionlist.
     *
     *    @param s The function's description
     */
    public Function getFunction (String s) {
        int index = completeDescriptionList.indexOf(s);
        if(index!=-1){
            return (Function)completeFunctionList.get(index);
        }
        else return null;
    }

    /**
     *    Replaces a function on the functionlist.
     *
     *    This copies a Function <code>s</code> from
     *    the in-waiting list to the to-plot list.
     *
     *    @param s The function's description
     */
    public void replaceFunction (String s) {
        int index = completeDescriptionList.indexOf(s);
        if(index!=-1 && !descriptionList.contains(s)){
            functionList.add(completeFunctionList.get(index));
            colorList.add(completeColorList.get(index));
            descriptionList.add(completeDescriptionList.get(index));
        }
        repaint();
    }

	/**
	 *    Removes the last function added from the function, color and description list
	 */
	public void removeLast() {
		if (descriptionList.size() > 0) {
			descriptionList.remove (functionList.size() - 1);
			colorList.remove (functionList.size() - 1);
			functionList.remove (functionList.size() - 1);
		}
		repaint();
	}


	/**
	 *    Returns the minimum x-value (world) of the plot's view.
	 *
	 *    @return  The lowest x-value shown on the plot (in world's coordinates)
	 */
	public double getMinX () {
		return minX;
	}

	/**
	 *    Returns the maximum x-value (world) of the plot's view.
	 *
	 *    @return  The highest x-value shown on the plot (in world's coordinates)
	 */
	public double getMaxX () {
		return maxX;
	}

	/**
	 *    Returns the minimum y-value (world) of the plot's view.
	 *
	 *    @return  The lowest y-value shown on the plot (in world's coordinates)
	 */
	public double getMinY () {
		return minY;
	}

	/**
	 *    Returns the maximum y-value (world) of the plot's view.
	 *
	 *    @return  The highest y-value shown on the plot (in world's coordinates)
	 */
	public double getMaxY () {
		return maxY;
	}
	
	/**
	 *    Sets the maximum x-value of the plot's view.
	 *
	 *    @param maxX The new maximum x-value of the plot's view.
	 */
	public void setMaxX (double maxX) {
		this.maxX = maxX;
	}

	/**
	 *    Sets the minimum x-value of the plot's view.
	 *
	 *    @param minX The new minimum x-value of the plot's view.
	 */
	public void setMinX (double minX) {
		this.minX = minX;
	}

	/**
	 *    Sets the maximum y-value of the plot's view.
	 *
	 *    @param maxY The new maximum y-value of the plot's view.
	 */
	public void setMaxY (double maxY) {
		this.maxY = maxY;
	}

    /**
     *    Sets the minimum y-value of the plot's view.
     *
     *    @param minY The new minimum y-value of the plot's view.
     */
    public void setMinY (double minY) {
        this.minY = minY;
    }

    /**
     *    Fits the graph to the screen using data from the EmpiricalFunction objects, if any.
     *
     */
    public void FitToScreen() {
        boolean initialized=false;
        Iterator func = functionList.iterator();
        while(func.hasNext()){
            Function f=(Function)func.next();
            if(f instanceof EmpiricalFunction){
                EmpiricalFunction ef = (EmpiricalFunction)f;
                Enumeration e = ef.points.elements();
                while(e.hasMoreElements()){
                    if(!initialized){
                        maxX=Double.MIN_VALUE; maxY=Double.MIN_VALUE;
                        minX=Double.MAX_VALUE; minY=Double.MAX_VALUE;
                        initialized=true;
                    }
                    EmpiricalFunction.PlotPoint p = (EmpiricalFunction.PlotPoint)e.nextElement();
                    if(p.x>maxX) maxX=p.x;
                    if(p.x<minX) minX=p.x;
                    if(p.y>maxY) maxY=p.y;
                    if(p.y<minY) minY=p.y;
                }
            }
        }
        if(initialized){
            if(maxX==minX) maxX++;
            if(maxY==minY) maxY++;
            minX=minX-Math.ceil(0.02*(maxX-minX));
            maxX=maxX+Math.ceil(0.02*(maxX-minX));
            minY=minY-Math.ceil(0.02*(maxY-minY));
            maxY=maxY+Math.ceil(0.02*(maxY-minY));
        }
    }


    /**
     *    Moves the window to include this point.
     *
     *    @param x x balue of point.
     *    @param y x balue of point.
     */
    public void includePoint(double x, double y) {
/*        if(x<getMinX()){
            setMaxX(getMaxX()-(getMinX()-x)+1);
            setMinX(x-1);
        }
        if(x>getMaxX()){
            setMinX(getMinX()+(x-getMaxX())-1);
            setMaxX(x+1);
        }
        if(y<getMinY()){
            setMaxY(getMaxY()-(getMinY()-y)+1);
            setMinY(y-1);
        }
        if(y>getMaxY()){
            setMinY(getMinY()+(y-getMaxY())-1);
            setMaxY(y+1);
        }*/
        if(x<getMinX()){
            setMaxX(getMaxX()-(getMinX()-x)-1);
            setMinX(x-1);
        }
        if(x>getMaxX()){
            setMinX(getMinX()+(x-getMaxX()+1));
            setMaxX(x+1);
        }
        if(y<getMinY()){
            setMaxY(getMaxY()-(getMinY()-y)-1);
            setMinY(y-1);
        }
        if(y>getMaxY()){
            setMinY(getMinY()+(y-getMaxY())+1);
            setMaxY(y+1);
        }
    }


    /**
     *    Toggles anti-aliasing on/off
     */
    public void setAntiAliasing (boolean antiAliasing) {
        this.antiAliasing = antiAliasing;
    }

    /**
     *    Toggles fit to screen on/off
     */
    public void setFitToScreen (boolean f) {
        this.fitToScreen = f;
    }

	private String double2String (double d) {
		return "" + (Math.round(d*1000.0)/1000.0);
	}
	
	private void updateData() {
		screenWidth = getWidth() - BORDER_LX - BORDER_RX;
		screenHeight = getHeight() - BORDER_TY - BORDER_BY;
		maxWidth = maxX - minX;
		maxHeight = maxY - minY;
	}
	
	private void drawAxis (Graphics2D g, boolean printGrid) {
		int count = 0;
		double step = (maxX - minX) / 10.0;

		for (double x = minX; x <= maxX; x += step, count++) {
			g.drawLine(worldToScreenX(x), screenHeight + BORDER_TY,
			           worldToScreenX(x), screenHeight + BORDER_TY - 3);
			String val = double2String(x);
			String printedVal = val.substring(0, val.length() < 5 ? val.length() : 5);
			int fontWidth = (int)(g.getFontMetrics().getStringBounds (printedVal, g).getWidth());
			if (screenWidth > 400 ||
			    (screenWidth > 140 && screenWidth <= 200 && count % 3 == 2) ||
			    (screenWidth > 200 && count % 2 == 1) ||
			    (screenWidth > 80 && screenWidth <= 140 && count % 4 == 3) )
				g.drawString(printedVal,
				             worldToScreenX(x) - fontWidth / 2,
				             screenHeight + BORDER_TY + fontHeight - 3);
			if (printGrid && worldToScreenX(x) != BORDER_LX + screenWidth - 1) {
				g.setColor(Color.gray);
				g.drawLine(worldToScreenX(x),
				           screenHeight + BORDER_TY - 3,
				           worldToScreenX(x), BORDER_TY);
				g.setColor(Color.black);
			}
		}				
		
		count = 0;
        if(maxY - minY>0)
            step = (maxY - minY) / 10.0;
		for (double y = minY; y <= maxY; y += step, count++) {
			g.drawLine(BORDER_LX, worldToScreenY(y),
			           BORDER_LX + 3, worldToScreenY(y));
			String val = double2String(y);
			String printedVal = val.substring(0, val.length() < 5 ? val.length() : 5);
			
			int fontWidth = (int)(g.getFontMetrics().getStringBounds (printedVal, g).getWidth());
			if (screenHeight > 60 && (screenHeight > 240 || count%2 == 1)) {
				if (y == minY)
					g.drawString(printedVal, BORDER_LX - fontWidth - 2, worldToScreenY(y));
				else
					g.drawString(printedVal, BORDER_LX - fontWidth - 2, worldToScreenY(y) + fontHeight/2 - 3);
			}
			if (printGrid && worldToScreenY(y) != BORDER_TY + 1) {
				g.setColor(Color.gray);
				g.drawLine(BORDER_LX+3, worldToScreenY(y),
				           screenWidth + BORDER_LX,
				           worldToScreenY(y));
				g.setColor(Color.black);
			}

		}				
		g.drawLine(BORDER_LX, screenHeight + BORDER_TY, BORDER_LX + screenWidth, screenHeight + BORDER_TY);
		g.drawLine(BORDER_LX, BORDER_TY, BORDER_LX, screenHeight + BORDER_TY);
		g.drawLine(screenWidth + BORDER_LX, BORDER_TY, screenWidth + BORDER_LX, screenHeight + BORDER_TY);
		g.drawLine(BORDER_LX, BORDER_TY, screenWidth + BORDER_LX, BORDER_TY);
		
		drawOrigin(g);
	}
	
	private int worldToScreenY(double y) {
		return screenHeight + BORDER_TY - (int)((y - minY) * ((double)screenHeight) / maxHeight);
	}

	private int worldToScreenX(double x) {
		return BORDER_LX + (int)((x - minX) * ((double)screenWidth) / maxWidth);
	}

	private double screenToWorldX(int x) {
		return (double)(x - BORDER_LX) / ((double)screenWidth / maxWidth) + minX;
	}

	private double screenToWorldY(int y) {
		return (double)(-y + BORDER_TY + screenHeight) / ((double)screenHeight / maxHeight) + minY;
	}

	
	private void drawOrigin(Graphics2D g) {
		double scaleWidth = (double)(screenWidth) / maxWidth;
		double scaleHeight = ((double)screenHeight)/maxHeight;
		float[] dashPattern = { 3, 8 };
		g.setStroke(new BasicStroke(1, BasicStroke.CAP_BUTT,
                                  BasicStroke.JOIN_MITER, 10,
                                  dashPattern, 0));
		if (maxX > 0.0 && minX < 0.0)
			g.drawLine(BORDER_LX + (int)((0.0 - minX) * scaleWidth),
			           screenHeight + BORDER_TY - 3,
			           BORDER_LX + (int)((0.0 - minX) * scaleWidth), BORDER_TY);
		if (maxY > 0.0 && minY < 0.0)
			g.drawLine(BORDER_LX, worldToScreenY(0),
			           BORDER_LX + screenWidth, worldToScreenY(0));
		g.setStroke(new BasicStroke());
	}
	
	private void plotFunction (Graphics2D g, Function f, Color c) {
		if(c==null)
            g.setColor(Color.blue);
        else
            g.setColor(c);

        int lastX = Integer.MIN_VALUE;
        int lastY = Integer.MIN_VALUE;

        if(f instanceof EmpiricalFunction){
            int x,y;
            EmpiricalFunction ef = (EmpiricalFunction)f;
            Enumeration e = ef.points.elements();
            while(e.hasMoreElements()){
                EmpiricalFunction.PlotPoint p = (EmpiricalFunction.PlotPoint)e.nextElement();
                if(tv==null || p.timeout==-1 || p.timeout>(int)(tv.getTosTime()*1000)){
                    if(p.color!=null)
                        g.setColor(p.color);

                    x = worldToScreenX(p.x);
                    y = worldToScreenY(p.y);
                    if(ef.plotStyle.equalsIgnoreCase("lines") || ef.plotStyle.equalsIgnoreCase("both")){
                        if(lastX!=Integer.MIN_VALUE && lastY!=Integer.MIN_VALUE){
                            if(lastX>=BORDER_LX && lastX<=getWidth()-BORDER_RX && lastY>=BORDER_TY && lastY<=getHeight()-BORDER_BY &&
                                x>=BORDER_LX && x<=getWidth()-BORDER_RX && y>=BORDER_TY && y<=getHeight()-BORDER_BY){
                                   g.drawLine(lastX,lastY,x,y);
                            }
                            //if old points are not within the box, extrapolate
    /*                        else{
                                if(lastX<BORDER_LX){
                                }
                                else if(lastX>screenWidth+BORDER_RX){
                                }
                                else if(lastY>BORDER_BY){
                                }
                                else if(lastY<screenHeight+BORDER_TY){
                                }
                                else if(x<BORDER_LX){
                                }
                                else if(x>screenWidth+BORDER_RX){
                                }
                                else if(y>BORDER_BY){
                                }
                                else if(y<screenHeight+BORDER_TY){
                                }
                            }
                            g.drawLine(lastX,lastY,x,y);*/
                        }
                    }

                    else if(ef.plotStyle.equalsIgnoreCase("dots") || ef.plotStyle.equalsIgnoreCase("both")){
                        x = worldToScreenX(p.x-p.radius);
                        y = worldToScreenY(p.y+p.radius);
                        System.out.println("p.x= " + p.x + "; p.radius = " + p.radius + "; radius = " + Math.abs(worldToScreenX(p.radius*2)-worldToScreenX(0)) + ";  x = " + x);
                        System.out.println("p.y= " + p.y + "; p.radius = " + p.radius + "; radius = " + Math.abs(worldToScreenY(p.radius*2)-worldToScreenY(0)) + ";  y = " + y);
                        if(x>BORDER_LX && x<screenWidth &&y>BORDER_TY && y<screenHeight)
                            g.fillOval(x,y,Math.abs(worldToScreenX(p.radius*2)-worldToScreenX(0)),Math.abs(worldToScreenY(p.radius*2)-worldToScreenY(0)));
                    }
                    if(p.label!=null)
                        g.drawString(p.label,x,y);

                    //doing this here because it crashes if we do it in repaint, which
                    //happens too often
                    if(fitToScreen){
                        if(p.x>maxX) maxX=p.x+Math.ceil(0.02*(maxX-minX));
                        if(p.x<minX) minX=p.x-Math.ceil(0.02*(maxX-minX));
                        if(p.y>maxY) maxY=p.y+Math.ceil(0.02*(maxY-minY));
                        if(p.y<minY) minY=p.y-Math.ceil(0.02*(maxY-minY));
                    }
                    lastX=x;lastY=y;
                }
            }
        }
		else{
            double step = (-minX + maxX) / (screenWidth-2);
            lastX = BORDER_LX+1;
            lastY = screenHeight + BORDER_TY - (int)((f.f(minX) - minY)/maxHeight*((double)screenHeight));

            for (double x = minX; x < maxX; x += step) {
                double y = f.f(x);
                int pixX = BORDER_LX + 1 + (int)((x - minX)/maxWidth*((double)screenWidth));
                int pixY = BORDER_TY + screenHeight - (int)((y - minY)/maxHeight*((double)screenHeight));


                // Keep curve inside the box
                // Make it look better for functions like tan() (ie steep curves)
                if (pixY > BORDER_TY && pixY < screenHeight + BORDER_TY && lastY >= screenHeight + BORDER_TY)
                    lastY = screenHeight + BORDER_TY - 1;
                else if (pixY > BORDER_TY && pixY < screenHeight + BORDER_TY && lastY <= BORDER_TY)
                    lastY = BORDER_TY + 1;
                if (pixY <= BORDER_TY && lastY > BORDER_TY + 1)
                    pixY = BORDER_TY + 1;
                else if (pixY >= screenHeight + BORDER_TY && lastY < screenHeight + BORDER_TY - 1)
                    pixY = screenHeight + BORDER_TY - 1;
                if (lastY <= BORDER_TY)
                    lastY = BORDER_TY + 1;
                else if (lastY >= screenHeight + BORDER_TY)
                    lastY = screenHeight + BORDER_TY - 1;

                if (pixY > BORDER_TY && pixY < screenHeight + BORDER_TY &&
                    lastY > BORDER_TY && lastY < screenHeight + BORDER_TY)
                    g.drawLine(lastX, lastY, pixX, pixY);

                lastX = pixX;
                lastY = pixY;
            }
        }
    }
	
	private void printDescriptions (Graphics2D g) {
		int x = screenWidth + BORDER_LX + 20;
		int y = BORDER_TY + 10;
		int z;

		for (int i = 0; i < functionList.size(); i++) {
			if (((String)descriptionList.get(i)).length() > 0) {
				String descr = (String)descriptionList.get(i);
				g.setColor((Color)colorList.get(i));
				g.fillRect(x, y, 5, 5);
				g.setColor(Color.black);
				if ((int)(g.getFontMetrics().getStringBounds (descr, g).getWidth()) > BORDER_RX - 25) {
					int len2 = 0;
					for (z = 0; z < descr.length(); y += fontHeight) {
						int len = Math.min(descr.length()-z, 2);
						while ((int)(g.getFontMetrics().getStringBounds (descr.substring(z, z+len), g).getWidth())
						       < BORDER_RX - 25 && len2 != len) {
							len2 = len;
							if (descr.charAt (z+len-1) == ' ')
								len++;
							
							while (len+z < descr.length() && descr.charAt (z+len-1) != ' ')
								len++;
						}
						g.drawString(descr.substring(z, z+len2), x + 9, y + 5);
						z += len2;
					}
				} else {
					g.drawString(descr, x + 9, y + 5);
					y += fontHeight;
				}
			}
		}
	}
	
	public void paint(Graphics g) {
		//Image screen = new Image(getWidth(), getHeight());
		Graphics2D g2d = (Graphics2D)g;
		g2d.setFont(new Font("SansSerif", Font.PLAIN, 10));
		fontHeight = (int)(g.getFontMetrics().getStringBounds ("0132465789", g).getHeight());
		cursorPosition.setBackground(getBackground());
		super.paintComponent (g);
		
		if (antiAliasing)
			g2d.addRenderingHints(AALIAS);
		updateData();
		g.setColor(Color.black);
		drawAxis(g2d, true);

		for (int i = 0; i < functionList.size(); i++)
			plotFunction (g2d, (Function)functionList.get(i), (Color)colorList.get(i));
/*        if (fitToScreen)
            this.FitToScreen();*/
		printDescriptions(g2d);
	}

}