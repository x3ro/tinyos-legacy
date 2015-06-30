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

import isis.nest.geneticoptimizer.Genotype;
import isis.nest.geneticoptimizer.RandomSingleton;

import java.util.Iterator;
import java.util.Random;


public class LocalizationSolution extends Genotype
{    
    protected LocalizationData    problem;
    protected Point[]             sensors;
    protected double[]            measurement_weight;
    double                        measurement_weight_avg;
       
    protected Random  rand  = RandomSingleton.instance();

    public LocalizationSolution( LocalizationData problem )
    {
        this.problem = problem;
        measurement_weight = new double[problem.abcd_measurements.size()];        
        random();
    }

    public LocalizationSolution( LocalizationSolution sol )
    {
        int i;
        problem = sol.problem;
        sensors = new Point[sol.sensors.length];
        measurement_weight = new double[sol.measurement_weight.length];
        for( i=0; i<measurement_weight.length; ++i )
            measurement_weight[i] = sol.measurement_weight[i];
        for( i=0; i<sol.sensors.length; ++i )
            sensors[i] = new Point( sol.sensors[i].x, sol.sensors[i].y, sol.sensors[i].z );
        fitness = sol.fitness;       
    }
    
    public void printSensorCoordinates()
    {
    	Object[] sensorsArray = problem.sensors.values().toArray(); 
    	System.out.println("Calculated locations (nodeID, x, y, z):");
        for( int i=0; i<sensors.length; ++i )
            System.out.println( ((LocalizationData.Sensor)sensorsArray[i]).getId() + "\t" + sensors[i].x + "\t " + sensors[i].y + "\t" + sensors[i].z );       
    }
        
    public double[] calcWeightStat( double max_error )
    {        
        int good_num = 0;
        int bad_num  = 0;
        double good_avg = 0;
        double bad_avg  = 0;
        int i = 0;
        int bad_above_05 = 0;
        
        Iterator it = problem.abcd_measurements.iterator();
        while( it.hasNext() )
        {
            ABCDMeasurement m = (ABCDMeasurement)it.next();
            if( Math.abs(m.calc_dist-m.real_dist) < max_error )
            {
                good_avg += measurement_weight[i];
                good_num++;                  
            }
            else
            {
                bad_avg += measurement_weight[i];
                bad_num++;                
                if( measurement_weight[i] > 0.5 )
                    bad_above_05++;                
            }   
            i++;
        }
        
        good_avg/=good_num;
        bad_avg/=bad_num;
                
        double ret[] = {good_avg, bad_avg,bad_above_05};
        return ret;
    }

    public void printUsedStatistcs()
    {
    	int i = 0;
        Iterator it = problem.abcd_measurements.iterator();
        while( it.hasNext() )
        {
            ABCDMeasurement m = (ABCDMeasurement)it.next();
            System.out.println( Math.abs(m.calc_dist-m.real_dist) + "\t" + measurement_weight[i] );
            i++;    
        }
    }


    public void random()
    {
        int i;
        sensors = new Point[problem.sensors.size()];
        for( i=0; i<sensors.length; ++i )
        {
            LocalizationData.Sensor sensor = (LocalizationData.Sensor)problem.sensors.values().toArray()[i];
            if( sensor.anchor )
            {
                sensors[i] = new Point();
                sensors[i].copy(sensor.pos);                
            }
            else
            {                       
                sensors[i] = new Point( problem.x_max * rand.nextDouble(), problem.y_max * rand.nextDouble(), 
                    problem.z_max * rand.nextDouble() ); 
            }
        }   
        
        for( i=0; i<measurement_weight.length; ++i )
            measurement_weight[i] = rand.nextDouble();
    }

