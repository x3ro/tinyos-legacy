/* Copyright (c) 2006 Shockfish SA
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without modification, 
 * are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *   this list of conditions and the following disclaimer in the documentation 
 *   and/or other materials provided with the distribution.
 * - Neither the name of Shockfish SA nor the names of its contributors 
 *   may be used to endorse or promote products derived from this software 
 *   without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, 
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS 
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package com.shockfish.tinyos.bouncer;

/**
 * @author Pierre Metrailler, Shockish SA
 */

import java.util.logging.Logger;
import java.util.logging.Level;

public class TOSBouncer {
	
    BouncerServerSocketThread s;
    BouncerServerSocketThread g;
	
    boolean both;
	
	public void bounce(int lp, int hp) {
        try {
            s = new BouncerServerSocketThread(hp);
            g = new BouncerServerSocketThread(lp);
        } catch (Exception e) {
            return;
        }
        
		both = false;
		g.start();
		s.start();
        

		Logger.global.info("Initiating bridge on port " + g.getPort() + " and " + s.getPort());
		for (;;) {
			try {
				Thread.sleep(20);
                
                // resurrection
                if (!s.isAlive()) {
                    disconnected();
                    s.start();
                }
                if (!g.isAlive()) {
                    disconnected();
                    g.start();
                }
				if ((s.sock!=null) && (g.sock!=null))
				if ((s.sock.isConnected()) && (g.sock.isConnected()) && (!both)) {
					both = true;
					try {
						Logger.global.info("Endpoints connected");
						s.out = g.sock.getOutputStream();
						g.out = s.sock.getOutputStream();
						
					} catch (Exception e) {
                        both = false;
                        Logger.global.severe("Error when connecting endpoints ("+e.getMessage()+")");
                        // in theory we should shut down the 2 threads.
                        return;
					}
					g.setSwallow(true);
					s.setSwallow(true);
					g.tell();
					s.tell();
					Logger.global.info("Redirection enabled!");
				}
			} catch (Exception e) {
				both = false;
                Logger.global.severe("Error in server logic ("+e.getMessage()+")");
                // in theory we should shut down the 2 threads.
                return;
			}
			
		}
	}
	
    private void disconnected() {
        both = false;
        Logger.global.info("Redirection disabled.");
    }
    
	public static void main(String[] args) {
		
		Logger.global.setLevel(Level.FINEST);
		
		int mlp = 0;
		int mhp = 0;
		 try {
		     mlp = Integer.parseInt(args[0]);
		     mhp = Integer.parseInt(args[1]);
		 } catch (NumberFormatException e) {
		     System.out.println("Bad arguments.");
		     return;
		 }
		TOSBouncer b = new TOSBouncer();
		b.bounce(mlp, mhp);
        Logger.global.info("Bridge terminated.");
	}
	
	
	
	
}
