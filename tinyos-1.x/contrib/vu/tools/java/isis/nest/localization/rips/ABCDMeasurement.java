/*
 * Copyright (c) 2005, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for instruction and non-commercial research only, without
 * fee, and without written agreement is hereby granted, provided that the
 * this copyright notice including the following two paragraphs and the 
 * author's name appear in all copies of this software.
 * 
 * IN NO EVENT SHALL VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */
 // @author Brano Kusy: kusy@isis.vanderbilt.edu
 
 package isis.nest.localization.rips;

//import java.io.BufferedReader;
//import java.io.FileReader;
//import java.util.StringTokenizer;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Iterator;

public class ABCDMeasurement
{
    public static class ABCDMeasurementComparator implements Comparator
    {
        static private ABCDMeasurementComparator theInstance = null;

        public int compare(Object arg0, Object arg1)
        {
            double e0 = ((ABCDMeasurement)arg0).error;
            double e1 = ((ABCDMeasurement)arg1).error;
    
            if( e0 > e1 )
                return 1;
            else if( e0 < e1 )
                return -1;
            else
                return System.identityHashCode(arg0) - System.identityHashCode(arg1);        
        }
    
        static public ABCDMeasurementComparator instance() 
        {
            if( theInstance == null )
                theInstance = new ABCDMeasurementComparator();

            return theInstance;
        }                  
    }
    
    static class PhaseOffset
    {
        protected boolean valid;      // true if measurement is valid
        protected double  freq;       // in hertz
        protected double  amplitude;  // amplitude, scaled from 0-1  
        protected double  k;          // 2*pi*freq/c
        protected double  offset;     // phase offset in radian               
                    
        PhaseOffset( double freq, double offset, double amplitude, boolean good )
        {
            this.freq      = freq;
            this.offset    = offset;
            this.amplitude = amplitude; 
            this.valid     = good;
            k = 2*Math.PI*freq/Constants.SPEED_OF_LIGHT;
            //System.out.println("k=\t"+k);
        }
    }           
    
    protected int sensor_A;       // id of first sender
    protected int sensor_B;       // id of second sender
    protected int sensor_C;       // id of first receiver
    protected int sensor_D;       // id of second receiver        
    
    protected int sensor_A_ind;       // index of first sender
    protected int sensor_B_ind;       // index of second sender
    protected int sensor_C_ind;       // index of first receiver
    protected int sensor_D_ind;       // index of second receiver*/
    
    protected ArrayList phaseOffsetMeasurments = new ArrayList();  // phase offcet measurements
    protected int goodOffsetMeasurements = 0;
    protected double    calc_dist              = 0;   // calculated AC-BC+BD-AD distance
    protected double	dist_dev			   = 0;	  // internal error of calc_dist (deviation of all solutions)  
    protected double    real_dist              = 0;   // real AC-BC+BD-AD distance
    protected double    error                  = 0;
    protected boolean   valid                  = false;      // true if dist_abcd is valid
   
    public String toString()
    {
        return sensor_A + "\t" + sensor_B + "\t" + sensor_C + "\t" + sensor_D + "\t" + real_dist + 
            "\t" + calc_dist + "\t" + error + "\t" + Math.abs(real_dist-calc_dist);   
    }

    /*public void read( String file_name ) throws Exception 
    {
        BufferedReader r = new BufferedReader(new FileReader(file_name));
        String line = r.readLine();

        // read measurements       
        phaseOffsetMeasurments.clear();
        while( line != null )
        {
            StringTokenizer t = new StringTokenizer(line);
            double freq = Double.parseDouble(t.nextToken());
            double offset = Double.parseDouble(t.nextToken());
            phaseOffsetMeasurments.add( new PhaseOffset(freq, offset,0,true) );
            //System.out.println(freq + "\t" + offset);                
            line = r.readLine();
        }
    }*/

