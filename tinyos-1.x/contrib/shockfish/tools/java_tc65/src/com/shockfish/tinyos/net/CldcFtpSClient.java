package com.shockfish.tinyos.net;

import javax.microedition.io.*;

import com.shockfish.tinyos.tools.CldcLogger;

import java.io.*;

/**
 * 
 * @author Pierre Metrailler, Shockfish
 */

public class CldcFtpSClient extends CldcFtpClient {

  public void connect(String host, int port, String user, String pass,
      String sockOpts) throws IOException {
    this.sockOpts = sockOpts;
    if (sc != null) {
      System.out.println("[cldc]\tsc != null OK");
      return;
    }
    String connectStr = "ssl://" + host + ":" + port + sockOpts;
    CldcLogger.devDebug(numDebug, "[cldc]\tConnect str =" + connectStr); // 1
    sc = (SecureConnection) Connector.open(connectStr,Connector.READ_WRITE,true);

    CldcLogger.devDebug(numDebug, "[cldc]\tConnector.open OK"); // 2
    SecurityInfo info = ((SecureConnection) sc).getSecurityInfo();
    CldcLogger.devDebug(numDebug, "[cldc]\tSecureConnection:" + info.getProtocolName());

    sc.setSocketOption(SocketConnection.LINGER, 5);

    is = sc.openDataInputStream();
    os = sc.openDataOutputStream();

    String response = readLine();
    // FIXME : banner can actually be spread over several 200-lines
    if (!response.startsWith("220 ")) {
      CldcLogger.devDebug(numDebug, "Unexpected response");
      return;
    }
    sendLine("USER " + user);
    response = readLine();
    if (!response.startsWith("331 ")) {
      CldcLogger.devDebug(numDebug, "Unexpected response");
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
      throw (new IOException("Not logged in (" + response + ")."));
    } // FIXME Est-ce qu'on lance une déconnexion?

    CldcLogger.devDebug(numDebug, "[cldc]\tUser and password accepted.");
    if (!response.startsWith("230 ")) {
      CldcLogger.devDebug(numDebug, "Unexpected response");
      return;
    }

    // TODO CLNT, OPTS

    // TODO have a method for 200-check
    sendLine("PBSZ 0");
    response = readLine();
    if (!response.startsWith("200 ")) {
      CldcLogger.devDebug(numDebug, "Unexpected response");
      return;
    }

    CldcLogger.devDebug(numDebug, "[cldc]\tafter PBSZ 0");
    sendLine("PROT P");
    response = readLine();
    if (!response.startsWith("200 ")) {
      CldcLogger.devDebug(numDebug, "Unexpected response");
      return;
    }
    

    CldcLogger.devDebug(numDebug, "[cldc]\tFIN Connect()");
  }

  public boolean putData(String data, String filename) throws IOException {
    /*if (!isAlive()) {
     throw new IOException("connection died"); 
    }*/
    
    sendLine("PASV");
    String response = readLine();
    if (!response.startsWith("227 ")) {
      return false;
    }

    CldcLogger.devDebug(numDebug,
        "putData()\t 1 first readLine passed \n(" + response + ")");
    
    // bug 1-3 (sf 29.05 nuit)

    String dataCon = parseDataCon(response);
    sendLine("STOR " + filename);
    CldcLogger.devDebug(numDebug, "putData()\t 1.5 sent STOR command");

    SocketConnection dataSc = null;
    try {
      dataSc = (SecureConnection) Connector.open("ssl://" + dataCon
          + sockOpts,Connector.READ_WRITE,true);
      CldcLogger.devDebug(numDebug, "putData()\t 2 data connection opened");
    } catch (IOException e) {
      CldcLogger.devDebug(numDebug, "putData()\t 2 data connection failed");
      try {
        dataSc.close();
      } catch (Exception e2) {
        // most of the time a IOException but can also be a NullPointerException
        CldcLogger.devDebug(numDebug, "putData()\t dataSC.close failed," +
            " but dont worry. " + e2);
      }
      dataSc = null;
      
      throw ((IOException) e);
    } catch (Exception e) {
      CldcLogger.severe("Not an IOException throw!");
      e.printStackTrace();
    }
    
    dataSc.setSocketOption(SocketConnection.LINGER, 5);
    CldcLogger.devDebug(numDebug, "putData()\t 4 socket option set");
    
    response = readLine();
    CldcLogger.devDebug(numDebug,
        "putData()\t 5 second readline \n(" + response + ")");
    
    if (!response.startsWith("150 ")) {
      return false;
    }

    DataOutputStream output = dataSc.openDataOutputStream();
    InputStream input = new ByteArrayInputStream(data.getBytes());
    CldcLogger.devDebug(numDebug, "putData()\t 5 streams opened");

    byte[] buffer = new byte[4096];
    int bytesRead = 0;
    while ((bytesRead = input.read(buffer)) != -1) {
      output.write(buffer, 0, bytesRead);
    }
    CldcLogger.devDebug(numDebug, "putData()\t 6 data sended");

    output.flush();
    output.close();
    input.close();

    dataSc.close();
    CldcLogger.devDebug(numDebug, "putData()\t 7 streams closed...");

    response = readLine();

    CldcLogger.info("file " + filename + " uploaded. (" + response + ")");
    return response.startsWith("226 ");
  }

}
