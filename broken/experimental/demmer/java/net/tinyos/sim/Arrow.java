// $Id: Arrow.java,v 1.1 2003/10/17 01:53:35 mikedemmer Exp $

/** 
 * @(#)Arrow.java * * Copyright (c) 2000 by Sundar Dorai-Raj
 * @author Sundar Dorai-Raj
 * Email: sdoraira@vt.edu
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License 
 * as published by the Free Software Foundation; either version 2 
 * of the License, or (at your option) any later version, 
 * provided that any use properly credits the author. 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details at http://www.gnu.org 
 * 
 * Modified by Matt Welsh (mdw@intel-research.net)
 */

package net.tinyos.sim;
import java.awt.*;

public class Arrow {
    public static final int SIDE_LEAD=0, SIDE_TRAIL=1, SIDE_BOTH=2, SIDE_NONE=3;
    private static final double pi=Math.PI;
    private static final int ARROW_LENGTH = 10;
    private static final double ARROW_ANGLE = Math.toRadians(15.0);

    
    
    public static void drawArrow(Graphics g,
				 int x1, int y1, int x2, int y2, int side) {
	int x3,y3,x4,y4;
	double angle;

	try {
	    g.drawLine(x1,y1,x2,y2);

	    switch (side) {
	    case SIDE_LEAD :
		drawArrow(g,x1,y1,x2,y2);
		break;
	    case SIDE_TRAIL :
		drawArrow(g,x2,y2,x1,y1);
		break;
	    case SIDE_BOTH :
		drawArrow(g,x1,y1,x2,y2);
		drawArrow(g,x2,y2,x1,y1);
		break;
	    case SIDE_NONE :
		break;
	    default:
		throw new IllegalArgumentException();
	    }
	}
	catch (IllegalArgumentException iae) {
	    System.out.println("Invalid value for variable side.");
	}
    }

    
    public static void drawArrow(Graphics g,
				 int x1, int y1, int x2, int y2) {
	int x3,y3,x4,y4;
	double angle;
	
	angle = Math.atan2(y2-y1, x2-x1)+pi;
	
	x3=(int)(x2+Math.cos(angle-ARROW_ANGLE)*ARROW_LENGTH);
	y3=(int)(y2+Math.sin(angle-ARROW_ANGLE)*ARROW_LENGTH);
	x4=(int)(x2+Math.cos(angle+ARROW_ANGLE)*ARROW_LENGTH);
	y4=(int)(y2+Math.sin(angle+ARROW_ANGLE)*ARROW_LENGTH );
	
	g.drawLine(x2,y2,x3,y3);
	g.drawLine(x2,y2,x4,y4);
	g.drawLine(x3,y3,x4,y4);
    }    
}
