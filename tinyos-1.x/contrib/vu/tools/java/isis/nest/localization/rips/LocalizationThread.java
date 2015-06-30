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

import isis.nest.geneticoptimizer.Optimizer;

/**
 * @author brano
 *
 */

public class LocalizationThread extends Thread
{   
    public static int LT_STATE_IDLE = 0;
    public static int LT_STATE_RUNING = 1;
    	
	private int                          state;    
    private LocalizationSolutionCallback callback  = null;
    private Optimizer                    optimizer = null;
    private LocalizationData             locData   = null;
    	    	
	public LocalizationThread(LocalizationSolutionCallback callback, LocalizationData locData) throws Exception
    {		
		this.callback = callback;
        optimizer = new Optimizer(locData, Constants.POPULATION_SIZE, Constants.POPULATION_SIZE/10);
        state = LT_STATE_RUNING;
        start();		       		
	}
    
    public int getThreadState()
    {
        return state;
    }
        
    public synchronized void stopLoc()
    {
        state = LT_STATE_IDLE;
        if( callback != null )
            callback.localizationFinished();
            
        // wait thread to finish
        try
        {
            wait();
        }              
        catch(Exception e)
        {
            e.printStackTrace();
        }
              
        optimizer = null;
        System.gc();        
    }
    
    public void run()
    {
        int steps = 0;
        while( state == LT_STATE_RUNING && steps < Constants.MAX_LOC_STEPS)
        {
            steps++;
            optimizer.run(200, 0);
            LocalizationSolution best = (LocalizationSolution)optimizer.getBestSolution();
            if( callback != null )            
                callback.localizationSolution(steps, best);         
            try 
            {
                sleep(20);
            }
            catch(Exception e)
            {
                stopLoc();
                return;
            }          
        }           
        if( callback != null )
            callback.localizationFinished();
        synchronized(this)
        {
            notify();
        }    
    }
}
