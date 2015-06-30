/**
 * Created on 15. Mai 2005, 15:00
 *
 * Copyright (c) 2005, Olaf Landsiedel, Thomas Gärtner, Protocol Engineering and
 * Distributed Systems, University of Tuebingen
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * Neither the name of the Protocol Engineering and Distributed Systems
 * Group, the name of the University of Tuebingen nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package avrora.sim.platform;

import avrora.sim.FiniteStateMachine;
import avrora.sim.Simulator;
import avrora.sim.clock.Clock;
import avrora.sim.energy.Energy;
import avrora.sim.mcu.Microcontroller;
import avrora.util.StringUtil;
import avrora.util.Terminal;
import avrora.util.Verbose;

/**
 * The <code>ExternalFlash</code> class implements the necessary functionality of the
 * Atmega Dataflash interface to use the Mica2 DataFlash
 * This device requires use of the following pins:
 * <p/>
 * PA3 - Flash Cable Seclect
 * <p/>
 * PD2 - USART1_RXD
 * PD3 - USART1_TXD
 * PD5 - USART1_CLK
 *
 * @author Thomas Gaertner
 */
public class ExternalFlash {

    protected final Simulator sim;
    protected final Clock clock;
    protected Microcontroller mcu;
    private boolean isSelected;	// true if PA3 is 0
    private boolean isReading;		// mcu is reading from so of dataflash?
    private int dfOpcode;
    private int dfPageAddress;
    private int dfByteOffset;
    private int dfTempByte;
    private short dfStatus;		// Dataflash Status LegacyRegister
    private long dfDelay;			// delay while busy in cycles
    private boolean so, si;		// serial output, serial input
    private int icOffset, icPage;				// internal address counter
    private boolean tick;
    private boolean extraTick = false;
    private short step;
    private byte i;

    //	DataFlash Status LegacyRegister
    //	bits 5, 4, 3
    public static final int DF_STATUS_REGISTER_DENSITY = 0x18;
    public static final int DF_STATUS_READY = 0x80;
    public static final int DF_STATUS_COMPARE = 0x40;
    //	SC Characteristics
    //	all below in ms
    public static final double DF_TEP = 11.976;
    public static final double DF_TP = 5.676;
    public static final double DF_TPE = 6.466;
    public static final double DF_TBE = 6.466;
    public static final double DF_TXFR = 0.105;

    public static final boolean ECHO_EVENT = Verbose.getVerbosePrinter("mica2.flash").enabled;
   
    private static final int E_MODE_STANDBY = 0;
    private static final int E_MODE_READ = 1;
    private static final int E_MODE_PREPFLASHTOBUF = 2;
    private static final int E_MODE_FLASHTOBUF = 3;
    private static final int E_MODE_BUFTOSPI = 4;
    private static final int E_MODE_FLASHTOSPI = 5;
    private static final int E_MODE_SPITOBUF = 6;
    private static final int E_MODE_PREPWRITE = 7;
    private static final int E_MODE_ERASE = 8;
    private static final int E_MODE_WRITE = 9;
    private static final int E_MODE_ERASEWRITE = 10;
    private static final int E_MODE_FINISHWRITE = 11;
    // names of the states of this device
    private static final String[] modeName = {"standBy", "read", "prepFlashToBuf", "flashToBuf", "bufToSpi", "flashToSpi", "spiToBuf", "prepWrite", "erase", "write", "eraseWrite", "finishWrite"};
    // power consumption of the device states
    private static final double[] modeAmpere = {0.000002, 0.001, 0.0047, 0.0075, 0.0064, 0.003, 0.0036, 0.0021, 0.023, 0.0214, 0.0201, 0.0017};
    // default mode of the device is standby
    private static final int startMode = 0;
    // the Dataflash Memory
    public Memory memory;

    protected final FiniteStateMachine stateMachine;

    /**
     * The <code>Memory</code> class simulates the Dataflash Memory
     */
    private class Memory {
        Page[] pages;
        Page buffer1;
        Page buffer2;

        protected Memory() {
            pages = new Page[2048];
            buffer1 = new Page();
            buffer2 = new Page();
            for (int i = 0; i < 2048; i++) {
                pages[i] = new Page();
            }
        }
    }

