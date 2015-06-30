

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
  private InputStream       packetIStream  = null;
  private OutputStream       packetOStream  = null;
  private PacketListenerIF  listener      = null;
  public final static int   PACKET_SIZE   = 36;

  public SerialForwarderReader ( String host, int port )
  {
    this.host = host;
    this.port = port ;
  }

  public void registerPacketListener ( PacketListenerIF listener )
  {
    this.listener = listener;
  }

  public void Close ( ) throws IOException
  {
	packetOStream.flush();
	commSocket.close();


  }

  public void Open ( ) throws IOException
  {
    // connect to server
    commSocket = new Socket(host, port);
    packetIStream = commSocket.getInputStream();
    packetOStream = commSocket.getOutputStream();
  }

  public void Read ( ) throws IOException
  {
    byte[] packet = new byte[PACKET_SIZE];
    int nBytesRead = 0;
    int nBytesReturned = packetIStream.read ( packet, nBytesRead,
                                               PACKET_SIZE - nBytesRead );

    while ( nBytesReturned != -1 )
    {
      nBytesRead += nBytesReturned;
      if ( nBytesRead == PACKET_SIZE )
      {
          nBytesRead = 0;
	  if(listener != null){
          	listener.packetReceived ( packet );
	  }
      }
      nBytesReturned = packetIStream.read ( packet, nBytesRead,
                                               PACKET_SIZE - nBytesRead );
    }
  }

    private short calculateCRC(byte packet[]) {
	short crc;
	int i;
	int index = 0;
	int count = packet.length - 2;
	crc = 0;
	while (--count >= 0) {
	    crc = (short) (crc ^ ((short) (packet[index++]) << 8));
	    i = 8;
	    do {
		if ((crc & 0x8000) != 0)
		    crc = (short)(crc << 1 ^ ((short)0x1021));
		else
		    crc = (short)(crc << 1);
	    } while(--i>0);
	}
	return (crc);
    }

  
  public void Write(byte[] pack) throws IOException {
	short crc = calculateCRC(pack);
	pack[pack.length-1] = (byte) ((crc >> 8) & 0xff);
	pack[pack.length-2] = (byte) (crc & 0xff);
	packetOStream.write(pack);	
  }

}
