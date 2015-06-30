//$Id: HPLCC2420FIFO.nc,v 1.1.1.1 2007/11/05 19:11:24 jpolastre Exp $
/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * FIFO Access to the CC2420 transceiver.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
interface HPLCC2420FIFO {
  /**
   * Read from the RX FIFO queue.  Will read bytes from the queue
   * until the length is reached (determined by the first byte read).
   * RXFIFODone() is signalled when all bytes have been read or the
   * end of the packet has been reached.
   *
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   * @param length number of bytes requested from the FIFO
   * @param data buffer bytes should be placed into
   *
   * @return SUCCESS if the bus is free to read from the FIFO
   */
  async command result_t readRXFIFO(uint8_t rh, uint8_t length, uint8_t *data);

  /**
   * Writes a series of bytes to the transmit FIFO.
   *
   * @param rh either RESOURCE_NONE for automatic resource scheduling or a
   * resource handle acquired by CC2420ResourceC
   * @param length length of data to be written
   * @param data the first byte of data
   *
   * @return SUCCESS if the bus is free to write to the FIFO
   */
  async command result_t writeTXFIFO(uint8_t rh, uint8_t length, uint8_t *data);

  /**
   * Notification that a byte from the RX FIFO has been received.
   *
   * @param length number of bytes actually read from the FIFO
   * @param data buffer the bytes were read into
   *
   * @return SUCCESS 
   */
  async event result_t RXFIFODone(uint8_t length, uint8_t *data);

  /**
   * Notification that the bytes have been written to the FIFO
   * and if the write was successful.
   *
   * @param length number of bytes written to the fifo queue
   * @param data the buffer written to the fifo queue
   *
   * @return SUCCESS
   */
  async event result_t TXFIFODone(uint8_t length, uint8_t *data);
}