    private class Page {
        public short[] bytes;

        protected Page() {
            bytes = new short[264];
        }
		void debug() {
			int i;
			for(i = 0; i < 264; i++) {
				echo("Byte " + i + " = " + bytes[i]);
			}
		}
		
		public boolean equals(Object obj) {
			if ((obj != null) && this.getClass().equals(obj.getClass())) {
				Page other = (Page) obj;
				if (this.bytes.length == other.bytes.length) {
					for (int i=0; i<this.bytes.length; i++) {
						if (this.bytes[i] != other.bytes[i]) {
							return false;
						}
					}
					return true;
				}
			}
			return false;
		}
		
    }

    // TODO: parameterize this class by size, page size, etc
    public ExternalFlash(Microcontroller mcunit) {
        memory = new Memory();
        mcu = mcunit;
        sim = mcu.getSimulator();
        clock = sim.getClock();
        dfStatus = DF_STATUS_REGISTER_DENSITY | DF_STATUS_READY;
        tick = false;
        i = 0;
        step = 0;

        stateMachine = new FiniteStateMachine(clock, startMode, modeName, 0);
        // connect Pins
        // output
        mcu.getPin("PA3").connect(new PA3Output());
        mcu.getPin("PD3").connect(new PD3Output());
        mcu.getPin("PD5").connect(new PD5Output());
        // input
        mcu.getPin("PD2").connect(new PD2Input());

        //setup energy recording
        new Energy("flash", modeAmpere, stateMachine);
    }

    private Page getMemoryPage(int num) {
        return this.memory.pages[num];
    }

    private short getMemoryPageAt(int num, int offset) {
        return this.memory.pages[num].bytes[offset];
    }

    private void setMemoryPage(int num, Page val) {
    	for (int i=0; i<val.bytes.length; i++) {
    		this.memory.pages[num].bytes[i] = val.bytes[i];
    	}
        //BUG this.memory.pages[num] = val;
		this.memory.pages[num].debug();
    }

    private Page getBuffer1() {
        return this.memory.buffer1;
    }

    private short getBuffer1(int offset) {
        return this.memory.buffer1.bytes[offset];
    }

    private void setBuffer1(Page value) {
    	for (int i=0; i<value.bytes.length; i++) {
    		this.memory.buffer1.bytes[i] = value.bytes[i];
    	}
//BUG        this.memory.buffer1 = value;
    }

    private void setBuffer1(int offset, short value) {
        this.memory.buffer1.bytes[offset] = value;
    }

    private Page getBuffer2() {
        return this.memory.buffer2;
    }

    private short getBuffer2(int offset) {
        return this.memory.buffer2.bytes[offset];
    }

    private void setBuffer2(Page value) {
    	for (int i=0; i<value.bytes.length; i++) {
    		this.memory.buffer2.bytes[i] = value.bytes[i];
    	}
//BUG        this.memory.buffer2 = value;
    }

    private void setBuffer2(int offset, short value) {
        this.memory.buffer2.bytes[offset] = value;
    }

    private void copyBuffer1toPage(int num) {
        setMemoryPage(num, getBuffer1());
    }

    private void copyBuffer2toPage(int num) {
        setMemoryPage(num, getBuffer2());
    }

    private void copyPageToBuffer1(int num) {
        setBuffer1(getMemoryPage(num));
    }

    private void copyPageToBuffer2(int num) {
        setBuffer2(getMemoryPage(num));
    }

