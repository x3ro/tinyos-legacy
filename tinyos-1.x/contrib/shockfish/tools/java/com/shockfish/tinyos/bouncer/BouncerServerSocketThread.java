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

import java.net.*;
import java.io.*;
import java.util.logging.Logger;
import java.util.logging.Level;

class BouncerServerSocketThread extends Thread {
	
	ServerSocket ss = null;
	boolean  swallow = false;
	int port;
	
	public static final int BUFSIZE = 50;	
	
	public Socket sock = null;
	public OutputStream out = null;

    private DataInputStream in = null;
    
	public BouncerServerSocketThread(int port) throws Exception {
		super();
		this.port = port;
		try {
			this.ss = new ServerSocket(port);
		} catch (IOException ioe) {
            Logger.global.info("Could not bind socket on port "+port);
            throw new Exception("Bind error");
		}
	}
	
	public int getPort() { return this.port; }
	public synchronized void setSwallow(boolean set) {	this.swallow = set; }	
	public synchronized void tell() { notifyAll(); }

	public synchronized void standby() {
		while (!swallow) {
			try {
				wait();
			} catch (InterruptedException e) {e.printStackTrace();}	
		}
	}
	
	public void run() {
		for (;;) {
			try {
                Logger.global.info("Waiting for incoming connection on port "+this.port);
				this.sock = ss.accept();
            } catch (IOException ioe) {
                Logger.global.info("Could not accept connections on port "+port);
                cleanupThread();
                return;
            } catch (Exception e) {
                Logger.global.info("Unknown exception when binding.");
                cleanupThread();
                return;
            }
            
            
            try {
				Logger.global.info("Connection accepted on port "+port);
				in = new DataInputStream(sock.getInputStream());
				for(;;) {
					standby();
					try {
						
						byte[] buf = new byte[BUFSIZE];
						int n = in.read(buf);
						if (n>0) {
							//Logger.global.info("Read "+n+" bytes on port "+this.port+". Copying...");
							out.write(buf,0,n);
							out.flush();
						}
					} catch (IOException ioe) {
                        Logger.global.severe("I/O Error on port "+this.port+" ("+ioe.getMessage()+")");
                        cleanupThread();
                        return;
                    }
				}	
			} catch (Exception ioe) {
                Logger.global.severe("Error on port "+this.port+" ("+ioe.getMessage()+")");
                cleanupThread();
                return;
            }
		}
	}
  
    private void cleanupThread() {
        this.swallow = false;
        try {
            this.sock.close();
        } catch (Exception e) {}
    }
}