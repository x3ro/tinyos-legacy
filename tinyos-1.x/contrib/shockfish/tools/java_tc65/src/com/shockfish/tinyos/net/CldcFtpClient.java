package com.shockfish.tinyos.net;

import javax.microedition.io.*;

import com.shockfish.tinyos.tools.CldcLogger;

import java.io.*;

/**
 * 
 * @author Pierre Metrailler, Shockfish
 * @author Raphael KOENG, HEIG-VD
 */

public class CldcFtpClient {

	protected SocketConnection sc = null;

	protected DataInputStream is;

	protected DataOutputStream os;

	protected String sockOpts;
  
	protected final int numDebug = CldcLogger.SRC_3;
  
	public final static int FTP_COMMAND_MAX_LENGTH = 400;
	
  
  public CldcFtpClient() {
	  System.out.println("##### New instance of FTPclient created.");
    if (!CldcLogger.setSourceLabel(numDebug, "CldcFtpClient"))
    CldcLogger.devDebug(numDebug, "this source will also print debug for " +
        "CldcFtpClient");
  }

	public boolean ascii() throws IOException {
		sendLine("TYPE A");
		String response = readLine();

		return (response.startsWith("200 "));
	}

	public boolean bin() throws IOException {
		sendLine("TYPE I");
		String response = readLine();
		return (response.startsWith("200 "));
	}

	/**
	 * 
	 * @param host ftp IP or domaine name
	 * @param port port to connect to
	 * @param user ftp user name
	 * @param pass ftp password of the user
	 * @param sockOpts 
	 * @throws IOException
	 */

	public void connect(String host, int port, String user, String pass,
			String sockOpts) throws IOException {
    CldcLogger.devDebug(numDebug, "connect()\tBegin connection");
		this.sockOpts = sockOpts;
		if (sc != null) {
			return;
		}

		sc = (SocketConnection) Connector.open("socket://" + host + ":" + port
				+ sockOpts,Connector.READ_WRITE,true);
    CldcLogger.devDebug(numDebug, "connect()\tConnection open");

		// FIXME according to javax.microedition.io: Interface SocketConnection for
		// tc65: "The TC65 does not support the socket options KEEPALIVE and LINGER" 
		sc.setSocketOption(SocketConnection.LINGER, 5);

		is = sc.openDataInputStream();
		os = sc.openDataOutputStream();

		String response = readLine();
		if (!response.startsWith("220 ")) {
      CldcLogger.devDebug(numDebug, "connect()\tUnexpected response");
			return;
		}
		sendLine("USER " + user);
		response = readLine();
		if (!response.startsWith("331 ")) {
      CldcLogger.devDebug(numDebug, "connect()\tUnexpected response");
			return;
		}
		sendLine("PASS " + pass);
		response = readLine();

		if (response.startsWith("530 ")) {
			// we are automaticly disconnected!
			try {
				os.close();
				is.close();
				sc.close();
			} finally {
				os = null;
				is = null;
				sc = null;
			}
			throw (new IOException("Not logged in (ftp response : " + response + ")."));
		}

		if (!response.startsWith("230 ")) {
      CldcLogger.devDebug(numDebug, "connect()\tUnexpected response");
			return;
		}
    CldcLogger.devDebug(numDebug, "connect()\tConnected");
	}

	public boolean changeDir(String dir) throws IOException {
  	sendLine("CWD " + dir); // Change Working Directory
  	String response = readLine();
  	return (response.startsWith("250 "));
  }
  
  /* fileName can be dir/file.txt */
  public boolean delete (String fileName) throws IOException {
    sendLine("dele " + fileName);
    // String response = readLine();

    // TODO ok like that?
    if (!checkResponse(250)) {
      CldcLogger.devDebug(numDebug, "delete()\tdele failed.");
      //           " Server response = " + response);
      return false;
    }
    
    return true;
  }

  public void disconnect() throws IOException {
    CldcLogger.devDebug(numDebug, "disconnect()\tBegin disconnection");
		try {
			if (os != null) {
				sendLine("QUIT");
			}

			if (os != null)
				os.close();

			if (is != null)
				is.close();

			if (sc != null)
				sc.close();
				
		} finally {
			os = null;
			is = null;
			sc = null;
		}
    CldcLogger.devDebug(numDebug, "disconnect()\tDisconnected");
	}

