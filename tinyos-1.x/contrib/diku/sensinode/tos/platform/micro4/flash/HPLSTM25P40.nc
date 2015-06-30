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


interface HPLSTM25P40 {

	/**
	 * Read flash block.
	 *
	 *
	 * \param address block address on flash
	 * \param buffer  pointer to buffer
	 * \param length  length of read buffer
	 *
	 * \return SUCCESS
	 */
	command result_t read(uint32_t address, uint8_t *buffer, uint16_t length);

	/**
	 * Fast Read flash block.
	 *
	 *
	 * \param address block address on flash
	 * \param buffer  pointer to buffer
	 * \param length  length of read buffer
	 *
	 * \return SUCCESS
	 */
	command result_t fastRead(uint32_t address, uint8_t *buffer, uint16_t length);

	/**
	 * Write flash page. Page size is 256 bytes.
	 * Write address must point at start of page.
	 *
	 * \param address block address on flash
	 * \param buffer  pointer to buffer
	 * \param length  length of read buffer
	 *
	 * \return SUCCESS
	 */
	command result_t write(uint32_t address, uint8_t *buffer, uint16_t length);

	/**
	 * Flash sector erase. Sector size is 64 kilobytes.
	 * Address must point at start of or within sector.
	 *
	 * \param address block address on flash
	 *
	 * \return SUCCESS
	 */
	command result_t sectorErase(uint32_t address);

	/**
	 * Flash bulk erase. 
	 * Erases entire flash
	 *
	 * \return SUCCESS
	 */
	command result_t bulkErase();

	/**
	 * Deep Power-down. 
	 *
	 * \return SUCCESS
	 */
	command result_t sleep();

	/**
	 * Flash signature read. Wakes the device up from power down mode.
	 * Signature value should be 0x12 if the flash is present and working.
	 *
	 * \return signature value
	 */
	command int16_t wakeUp();

	/**
	 * Flash identification read. 
	 * Only available in chips with Process Technology code X
	 *
	 * \return id value
	 */
	command int32_t readIdentification();

	/**
	 * Flash status register read. 
	 *
	 * \return status register value
	 */
	command int16_t readStatus();

	/**
	 * Flash status register write. 
	 *
	 * \return SUCCESS
	 */
	command result_t writeStatus(uint8_t value);

	/**
	 * Flash write status. 
	 *
	 * \return SUCCESS
	 * \return FAIL		write in progress
	 */
	command result_t isFree();

}