    // Flash_CS as output pin
    protected class PA3Output extends Microcontroller.OutputPin {
        // Flash_CS is connected inverted
        public void write(boolean level) {
            double delay = 0;		// delay while busy in ms
            if (!level && !isSelected) {
                // falling edge, so instruction starts
                if (clock.getCount() > 1500) {
                    echo("Instruction started");
                }
                /* determine SPI mode: mode0 if CLK is low when CS is set to low. Then, an extra CLK tick is needed in read operation */
                extraTick = !tick;
                isSelected = true;
                if (stateMachine.getCurrentState() == E_MODE_STANDBY) {
                	stateMachine.transition(E_MODE_READ);
                }
            } else if (level && isSelected) {
                // rising edge, so instruction terminates
                if (clock.getCount() < 1500) {
                    echo("initialized");
                } else {
                    echo("Instruction finished");
                }
                isSelected = false;

                switch (dfOpcode) {
                    // Read Commands
                    case 0x68:  // Continous Array Read
                    case 0xE8:  // Continous Array Read
                    case 0x52:  // Main Memory Page Read
                    case 0xD2:  // Main Memory Page Read
                    case 0x54:  // Buffer1 Read
                    case 0xD4:  // Buffer1 Read
                    case 0x56:  // Buffer2 Read
                    case 0xD6:  // Buffer2 Read
                    case 0x57:  // Status LegacyRegister Read
                    case 0xD7:  // Status LegacyRegister Read
                        break;

                        // Program and Erase Commands
                    case 0x83:  // Buffer1 to Memory with Built-in Erase
                        copyBuffer1toPage(dfPageAddress);
                        echo("copy Buffer1 to Memory Page " + dfPageAddress);
                        delay = DF_TEP;
                        stateMachine.transition(E_MODE_ERASEWRITE);
                        break;

                    case 0x86:  // Buffer2 to Memory with Built-in Erase
                        copyBuffer2toPage(dfPageAddress);
                        echo("copy Buffer2 to Memory Page " + dfPageAddress);
                        delay = DF_TEP;
                        stateMachine.transition(E_MODE_ERASEWRITE);
                        break;

                    case 0x88:  // Buffer1 to Memory without Built-in Erase
                        copyBuffer1toPage(dfPageAddress);
                        echo("copy Buffer1 to Memory Page " + dfPageAddress);
                        delay = DF_TP;
                        stateMachine.transition(E_MODE_WRITE);
                        break;

                    case 0x89:  // Buffer2 to Memory without Built-in Erase
                        copyBuffer2toPage(dfPageAddress);
                        echo("copy Buffer2 to Memory Page " + dfPageAddress);
                        delay = DF_TP;
                        stateMachine.transition(E_MODE_WRITE);
                        break;

                    case 0x81:  // Page Erase
                        delay = DF_TPE;
                        stateMachine.transition(E_MODE_ERASE);
                        break;

                    case 0x50:  // Block Erase
                        delay = DF_TBE;
                        stateMachine.transition(E_MODE_ERASE);
                        break;

                    case 0x82:  // Memory Program through Buffer1
                        // read from SI into Buffer1, write to Memory when Flash_CS gets 1
                        copyBuffer1toPage(dfPageAddress);
                        echo("copy Buffer1 to Memory Page " + dfPageAddress);
                        delay = DF_TEP;
                        stateMachine.transition(E_MODE_ERASEWRITE);
                        break;

                    case 0x85:  // Memory Program through Buffer2
                        // read from SI into Buffer2, write to Memory when Flash_CS gets 1
                        copyBuffer2toPage(dfPageAddress);
                        echo("copy Buffer2 to Memory Page " + dfPageAddress);
                        delay = DF_TEP;
                        stateMachine.transition(E_MODE_ERASEWRITE);
                        break;

                        // Additional Commands
                    case 0x53:  // Main Memory Page to Buffer1 Transfer
                        copyPageToBuffer1(dfPageAddress);
                        echo("copy Memory Page " + dfPageAddress + " to Buffer1");
                        delay = DF_TXFR;
                        stateMachine.transition(E_MODE_FLASHTOBUF);
                        break;

                    case 0x55:  // Main Memory Page to Buffer2 Transfer
                        copyPageToBuffer2(dfPageAddress);
                        echo("copy Memory Page " + dfPageAddress + " to Buffer2");
                        delay = DF_TXFR;
                        stateMachine.transition(E_MODE_FLASHTOBUF);
                        break;

                    case 0x60:  // Main Memory Page to Buffer1 Compare
                        if (getBuffer1().equals(getMemoryPage(dfPageAddress))) {
                            dfStatus &= ~DF_STATUS_COMPARE;
                            echo("compare Memory Page " + dfPageAddress + " to Buffer1: identical");
                        } else {
                            dfStatus |= DF_STATUS_COMPARE;
                            echo("compare Memory Page " + dfPageAddress + " to Buffer1: different");
                        }
                        delay = DF_TXFR;
                        stateMachine.transition(E_MODE_FLASHTOBUF);
                        break;

                    case 0x61:  // Main Memory Page to Buffer2 Compare
                        if (getBuffer2().equals(getMemoryPage(dfPageAddress))) {
                            dfStatus &= ~DF_STATUS_COMPARE;
                            echo("compare Memory Page " + dfPageAddress + " to Buffer2: identical");
                        } else {
                            dfStatus |= DF_STATUS_COMPARE;
                            echo("compare Memory Page " + dfPageAddress + " to Buffer2: different");
                        }
                        delay = DF_TXFR;
                        stateMachine.transition(E_MODE_FLASHTOBUF);
                        break;

                    case 0x58:  // Auto Page Rewrite
                    case 0x59:  // Auto Page Rewrite
                        delay = DF_TEP;
                        stateMachine.transition(E_MODE_ERASEWRITE);
                        break;

                }

                // Dataflash is busy
                dfStatus &= ~DF_STATUS_READY;
                dfDelay = clock.millisToCycles(delay);  //cycles until access is finished
                clock.insertEvent(new Delay(), dfDelay);
                System.out.println(StringUtil.getIDTimeString(sim)+" Opcode 0x"+Integer.toHexString(dfOpcode)+", delay "+dfDelay);

                // reset values
                dfOpcode = 0;
                dfByteOffset = 0;
                dfPageAddress = 0;
                step = 0;
                isReading = false;
                i = 0;
            }
        }
    }

