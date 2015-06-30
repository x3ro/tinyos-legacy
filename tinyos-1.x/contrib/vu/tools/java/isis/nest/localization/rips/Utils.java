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

public class Utils
{    
    /**
     * Find the cluster center of a set of values.
     * For each point calculate the score: number of neighbours in error radus
     * Than find the point with maximum score. 
     * @param vals Set of values
     * @param error Error radius
     * @return a two elemet array, first element it the best value, 
     * second is its score
     */
    public static double[] simpleClustering( double[] vals, double error )
    {
        double best_val = 0;
        int    best_score = 0;
        for( int i=0; i<vals.length; ++i )
        {
            double min = vals[i] - error;
            double max = vals[i] + error;
            
            int score = 0;
            double avg_in_window = 0;
            for( int j=0; j<vals.length; ++j )
            {
                if( vals[j]>=min && vals[j]<=max )
                {
                    score++;
                    avg_in_window += vals[j];                     
                }
            }
            avg_in_window/=score;
            
            if( score > best_score )
            {
                best_score = score;
                best_val = avg_in_window;
            }
        }        
        
        double ret[] = new double[2];
        ret[0] = best_val;
        ret[1] = best_score;
                
        return ret; 
    }

    
}
