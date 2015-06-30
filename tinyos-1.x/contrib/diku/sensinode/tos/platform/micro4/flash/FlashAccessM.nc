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


module FlashAccessM
{
	provides {
		interface StdControl as FlashControl;
		interface FlashAccess;
	}
	uses interface HALSTM25P40 as Flash;
}

implementation
{

#define FIRST_PAGE 0x0000
#define LAST_PAGE 0x07FF
#define PAGE_SIZE 0x0100

	command result_t FlashControl.init()
	{
		result_t r1, r2;
		
		r1 = call Flash.wakeUp();
		r2 = call Flash.sleep();
		
		return rcombine(r1, r2);
	}

	command result_t FlashControl.start()
	{
		return call Flash.wakeUp();
	}

	command result_t FlashControl.stop()
	{
		return call Flash.sleep();
	}

	command uint16_t FlashAccess.firstUsablePage() {
	
		return FIRST_PAGE;
	}
	
	command uint16_t FlashAccess.lastUsablePage() {
	
		return LAST_PAGE;
	}

	/**
	* Read a page from the flash. 
	*
	* @param page_no The page to read from.
	* @param page    A buffer to hold the page bring read.
	* @return SUCCESS, the page could be read
	*/
	command result_t FlashAccess.read(uint16_t page_no, void *page) {
	
		uint32_t address;

		if ( (FIRST_PAGE <= page_no) && (page_no <= LAST_PAGE) ) {
			address = page_no;
			address = address << 8;
	
			return call Flash.read(address, (uint8_t *) page, PAGE_SIZE);

		} else {
			return FAIL;
		}
	}

	event void Flash.readReady(uint32_t address, uint8_t *buffer, uint16_t length) {
		
		signal FlashAccess.readReady(address >> 8, buffer, length);
		
		return;
	}

	event void Flash.fastReadReady(uint32_t address, uint8_t *buffer, uint16_t length) {
		return;
	}

	/**
	* Erase the sector holding the page in the flash.
	*
	* @param page_no The page inside the sector.
	* @return SUCCESS, the sector was erased.
	*/
	command result_t FlashAccess.erase(uint16_t page_no) {
	
		uint32_t address;

		if ( (FIRST_PAGE <= page_no) && (page_no <= LAST_PAGE) ) {
			address = page_no;
			address = address << 8;
	
			return call Flash.sectorErase(address);

		} else {
			return FAIL;
		}
	} 
	
	event void Flash.sectorEraseDone(uint32_t address)
	{
		signal FlashAccess.eraseDone(address >> 8);
	}

	/**
	* Erase the sector holding the page in the flash.
	*
	* @param page_no The page inside the sector.
	* @return SUCCESS, the sector was erased.
	*/
	command result_t FlashAccess.eraseAll() {
	
		return call Flash.bulkErase();
	} 
	
	event void Flash.bulkEraseDone()
	{
		signal FlashAccess.eraseAllDone();
	}

	/**
	* Write a page to the flash
	*
	* <p>Note this function does not clear the page before the
	* write. This must be done by calling erase</p>
	*
	* @param page_no The page to write
	* @param page    A buffer containing the contents to write
	* @result SUCCESS, the self-programming has successfully finished.
	*/
	command result_t FlashAccess.write(uint16_t page_no, void *page) { 

		uint32_t address;

		if ( (FIRST_PAGE <= page_no) && (page_no <= LAST_PAGE) ) {
			address = page_no;
			address = address << 8;
	
			return call Flash.write(address, (uint8_t *) page, PAGE_SIZE);
			
		} else {
			return FAIL;
		}
	}
	
	event void Flash.writeDone(uint32_t address, uint8_t *buffer, uint16_t length)
	{
		signal FlashAccess.writeDone(address >> 8, buffer);
	}

}

