/*
 * Copyright (c) 2007, RWTH Aachen University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL RWTH AACHEN UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF RWTH AACHEN
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * RWTH AACHEN UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND RWTH AACHEN UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 */
 
 /**
 * @author Krisakorn Rerkrai <kre@mobnets.rwth-aachen.de>
 **/
 
includes ulla;
includes msg_type;

interface LinkProviderIf {

   
    command uint8_t execCmd(CmdDescr_t* cmdDescr);

    command uint8_t requestUpdate(RuId_t ruId, RuDescr_t* ruDescr, AttrDescr_t* attrDescr);

    command uint8_t cancelUpdate(RuId_t ruId);

    command uint8_t getAttribute (AttrDescr_t* attDescr);
    event result_t getAttributeDone (AttrDescr_t* attDescr, uint8_t *result);

    command uint8_t setAttribute(AttrDescr_t* attDescr);

    command void freeAttribute(AttrDescr_t* attDescr);
}
 
