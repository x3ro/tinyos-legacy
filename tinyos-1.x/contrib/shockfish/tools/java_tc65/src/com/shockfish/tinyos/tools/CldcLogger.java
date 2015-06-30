package com.shockfish.tinyos.tools;

import java.util.Calendar;
import com.shockfish.tinyos.tools.Tc65Manager;
/**
 * This logger enable the control of the message to display. Mainly, you can
 * define current display level. If the message level is equal or higher
 * (depends on the display methode you have chosed) to the current display
 * level, it will be display (otherwise not).
 * 
 * In parallel, you can, for the debug level, select which source you want to
 * display. This allow you for exemple to stop display debug from SRC_1 which do
 * its job fine, and concentrate on debug from source SRC_2.
 * 
 * Display levels: - severe (higest level) - warning - info - debug (lowest
 * level)
 * 
 * 16 sources are defined for debug level, first is SRC_1, last is SRC_16.
 * 
 * Default setting are: - current display level : info - source for debug level :
 * all
 * 
 * @author Karl Baumgartner, HEIG-VD
 * @author Raphael Koeng, HEIG-VD
 */

public class CldcLogger {
	/** debug level */
	public final static int DEBUG_LEVEL = 4;

	/** info level */
	public final static int INFO_LEVEL = 5;

	/** severe level */
	public final static int SEVERE_LEVEL = 7;

	/** warning level */
	public final static int WARNING_LEVEL = 6;

	/** source 1 for the debug level */
	public final static int SRC_1 = 1;

	public final static int SRC_2 = SRC_1 * 2;

	public final static int SRC_3 = SRC_2 * 2;

	public final static int SRC_4 = SRC_3 * 2;

	public final static int SRC_5 = SRC_4 * 2;

	public final static int SRC_6 = SRC_5 * 2;

	public final static int SRC_7 = SRC_6 * 2;

	public final static int SRC_8 = SRC_7 * 2;

	public final static int SRC_9 = SRC_8 * 2;

	public final static int SRC_10 = SRC_9 * 2;

	public final static int SRC_11 = SRC_10 * 2;

	public final static int SRC_12 = SRC_11 * 2;

	public final static int SRC_13 = SRC_12 * 2;

	public final static int SRC_14 = SRC_13 * 2;

	public final static int SRC_15 = SRC_14 * 2;

	public final static int SRC_16 = SRC_15 * 2;

	/** Selection of all the defined sources */
	public final static int ALL_SOURCES = SRC_1 | SRC_2 | SRC_3 | SRC_4 | SRC_5
			| SRC_6 | SRC_7 | SRC_8 | SRC_9 | SRC_10 | SRC_11 | SRC_12 | SRC_13
			| SRC_14 | SRC_15 | SRC_16;

	private final static String SEVERE_STRING = "SEVERE";

	private final static String WARNING_STRING = "WARNING";

	private final static String INFO_STRING = "INFO";

	private final static String DEBUG_STRING = "DEBUG";

	private final static String SEPARATOR = ": ";

	private final static int NB_SOURCE = 16;

	private final static String[] SRC_LABELS = new String[NB_SOURCE];

	/* Attributes to select what can be display */
	private static int activeSource;

	private static int levelOfDisplay;

	static {
		activeSource = ALL_SOURCES;
		levelOfDisplay = INFO_LEVEL;
	}

	/**
	 * Add for debug level, a source of debug.
	 * 
	 * @param src
	 *            source to add
	 * @return true if the source was added, else false (source not defined or
	 *         already added)
	 */
	public static boolean addSource(int src) {
		if (((ALL_SOURCES & src) == 0) || ((activeSource & src) != 0)) {
			return false;
		} else {
			activeSource |= src;
			return true;
		}
	}

	/**
	 * Display message if the display level is INFO_DEBUG or lower and if the
	 * source is active (set to be display).
	 * 
	 * @param src
	 *            source of the debug
	 * @param msg
	 *            debug message
	 */
	public static void devDebug(int src, String msg) {
		if ((levelOfDisplay <= DEBUG_LEVEL) && ((activeSource & src) != 0)) {
			String label = null;

			if ((src & ALL_SOURCES) != 0) {
				label = SRC_LABELS[indexLabel(src)];
			} else {
				label = "From undefined source";
			}

			if (label == null) {
				label = "No label set for source " + src;
			}

			logStdOut(DEBUG_STRING + " [ " + label + " ] " + SEPARATOR + msg);
		}
	}

	/**
	 * Display message if the display level is INFO_LEVEL or lower.
	 * 
	 * @param msg
	 *            to display
	 */
	public static void info(String msg) {
		if (levelOfDisplay <= INFO_LEVEL) {
			logStdOut(INFO_STRING + SEPARATOR + msg);
		}
	}

	/**
	 * Remove for debug level, a source of debug.
	 * 
	 * @param src
	 *            source to remove
	 * @return true if the source was added, else false (source not defined or
	 *         already removed)
	 */
	public static boolean removeSource(int src) {
		if (((ALL_SOURCES & src) == 0) || ((activeSource & src) == 0)) {
			return false;
		} else {
			activeSource = ~src & activeSource;
			return true;
		}
	}

	/**
	 * Set the level to display message. Message with level higher or equal to
	 * level will be displayed.
	 * 
	 * @param level
	 *            level
	 */
	public static void setLevelOfDisplay(int level) {
		if (level > 0) {
			levelOfDisplay = level;
		}
	}

	/**
	 * Set a label for a source. This label will be display before each message
	 * from the source.
	 * 
	 * @param src
	 *            source
	 * @param label
	 *            label for the source
	 * @return true if the label could be set, otherwise false (source not
	 *         defined or label already defined)
	 */
	public static boolean setSourceLabel(int src, String label) {
		if ((src & ALL_SOURCES) != 0 && SRC_LABELS[indexLabel(src)] == null) {
			SRC_LABELS[indexLabel(src)] = label;
			return true;
		} else {
			return false;
		}
	}

	/**
	 * Display message if the display level is INFO_SEVERE or lower.
	 * 
	 * @param msg
	 *            to display
	 */
	public static void severe(String msg) {
		if (levelOfDisplay <= SEVERE_LEVEL) {
			logStdOut(SEVERE_STRING + SEPARATOR + msg);
		}
	}

	/**
	 * Display message if the display level is INFO_WARNING or lower.
	 * 
	 * @param msg
	 *            to display
	 */
	public static void warning(String msg) {
		if (levelOfDisplay <= WARNING_LEVEL) {
			logStdOut(WARNING_STRING + SEPARATOR + msg);
		}
	}

	private static void logStdOut(String msg) {
		Calendar now = Calendar.getInstance();
		now.setTime(Tc65Manager.getDate());
		System.out.println(oneDayToString(now)+ " " + msg);
	}

	/* return the index for tables of label for a src */
	private static int indexLabel(int src) {
		int num = 0;
		while ((src /= 2) != 0)
			num++;
		return num;
	}

	static String oneDayToString(Calendar oneDay) {
		return oneDay.get(Calendar.YEAR)
				+ minTwoDigitString(oneDay.get(Calendar.MONTH) + 1)
				+ minTwoDigitString(oneDay.get(Calendar.DAY_OF_MONTH))
				+ minTwoDigitString(oneDay.get(Calendar.HOUR_OF_DAY))
				+ minTwoDigitString(oneDay.get(Calendar.MINUTE))
				+ minTwoDigitString(oneDay.get(Calendar.SECOND));
	}

	private static String minTwoDigitString(int i) {
		if (i >= 0 && i < 10)
			return "0" + i;
		else
			return "" + i;
	}
}