    // USART1_TXD as output pin connected to SI
    protected class PD3Output extends Microcontroller.OutputPin {

        public void write(boolean level) {
            si = level;
        }
    }

    // USART1_CLK as output pin connected to SCK
    protected class PD5Output extends Microcontroller.OutputPin {
        private short temp;

        public void write(boolean level) {
            if (isSelected) {
                // toggling SCK
                if (tick != level) {
                    if (tick) {

                        // <<<<<<<< high-to-low <<<<<<<<
                        if (isReading) {
							//echo("dfByteOffset = " + dfByteOffset);
                            //set so bitwise
                            setSO();

                            // Energy
                            //stateMachine.transition(1); // read mode

                            i++;

                            if (i > 7) {
                                echo("1 Byte of serial data was output on the SO: " + temp);

                                // internal address counter
                                icOffset = dfByteOffset + 1;
                                if (icOffset > 263) {
                                    icOffset -= 264;
                					if ((dfOpcode == 0x68) || (dfOpcode == 0xE8)) { //AL

                						icPage = dfPageAddress + 1;
                						if (icPage > 2047) {
                							icPage -= 2048;
                						}
                                        dfPageAddress = icPage;
                					}
                                }
                                dfByteOffset = icOffset;
                                i = 0;
                            }
                        }
                    } else {
                        // >>>>>>>> low-to-high  >>>>>>>>
                        // first starts here with step 1: get opcode
                        if (!isReading) {
                            // get SI bytewise
                            dfTempByte |= ((si) ? 1 : 0) << (7 - i);  // MSB first

                            i++;

                            if (i > 7) {
                                i = 0;
                                step++;
                                doStep();
                                dfTempByte = 0;

                                // energy
/*                                if (step <= 4) {
                                    stateMachine.transition(3); // load
                                } else {
                                    stateMachine.transition(2); // write
                                }*/
                            }
                        }
                    }
                    // set clock state
                    tick = level;
                }
            }
        }

        private void setSO() {
			if (extraTick && ((dfOpcode == 0x68) ||
					  (dfOpcode == 0x52) ||
					  (dfOpcode == 0x54) ||
					  (dfOpcode == 0x56) ||
					  (dfOpcode == 0x57))) {
				extraTick = false;
				return;
			}
            switch (dfOpcode) {
                case 0x68:  // Continous Array Read
                case 0xE8:  // Continous Array Read
                case 0x52:  // Main Memory Page Read
                case 0xD2:  // Main Memory Page Read
                	temp = getMemoryPageAt(dfPageAddress, dfByteOffset);
                	echo("Temp "+temp+", page "+dfPageAddress+", offset "+dfByteOffset);
                	break;
                    // Buffer 1 Read
                case 0x54:
                case 0xD4:
                    temp = getBuffer1(dfByteOffset);
                    break;

                    // Buffer 2 Read
                case 0x56:
                case 0xD6:
                    temp = getBuffer2(dfByteOffset);
                    break;

                    // Status LegacyRegister Read
                case 0x57:
                case 0xD7:
                    temp = dfStatus;
                    break;

                default:
                    temp = getMemoryPageAt(dfPageAddress, dfByteOffset);
            }

            // write relevant bit to so
            so = ((temp & (1 << (7 - i))) > 0); // MSB first

        }

