/* Copyright (c) 2006, Jan Flora <janflora@diku.dk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *  - Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  - Neither the name of the University of Copenhagen nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
  @author Jan Flora <janflora@diku.dk>
*/

includes adts;

interface IeeeAclDescriptor
{
/*	command result_t create( char* buffer,
	                         uint8_t bufferLen,
	                         Ieee_AclDescriptor *aclDescriptor );
	                         
	command char* getBuffer( Ieee_AclDescriptor aclDescriptor );*/
	
	command result_t create( Ieee_AclDescriptor *aclDescriptor );
	command result_t destroy( Ieee_AclDescriptor aclDescriptor );
	
	command void setAclExtendedAddress( Ieee_AclDescriptor aclDescriptor,
	                                    uint64_t aclExtendedAddress );

	command void setAclShortAddress( Ieee_AclDescriptor aclDescriptor,
	                                 uint16_t aclShortAddress );
	                                 
	command void setAclPanId( Ieee_AclDescriptor aclDescriptor,
	                          uint16_t aclPanId );
	                          
	command void setAclSecurityMaterialLength( Ieee_AclDescriptor aclDescriptor,
	                                           uint8_t aclSecurityMaterialLength );

	// To set the security material, use getAclSecurityMaterial and modify the
	// buffer directly
		                                           
	command void setAclSecuritySuite( Ieee_AclDescriptor aclDescriptor,
	                                  uint8_t aclSecuritySuite );

	command uint64_t getAclExtendedAddress( Ieee_AclDescriptor aclDescriptor );
	command uint16_t getAclShortAddress( Ieee_AclDescriptor aclDescriptor );
	command uint16_t getAclPanId( Ieee_AclDescriptor aclDescriptor );
	command uint8_t getAclSecurityMaterialLength( Ieee_AclDescriptor aclDescriptor );
	command uint8_t* getAclSecurityMaterial( Ieee_AclDescriptor aclDescriptor );
	command uint8_t getAclSecuritySuite( Ieee_AclDescriptor aclDescriptor );
}
