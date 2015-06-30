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
 * This interface encapsulates the Link Policy commands and events
 */

includes HCITypes;

interface HCILinkPolicy {

  command result_t Hold_Mode( tHandle Connection_Handle,
                              uint16 Hold_Mode_Max_Interval,
                              uint16 Hold_Mode_Min_Interval);

  command result_t Sniff_Mode( tHandle Connection_Handle,
                               uint16 Sniff_Max_Interval,
                               uint16 Sniff_Min_Interval,
                               uint16 Sniff_Attempt,
                               uint16 Sniff_Timeout);

  command result_t Exit_Sniff_Mode( tHandle Connection_Handle);

  command result_t Park_Mode( tHandle Connection_Handle,
                              uint16 Beacon_Max_Interval,
                              uint16 Beacon_Min_Interval);

  command result_t Exit_Park_Mode( tHandle Connection_Handle);

  command result_t Role_Discovery( tHandle Connection_Handle);

  command result_t Switch_Role( tBD_ADDR BD_ADDR, uint8 Role);

  command result_t Write_Link_Policy_Settings( tHandle Connection_Handle,
                                               uint16 Link_Policy_Settings);

  event result_t Role_Change( uint8 Status,
                              tBD_ADDR BD_ADDR,
                              uint8 New_Role);

  event result_t Command_Complete_Role_Discovery( uint8 Status,
                                                  tHandle Connection_Handle,
                                                  uint8 Current_Role);

  event result_t Mode_Change( uint8 Status, uint16 Connection_Handle,
                              uint8 Current_Mode, uint16 Interval);


}
