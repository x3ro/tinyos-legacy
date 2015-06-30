/*
 * Copyright (c) 2006
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

/**
 * <pre>URL: http://www.eecs.harvard.edu/~konrad/projects/shimmer</pre>
 * @author Konrad Lorincz
 * @version 1.0, November 10, 2006
 */


// If defined, the sampling interval is generated directly by TimerA;  else, it uses TimerC
#define MCS_USE_TIMERA

configuration MultiChanSamplingC 
{
    provides interface MultiChanSampling;
}
implementation 
{
    components Main, MultiChanSamplingM;

    MultiChanSampling = MultiChanSamplingM;

    Main.StdControl -> MultiChanSamplingM;

    components HPLADC12M;
    MultiChanSamplingM.HPLADC12 -> HPLADC12M;

#ifdef MCS_USE_TIMERA
    components MSP430TimerC;
    MultiChanSamplingM.TimerA -> MSP430TimerC.TimerA;
    MultiChanSamplingM.ControlA0 -> MSP430TimerC.ControlA0;
    MultiChanSamplingM.CompareA0 -> MSP430TimerC.CompareA0;
#else
    components TimerC;
    Main.StdControl -> TimerC;
    MultiChanSamplingM.Timer -> TimerC.Timer[unique("Timer")];
    MultiChanSamplingM.LocalTime -> TimerC;
#endif
}


