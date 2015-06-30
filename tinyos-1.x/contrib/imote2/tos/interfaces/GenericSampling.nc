/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/** 
 * A sampling interface. Note that where sampling data is collected and
 * how that data is recovered is up to each sampling component
 * This interface is based on the original Sampling interface developed by
 * IRB and has been modified to support new features.
 */

includes GenericSampling;
interface GenericSampling {
  /**
   * Prepare to peform sampling. 
   * @param channel The sensor channel id
   * @param samplingRate The sampling rate specified in Hz
   * @param numSamples The number of samples to collect
   * @param sampleWidth The number of bits per sample 
   * @param streaming TRUE for streaming (sampling will only
   *   end when stop is called.
   * @param warmup The sensor warmup time in microseconds, this will imply
   *   that once the start function is called, the sensor will turn on and 
   *   the samples will be dropped for at least warmup microseconds
   * @param type The sensor type to be sampled.  Some boards might expose 
   *   multiple type sensors on one channel.  The value is an enum that is 
   *   sensor board specific
   * @param function The sensor driver can support some form of post 
   *   processing capability (e.g. average, FFT, etc).  This supported values
   *   in this field will be sensor board specfic. Note that the meaning 
   *   of the numSamples parameter will be dependent on the post processing 
   *   function.
   * @param other this is an array of type value pairs that will capture
   *   board specific parameters that don't need to be applied to all boards
   *   The last item in the array will have a type 0 to indidate end of list
   * @return If the result is SUCCESS, <code>ready</code> will be signaled
   *   If the result is FAIL, no sampling will happen.
   */
  command result_t prepare(uint8_t channel, uint32_t samplingRate, 
                           uint32_t numSamples, uint8_t sampleWidth, 
                           bool streaming, uint32_t warmup, uint32_t type, 
                           uint32_t function, TypeValItem *other);

  /**
   * Prepare a trigger channel
   * @param channel The sensor channel id
   * @param samplingRate The sampling rate specified in Hz
   * @param numSamples The number of samples to collect
   * @param sampleWidth The number of bits per sample 
   * @param streaming TRUE for streaming (sampling will only
   *   end when stop is called.
   * @param warmup The sensor warmup time in microseconds, this will imply
   *   that once the start function is called, the sensor will turn on and 
   *   the samples will be dropped for at least warmup microseconds
   * @param type The sensor type to be sampled.  Some boards might expose 
   *   multiple type sensors on one channel.  The value is an enum that is 
   *   sensor board specific
   * @param function The sensor driver can support some form of post 
   *   processing capability (e.g. average, FFT, etc).  This supported values
   *   in this field will be sensor board specfic. Note that the meaning 
   *   of the numSamples parameter will be dependent on the post processing 
   *   function.
   * @param other this is an array of type value pairs that will capture
   *   board specific parameters that don't need to be applied to all boards
   *   The last item in the array will have a type 0 to indidate end of list
   * @param storeData if TRUE the trigger channel is sampled like a regular
   *   channel and the data is stored in the same way.  If FALSE, the trigger
   *   channel data is just used for the purpose of triggering another channel
   * @return If the result is SUCCESS, <code>ready</code> will be signaled
   *   If the result is FAIL, no sampling will happen.
   */
  command result_t prepareTrigger(uint8_t channel, uint32_t samplingRate, 
                                  uint32_t numSamples, uint8_t sampleWidth, 
                                  bool streaming, uint32_t warmup, 
                                  uint32_t type, uint32_t function, 
                                  TypeValItem *other, bool storeData);


  /**
   * Report if sampling can be started
   * @param channel The sensor channel id
   * @param ok SUCCESS if sampling can be started by calling 
   *   <code>start</code>, FAIL otherwise
   * @return Ignored
   */
  event result_t prepareDone(uint8_t channel, result_t ok);