        private void doStep() {
            switch (step) {
                case 1:
                    //	get opcode
                    dfOpcode = dfTempByte;
                    echo("Recieved Opcode: " + dfOpcode);
                    // Status LegacyRegister Read?
                    if ((dfOpcode == 0x57) || (dfOpcode == 0xD7)) {
                        isReading = true;
                    }
                    if (stateMachine.getCurrentState() == E_MODE_READ) {
                        switch (dfOpcode) {
                		  // TODO: energy for plain status register read?
                		  //       confirm energy for program through buffer
                		  //       confirm energy for buffer compare
                		  //       test auto page rewrite
                		case 0x68:
                		case 0xE8: // continuous array read
                		case 0x52:
                		case 0xD2: // main memory page read
                			stateMachine.transition(E_MODE_FLASHTOSPI); // direct transfer of flash memory to SPI
                		  break;
                	    
                		case 0x54:
                		case 0xD4: // buffer 1 read
                		case 0x56:
                		case 0xD6: // buffer 2 read
                		  stateMachine.transition(E_MODE_BUFTOSPI);
                		  break;
                	  
                		case 0x53: // main memory page to buffer 1 transfer
                		case 0x55: // main memory page to buffer 2 transfer
                		case 0x60: // main memory page to buffer 1 compare
                		case 0x61: // main memory page to buffer 2 compare
                		case 0x58: // auto page rewrite 1 
                		case 0x59: // auto page rewrite 2
                			stateMachine.transition(E_MODE_PREPFLASHTOBUF);
                		  break;
                	    
                		case 0x84: // buffer 1 write
                		case 0x87: // buffer 2 write
                			stateMachine.transition(E_MODE_SPITOBUF);
                		  break;
                	  
                		case 0x83: // buffer 1 to main memory page program with built-in erase
                		case 0x86: // buffer 2 to main memory page program with built-in erase
                		case 0x88: // buffer 1 to main memory page program without built-in erase
                		case 0x89: // buffer 2 to main memory page program without built-in erase
                		case 0x81: // page erase
                		case 0x50: // block erase
                		case 0x82: // main memory page program through buffer 1
                		case 0x85: // main memory page program through buffer 2
                			stateMachine.transition(E_MODE_PREPWRITE);
                		  break;
                		}
                      }

                    break;

                case 2:
                    // get first part of adressing sequence
                    dfPageAddress = (dfTempByte << 7) & 0x0780;
                    echo("Received Address byte 1: " + dfTempByte);
                    break;

                case 3:
                    // get second part of adressing sequence
                    dfPageAddress |= (dfTempByte >> 1);
                    // and first part of byte offset
                    dfByteOffset = dfTempByte & 0x0100;
                    echo("Received Address byte 2: " + dfTempByte);
                    break;

                case 4:
                    // get second part of byte offset
                    dfByteOffset |= dfTempByte;
                    echo("Received Address byte 3: " + dfByteOffset);
                    break;

                default:
                    // adressing sequence complete
                    if (step > 4) {
                        doAction();
                    }
            }
        }