    public void derive( Genotype parent1, Genotype parent2 )
    {
        int i,j;
        
        LocalizationSolution p1 = (LocalizationSolution)parent1;
        LocalizationSolution p2 = (LocalizationSolution)parent2;
            
        double p = rand.nextDouble();        
        double delta = -fitness;
        if( rand.nextBoolean() )
            delta = 0.1 * rand.nextDouble();
            
        // inherit and mutate used measurements        
        for( i=0; i<measurement_weight.length; ++i )
        {
        	//inherit       	
            if( rand.nextBoolean() )
                measurement_weight[i] = p1.measurement_weight[i];
            else
                measurement_weight[i] = p2.measurement_weight[i];
	            
            //mutate
        	//measurement_weight[i] += 0.01*rand.nextDouble() * (rand.nextInt(3)-1 );
            measurement_weight[i] += 0.01*rand.nextGaussian();
        	        		        	
    	    if( measurement_weight[i] < 0)
    	    	measurement_weight[i] = 0;
        	
            if( measurement_weight[i] > 1)
            	measurement_weight[i] = 1; 
        }
                             
    	Object[] sensorsArray = problem.sensors.values().toArray(); 

    	// inherit sensor pos
        for( i=0; i<sensors.length; ++i )
        {
            LocalizationData.Sensor sensor = (LocalizationData.Sensor)sensorsArray[i];
            if( !sensor.anchor )
            {                        
                if( rand.nextBoolean() )
                    sensors[i].copy( p1.sensors[i] );                   
                else
                    sensors[i].copy( p2.sensors[i] );
            }
        }             
    
        // mutate sensor pos
        if( rand.nextBoolean() )
        {        
            for( i=0; i<sensors.length; ++i )
            {
                LocalizationData.Sensor sensor = (LocalizationData.Sensor)sensorsArray[i];                                
                if( !sensor.anchor && rand.nextDouble() < p )
                {
                    sensors[i].x += delta * rand.nextGaussian();
                    sensors[i].y += delta * rand.nextGaussian();
                    sensors[i].z += delta * rand.nextGaussian();
                }                
            }
        }
        else if( rand.nextBoolean() )
        {
            i = rand.nextInt(sensors.length);
            LocalizationData.Sensor sensor = (LocalizationData.Sensor)sensorsArray[i];
            if( !sensor.anchor  )
            {                               
                sensors[i].x = problem.x_max * rand.nextDouble();
                sensors[i].y = problem.y_max * rand.nextDouble();
                sensors[i].z = problem.z_max * rand.nextDouble();
            }
        }
        else
        {
            // move the whole net
            double dx = delta * rand.nextGaussian();
            double dy = delta * rand.nextGaussian();
            double dz = delta * rand.nextGaussian();
            for( i=0; i<sensors.length; ++i )
            {
                LocalizationData.Sensor sensor = (LocalizationData.Sensor)sensorsArray[i];                                
                if( !sensor.anchor )
                {
                    sensors[i].x += dx;
                    sensors[i].y += dy;
                    sensors[i].z += dz;
                }
            }
        }
        
        // validate pos
        for( i=0; i<sensors.length; ++i )
        {
            LocalizationData.Sensor sensor = (LocalizationData.Sensor)sensorsArray[i];                              
            if( !sensor.anchor )
            {
                if( sensors[i].x < 0 )
                    sensors[i].x = 0;
                if( sensors[i].x > problem.x_max )
                    sensors[i].x = problem.x_max;
        
                if( sensors[i].y < 0 )
                    sensors[i].y = 0;
                if( sensors[i].y > problem.y_max )
                    sensors[i].y = problem.y_max;
        
                if( sensors[i].z < 0 )
                    sensors[i].z = 0;
                if( sensors[i].z > problem.z_max )
                    sensors[i].z = problem.z_max;
            }
        }
        
    }

    public double evaluate()
    {       
        int i = 0;
        double n  = 0;    // all       
        double error2 = 0;
        double max = 0;
        
        Iterator it = problem.abcd_measurements.iterator();
        while( it.hasNext() )
        {
            ABCDMeasurement m = (ABCDMeasurement)it.next();
            if( m.sensor_A_ind>=0 && m.sensor_B_ind>=0 && m.sensor_C_ind>=0 && m.sensor_D_ind>=0 )
            {                       
                double dist =
                    sensors[m.sensor_A_ind].distance(sensors[m.sensor_D_ind]) -
                    sensors[m.sensor_B_ind].distance(sensors[m.sensor_D_ind]) +
                    sensors[m.sensor_B_ind].distance(sensors[m.sensor_C_ind]) -
                    sensors[m.sensor_A_ind].distance(sensors[m.sensor_C_ind]);
                double measured_dist = m.calc_dist;
                
                double e = Math.abs(dist-measured_dist);
                                
                double w = 1;
                
                error2 += w*e*e*measurement_weight[i]*measurement_weight[i];
                //error2 += w*e*e;
                measurement_weight_avg += measurement_weight[i];
                n+=w;
            }
            i++;
        }
                        
        measurement_weight_avg = measurement_weight_avg / n;
        error2 = (Math.sqrt(error2)/n)/(measurement_weight_avg);
        //error2 = Math.sqrt(error2)/n;
        
        fitness = -error2;                     

        return fitness;        
    }

    public double maxLocError()
    {
        double max_error = - Double.MAX_VALUE;
        for( int i=0; i<sensors.length; ++i )
        {
           	LocalizationData.Sensor sensor = (LocalizationData.Sensor)problem.sensors.values().toArray()[i];
            if( !sensor.anchor )
            {
                if (max_error < Math.abs(sensor.pos.distance(sensors[i])))
                    max_error = Math.abs(sensor.pos.distance(sensors[i]));
            }
        }
        return max_error;
        
    }

    public double locError()
    {
        int n = 0;
        double error = 0;
        for( int i=0; i<sensors.length; ++i )
        {
           	LocalizationData.Sensor sensor = (LocalizationData.Sensor)problem.sensors.values().toArray()[i];
            if( !sensor.anchor )
            {
                error += Math.abs(sensor.pos.distance(sensors[i]));
                n++;
            }
        }
        return error/n;
    }
    
    public void printLocError()
    {
        int n = 0;
        double error = 0;
        for( int i=0; i<sensors.length; ++i )
        {
            LocalizationData.Sensor sensor = (LocalizationData.Sensor)problem.sensors.values().toArray()[i];
            if( !sensor.anchor )
            {
                double dist = sensor.pos.distance(sensors[i]);                
                error += dist;
                n++;
                
                System.out.println( sensor.id + "\t" + dist );
            }
        }
        System.out.println( "avg error=\t" + (error/n) );
    }
 
}
