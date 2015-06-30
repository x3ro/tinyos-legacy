// $Id: EmpiricalFunction.java,v 1.3 2003/10/07 21:46:01 idgay Exp $

package net.tinyos.plot;

import java.util.Vector;
import java.awt.*;

public class EmpiricalFunction implements Function {
    public Vector points = new Vector();
    public String plotStyle = new String("lines");//lines, dots, both

	public EmpiricalFunction() {
	}
	
	public double f(double x) {
		return Double.NaN;
	}

      public class PlotPoint{
          double x;
          double y;
          double radius;
          int timeout;
          Color color;
          String label;

          public PlotPoint(double x, double y, double radius, int timeout, Color color, String label){
              this.x=x;
              this.y=y;
              this.radius=radius;
              this.timeout=timeout;
              this.color=color;
              this.label=label;
          }

          public boolean equals(PlotPoint p){
              return (x==p.x && y==p.y);
          }

      }

}