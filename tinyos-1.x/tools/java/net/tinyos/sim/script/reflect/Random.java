// $Id: Random.java,v 1.1 2004/06/11 21:30:15 mikedemmer Exp $

/*
 *
 *
 * "Copyright (c) 2004 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice and the following two paragraphs appear in all copies of
 * this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Authors:	Michael Demmer
 * Date:        June 10, 2004
 * Desc:        Random number generator 
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim.script.reflect;

import net.tinyos.sim.*;
import net.tinyos.sim.script.ScriptInterpreter;

/**
 * The Random class is used as a hook to get random numbers from the
 * single random number generator instance within the simulator. This
 * should be used instead of java.util.Random or the python builtin
 * interface to allow a single seed value to be passed to Tython and
 * therefore enable repeatable simulations.
 */
public class Random extends SimReflect {
  private SimRandom simRandom;
  
  public Random(ScriptInterpreter interp, SimDriver driver) {
    super(interp, driver);
    simRandom = driver.getSimRandom();
  }

  public boolean nextBoolean()		{ return simRandom.nextBoolean(); }
  public void	nextBytes(byte[] bytes) { simRandom.nextBytes(bytes); }
  public double nextDouble()		{ return simRandom.nextDouble(); }
  public float  nextFloat()		{ return simRandom.nextFloat(); }
  public double nextGaussian()		{ return simRandom.nextGaussian(); }
  public int	nextInt()		{ return simRandom.nextInt(); }
  public int 	nextInt(int n)		{ return simRandom.nextInt(n); }
  public long 	nextLong()		{ return simRandom.nextLong(); }
}
  
