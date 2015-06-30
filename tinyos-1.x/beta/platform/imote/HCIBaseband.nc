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
 * This interface encapsulates the HCI Baseband commands and events.
 */

includes HCITypes;

interface HCIBaseband {

  command result_t Set_Event_Filter( uint8 Filter_Type,
                                     uint8 Filter_Condition_Type,
                                     uint8 *Condition);

  command result_t Write_Page_Timeout( uint16 Page_Timeout);

  command result_t Write_Scan_Enable( uint8 Scan_Enable);

  event result_t Command_Complete_Write_Scan_Enable( uint8 Status );

  command result_t Write_Page_Scan_Activity( uint16 Page_Scan_Interval,
                                             uint16 Page_Scan_Window);

  command result_t Write_Inquiry_Scan_Activity( uint16 Inquiry_Scan_Interval,
                                                uint16 Inquiry_Scan_Window);

  command result_t Write_Automatic_Flush_Timeout( tHandle Connection_Handle,
                                                  uint16 Flush_Timeout);

  command result_t Write_Hold_Mode_Activity( uint8 Hold_Mode_Activity);

  command result_t Read_Link_Supervision_Timeout( tHandle Connection_Handle );

  event result_t Command_Complete_Read_Link_Supervision_Timeout( uint8 Reason, tHandle Connection_Handle, uint16 Timeout );

  command result_t Write_Link_Supervision_Timeout( tHandle Connection_Handle,
                                                   uint16 Timeout);

  command result_t Write_Current_IAC_LAP( uint8 Num_Current_IAC, tLAP IAC_LAP);

  event result_t Command_Complete_Write_Current_IAC_LAP( uint8 Status );

  command result_t Read_Transmit_Power_Level( tHandle Connection_Handle, uint8 Type);

  event result_t Command_Complete_Read_Transmit_Power_Level( uint8 Status,
                                                      tHandle Connection_Handle,
                                                      int8_t Transmit_Power_Level);

}
