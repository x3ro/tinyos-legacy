/*
  Copyright (C) 2004 Klaus S. Madsen <klaussm@diku.dk>
  Copyright (C) 2006 Marcus Chang <marcus@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/


module HPLCC2420M {
	provides {
		interface HPLCC2420;
		interface HPLCC2420RAM;
		interface HPLCC2420FIFO;
		interface HPLCC2420Status;
		interface StdControl as HPLCC2420Control;
	}
	uses {
		interface Spi;
	}
}

implementation {

	void cc2420_select()
	{
		TOSH_SET_RADIO_CSN_PIN();
	}

	void cc2420_unselect()
	{
		TOSH_CLR_RADIO_CSN_PIN();
	}


	/*********************************************************************
	 *
	 * HPLCC2420Control interface
	 *
	 ********************************************************************/
	command result_t HPLCC2420Control.init() 
	{
		/* Taken from CC2420_INIT in NanoStack's rf.c */
		P5DIR &= ~0x70; 
		P1DIR &= ~0x80; 
		P5SEL &= ~0x70; 
		P1SEL &= ~0x80;

		return SUCCESS;
	}

	command result_t HPLCC2420Control.start()
	{
		return SUCCESS;
	}

	command result_t HPLCC2420Control.stop()
	{
		return SUCCESS;
	}


  /** 
   * Zero out the reserved bits since they can be either 0 or 1.
   * This allows the use of "if !cmd(x)" in the radio stack
   */
  uint8_t adjustStatusByte(uint8_t status) {
    return status & 0x7E;
  }

	async command uint8_t HPLCC2420.cmd(uint8_t addr)
	{
		uint8_t value;
		
		cc2420_select();
		value = call Spi.write(addr);
		cc2420_unselect();
		return value;
	}

	async command uint8_t HPLCC2420.write(uint8_t reg, uint16_t data)
	{
		uint8_t res;

		cc2420_select();
		res = call Spi.write(reg & 0x3F);
		call Spi.write(data >> 8);
		call Spi.write(data);
		cc2420_unselect();

		return adjustStatusByte(res);
	}

	async command uint16_t HPLCC2420.read(uint8_t reg)
	{
		uint16_t value;
		
		cc2420_select();
		call Spi.write((uint8_t) reg | 0x40);
		value = call Spi.write(0);
		value <<= 8;
		value |= (uint16_t)call Spi.write(0);
		cc2420_unselect();

		return value;
	}

	/*********************************************************************
	 *
	 * HPLCC2420RAM interface
	 *
	 ********************************************************************/

  norace uint8_t rxramlen;
  norace uint16_t rxramaddr;
  norace uint8_t* rxrambuf;

  task void signalRAMRd() {
    signal HPLCC2420RAM.readDone(rxramaddr, rxramlen, rxrambuf);
  }

  async command result_t HPLCC2420RAM.read(uint16_t addr, uint8_t _length, uint8_t* buffer) {
		uint8_t i = 0;

		atomic {
			rxramaddr = addr;
			rxramlen = _length;
			rxrambuf = buffer;
		}

		cc2420_select();
 		call Spi.write((rxramaddr & 0x7F) | 0x80);
		call Spi.write(((rxramaddr >> 1) & 0xC0) | 0x20);

		for (i = 0 ; i < rxramlen; i++) {
			buffer[i] = call Spi.write(0);
		}

		cc2420_unselect();

		return post signalRAMRd();
	}

  norace uint8_t* rambuf;
  norace uint8_t ramlen;
  norace uint16_t ramaddr;

  task void signalRAMWr() {
    signal HPLCC2420RAM.writeDone(ramaddr, ramlen, rambuf);
  }

  async command result_t HPLCC2420RAM.write(uint16_t addr, uint8_t _length, uint8_t* buffer) {
		uint8_t i;

		atomic {
			ramaddr = addr;
			ramlen = _length;
			rambuf = buffer;
		}

		cc2420_select();

		call Spi.write((ramaddr & 0x7F) | 0x80);
		call Spi.write(((ramaddr >> 1) & 0xC0));

		for (i = 0; i < ramlen; i++) {
			call Spi.write(rambuf[i]);
		}

		cc2420_unselect();

		return post signalRAMWr();
	}

  default async event result_t HPLCC2420RAM.readDone(uint16_t addr, 
																										 uint8_t _length, 
																										 uint8_t *data) 
	{ 
		return SUCCESS; 
	}

  default async event result_t HPLCC2420RAM.writeDone(uint16_t addr, 
																											uint8_t _length, 
																											uint8_t *data) 
	{ 
		return SUCCESS; 
	}


	/*********************************************************************
	 *
	 * HPLCC2420FIFO
	 *
	 ********************************************************************/
  norace uint8_t rxlen;
  norace uint8_t* rxbuf;

  task void signalRXFIFO() {
    uint8_t _rxlen;
    uint8_t* _rxbuf;
		
    atomic {
      _rxlen = rxlen;
      _rxbuf = rxbuf;
    }
		
    signal HPLCC2420FIFO.RXFIFODone(_rxlen, _rxbuf);
  }

  async command result_t HPLCC2420FIFO.readRXFIFO(uint8_t length, 
																									uint8_t *data) 
	{
    uint8_t i;

		cc2420_select();

		rxbuf = data;
		call Spi.write(CC_REG_RXFIFO | 0x40);
		rxlen = call Spi.write(0) & 0x7F;

		if (rxlen > 0) {
			rxbuf[0] = rxlen;
			rxlen++;

			if (rxlen > length) rxlen = length;

			for (i = 1 ; i < rxlen; i++) {
				rxbuf[i] = call Spi.write(0);
			}
		}

		cc2420_unselect();

    return post signalRXFIFO();
	}

  norace uint8_t txlen;
  norace uint8_t* txbuf;

  task void signalTXFIFO() {
    uint8_t _txlen;
    uint8_t* _txbuf;

    atomic {
      _txlen = txlen;
      _txbuf = txbuf;
    }

    signal HPLCC2420FIFO.TXFIFODone(_txlen, _txbuf);
  }

  async command result_t HPLCC2420FIFO.writeTXFIFO(uint8_t length, uint8_t *data) 
	{
		uint8_t i;
		
		atomic {
			txlen = length;
			txbuf = data;
		}
		
		cc2420_select();
		call Spi.write(CC_REG_TXFIFO);
		call Spi.write(txlen);

		for (i = 1; i < txlen; i++) {
			call Spi.write(txbuf[i]);
		}
		
		/* Release the radio */
		cc2420_unselect();

		return post signalTXFIFO();
	}

  default async event result_t HPLCC2420FIFO.RXFIFODone(uint8_t _length, 
																												uint8_t *data) 
	{ 
		return SUCCESS; 
	}

  default async event result_t HPLCC2420FIFO.TXFIFODone(uint8_t _length, 
																												uint8_t *data) { 
		return SUCCESS; 
	}

	/*********************************************************************
	 *
	 * HPLCC2420Status
	 *
	 ********************************************************************/
	async command bool HPLCC2420Status.FIFO()
	{
		return P5IN & (1 << 5);
	}

	async command bool HPLCC2420Status.FIFOP()
	{
		return P5IN & (1 << 6);
	}

	async command bool HPLCC2420Status.CCA()
	{
		return P5IN & (1 << 4);
	}

	async command bool HPLCC2420Status.SFD()
	{
		return P1IN & (1 << 7);
	}


}