        private void doAction() {
            // ajust offset
            if (dfByteOffset > 263) {
                dfByteOffset -= 264;
            }
            switch (dfOpcode) {
                // Read Commands

                // Continous Array Read
                case 0x68:
                case 0xE8:
                    // Additional Don't cares Required: 4 Bytes
                    if (step == (4 + 4)) {
                        isReading = true;
                    }
                    break;

                    // Main Memory Page Read
                case 0x52:
                case 0xD2:
                    // Additional Don't cares Required: 4 Bytes
                    if (step == (4 + 4)) {
                        isReading = true;
                    }
                    break;

                    // Buffer 1 Read
                case 0x54:
                case 0xD4:
                    // Additional Don't cares Required: 1 Byte
                    if (step == (4 + 1)) {
                        isReading = true;
                    }
                    break;

                    // Buffer 2 Read
                case 0x56:
                case 0xD6:
                    if (step == (4 + 1)) {
                        isReading = true;
                    }
                    break;

                    //	Status LegacyRegister Read
                case 0x57:
                case 0xD7:


                    //Program and Erase Commands

                    //	Buffer 1 Write
                case 0x84:
                    setBuffer1(dfByteOffset, (short) dfTempByte);
                    echo("written Buffer 1 Byte: " + (short) (dfByteOffset) + ": " + dfTempByte);
                    dfByteOffset += 1;
                    break;

                    //	Buffer 2 Write
                case 0x87:
                    setBuffer2(dfByteOffset, (short) dfTempByte);
                    echo("written Buffer 2 Byte: " + (short) (dfByteOffset) + ": " + dfTempByte);
                    dfByteOffset += 1;
                    break;

                    // Buffer 1 to Memory with Built-in Erase
                case 0x83:
                    // write when Flash_CS gets 1
                    break;

                    // Buffer 2 to Memory with Built-in Erase
                case 0x86:
                    // write when Flash_CS gets 1
                    break;

                    // Buffer 1 to Memory without Built-in Erase
                case 0x88:
                    // write when Flash_CS gets 1
                    break;

                    // Buffer 2 to Memory without Built-in Erase
                case 0x89:
                    // write when Flash_CS gets 1
                    break;

                    // Page Erase
                case 0x81:
                    // erase when Flash_CS gets 1
                    break;

                case 0x50:  // Block Erase
                    // Block address in this case
                    dfPageAddress >>= 3;
                    break;

                    // Memory Program through Buffer 1
                case 0x82:
                    // read from SI into buffer1, write to memory when Flash_CS gets 1
                    setBuffer1(dfByteOffset, (short) dfTempByte);
                    echo("written Buffer 1 Byte: " + (short) (dfByteOffset) + ": " + dfTempByte);
                    dfByteOffset += 1;
                    break;

                    // Memory Program through Buffer 2
                case 0x85:
                    // read from SI into buffer2, write to mem when Flash_CS gets 1
                    setBuffer2(dfByteOffset, (short) dfTempByte);
                    echo("written Buffer 2 Byte: " + (short) (dfByteOffset) + ": " + dfTempByte);
                    dfByteOffset += 1;
                    break;
            }
        }
    }

    // Flash_RXD as input pin from SO
    protected class PD2Input extends Microcontroller.InputPin {
        // connected to serial output of dataflash
        public boolean read() {
            return so;
        }
    }

    protected class Delay implements Simulator.Event {
        /**
         * delay while dataflash is busy
         *
         * @see avrora.sim.Simulator.Event#fire()
         */
        public void fire() {
            if (dfOpcode == 0) {
            	stateMachine.transition(E_MODE_STANDBY);
            }
            else {
            	switch (stateMachine.getCurrentState()) {
          	  	case E_MODE_ERASE:
          	  	case E_MODE_WRITE:
          	  	case E_MODE_ERASEWRITE:
          	  		stateMachine.transition(E_MODE_FINISHWRITE);
          	  		break;
          	  	case E_MODE_FLASHTOBUF:
          	  		stateMachine.transition(E_MODE_BUFTOSPI);
          	  		break;
          	  	default:      
                }
            }
            // operation finished
            dfStatus |= DF_STATUS_READY;
            // check if we have to raise an interrupt

            if (((dfOpcode == 0x57) || (dfOpcode == 0xD7))
                && (i == 1)  // we have output the MSB only
                && (!tick)) {  // CLK is low
            	so = true;
            }
        }
    }

    private void echo(String str) {
        if (ECHO_EVENT) {
            // print the status of the LED
            synchronized (Terminal.class) {
                // synchronize on the terminal to prevent interleaved output
    			StringBuffer buf = new StringBuffer(45);
    	        StringUtil.getIDTimeString(buf, sim);
                Terminal.print(buf.toString());
                Terminal.print(Terminal.COLOR_BLUE, "Dataflash");
                Terminal.println(": " + str);
            }
        }
    }

}
	

	