	/**
   * 
   * @param filename
   * @return the file content, null if the file does not exist.
   * @throws IOException 
   */
  public String getData(String filename) throws IOException {
  	CldcLogger.devDebug(numDebug, "getData()\tBegin upload"
  			+ filename);
  	sendLine("PASV");
  	String response = readLine();
  	if (!response.startsWith("227 ")) {
  		return null;
  	}
  
  	String dataCon = parseDataCon(response);
  	sendLine("RETR " + filename);
  
  	// open
  	SocketConnection dataSc = null;
  	dataSc = (SocketConnection) Connector.open("socket://" + dataCon
  			+ sockOpts,Connector.READ_WRITE,true);
  	dataSc.setSocketOption(SocketConnection.LINGER, 5);
  	DataInputStream dataIn = dataSc.openDataInputStream();
  
  	response = readLine();
  	if (response.startsWith("550 ")) {
  		throw (new IOException("Cannot open ftp data connexion ("
  				+ response + ")"));
  	}
  	if (!response.startsWith("150 ")) {
  		return null;
  	}
  
  	// read
  	StringBuffer buf = new StringBuffer();
  	int c;
  	boolean readMore = true;
  	do {
  		c = dataIn.read();
  		switch (c) {
  		case -1:
  			readMore = false;
  			break;
  		default:
  			buf.append((char) c);
  		}
  	} while (readMore);
  
  	// close
  	dataIn.close();
  	dataSc.close();
  
  	response = readLine();
  	if (!response.startsWith("226 ")) {
  		return null;
  	}
  
  	CldcLogger.info("file " + filename + " downloaded.");
  
  	return buf.toString();
  }
  
  // juste to test multiline response
  public String getServerInfo() throws IOException {
    sendLine("HELP");
    return readResponse();
  }

  /* dir can be folder or folder/folder/... (end / optional) */
	public boolean makeDir(String dir) throws IOException {
		sendLine("MKD " + dir);
		String response = readLine();

		if (response.startsWith("550 "))
			throw new IOException("Dir already exist (FTP server response: "
					+ response + ")");

		return (response.startsWith("250 "));
	}
  
  /*
   * cant also be used to move a file.
   */
  public boolean renameFile(String actualName, String newName) throws IOException {
    // FIXME is it necessary to inroduice a LOCK? So the commande rnfr et rnto
    // will be execute one after the other (no concurrence).
    
    sendLine("rnfr " + actualName);
    String response = readLine();
    
    if (!response.startsWith("350 ")) {
      CldcLogger.devDebug(numDebug, "renameFile()\trnfr failed." +
          " Server response = " + response);
      return false;
    }
    
    sendLine("rnto " + newName);
    response = readLine();
    
    if (!response.startsWith("250 ")) {
      CldcLogger.devDebug(numDebug, "renameFile()\trnto failed." +
          " Server response = " + response);
      return false;
    }
    
    CldcLogger.info("file " + actualName + " renamed to " + newName + ".");
    
    return true;
  }

	public boolean putData(String data, String filename) throws IOException {

		sendLine("PASV");
		String response = readLine();
		if (!response.startsWith("227 ")) {
			return false;
		}

		CldcLogger.devDebug(numDebug,
				"putData()\t 1 first readLine passed \n(" + response + ")");
    
		String dataCon = parseDataCon(response);
		sendLine("STOR " + filename);

		SocketConnection dataSc = null;
		try {
			dataSc = (SocketConnection) Connector.open("socket://" + dataCon
					+ sockOpts,Connector.READ_WRITE,true);
      CldcLogger.devDebug(numDebug,
          "putData()\t 2 second readLine passed \n(" + response + ")");
		} catch (IOException e) {
			dataSc = null;
			throw ((IOException) e);
		}
		CldcLogger.devDebug(numDebug, " 3 putData()\t data stream opened");
		dataSc.setSocketOption(SocketConnection.LINGER, 5);
		
    CldcLogger.devDebug(numDebug, " 4 putData()\t socket option set");
    
		response = readLine();
    
    CldcLogger.devDebug(numDebug,
        "putData()\t 5 second readline \n(" + response + ")");
    
		if (!response.startsWith("150 ")) {
			return false;
		}

    DataOutputStream output = dataSc.openDataOutputStream();
	InputStream input = new ByteArrayInputStream(data.getBytes());
    CldcLogger.devDebug(numDebug, "putData()\t streams opened");

		byte[] buffer = new byte[4096];
		int bytesRead = 0;
		while ((bytesRead = input.read(buffer)) != -1) {
			output.write(buffer, 0, bytesRead);
		}
    CldcLogger.devDebug(numDebug, "putData()\t data sended");

		output.flush();
		output.close();
		input.close();

		// rkg
		dataSc.close();
    CldcLogger.devDebug(numDebug, "putData()\t streams closed...");

		response = readLine();

		CldcLogger.info("file " + filename + " uploaded. (" + response + ")");
		return response.startsWith("226 ");
	}