    public void computeDistFast( PrintStream log )
    {            
        ArrayList valid_measurements = new ArrayList();
		int good_freq = 0;

		// the average q-range of the frogs
		double sum = 0;

		// ArrayList n = new ArrayList();
		ArrayList<Double> xal = new ArrayList<Double>();
		// ArrayList offset = new ArrayList();
		// ArrayList k = new ArrayList();
		ArrayList<Double> jal = new ArrayList<Double>();

		// calculate initial frog positions and jump lengths
		double accumulatedPhaseError = 0.0;
        Iterator it = phaseOffsetMeasurments.iterator();
        while( it.hasNext() )
        {     
        	PhaseOffset o = (PhaseOffset)it.next();

			if (o == null || !o.valid)
				continue;

			// calculate the phase offset
			double phase_offset = o.offset;
			// store phase offset
			// offset.add(new Double(phase_offset));
			// calculate scaling constant
			double k_ = o.k;
			// store k
			// k.add(new Double(k_));

			// calculate n for the starting position of the frog of the channel
			int n_ = (int) Math.round((k_ * -Constants.MAX_ABCD_RANGE - phase_offset)
					/ (2 * Math.PI));
			// n.add(new Integer(n_));

			// calculate position for the starting position of the frog of the
			// channel
			xal.add(new Double((phase_offset + n_ * 2 * Math.PI) / k_));

			// calculate jump length for the frog of the channel
			jal.add(new Double(2 * Math.PI / k_));

			// increase average
			sum += ((Double) xal.get(good_freq)).doubleValue();

			// increase number of frog positions in average
			good_freq++;
		}

		// convert xal to array of doubles
		double[] x = new double[good_freq];
		for (int i = 0; i < xal.size(); i++)
			x[i] = ((Double) xal.get(i)).doubleValue();

		// convert jal to array of doubles
		double[] j = new double[good_freq];
		for (int i = 0; i < jal.size(); i++)
			j[i] = ((Double) jal.get(i)).doubleValue();

		// precalculate weight of a frog in avg and var
		double frogWeight = 1.0 / good_freq;

		// calculate average of frog positions
		double avg = sum * frogWeight;

		// calculate variance of frog positions
		double var = 0;
		for (int i = 0; i < good_freq; ++i)
			var += Math.pow(avg - x[i], 2);
		var *= frogWeight;

		double min_error = Double.MAX_VALUE;
		double best_x = 0;

		while (avg < Constants.MAX_ABCD_RANGE) {
			double error = Math.sqrt(var);

			// update best error and the corresponding distance
			if (error < min_error) {
				min_error = error;
				best_x = avg;
			}
            if( log!=null )
            {                               
                log.println( avg + "\t" + error );                           
            }
 
			// find the last frog
			int lastFrog = 0;
			for (int i = 1; i < good_freq; ++i)
				if (x[i] < x[lastFrog])
					lastFrog = i;

			// decrease average and variance with the position of last frog
			var -= Math.pow(x[lastFrog] - avg, 2) * frogWeight;
			avg -= x[lastFrog] * frogWeight;

			// jump the last frog
			x[lastFrog] += j[lastFrog];

			// increase average and variance with the new position of last frog
			avg += x[lastFrog] * frogWeight;
			var += Math.pow(x[lastFrog] - avg, 2) * frogWeight;

		}

		calc_dist = best_x;
		dist_dev = min_error;
		valid = true;
	}
    
    
    public void computeDist( PrintStream log )
    {            
        // given a set of equations: 
        // k(i)*x = y(i) + 2*pi*n(i)
        // ...
        // k(m)*x = y(m) + 2*pi*n(m)            
        // where x is the dist_abcd, y(i) is the phase offset,
        // k(i) is 2*pi*freq/c
        
        // filter out invalid measurements       
        ArrayList valid_measurements = new ArrayList();
        int m = 0;
        int i = 0;
        Iterator it = phaseOffsetMeasurments.iterator();
        while( it.hasNext() )
        {            
            PhaseOffset o = (PhaseOffset)it.next();
            if( o.valid )
            {
                valid_measurements.add(o);
                m++;
            }
            i++;
        }

        // compute n(1)..n(m) for min distance
        PhaseOffset p;
        int n[] = new int[m];
        double x[] = new double[n.length];            
        double min_dist = -Constants.MAX_ABCD_RANGE;
        for( i=0; i<m; ++i )
        {
            p = (PhaseOffset)valid_measurements.get(i);
            n[i] = (int)Math.round((p.k * min_dist - p.offset) / (2*Math.PI));
            x[i] = (p.offset + n[i]*2*Math.PI) / p.k;
        }
    
        double min_error = Double.MAX_VALUE;
        double best_x = 0;

        while( x[0]<Constants.MAX_ABCD_RANGE )
        {
            double error = 0;
                                      
            // calc average
            double avg = 0;                               
            for( i=0; i<m; ++i )
                avg += x[i];                     
            avg /= m;
            
            // calc variance
            double dev = 0;
            for( i=0; i<m; ++i )
                dev += (avg-x[i]) * (avg-x[i]);
            dev = Math.sqrt(dev/m);        
            error = dev;
            if( error < min_error)
            {
                min_error = error;
                best_x = avg; 
            }
            
            if( log!=null )
            {                               
                log.println( avg + "\t" + error );                           
            }
        
            // find smallest x, increase its n, and recalculate x
            int min_x = 0;
            for( i=1; i<m; ++i )                
                if( x[i]<x[min_x] )
                    min_x = i;
            n[min_x]++;
            p = (PhaseOffset)valid_measurements.get(min_x);                
            x[min_x] = (p.offset + n[min_x]*2*Math.PI) / p.k;
        }
        
        calc_dist = best_x;
        dist_dev = min_error;
        valid = true;                            
    }
}
