
import net.tinyos.util.*;
//package net.tinyos.util;

import java.io.*;
import java.net.*;
import java.util.*;

public class SerialStubThread extends Thread
{
  SerialStub m_ss = null;
  private static final boolean DEBUG = false;

  public SerialStubThread( SerialStub ss )
  {
    m_ss = ss;
  }

  /**
  * Body of this thread. Repeatedly reads and dispatches messages from
  * the SerialForwarder 
  */
  public void run()
  {
    try { if(DEBUG) System.out.println("SerialStubThread: read"); m_ss.Read(); }
    catch (IOException e) { e.printStackTrace(); }           
  }
}

