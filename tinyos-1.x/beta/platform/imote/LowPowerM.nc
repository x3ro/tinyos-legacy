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

#define ACTIVE_MODE 0
#define HOLD_MODE   1
#define SNIFF_MODE  2
#define PARK_MODE   3

#define MAX_NODES 10

//#define LP_DEBUG

module LowPowerM {
    provides {
        interface LowPower;
    }
    uses {
        interface HCILinkPolicy;
        interface HCIBaseband;
        interface NetworkTopology;
        interface Timer;
    }
}
implementation {
#define TRACE_DEBUG_LEVEL 0ULL

    uint16 min_sleep, max_sleep;
    uint8 low_power_enabled;
    uint8 num_handle, handle_completed, handle_flag[MAX_NODES];
    tHandle handle[MAX_NODES];

    tHandle GlobalHandle;
    #define WAKEUP_DELAY 500 // 500ms

    command result_t LowPower.init(uint16 min_sleep_slots, uint16 max_sleep_slots) {
        TM_DisableDeepSleep(TM_DEEPSLEEP_APLICATION_ID_1);
        min_sleep = min_sleep_slots;
        max_sleep = max_sleep_slots;
        low_power_enabled = 0;
        return SUCCESS;
    }

    command result_t LowPower.EnterLowPower(uint32 *nodeID, uint8 numNodes) {
        uint8 i;
        low_power_enabled = 1;
        num_handle = numNodes;
        for (i=0; i<numNodes; i++) {
            call NetworkTopology.GetNextConnection (nodeID[i], NULL, &handle[i]);
            call HCILinkPolicy.Hold_Mode (handle[i], min_sleep, max_sleep);
            trace(TRACE_DEBUG_LEVEL,"Entering low power for node %05X, handle %d\r\n", nodeID[i], handle[i]);
            handle_flag[i] = 0;
        }
        handle_completed = 0;
        signal LowPower.PowerModeChange(true);
        trace(TRACE_DEBUG_LEVEL,"PowerModeChange signaled, true\r\n");
        return SUCCESS;
    }

    event result_t HCILinkPolicy.Mode_Change (uint8 Status, uint16 Connection_Handle,
                              uint8 Current_Mode, uint16 Interval) {
        uint8 i, handle_exist;
        trace(TRACE_DEBUG_LEVEL,"Mode change status %d, handle %d, mode %d\r\n", Status, Connection_Handle, Current_Mode);
        
        // check to see if all links have entered hold
        if (low_power_enabled && (Current_Mode==HOLD_MODE)) {

            for (i=0; i<num_handle; i++)
                if (handle[i] == Connection_Handle) {
                    if (!handle_flag[i])
                        handle_completed++;
                    handle_flag[i] = 1;
                }
            if (handle_completed == num_handle)
                signal LowPower.EnterLowPowerComplete();
        }

        if (low_power_enabled && (Current_Mode==ACTIVE_MODE)) {
            handle_exist = 0;
            for (i=0; i<num_handle; i++)
                if (handle[i] == Connection_Handle) 
                    handle_exist = 1;
            if (handle_exist) {
              GlobalHandle = Connection_Handle;
              call HCILinkPolicy.Hold_Mode (GlobalHandle, min_sleep, max_sleep);
//              call Timer.start(TIMER_ONE_SHOT, WAKEUP_DELAY);
            }
        }

        return SUCCESS;
    }

    event result_t Timer.fired() {
      call HCILinkPolicy.Hold_Mode (GlobalHandle, min_sleep, max_sleep);
      return SUCCESS;
    }

    command result_t LowPower.ExitLowPower() {
        low_power_enabled = 0;
        signal LowPower.PowerModeChange(false);
        trace(TRACE_DEBUG_LEVEL,"PowerModeChange signaled, false\r\n");
        return SUCCESS;
    }

    command result_t LowPower.EnterDeepSleep() {
        TM_EnableDeepSleep(TM_DEEPSLEEP_APLICATION_ID_1);
        return SUCCESS;
    }

    command result_t LowPower.ExitDeepSleep() {
        TM_DisableDeepSleep(TM_DEEPSLEEP_APLICATION_ID_1);
        return SUCCESS;
    }


    // unused events
    event result_t HCILinkPolicy.Role_Change (uint8 Status,
                              tBD_ADDR BD_ADDR,
                              uint8 New_Role) {
        return SUCCESS;
    }

    event result_t HCILinkPolicy.Command_Complete_Role_Discovery (uint8 Status,
                                                  tHandle Connection_Handle,
                                                  uint8 Current_Role) {
        return SUCCESS;
    }

    event result_t HCIBaseband.Command_Complete_Write_Scan_Enable ( uint8 Scan_Enable) {
        return SUCCESS;
    }

    event result_t HCIBaseband.Command_Complete_Read_Link_Supervision_Timeout (uint8 Reason, tHandle Connection_Handle, uint16 Timeout ) {
        return SUCCESS;
    }


    event result_t HCIBaseband.Command_Complete_Write_Current_IAC_LAP (uint8 Status) {
        return SUCCESS;
    }

    event result_t HCIBaseband.Command_Complete_Read_Transmit_Power_Level(
                                                  uint8 Status,
                                                  tHandle Connection_Handle,
                                                  int8_t Transmit_Power_Level) {
      return SUCCESS;
    }

}
