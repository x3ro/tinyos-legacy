/* Copyright (c) 2007 Dartmouth SensorLab.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * paragraph and the author appear in all copies of this software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

/* The funneling-MAC code.
 *
 * Authors: Gahng-Seop Ahn   <ahngang@ee.columbia.edu>,
 *          Emiliano Miluzzo <miluzzo@cs.dartmouth.edu>.
 */

interface Query {
  event result_t StartSendData(uint16_t rate);
  command result_t StartSendQuery(bool sendQuery, uint16_t rate);
}
