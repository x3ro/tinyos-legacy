package com.shockfish.tinyos.gateway;

/**
 * @author Karl Baumgartner, HEIG-VD
 */

//import net.tinyos.message.Dump;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import javax.microedition.io.SocketConnection;
import javax.microedition.io.Connector;
import java.util.Date;

public class CldcDataSender extends ProtocolGateway {

	private String Address;

	private int port;
	
	private String optionalParameter;

	private SocketConnection sc;

	private DataInputStream is;
	private DataOutputStream os;


	public CldcDataSender( String Address, int port, String optionalParameter) {
		this.Address = Address;
		this.port = port;
		this.optionalParameter=optionalParameter;
	}
	
	public void connect() throws IOException {
		sc = (SocketConnection)Connector.open("socket://"+Address+":"+port+optionalParameter);
		sc.setSocketOption(SocketConnection.LINGER, 5);
		
		is = sc.openDataInputStream();
		os = sc.openDataOutputStream();
	}
	
	public void sendInit(String id_Basestation,Date date) throws IOException {
		os.writeUTF(id_Basestation);
		os.writeLong(date.getTime());
		os.flush();
	}
	
	public void sendRecord (byte [] data) throws IOException {
		os.writeByte(NEW_VALUE);
		os.write(data);
		os.flush();
	}
		
	public void sendEnd() throws IOException {
		os.writeByte(END_VALUE);
		os.flush();
	}
	
	public void close() throws IOException {
		is.close();
		os.close();
		sc.close();
	}
}