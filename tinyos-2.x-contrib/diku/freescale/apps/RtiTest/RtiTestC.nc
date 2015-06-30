/* Copyright (c) 2007, Tor Petterson <motor@diku.dk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  - Neither the name of the University of Copenhagen nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * This program test the real-time interrupt and the stop3 mode
 * 
 * @author Tor Petterson <motor@diku.dk>
*/

module RtiTestC
{
  uses interface Boot;
  uses interface StdControl as UartControl;
  uses interface UartStream; 
  uses interface Hcs08Rti as Rti;
  uses interface StdControl as RtiControl;
}
implementation
{
  char* buf1 = "Booted\n";
  char* buf2 = "Im Awake\n";
  
  event void Boot.booted() {
    call RtiControl.start();
    call UartControl.start();
    call UartStream.send(buf1, 7);
  }

  
  async event void Rti.fired()
  {
  	call UartControl.start();
  	call UartStream.send(buf2, 9);
  }
  

  async event void UartStream.sendDone( uint8_t* buf, uint16_t len, error_t error )
  {
  	call UartControl.stop();
  }
  
  async event void UartStream.receivedByte( uint8_t byte )
  {
  }
  
  async event void UartStream.receiveDone( uint8_t* buf, uint16_t len, error_t error )
  {
  }

}

