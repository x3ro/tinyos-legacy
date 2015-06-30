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


module UARTFrameM {
	provides {
		interface StdControl;
		interface UARTFrame;
	}
	uses {
		interface HPLUART as UART;
		interface LocalTime;
		interface CRC16;
	}
}

implementation {

#define MAX_PAYLOAD (MAX_FRAME_LENGTH - 1)
#define MAX_TIME_DELAY 1000UL // ~1050000 ticks@4MHz clock and 0.000035s@230400 bps


	/* transmission */
	bool sending;
	uint8_t * sendFramePtr;
	uint8_t * next_send_byte;
	uint8_t send_left;
	task void packet_send_done();

	/* reception */
	uint8_t receiveBuffer[MAX_FRAME_LENGTH];
	uint8_t handleBuffer[MAX_FRAME_LENGTH];
	uint8_t * receiveBufferPtr, * handleBufferPtr;
	uint8_t * next_recv_byte;
	uint8_t recv_left;

	/* frame handling */
	bool handlingFrame;
	task void packet_recv();

	/* timeout */
	uint32_t lastTime;

	/**************************************************************************
	** StdControl
	**************************************************************************/
	command result_t StdControl.init()
	{
		call UART.init();

		atomic {
			/* transmission */
			sending = FALSE;
			next_send_byte = 0;
			send_left = 0;

			/* reception */
			receiveBufferPtr = receiveBuffer;
			handleBufferPtr = handleBuffer;
			
			next_recv_byte = receiveBufferPtr;
			recv_left = 0;

			handlingFrame = FALSE;
		}

		return SUCCESS;
	}

	command result_t StdControl.start()
	{
		return SUCCESS;
	}
 	
	command result_t StdControl.stop()
	{
		call UART.stop();
		return SUCCESS;
	}

	/**************************************************************************
	** UARTFrame
	**************************************************************************/
	command result_t UARTFrame.sendFrame(uint8_t * frame)
	{
		uint8_t size;
		uint16_t crc;

		if (sending)
			return FAIL;

		sending = TRUE;

		/* store buffer pointer */
		sendFramePtr = frame;

		/* insert 16-bit crc at end of buffer */
		size = sendFramePtr[0];
		crc = call CRC16.calc(sendFramePtr, size - 1);
		sendFramePtr[size-1] = crc >> 8;
		sendFramePtr[size] = crc;

		atomic {
			/* point to next byte to be written */
			next_send_byte = sendFramePtr;
			/* setup remaining bytes to be written */
			send_left = sendFramePtr[0] + 1;
			/* initiate offload */
			signal UART.putDone();
		}

		return SUCCESS;
	}
	
	/**************************************************************************
	** UART
	**************************************************************************/
	async event result_t UART.putDone()
	{
		if (send_left) {
		
			call UART.put(*next_send_byte++);
			send_left--;

			if (!send_left)
				post packet_send_done();
		}
		return SUCCESS;
	}

	task void packet_send_done()
	{
		sending = FALSE;

		/* return buffer pointer to caller */
		signal UARTFrame.sendFrameDone(sendFramePtr);
	}

	/**************************************************************************
	**************************************************************************/
	async event result_t UART.get(uint8_t data) 
	{
		uint32_t thisTime;
		uint8_t * ptr;
		
		/* buffer space available */	
		if (!next_recv_byte) 
			return FAIL;

		/* reset buffer is time between chars is too high */
		thisTime = call LocalTime.read();
		if ( (thisTime - lastTime) > MAX_TIME_DELAY) {
			next_recv_byte = receiveBufferPtr;
			recv_left = 0;
		}
		lastTime = thisTime;
			
		/* store byte in buffer and update pointer */
		*next_recv_byte++ = data;

		/* update number of remaining bytes */
		if (!recv_left) {
			recv_left = data;
		} else {
			recv_left--;			
		}

		/* frame complete */
		if (!recv_left) 
		{		
			/* check if buffer is ready */
			if (handlingFrame) 
			{
				/* buffer not ready */
				next_recv_byte = 0;
				
			} else {
				handlingFrame = TRUE;
				
				/* switch buffer */
				ptr = receiveBufferPtr;
				receiveBufferPtr = handleBufferPtr;
				handleBufferPtr = ptr;

				next_recv_byte = receiveBufferPtr;

				/* handle received frame */
				post packet_recv();
			}
		}

		return SUCCESS;
	}

	task void packet_recv()
	{
		uint8_t length;
		uint16_t crcval, crcframe;
		uint8_t * buf, * ptr, * next_recv_byte_sync;

		atomic buf = handleBufferPtr;

		/* calculate crc */
		length = buf[0];
		crcval = call CRC16.calc(buf, length - 1);
		crcframe = buf[length-1];
		crcframe = (crcframe << 8) + buf[length];

		/* signal frame if crc checks out */
		if (crcframe == crcval)
		{
			signal UARTFrame.receivedFrame(buf);
		}

		/* frame waiting to be processed */
		atomic next_recv_byte_sync = next_recv_byte;
		if (!next_recv_byte_sync)
		{
			atomic {
				/* switch buffer */
				ptr = receiveBufferPtr;
				receiveBufferPtr = handleBufferPtr;
				handleBufferPtr = ptr;
	
				/* unblock reception */
				next_recv_byte = receiveBufferPtr;
			}

			/* handle receiveed frame */				
			post packet_recv();
		} else {

			/* frame handling complete */
			atomic handlingFrame = FALSE;
		}
			
	}

}
