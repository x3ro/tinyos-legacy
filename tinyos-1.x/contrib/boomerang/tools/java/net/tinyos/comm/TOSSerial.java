//$Id: TOSSerial.java,v 1.1.1.1 2007/11/05 19:11:22 jpolastre Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

package net.tinyos.comm;

import java.io.*;
import java.util.*;
import java.util.regex.*;

public class TOSSerial extends NativeSerial implements SerialPort {

  SerialInputStream m_in;
  SerialOutputStream m_out;
  ReadThread m_read;
  ByteQueue bq_input = new ByteQueue(128);


  class ReadThread extends Thread {
    Object input_ready = new Object();
    boolean m_run;

    public ReadThread() {
      super();
    }

    public ReadThread( String name ) {
      super(name);
    }

    public void start() {
      m_run = true;
      super.start();
    }

    public void flush() {
      byte buffer[] = new byte[1024];
      for( int i=0; i<16; i++ )
        TOSSerial.this.read( buffer, 0, buffer.length, 0 );
    }

    public void run() {
      byte buffer[] = new byte[1024];
      int nread = 1;
      int timeout = 200;
      while( m_run ) {
        int n = TOSSerial.this.read( buffer, 0, nread, timeout );
        if( n > 0 ) {
          synchronized( input_ready ) {
            bq_input.push_back( buffer, 0, n );
            input_ready.notify();
          }
          nread = buffer.length;
          timeout = 0;
        }
        else {
          nread = 1;
          timeout = 200;
        }
      }
    }

    public void wait_for_data() throws InterruptedException {
      while( true ) {
        synchronized( input_ready ) {
          if( available() > 0 )
            break;
          input_ready.wait(200);
        }
      }
    }

    public void close() {
      m_run = false;
    }
  }


  class SerialInputStream extends InputStream {

    public int read() {
      int n = 0;
      try {
        m_read.wait_for_data();
        n = bq_input.pop_front();
      }
      catch( InterruptedException e ) {
      }
      return n;
    }

    public int read( byte[] b ) {
      return read( b, 0, b.length );
    }

    public int read( byte[] b, int off, int len ) {
      int n = 0;
      try {
        m_read.wait_for_data();
        n = bq_input.pop_front(b,off,len);
      }
      catch( InterruptedException e ) {
      }
      return n;
    }

    public int available() {
      return TOSSerial.this.available();
    }
  }


  class SerialOutputStream extends OutputStream {

    byte write_byte[] = new byte[1];

    void writeall( byte[] b, int off, int len ) {
      // assumed to already my synchronized on sync_output
      int nwritten = 0;
      while( nwritten < len ) {
        int n = TOSSerial.this.write( b, off+nwritten, len-nwritten, 200 );
        if( n >= 0 ) {
          nwritten += n;
        }
        else {
          // throw an error, stream closed, does this ever happen?
          return;
        }
      }
    }

    synchronized public void write( int b ) {
      write_byte[0] = (byte)b;
      writeall( write_byte, 0, 1 );
    }

    synchronized public void write( byte[] b ) {
      writeall( b, 0, b.length );
    }

    synchronized public void write( byte[] b, int off, int len ) {
      writeall( b, off, len );
    }
  }


  int available() {
    return bq_input.available();
  }


  public TOSSerial( String portname ) {
    super( portname );
    m_in = new SerialInputStream();
    m_out = new SerialOutputStream();
    m_read = new ReadThread("TOSSerial.ReadThread");
    m_read.flush();
    m_read.start();
  }


  public InputStream getInputStream() {
    return m_in;
  }


  public OutputStream getOutputStream() {
    return m_out;
  }


  public void close() {
    try {
      if( m_read != null ) {
        m_read.close();
        m_read.join();
      }
    }
    catch( InterruptedException e ) {
    }

    try {
      if( m_in != null )
	m_in.close();

      if( m_out != null )
	m_out.close();
    }
    catch( IOException e ) {
    }

    super.close();

    m_in = null;
    m_out = null;
    m_read = null;
    bq_input = null;
  }


  protected void finalize() {
    // Be careful what you call here. The object may never have been
    // created, so the underlying C++ object may not exist, and there's
    // insufficient guarding to avoid a core dump. If you call other
    // methods than super.close() or super.finalize(), be sure to
    // add an if (swigCptr != 0) guard in NativeSerial.java.
    System.out.println("Java TOSSerial finalize");
    close();
    super.finalize();
  }
}