	// parse the response of a PASV command
	protected String parseDataCon(String rawCon) {
		// exemple of a rawCon "227 Entering Passive Mode (15,16,17,18,140,240)."
		// 4 first num for IP, 2 last for port.
		int portNum = 0;
		String ip = "";
		int par1idx = rawCon.indexOf('(');
		int par2idx = rawCon.indexOf(')', par1idx + 1);

		if (par2idx > 0) {
			String dc = rawCon.substring(par1idx + 1, par2idx);
			// begin of Least Significant Byte of the port
			int p2idx = dc.lastIndexOf(',');
			// begin of Most Significant Byte of the port
			int p1idx = dc.lastIndexOf(',', (p2idx - 1)); //
			try {
				portNum = ((Integer.parseInt(dc.substring(p1idx + 1, p2idx))) * 256)
						+ (Integer.parseInt(dc.substring(p2idx + 1)));
			} catch (NumberFormatException nfe) {
        CldcLogger.warning("Number format doomed");
			}
			ip = (dc.substring(0, p1idx)).replace(',', '.');
		}
		return ip + ":" + portNum;
	}

  protected boolean checkResponse (int expectedResponseCode) throws IOException {
    String response = readResponse();
    return response.startsWith(Integer.toString(expectedResponseCode));
  }
  
  /**
   * Read response of the ftp server (on the command channel)
   * 
   * @return the response (1 or more lines)
   * @throws IOException when connection problem occure or when response is not
   * valid (acording to the rfc 959)
   */
  protected String readResponse() throws IOException {
    /* response always start with a 3 digits code
     * Can be 1 line, but also multiline.
     * first line of a multiline response begins with the 3 digits response
     * code follow by '-'.
     * Last line (in both case, 1 line or multiline) begins with the 3 digits
     * response code follow by a white space.
     * Attention: first line code and last line code are equal and between may
     * also start with a number!
     */
    /* multiline response ("valid") exemple:
     * 214-The following commands are recognized:
     *    USER   PASS   QUIT   CWD    PWD    PORT   PASV   TYPE
     *    ...
     *    120 commands are accepted
     * 214 Have a nice day.
     */
    String responseLine = readLine();
    
    // check that the 3 firts digit are number
    if (!isAValidCode(responseLine.substring(0, 3)))
      throw (new IOException("FTP response format is not valid"));
    
    
    if (responseLine.charAt(3) == ' ') {
      // one line response
      return responseLine;
      
    } else if (responseLine.charAt(3) == '-') {
      // multine response
      String beginLastLine = responseLine.substring(0, 3) + " ";
      String allResponse = responseLine;
      responseLine = readLine();
      while (!responseLine.startsWith(beginLastLine)) {
        allResponse += responseLine;
        responseLine = readLine();
      }
      allResponse += responseLine;
      return allResponse;
      
    } else {
      // does not respect rfc 959
      throw (new IOException("FTP response format is not valid"));
    }
  }
  
  // TODO for the moment, only check if code is a number, but not all the numbers
  // between 0 and 999 are acceptable which should be also check!
  private boolean isAValidCode (String code) {
    if (code.length() != 3)
      return false;
    
    try {
      Integer.parseInt(code);
    }  catch (NumberFormatException e) {
      return false;
    }
      return true;
  }
  
	protected String readLine() throws IOException {
		int b;
		int bytesRead = 0;
		String buf = "";
		while (true) {
			b = is.read();
			bytesRead++;
			
			// Experimental results have shown that closing the connection on
			// the server side does not throw any exception on the client side.
			// Even worse, the read() method always returns 0 (a valid value) and
			// the thread enters an infinite loop. As a workaround we set an upper
			// bound on the number of char we expected from a readline() and throw
			// an exception if that figure is exceeded.
			 
			if (bytesRead > FTP_COMMAND_MAX_LENGTH) {
				throw (new IOException("FTP_COMMAND_MAX_LENGTH exceeded, probably due to broken pipe."));
			}
			
			if (b == -1) {
				// Mainly due to a reset connection from the server / server has
				// closed connection
				CldcLogger.devDebug(numDebug, "Readline read returned  -1");
				throw (new IOException(
						"Cannot read in the input stream (return " + b + ")"));
			}
			if (((char) b) == '\n') {
				return buf;
			}
			buf = buf + ((char) b);
		}
	}

	protected void sendLine(String line) throws IOException {
		if (sc == null) {
			System.out.println("no socket found");
			return;
		}
		try {
			line = line + "\r\n";
			os.write(line.getBytes());
			os.flush();
		} catch (IOException e) {
			CldcLogger.devDebug(numDebug, "Error in sendline, exception follows.)");
			// if (e.getMessage().startsWith("Socket was closed"))
				// procedureAlert();
			sc = null;
			throw e;
		}
	}
  

}
