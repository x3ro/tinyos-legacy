/*
 * Copyright (c) 2004, Intel Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the Intel Corporation nor the names of its contributors
 * may be used to endorse or promote products derived from this software
 * without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * The HCI interface is dcoumented in the Bluetooth Specifications and will not
 * be explained here.  The parameter list order and size should match the
 * parameter list at the beginning of the packet described in the specification.
 * This interface abstracts the Link Control commands and events.
 */

includes HCITypes;

interface HCILinkControl {

  command result_t Inquiry( tLAP LAP,
                            uint8 Inquiry_Length,
                            uint8 Num_Responses);

  command result_t Inquiry_Cancel( );

  command result_t Periodic_Inquiry_Mode( uint16 Max_Period_Length,
                                          uint16 Min_Period_Length,
                                          tLAP LAP,
                                          uint8 Inquiry_Length,
                                          uint8 Num_Responses);

  command result_t Create_Connection( tBD_ADDR BD_ADDR,
                                      uint16 Packet_Type,
                                      uint8 Page_Scan_Repetition_Mode,
                                      uint8 Page_Scan_Mode,
                                      uint16 Clock_Offset,
                                      uint8 Allow_Role_Switch);

  command result_t Disconnect( tHandle Connection_Handle,
                               uint8 Reason);

  command result_t Accept_Connection_Request( tBD_ADDR BD_ADDR,
                                              uint8 Role);

  command result_t Reject_Connection_Request( tBD_ADDR BD_ADDR,
                                              uint8 Role);

  event result_t Command_Status_Inquiry(uint8 Status);

  event result_t Inquiry_Result( uint8 Num_Responses,
                                 tBD_ADDR *BD_ADDR_ptr,
                                 uint8 *Page_Scan_Repetition_Mode_ptr,
                                 uint8 *Page_Scan_Period_Mode,
                                 uint8 *Page_Scan_Mode,
                                 uint32 *Class_of_Device,
                                 uint16 *Clock_Offset);

  event result_t Inquiry_Complete( uint8 Status );

  event result_t Command_Complete_Inquiry_Cancel( uint8 Status );

  event result_t Connection_Complete( uint8 Status,
                                      tHandle Connection_Handle,
                                      tBD_ADDR BD_ADDR,
                                      uint8 Link_Type,
                                      uint8 Encryption_Mode);

  event result_t Connection_Request( tBD_ADDR BD_ADDR,
                                     uint32 Class_of_Device,//3 bytes meaningful
                                     uint8 Link_Type);

  event result_t Disconnection_Complete( uint8 Status,
                                         tHandleId Connection_Handle,
                                         uint8 Reason);



}
