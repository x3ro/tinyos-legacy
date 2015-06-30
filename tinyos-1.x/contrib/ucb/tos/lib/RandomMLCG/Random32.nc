/*
 * "Copyright (c) 2002-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */
/*
 * Authors:	 	Barbara Hohlt	
 * Date last modified:  02/28/05 
 */

/**
 * This is the interface to a fast pseudorandom number generator. 
 * This interface is implemented by RandomMLCG, which uses a 
 * multiplicative linear congruential generator. 
 *
 * @author  Barbara Hohlt 
 * @modified 
 */

interface Random32
{
    /**
     * Initialize the random number generator.
     * @return Returns SUCCESS if the initialization is successful, or FAIL if
     * the initialization failed.  For the current implementation
     * there are no known failure modes.
     */
  async command result_t init();

    /**
     * Initialize the random number generator.
     *
     * @param s Initialize with 16-bit seed.
     *
     * @return Returns SUCCESS if the initialization is successful, or FAIL if
     * the initialization failed.  For the current implementation
     * there are no known failure modes.
     */
  async command result_t initSeed(uint16_t s);

    /** 
     * Produces a 32-bit pseudorandom number. 
     * @return Returns a 32-bit pseudorandom number.
     */
  async command uint32_t rand32();

    /** 
     * Produces a 32-bit pseudorandom number. 
     * @return Returns low 16 bits of the pseudorandom number.
     */
  async command uint16_t rand16();

}

    
