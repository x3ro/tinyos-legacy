/* Copyright (c) 2007 ETH Zurich.
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions
*  are met:
*
*  1. Redistributions of source code must retain the above copyright
*     notice, this list of conditions and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright
*     notice, this list of conditions and the following disclaimer in the
*     documentation and/or other materials provided with the distribution.
*  3. Neither the name of the copyright holders nor the names of
*     contributors may be used to endorse or promote products derived
*     from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
*
*  For additional information see http://www.btnode.ethz.ch/
*
*  $Id: TreeInfoVertexPaintFunction.java,v 1.1 2008/01/11 19:19:15 rlim Exp $
*  
*/

/**
 * @author Roman Lim
 */

import java.awt.Color;
import java.awt.Paint;

import edu.uci.ics.jung.graph.Vertex;
import edu.uci.ics.jung.graph.decorators.VertexPaintFunction;


public class TreeInfoVertexPaintFunction implements VertexPaintFunction {

	private Paint active, standby, inactive, border;
	private int timeout, standbytimeout;
	
	public TreeInfoVertexPaintFunction(int timeout, int standbytimeout){
		active=new Color(0x00ff00);
		standby=new Color(0x009000);
		inactive=new Color(0x801010);
		border=new Color(0x000000);
		this.timeout = timeout;
		this.standbytimeout = standbytimeout;
	}
	
	public Paint getDrawPaint(Vertex v) {
		return border; 
	}

	public Paint getFillPaint(Vertex v) {
		if (System.currentTimeMillis()-((TosNode)v).getLastSeen()>standbytimeout) {
			return inactive;
		}
		else if (System.currentTimeMillis()-((TosNode)v).getLastSeen()>timeout) {
			return standby;
		}
		else
			return active;
	}
}
