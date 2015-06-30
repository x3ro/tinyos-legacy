/** * Copyright (c) 2003 - The Ohio State University. * All rights reserved. * * Permission to use, copy, modify, and distribute this software and its * documentation for any purpose, without fee, and without written agreement is * hereby granted, provided that the above copyright notice, the following * two paragraphs, and the author attribution appear in all copies of this * software. * * IN NO EVENT SHALL THE OHIO STATE UNIVERSITY BE LIABLE TO ANY PARTY FOR * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE OHIO STATE * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. * * THE OHIO STATE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS * ON AN "AS IS" BASIS, AND THE OHIO STATE UNIVERSITY HAS NO OBLIGATION TO * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. */

import javax.management.*;

import java.awt.* ;

public class Targetinfo
{

    private int x;
    private int y;
    private int type;
    private int expected_type;
    private int num_correct_predictions;
    private int iteration;
    private int confidence;
    private int max_x;
    private int max_y;
    private int min_x;
    private int min_y;
    private int active;
    private int low_count;

    private int prevx;
    private int prevy;

    private int displaybit;
    
    public Targetinfo(int type, int x, int y) 
    {
        this.type=type;
        this.x=x;
        this.y=y;
        this.prevx=x;
        this.prevy=y;
        this.expected_type=type;
        this.num_correct_predictions=0;
        this.iteration=0;
        this.confidence=0;
        this.active=1;
        this.max_x=this.max_y=this.min_x=this.min_y=0;
        this.low_count=0;
	this.displaybit=0;
    }

    public void inc_low_count()
    {
        low_count++;
    }

     public void set_low_count(int s)
     {
	low_count=s;
      }

    public void set_displaybit(int s)
     {
	displaybit=s;
      }

    public int get_displaybit()
     {
	return displaybit;
      }

    public void inc_iteration()
    {
        iteration++;
    }

    public int get_iteration()
    {
        return iteration;
    }

    public void inc_num_correct_pred()
    {
        num_correct_predictions++;
    }

    public void deactivate()
    {
        active=0;
    }

    public void activate(int t, int xa, int ya)
    {
        active=1;
        type=t;
        x=xa;
        y=ya;
    }

    public void calculate_expected_type(int dist_motes)
    {
        expected_type=type;
        max_x = x+type*dist_motes*2 +1;
        min_x = x-type*dist_motes*2 -1;
        if (min_x<0) min_x=0;
        max_y = y+type*dist_motes*2+1;
        min_y = y-type*dist_motes*2-1;
        if (min_y<0) min_y=0;
    }

    public void display()
    {
       System.out.println("Active state " + active);
        System.out.println("Type is " + type);
        System.out.println("X position " + x);
        System.out.println("Y Position " + y);
        if (confidence == 0) System.out.println("Confidence of plot is low" );
            else if (confidence == 1) System.out.println("Confidence of plot is medium" );
            else System.out.println("Confidence of plot is high" );
    
    }

    

    public int active()
    {
        return active;
    }

    public int max_x()
    {
        return max_x;
    }

    public int min_x()
    {
        return min_x;
    }

    public int max_y()
    {
        return max_y;
    }

    public int min_y()
    {
        return min_y;
    }

    public int confidence()
    {
        return confidence;
    }

    public int low_count()
    {
        return low_count;
    }

    public int expected_type()
    {
        return expected_type;   
    }

    public void set_confidence(int conf)
    {
        confidence=conf;
    }

    public void setx(int meanx)
    {
        x=meanx;
    }

    public void sety(int meany)
    {
        y=meany;
    }

    public void set_type(int t)
    {
        type=t;
    }
    
    public int gettype()
    {
        return type;
    }
    
    public int getx()
    {
        return x;
    }
    
    public int gety()
    {
        return y;
    }

    public int get_prevx()
    {
        return prevx;
    }
    
    public int get_prevy()
    {
        return prevy;
    }
    

}
