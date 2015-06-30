package com.rincon.blackbook.memorystick;

/*
 * Copyright (c) 2004-2006 Rincon Research Corporation.  
 * All rights reserved.
 * 
 * Rincon Research will permit distribution and use by others subject to
 * the restrictions of a licensing agreement which contains (among other things)
 * the following restrictions:
 * 
 *  1. No credit will be taken for the Work of others.
 *  2. It will not be resold for a price in excess of reproduction and 
 *      distribution costs.
 *  3. Others are not restricted from copying it or using it except as 
 *      set forward in the licensing agreement.
 *  4. Commented source code of any modifications or additions will be 
 *      made available to Rincon Research on the same terms.
 *  5. This notice will remain intact and displayed prominently.
 * 
 * Copies of the complete licensing agreement may be obtained by contacting 
 * Rincon Research, 101 N. Wilmot, Suite 101, Tucson, AZ 85711.
 * 
 * There is no warranty with this product, either expressed or implied.  
 * Use at your own risk.  Rincon Research is not liable or responsible for 
 * damage or loss incurred or resulting from the use or misuse of this software.
 */

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;

import com.rincon.blackbook.Util;
import com.rincon.blackbook.bfiledelete.BFileDelete;
import com.rincon.blackbook.bfiledelete.BFileDeleteEvents;
import com.rincon.blackbook.bfiledir.BFileDir;
import com.rincon.blackbook.bfiledir.BFileDirEvents;
import com.rincon.blackbook.bfileread.BFileRead;
import com.rincon.blackbook.bfileread.BFileReadEvents;
import com.rincon.blackbook.bfilewrite.BFileWrite;
import com.rincon.blackbook.bfilewrite.BFileWriteEvents;
import com.rincon.blackbook.messages.BlackbookConnectMsg;

