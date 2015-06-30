package com.shockfish.tinyos.tools;

import com.siemens.icm.io.ATCommand;
import com.siemens.icm.io.ATCommandFailedException;
import com.siemens.icm.io.ATStringConverter;

import com.siemens.icm.io.*;
import java.io.*;

import com.siemens.icm.io.file.*;
import java.util.Enumeration;
import javax.microedition.io.*;
import java.util.Date;
import java.util.Calendar;
import java.util.Hashtable;

public abstract class Tc65Manager implements ATCommandListener {

	// AT-related
	private final static String URC_INCOMING_SMS = "+CMTI: \"MT\",";

	private final static char AT_CTRL_Z = (char) 26;

	private final static String SMS_TEXT_READY = ">";

	// TC65-related

	private final static String FILE_CONN_FLASH_FS = "file:///a:/";

	// OTAP-related
	private final static String OTAP_KEYWORD = "OTAP_TINYNODE";

	private final static String OTAP_PWD = "PWD";

	private final static String OTAP_COMMAND = "COMMAND";

	private final static String OTAP_ARGS = "ARGS";

	private final static String OTAP_NL = "\n";

	// Config-related
	private final static String FACTORY_GPRS_OPTS =
        ";bearer_type=gprs;access_point=internet;" 
        + "dns=213.055.128.001;timeout=40";

	// informe if the timer of the module has been synchronized correctly
	private boolean synced_Time = false;

	private static Calendar calendar;

	// difference between the actual system time and the calendar received
	private static long offsetCalendar;

	// time at which the app has been started up, used to maintain the uptime.
	private static long startTime = 0;

	private Hashtable propertiesTable;

	protected ATCommand ata;

	public Tc65Manager() {
		startTime = System.currentTimeMillis();

		try {
			ata = new ATCommand(false);
		} catch (ATCommandFailedException e) {
			System.out.println("Could not create the At parser");
		}
		calendar = Calendar.getInstance();
		propertiesTable = new Hashtable();
		init();
		ata.addListener(this);
	}

	public static Date getDate() {
		return new Date(System.currentTimeMillis() + offsetCalendar);
	}

	public static long getUptime() {
		return System.currentTimeMillis() - startTime;
	}

	public static long getTime() {
		return System.currentTimeMillis() + offsetCalendar;
	}

	private static long lastDateUpdate;

	private static long derivationAveragePerHour = 0;

	private final static long ONE_HOUR_IN_MILLI_SEC = 1000 * 60 * 60;

	public void setOffsetCalendar(long off) {
		this.offsetCalendar = off;
	}

	public boolean pinCode(int password) {
		return sendAT("at+cpin=" + password, "OK");
	}

	public boolean setQoSforGRPS(int cid, int precedence, int delay,
			int reliability, int peak, int mean) {
		return sendAT("AT+CGQREQ=" + cid + "," + precedence + "," + delay + ","
				+ reliability + "," + peak + "," + mean, "OK");
	}

	public void setSyncedTime() {
		synced_Time = true;
	}

	public void resetSyncedTime() {
		synced_Time = false;
	}

	public boolean IsSyncedTime() {
		return synced_Time;
	}

	public static String getFlashPath() {
		return FILE_CONN_FLASH_FS;
	}

	public String getGprsConf() {
		String conf = readProp("GPRSCONF");
		if (conf == null) {
			conf = FACTORY_GPRS_OPTS;
		}
		return conf;
	}

	/**
	 * @param prop
	 * @return property value, null if the property is not set.
	 */
	public String readProp(String prop) {
		// check if value is already in the table
		if (propertiesTable.containsKey(prop)) {
			return (String) propertiesTable.get(prop);

		} else { // read property from flash
			String val = null;
			try {
				FileConnection fconn = (FileConnection) Connector.open(
						FILE_CONN_FLASH_FS + prop, Connector.READ);
				if (fconn.exists()) {
					InputStream is = fconn.openInputStream();
					val = "";
					int b;
					while (true) {
						b = is.read();
						if (b == -1)
							break;
						val = val + ((char) b);
					}
					is.close();
				}
				fconn.close();
			} catch (IOException ioe) {
				ioe.printStackTrace();
			}
			// add the new prop in the properties table
			if (val != null) {
				propertiesTable.put(prop, val);
				CldcLogger.info("property (" + prop + "|" + val
						+ ") loaded.");
			} else {
				CldcLogger.warning("property \"" + prop + "\" is not set.");
			}
			return val;
		}
	}

