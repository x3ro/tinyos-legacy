// $Id: PlotApplet.java,v 1.2 2003/10/07 21:46:02 idgay Exp $

package net.tinyos.plot;

import java.applet.*;
import java.awt.*;
import javax.swing.*;
import java.util.*;

public class PlotApplet extends JApplet {
	private plotpanel plot;
	
	public PlotApplet() {
	}

	private Color toColor (String s) {
		StringTokenizer st = new StringTokenizer(s);
		Color c = new Color (Integer.parseInt(st.nextToken()),
			Integer.parseInt(st.nextToken()), Integer.parseInt(st.nextToken()));
		return c;
	}
	
	public void init() {
		plot = new plotpanel();
		getContentPane().add(plot);
		String bg = null;
		String antialiasing = getParameter ("antialiasing");
		String minX=getParameter ("minX"),
		       maxX=getParameter ("maxX"),
		       minY=getParameter ("minY"),
		       maxY=getParameter ("maxY");
		if (minX != null)
			plot.setMinX (Double.parseDouble(minX));
		if (minY != null)
			plot.setMinY (Double.parseDouble(minY));
		if (maxX != null)
			plot.setMaxX (Double.parseDouble(maxX));
		if (maxY != null)
			plot.setMaxY (Double.parseDouble(maxY));


		if (antialiasing != null && antialiasing.equals("true"))
			plot.setAntiAliasing (true);

		if ((bg = getParameter ("background")) != null) {
			Color c = toColor (bg);
			plot.setBackground(c);
		}
		for (int i = 1; ; i++) {
			String function = getParameter ("function"+i);
			if (function == null) {
				break;
			}
			String description = getParameter ("description"+i);
			String color = getParameter ("color"+i);
			plot.addFunction (new ParsedFunction(function), toColor(color), description);
		}
		//add (plot);	
	}
}