  /** 
   * Start sampling requested by previous <code>prepare</code>
   *   If multiple channels are being passed in a list, then the sensor
   *   board will start all the channel simultaneously if supported.  However
   *   if individual start calls are executed, these channels are assumed to
   *   be independent. 
   *   If a trigger is setup and linked to a target channel, when the target 
   *   channel is started, the trigger channel will be started instead and 
   *   the target channel will only be started if the trigger is invoked.
   * @param numChannels The number of channels listed in the channelList
   * @param channelList An array of channel id values to be started
   * @param timeout if the complete collection is not done within timeout
   *   msec, the board will stop the capture and signal the samplingDone
   *   with a timeout error condition
   * @return SUCCESS if sampling started (<code>done</code> will be signaled
   *   when it complates), FAIL if it didn't.
   */
  command result_t start(uint8_t numChannels, 
			 uint8_t *channelList, 
                         uint32_t timeout);

  /** 
   * Stop sampling started by earlier <code>start</code>
   * @param numChannels The number of channels listed in the channelList
   * @param channelList An array of channel id values to be started
   * @return SUCCESS if sampling can be stopped (<code>done</code> will 
   *   be signaled shortly), FAIL if it can't.
   */
  command result_t stop(uint8_t numChannels, uint8_t *channelList);

  /**
   * Report sampling completion
   * @param channel The sensor channel id
   * @param status SUCCESS if sampling was succesful, FAIL if it failed. Failure
   *   may be due to the sampling interval being too short or to a data
   *   logging problem.
   * @param numSamples Number of samples of data collected
   * @return Ignored
   */
  event result_t samplingDone(uint8_t channel, 
			      result_t status, 
                              uint32_t numSamples);

  /**
   * This function supports triggering channel sampling from one or many
   *   channels based on the behavior of a trigger channel.
   * 
   * @param boolOp Boolean operation to combine different triggers.  
   *   Supported enum is board specific
   * @param triggerFunction The supported functions are board specific
   *   examples are rising edge, falling edge, max, min, average
   * @param triggerValue The tigger function evaluates the function and 
   *   compares to the value to evaulate the trigger
   * @param triggerChannel the channel id of the trigger
   * @param targetChannel the channel id of the triggered channel 
   * 
   * @return SUCCESS indicates the trigger was setup
   */
  command result_t AddTrigger(uint8_t boolOp, 
			      uint32_t triggerFunction,
                              float triggerValue, 
                              uint32_t triggerWindowSamples, 
                              uint8_t triggerChannel, 
			      uint8_t targetChannel);

  /**
   * This function clears the preset trigger functionality
   * 
   * @param targetChannel the channel id of the target channel
   */
  command void ClearTrigger(uint8_t targetChannel);

  /**
   * Report that a target channel has been triggered (trigger invoked)
   * @param channel The target channel id 
   * @return Ignored
   */
  event result_t TargetChannelTriggered(uint8_t channel);

  /**
   * Retrieve information about a supported board feature
   * @param feature supported list of features to be interogated is board
   *   specific.  This will be an enumerated list that is defined across
   *   sensor boards, and each sensor board will support a subset of the
   *   range.  There is a special feature (type 0), which will return the
   *   list of supported features by this board rather than the infromation
   *   about a specific feature.
   * @param options This is an array options relating to the passed feature
   *   The driver will allocate the array.  The caller shouldn't modify 
   *   the contents of the array, nor can it assume that the array will
   *   persist after the function returns.
   * @return The function returns the number of entries in the array
   *   0 means that the feature is not supported
   */
  command uint32_t GetSupportedFeature(uint32_t feature, uint32_t *options);

  /**
   * Returns the actual data width of the sample returned by the board
   *   given a desired sample width.  e.g. the caller can request 14 bit
   *   samples and the board can pack it into 16 bit samples. It also
   *   indicates the endianess of the samples
   * @param sampleWidth desired number of bits per sample
   * @param dataWidth driver will return the data width in bits used to
   *   pack these samples
   * @param littleEndian driver will return the endianess of the data.  
   *   FALSE for little endian, FALSE for big endian
   *   
   */ 
  command void getSampleInfo(uint8_t sampleWidth, uint8_t *dataWidth, 
                             bool *littleEndian);
}