	public String setProp(String prop, String val) {
		// write to flash
		try {
			FileConnection fconn = (FileConnection) Connector.open(
					FILE_CONN_FLASH_FS + prop, Connector.READ_WRITE);
			if (fconn.exists()) {
				fconn.delete();
			}
			fconn.create();
			OutputStream output = fconn.openOutputStream();
			InputStream input = new ByteArrayInputStream(val.getBytes());
			byte[] buffer = new byte[4096];
			int bytesRead = 0;
			while ((bytesRead = input.read(buffer)) != -1) {
				output.write(buffer, 0, bytesRead);
			}
			output.flush();
			output.close();
			fconn.close();
		} catch (IOException ioe) {
			ioe.printStackTrace();
		}

		if (propertiesTable.containsKey(prop)) {
			CldcLogger.info("Replace property (" + prop + "|" + val + ")");
		} else {
			CldcLogger.info("Set new property (" + prop + "|" + val + ")");
		}
		propertiesTable.put(prop, val);
		return val;
	}

	private void init() {
		// for the pin code
		String pin = readProp("PIN_PASSWORD");
		if (pin != null) {
			pinCode(Integer.valueOf(pin).intValue());
		}
		// received SMS should go to MT memory, set preferred storage
		sendAT("AT+CPMS=\"MT\"", "OK");

		int i = 1;
		while (sendAT("AT+CMGD=" + i, "OK")) {
			i++;
		}

		// init for SMS URC
		// AT+CNMI=[<mode>][, <mt>][, <bm>][, <ds>][, <bfr>]
		sendAT("AT+CNMI=3,1,0,2,1", "OK");
		// init for text mode sms
		sendAT("AT+CMGF=1", "OK");
		// TODO enable OTAP
	}

	// this is the default, ugly wrapper.
	protected boolean sendAT(String command, String expect) {
		try {
			System.out.println(command);
			String response = ata.send(command + "\r");
			System.out.println(response);
			if (response.indexOf(expect) >= 0) {
				return true;
			}
		} catch (ATCommandFailedException e) {
			return false;
		}
		return false;
	}

	public boolean pubSendAT(String command, String expect) {
		return sendAT(command, expect);
	}

	protected String getAT(String command, String expect) {
		try {
			System.out.println(command);
			String response = ata.send(command + "\r");
			System.out.println(response);
			if (response.indexOf(expect) >= 0) {
				return response;
			}
		} catch (ATCommandFailedException e) {
			return null;
		}
		return null;
	}

	public void sendSms(String num, String msg) {
		sendAT("AT+CMGF=1", "OK");
		sendAT("AT+CMGS=" + num, SMS_TEXT_READY);
		sendAT(msg + AT_CTRL_Z, "OK");
	}

	public String getTc65Status() {
		return "\nSerial=" + getDeviceSerial() 
                + "\nFreemem=" + (Runtime.getRuntime()).freeMemory()
				+ "\nFreeflash=" + getFreeFlashSpace();
	}

