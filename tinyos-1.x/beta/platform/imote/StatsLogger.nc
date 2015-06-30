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
interface StatsLogger {

    /*
     * This command is used to add a value to a predefined counter
     */
    command result_t BumpCounter(uint8 counter_type, uint32 value);

    /*
     * This command overwrites the counter with the passed value
     */
    command result_t OverwriteCounter(uint8 counter_type, uint32 value);

    /*
     * This command captures the value of the local time, a later call
     * to StopTimerUpdateCounter will subtract the stored local time value 
     * from the new time and bump up the specified counter with that value
     */
    command result_t StartTimer(uint8 counter_type);

    command result_t StopTimerUpdateCounter(uint8 counter_type);

    /*
     * This command resets all the counters
     */
    command result_t ResetCounters();

    /*
     * This command prints the counter values into a buffer in the 
     * following format:
     * First byte contains number of counters
     * For each counter, it will add the following info
     * type <1B>, len <1B>, value <len B>
     */
    command uint8 *GetCounterBuffer(uint32 *buffer_size);

    /*
     * This command frees the buffer
     */
    command result_t FreeCounterBuffer(uint8 *CounterBuffer);

}