public class MemoryStick implements BFileReadEvents, BFileWriteEvents,
		BFileDeleteEvents, BFileDirEvents {

	/** BFileRead Transceiver */
	private BFileRead bFileRead;

	/** BFileWrite Transceiver */
	private BFileWrite bFileWrite;

	/** BFileDelete Transceiver */
	private BFileDelete bFileDelete;

	/** BFileDir Transceiver */
	private BFileDir bFileDir;

	/** File Writer */
	private DataOutputStream out;

	/** File Reader */
	private DataInputStream in;

	/** The local file on the computer to interact with */
	private File localFile;

	/** True if we're reading from flash, false if we're writing to flash */
	private boolean reading = false;

	/** True if we're writing to the flash from the computer */
	private boolean writing = false;

	/** The filename we're writing to on the mote */
	private String remoteWriteFile;

	/** Write buffer */
	private byte[] writeBuffer;
	
	/** The amount of bytes transferred */
	private long transferred;
	
	/** Basic CLI Progress Bar */
	private TransferProgress progress;
	
	/**
	 * Main Method
	 * @param args
	 */
	public static void main(String[] args) {
		new MemoryStick(args);
	}
	
	/**
	 * Constructor
	 * 
	 * @param args
	 */
	public MemoryStick(String[] args) {
		if (args.length < 1) {
			reportError("Not enough arguments");
		}

		initializeListeners();
		
		if (args[0].toLowerCase().matches("-get")) {
			reading = true;
			writing = false;

			if (args.length > 1) {
				localFile = new File(args[1]);
				if (args.length > 3) {
					if (args[2].toLowerCase().matches("as")) {
						localFile = new File(args[3]);
					}
				}

				if (localFile.exists()) {
					System.err.println(localFile.getName()
							+ " already exists! Delete? (Y/N)");
					BufferedReader stdin = new BufferedReader(
							new InputStreamReader(System.in));
					try {
						String answer = stdin.readLine();
						System.out.println();
						if (answer.toUpperCase().startsWith("Y")) {
							localFile.delete();
						} else {
							System.exit(1);
						}

					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();

					}
				}

				try {
					localFile.createNewFile();
					out = new DataOutputStream(new BufferedOutputStream(
							new FileOutputStream(localFile)));

					bFileRead.open(args[1]);

				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}

			} else {
				reportError("Not enough arguments");
			}
		} else if (args[0].toLowerCase().matches("-put")) {
			writing = true;

			if (args.length > 1) {
				localFile = new File(args[1]);
				remoteWriteFile = localFile.getName();

				if (args.length > 3) {
					if (args[2].toLowerCase().matches("as")) {
						remoteWriteFile = args[3];
					}
				}

				if (!localFile.exists()) {
					reportError(localFile.getAbsolutePath()
							+ " does not exist!");
				}

				try {
					in = new DataInputStream(new FileInputStream(localFile));

				} catch (FileNotFoundException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}

				writeBuffer = new byte[BlackbookConnectMsg.totalSize_data()];
				bFileDir.checkExists(remoteWriteFile);

			} else {
				reportError("Not Enough Arguments");
			}

		} else if (args[0].toLowerCase().matches("-dir")) {
			System.out.println(bFileDir.getTotalFiles() + " total files:");
			bFileDir.readFirst();

		} else if (args[0].toLowerCase().matches("-delete")) {
			if (args.length > 1) {
				bFileDelete.delete(args[1]);

			} else {
				reportError("Not Enough Arguments");
			}

		} else if (args[0].toLowerCase().matches("-freespace")) {
			System.out.println(bFileDir.getFreeSpace() + " bytes available");
			System.exit(0);

		} else if (args[0].toLowerCase().matches("-iscorrupt")) {
			if (args.length > 1) {
				System.out.println("Please wait, this could take awhile for large files...");
				bFileDir.checkCorruption(args[1]);

			} else {
				reportError("Not Enough Arguments");
			}
		} else {
			reportError("Unknown argument: " + args[0]);
		}
	}

	private void reportError(String error) {
		System.err.println(error);
		System.err.println(getUsage());
		System.exit(1);
	}

	public static String getUsage() {
		String usage = "";
		usage += "  MemoryStick\n";
		usage += "\t-get [filename on mote] [as <filename on computer>]\n";
		usage += "\t-put [filename on computer] [as <filename on mote>]\n";
		usage += "\t-dir\n";
		usage += "\t-delete [filename on mote]\n";
		usage += "\t-isCorrupt [filename on mote]\n";
		usage += "\t-freeSpace\n";
		return usage;
	}

	
	private void initializeListeners() {
		bFileDelete = new BFileDelete();
		bFileDir = new BFileDir();
		bFileRead = new BFileRead();
		bFileWrite = new BFileWrite();
		
		bFileDelete.addListener(this);
		bFileDir.addListener(this);
		bFileRead.addListener(this);
		bFileWrite.addListener(this);
	}
	
	
	/***************** BFileRead and BFileWrite Events ****************/
	public void opened(String fileName, long amount, boolean result) {
		if (!result) {
			reportError("Cannot open file");
		}


		transferred = 0;
		
		if (reading) {
			System.out.println("Getting " + fileName + " (" + amount + " bytes)");
			progress = new TransferProgress(amount);
			bFileRead.read(BlackbookConnectMsg.totalSize_data());

		} else if (writing) {
			byte[] empty = {(byte)0};
			System.out.println("Writing " + fileName.replaceAll(new String(empty),"") + " (" + localFile.length() + " bytes)");
			progress = new TransferProgress(localFile.length());
			write();
		}

	}

	public void closed(boolean result) {
		System.out.println("\n");
		
		if (reading) {
			try {
				out.flush();
				out.close();
			} catch (IOException e) {
				System.err.println(e.getMessage());
			}

			System.out.println(localFile.length() + " bytes read into "
					+ localFile.getAbsolutePath());
			System.exit(0);

		} else if (writing) {
			try {
				in.close();
				
			} catch (IOException e) {
				e.printStackTrace();
			}

			System.out.println(localFile.length() + " bytes written to "
					+ remoteWriteFile);
			System.exit(0);
		}
	}

	/** **************** BFileRead Events *************** */
	public void readDone(short[] dataBuffer, int amount, boolean result) {
		transferred += amount;
		progress.update(transferred);
		if (amount > 0) {
			try {
				out.write(Util.shortsToBytes(dataBuffer, amount));

			} catch (IOException e) {
				System.err.println(e.getMessage());
				bFileRead.close();
			}
			
			bFileRead.read(BlackbookConnectMsg.totalSize_data());

		} else {
			bFileRead.close();
		}
	}

	/** *************** BFileDelete Events *************** */
	public void deleted(boolean result) {
		if (result) {
			System.out.println("File deleted on mote.");
			if (writing) {
				bFileWrite.open(remoteWriteFile, localFile.length());

			} else {
				System.exit(0);
			}

		} else {
			System.out.println("Unable to delete file!");
			System.exit(0);
		}

	}

	/** *************** BFileWrite Events *************** */
	public void saved(boolean result) {
		// TODO Auto-generated method stub
	}

	public void appended(int amountWritten, boolean result) {
		transferred += amountWritten;
		progress.update(transferred);
		write();
	}

	/** *************** BFileDir Events *************** */
	public void corruptionCheckDone(boolean isCorrupt, boolean result) {
		if (isCorrupt) {
			System.out.println("File is corrupted on flash!");
		} else {
			System.out.println("File is OK on flash!");
		}
		System.exit(0);
	}

	public void existsCheckDone(boolean doesExist, boolean result) {
		// Here we are about to write a file to the mote,
		// and are checking to see if the file exists before
		// writing
		if (doesExist) {
			System.err.println(remoteWriteFile.replaceAll(" ","") + " already exists on the mote! Delete? (Y/N)");
			BufferedReader stdin = new BufferedReader(new InputStreamReader(
					System.in));
			try {
				String answer = stdin.readLine();
				System.out.println();
				if (answer.toUpperCase().startsWith("Y")) {
					bFileDelete.delete(remoteWriteFile);

				} else {
					System.exit(1);
				}

			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();

			}
		} else {
			bFileWrite.open(remoteWriteFile, localFile.length());
		}
	}

	public void nextFile(String fileName, boolean result) {
		if (result) {
			System.out.println("\t" + fileName);
			bFileDir.readNext(fileName);
		} else {
			System.exit(0);
		}
	}

	/***************** Methods ****************/
	private void write() {
		int appendAmount;
		try {
			if ((appendAmount = in.read(writeBuffer)) > 0) {
				bFileWrite.append(Util.bytesToShorts(writeBuffer), appendAmount);

			} else {
				bFileWrite.close();
			}

		} catch (IOException e) {
			System.err.println(e.getMessage());
			bFileWrite.close();
		}
	}
	
}
