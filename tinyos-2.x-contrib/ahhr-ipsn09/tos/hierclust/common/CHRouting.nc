/*
 * IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 * downloading, copying, installing or using the software you agree to
 * this license.  If you do not agree to this license, do not download,
 * install, copy or use the software.
 *
 * Copyright (c) 2006-2008 Vrije Universiteit Amsterdam and
 * Development Laboratories (DevLab), Eindhoven, the Netherlands.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions, the author, and the following
 *   disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions, the author, and the following disclaimer
 *   in the documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Vrije Universiteit Amsterdam, nor the name of
 *   DevLab, nor the names of their contributors may be used to endorse or
 *   promote products derived from this software without specific prior
 *   written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL VRIJE
 * UNIVERSITEIT AMSTERDAM, DEVLAB, OR THEIR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Authors: Konrad Iwanicki
 * CVS id: $Id: CHRouting.nc,v 1.1 2009/04/07 08:42:26 iwanicki Exp $
 */
#include "ClusterHierarchy.h"


/**
 * An interface for hierarchical forwarding.
 *
 * @author Konrad Iwanicki &lt;iwanicki@few.vu.nl&gt;
 */
interface CHRouting {

    /**
     * Returns the size of a header for a routing message.
     * @return the size of a routing message header
     */
    command uint8_t getRoutingHeaderSize();
    
    /**
     * Clears the header of a routing message.
     * The message can now be initialized with user data.
     * @param hdr a pointer to the routing header
     */
    command void clearRoutingHeader(nx_ch_routing_message_header_t * hdr);

    /**
     * Sets the length of the destination label.
     * @param hdr a pointer to the routing header
     * @param len the length to set
     * @return <code>SUCCESS</code>, if the length was set successfully,
     *         or <code>EINVAL</code>, if the length was invalid
     */
    command error_t setRoutingHeaderDstLabelLength(
        nx_ch_routing_message_header_t * hdr, uint8_t len);

    /**
     * Returns the length of the destination label.
     * The method assumes that the header is correct.
     * @param hdr a pointer to the routing header
     * @return the length of the destination label or <code>0</code> if no
     *         destination label is present
     */
    command uint8_t getRoutingHeaderDstLabelLength(
        nx_ch_routing_message_header_t const * hdr);

    /**
     * Sets a given element of the destination label.
     * @param hdr a pointer to the routing header
     * @param i the level at which the element is to be set
     * @param val the value of the element
     * @return <code>SUCCESS</code>, if the element was set successfully,
     *         or <code>EINVAL</code>, if the level or the element value
     *         was invalid
     */
    command error_t setRoutingHeaderDstLabelElement(
        nx_ch_routing_message_header_t * hdr, uint8_t i, uint16_t val);

    /**
     * Returns a given element of the destination label.
     * The method assumes that the header is correct.
     * @param hdr a pointer to the routing header
     * @param i the level at which the element is to be returned
     * @return the element value or <code>CH_INVALID_CLUSTER_HEAD</code>
     *         if the level is invalid
     */
    command uint16_t getRoutingHeaderDstLabelElement(
        nx_ch_routing_message_header_t const * hdr, uint8_t i);

    /**
     * Analyzes the header of the routing message.
     * Looks up the next routing hop for the message.
     * If the hop has been found, the header is updated to account
     * for the expected forwarding.
     * @param hdr a pointer to the routing header of the message
     * @return the link-layer address of the next-hop neighbor to which
     *         the message should be forwarded, the link-layer address of
     *         the present node, if it is the recipient of the message, or
     *         <code>AM_BROADCAST_ADDR</code> if the next hop could
     *          not be found
     */
    command am_addr_t getNextRoutingHop(nx_ch_routing_message_header_t * hdr);

}
