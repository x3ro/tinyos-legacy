/* 
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2005/11/17 13:59:26 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */
configuration PSAttributeContainerC {
  provides interface PSValue[uint16_t attrID];
  provides interface PSOperation[uint16_t attrID];
}
implementation {
  components Main
    , PingAttributeM
    , RandomAttributeM, RandomLFSR
    , new PSLocalAttributesC(7, 18) as LocalAttributes
#if defined(PLATFORM_EYESIFXV2)
    , new EyesIFXSensorC(0) as ExternalTemp
    , new EyesIFXSensorC(2) as Light
    , new EyesIFXSensorC(3) as RSSI
    , new EyesIFXSensorC(10) as InternalTemp
    , new EyesIFXSensorC(11) as Battery
#endif
    ;
  
  Main.StdControl -> PingAttributeM;
  PSValue[17] = PingAttributeM.PSValue;
  PSOperation[17] = PingAttributeM.PSOperation;
  
  Main.StdControl -> LocalAttributes;
  PSValue[18] = LocalAttributes.PSValue;
  PSOperation[18] = LocalAttributes.PSOperation;

  Main.StdControl -> RandomAttributeM;
  PSValue[19] = RandomAttributeM.PSValue;
  PSOperation[19] = RandomAttributeM.PSOperation;
  RandomAttributeM.Random -> RandomLFSR;

#if defined(PLATFORM_EYESIFXV2)
  Main.StdControl -> ExternalTemp;
  PSValue[0] = ExternalTemp.PSValue;
  PSOperation[0] = ExternalTemp.PSOperation;

  Main.StdControl -> Light;
  PSValue[2] = Light.PSValue;
  PSOperation[2] = Light.PSOperation;

  Main.StdControl -> RSSI;
  PSValue[3] = RSSI.PSValue;
  PSOperation[3] = RSSI.PSOperation;

  Main.StdControl -> InternalTemp;
  PSValue[10] = InternalTemp.PSValue;
  PSOperation[10] = InternalTemp.PSOperation;

  Main.StdControl -> Battery;
  PSValue[11] = Battery.PSValue;
  PSOperation[11] = Battery.PSOperation;
#endif

}


