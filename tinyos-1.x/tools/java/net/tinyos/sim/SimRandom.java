// $Id: SimRandom.java,v 1.2 2004/12/09 01:28:38 scipio Exp $

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
 * Desc:        Random number generator to be used for repeatable simulations
 *
 */

/**
 * @author Michael Demmer
 */


package net.tinyos.sim;

import java.util.*;

public class SimRandom {
  private static Random random;
  
  private long randomSeed;

  static {
    random = new Random(System.currentTimeMillis());
  }

  public SimRandom(long seed) {
    randomSeed = seed;
    random = new Random(seed);
  }

  public long getSeed() {
    return randomSeed;
  }

  /**
   * Accessor methods exported from java.util.Random
   */
  public boolean nextBoolean()		{ return random.nextBoolean(); }
  public void	nextBytes(byte[] bytes) { random.nextBytes(bytes); }
  public double nextDouble()		{ return random.nextDouble(); }
  public float  nextFloat()		{ return random.nextFloat(); }
  public double nextGaussian()		{ return random.nextGaussian(); }
  public int	nextInt()		{ return random.nextInt(); }
  public int 	nextInt(int n)		{ return random.nextInt(n); }
  public long 	nextLong()		{ return random.nextLong(); }

  /**
   * Static analog for Math.random().
   */
  public static double random() 	{ return random.nextDouble(); }

  /**
   * Method to get a new generator that's seeded based on a new random
   * seed, deterministically derived from the original seed.
   */
  public Random getRandom() {
    return new Random(nextLong());
  }
}
