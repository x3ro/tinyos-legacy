/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */


/***
** Usage:
** 
** public void paint(Graphics g) {
**   Arrow arrow=new Arrow();
**   arrow.drawArrow(g,100,100,Math.PI/4,100,Arrow.SIDE_LEAD);
** }
** 
** Source code:
** 
***/
/** * @(#)Arrow.java * * Copyright (c) 2000 by Sundar Dorai-Raj
  * * @author Sundar Dorai-Raj
  * * Email: sdoraira@vt.edu
  * * This program is free software; you can redistribute it and/or
  * * modify it under the terms of the GNU General Public License 
  * * as published by the Free Software Foundation; either version 2 
  * * of the License, or (at your option) any later version, 
  * * provided that any use properly credits the author. 
  * * This program is distributed in the hope that it will be useful,
  * * but WITHOUT ANY WARRANTY; without even the implied warranty of
  * * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  * * GNU General Public License for more details at http://www.gnu.org 
  * * */
import java.awt.*;

public class Arrow {
  public static final int SIDE_LEAD=0,
                          SIDE_TRAIL=1,
                          SIDE_BOTH=2,
                          SIDE_NONE=3;
  public final double pi=Math.PI;
  
  public Arrow () { ; }

  public void drawArrow(Graphics g,
                        int x,int y,
                        double theta,
                        int length,
                        int side) {
    try {
      if (length < 0) { 
        theta+=pi;
        length*=-1;
      }
      int x1,y1;
      x1=(int)Math.ceil(x + length*Math.cos(theta));
      y1=(int)Math.ceil(y - length*Math.sin(theta));
      g.drawLine(x,y,x1,y1);

      switch (side) {
        case SIDE_LEAD :
          drawArrow(g,x1,y1,theta+5*pi/4,5,SIDE_NONE);
          drawArrow(g,x1,y1,theta+3*pi/4,5,SIDE_NONE);
          break;
        case SIDE_TRAIL :
          drawArrow(g,x,y,theta-pi/4,5,SIDE_NONE);
          drawArrow(g,x,y,theta+pi/4,5,SIDE_NONE);
          break;
        case SIDE_BOTH :
          drawArrow(g,x,y,theta-pi/4,5,SIDE_NONE);
          drawArrow(g,x,y,theta+pi/4,5,SIDE_NONE);
          drawArrow(g,x1,y1,theta+5*pi/4,5,SIDE_NONE);
          drawArrow(g,x1,y1,theta+3*pi/4,5,SIDE_NONE);
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
}