	public void listFs() {
		try {
			Enumeration e = FileSystemRegistry.listRoots();
			while (e.hasMoreElements()) {
				String root = (String) e.nextElement();
				System.out.println("Fs:" + root);
				FileConnection fc = (FileConnection) Connector.open("file:///"
						+ root);
				System.out.println(fc.availableSize());
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	// serial is imei-imsi
	public String getDeviceSerial() {
		return getAT("AT+CGSN", "OK") + "-" + getAT("AT+CIMI", "OK");
	}

	public long getFreeFlashSpace() {
		long fs = -1;
		try {
			FileConnection fconn = (FileConnection) Connector.open(
					FILE_CONN_FLASH_FS, Connector.READ);
			fs = fconn.availableSize();
			fconn.close();
		} catch (IOException ioe) {
			ioe.printStackTrace();
		}
		return fs;
	}

	// listener interface

	/*
	 * when some AT event occurs, like a sms reception, a call reception.
	 */
	public void ATEvent(String event) {
		CldcLogger.devDebug(CldcLogger.SRC_1, "ATEvent()\tevent = \n" + event
				+ "(end)");
		int idx;
		idx = event.indexOf(URC_INCOMING_SMS);
		if (idx >= 0) {
			handleSms(event, idx);
		}
	}

	public void DCDChanged(boolean SignalState) {
	}

	public void DSRChanged(boolean SignalState) {
	}

	public void RINGChanged(boolean SignalState) {
	}

	public void CONNChanged(boolean SignalState) {
	}

	public void resetModule() {
		sendAT("at+cfun=1,1", "OK");
	}

	boolean once = false;

	private void handleSms(String event, int idx) {
		//sendAT("AT+CMGF=1", "OK");
		CldcLogger.devDebug(CldcLogger.SRC_1, "handleSms()\tevent = " + event
				+ " idx = " + idx);
		// fetch the sms index
		String smsId = "";
		int k = idx + URC_INCOMING_SMS.length();
		int j = 0;
		while (true) {
			if ((k + j + 1) > event.length())
				break;
			String c = event.substring(k + j, k + j + 1);
			try {
				Integer.parseInt(c);
				smsId = smsId + c;
			} catch (NumberFormatException nfe) {
				break;
			}
			j++;
		}

		String msg = ATStringConverter
				.GSM2Java(getAT("at+cmgr=" + smsId, "OK"));

		sendAT("AT+CMGD=" + smsId, "OK");

		CldcLogger.devDebug(CldcLogger.SRC_1, "handleSms()\tmsg = " + msg
				+ " and already erased");
		// TODO : delete message
		int otidx = msg.indexOf(OTAP_KEYWORD);

		if (otidx < 0) {
			System.out.println("Not a tinynode OTAP message, discarding");
			return;
		}

		msg = msg.substring(otidx);

		// check the secret
		String pass = getOtapPropValue(OTAP_PWD, msg);
		CldcLogger.devDebug(CldcLogger.SRC_1, "handleSms()\tsms pwd = <" + pass
				+ ">");
		if (!pass.equals(getSecret())) {
			System.out.println("Incorrect PWD");
			return;
		}

		System.out.println("CMD:" + getOtapPropValue(OTAP_COMMAND, msg));
		System.out.println("ARGS:" + getOtapPropValue(OTAP_ARGS, msg));

		boolean handled = customCommandHandler(getOtapPropValue(OTAP_COMMAND,
				msg), getOtapPropValue(OTAP_ARGS, msg));

		if (!handled) {
			defaultCommandHandler(getOtapPropValue(OTAP_COMMAND, msg),
					getOtapPropValue(OTAP_ARGS, msg));
		}

	}

    protected abstract boolean customCommandHandler(String command, String args);

    protected abstract void defaultCommandHandler(String command, String args);

    protected abstract String getSecret();

	private String getOtapPropValue(String propName, String msg) {
		String token = propName + ":";
		int idxa = msg.indexOf(token); //begin of the prop value
		if (idxa < 0)
			return null;

		int idxb = msg.indexOf(OTAP_NL, idxa); // end of the prop value

		int idxb_bis = msg.indexOf(" ", idxa); // end of the prop value
		if (idxb_bis > 0 && idxb_bis < idxb)
			idxb = idxb_bis;

		if (idxb < 0)
			return null;

		CldcLogger.devDebug(CldcLogger.SRC_1, "getOtapPropValue()\tprop = "
				+ propName + " value = "
				+ msg.substring(idxa + token.length(), idxb));
		return msg.substring(idxa + token.length(), idxb);
	}

}