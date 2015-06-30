

/**
 * Title:
 * Description:
 * Copyright:    Copyright (c) 2001
 * Company:
 * @author
 * @version 1.0
 */

import java.io.*;
import java.net.*;

public class SerialForwarderReader
{
  private String            host          = null;
  private int               port          = 0;
  private Socket            commSocket    = null;
  private InputStream       packetStream  = null;
  private PacketListenerIF  listener      = null;
  public final static int   PACKET_SIZE   = 17;

  public SerialForwarderReader ( String host, int port )
  {
    this.host = host;
    this.port = port ;
  }

  public void registerPacketListener ( PacketListenerIF listener )
  {
    this.listener = listener;
  }

  public void Open ( ) throws IOException
  {
    // connect to server
    commSocket = new Socket(host, port);
    packetStream = commSocket.getInputStream();
  }

  public void Read ( ) throws IOException
  {
    byte[] packet = new byte[PACKET_SIZE];
    int nBytesRead = 0;
    int nBytesReturned = packetStream.read ( packet, nBytesRead,
                                               PACKET_SIZE - nBytesRead );

    while ( nBytesReturned != -1 )
    {
      nBytesRead += nBytesReturned;
      if ( nBytesRead == PACKET_SIZE )
      {
          nBytesRead = 0;
          listener.packetReceived ( packet );
      }
      nBytesReturned = packetStream.read ( packet, nBytesRead,
                                               PACKET_SIZE - nBytesRead );
    }
  }
}
