/* "Copyright (c) 2000-2002 The Regents of the University of California.  
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
 */

// Authors: Cory Sharp
// $Id: ServiceM.nc,v 1.4 2003/10/04 00:10:16 cssharp Exp $

//!! Config 133 { uint8_t invoke_service = 0; }
//!! Config 134 { uint8_t running_service = 0; }
//!! Config 135 { uint8_t initial_service = 0; }

includes Config;

module ServiceM
{
  provides interface StdControl;
  uses interface StdControl as Service[ uint8_t service ];
  uses interface Config_invoke_service;
  uses interface RoutingReceive as ServiceControlMsg;
  uses interface MsgBuffers;
}
implementation
{
  enum
  {
    SERVICE_START = 1,
    SERVICE_STOP = 2,
    SERVICE_INIT = 9,
  };

  bool m_is_running;
  TOS_MsgPtr m_msg;

  task void change_service()
  {
    call Service.stop[ G_Config.running_service ]();
    call Service.start[ G_Config.invoke_service ]();
    G_Config.running_service = G_Config.invoke_service;
  }

  command result_t StdControl.init()
  {
    m_is_running = FALSE;
    m_msg = NULL;

    call MsgBuffers.init();

    //uint8_t service = 0;
    //do { call Service.init[service++](); }
    //while( service != 0 );

    call Service.init[0]();
    call Service.init[1]();
    call Service.init[2]();
    call Service.init[3]();
    call Service.init[4]();
    call Service.init[5]();
    call Service.init[6]();
    call Service.init[7]();
    call Service.init[8]();
    call Service.init[9]();
    call Service.init[10]();
    call Service.init[11]();
    call Service.init[12]();
    call Service.init[13]();
    call Service.init[14]();
    call Service.init[15]();
    call Service.init[16]();
    call Service.init[17]();
    call Service.init[18]();
    call Service.init[19]();
    call Service.init[20]();
    call Service.init[21]();
    call Service.init[22]();
    call Service.init[23]();
    call Service.init[24]();
    call Service.init[25]();
    call Service.init[26]();
    call Service.init[27]();
    call Service.init[28]();
    call Service.init[29]();
    call Service.init[30]();
    call Service.init[31]();
    call Service.init[32]();
    call Service.init[33]();
    call Service.init[34]();
    call Service.init[35]();
    call Service.init[36]();
    call Service.init[37]();
    call Service.init[38]();
    call Service.init[39]();
    call Service.init[40]();
    call Service.init[41]();
    call Service.init[42]();
    call Service.init[43]();
    call Service.init[44]();
    call Service.init[45]();
    call Service.init[46]();
    call Service.init[47]();
    call Service.init[48]();
    call Service.init[49]();
    call Service.init[50]();
    call Service.init[51]();
    call Service.init[52]();
    call Service.init[53]();
    call Service.init[54]();
    call Service.init[55]();
    call Service.init[56]();
    call Service.init[57]();
    call Service.init[58]();
    call Service.init[59]();
    call Service.init[60]();
    call Service.init[61]();
    call Service.init[62]();
    call Service.init[63]();
    call Service.init[64]();
    call Service.init[65]();
    call Service.init[66]();
    call Service.init[67]();
    call Service.init[68]();
    call Service.init[69]();
    call Service.init[70]();
    call Service.init[71]();
    call Service.init[72]();
    call Service.init[73]();
    call Service.init[74]();
    call Service.init[75]();
    call Service.init[76]();
    call Service.init[77]();
    call Service.init[78]();
    call Service.init[79]();
    call Service.init[80]();
    call Service.init[81]();
    call Service.init[82]();
    call Service.init[83]();
    call Service.init[84]();
    call Service.init[85]();
    call Service.init[86]();
    call Service.init[87]();
    call Service.init[88]();
    call Service.init[89]();
    call Service.init[90]();
    call Service.init[91]();
    call Service.init[92]();
    call Service.init[93]();
    call Service.init[94]();
    call Service.init[95]();
    call Service.init[96]();
    call Service.init[97]();
    call Service.init[98]();
    call Service.init[99]();
    call Service.init[100]();
    call Service.init[101]();
    call Service.init[102]();
    call Service.init[103]();
    call Service.init[104]();
    call Service.init[105]();
    call Service.init[106]();
    call Service.init[107]();
    call Service.init[108]();
    call Service.init[109]();
    call Service.init[110]();
    call Service.init[111]();
    call Service.init[112]();
    call Service.init[113]();
    call Service.init[114]();
    call Service.init[115]();
    call Service.init[116]();
    call Service.init[117]();
    call Service.init[118]();
    call Service.init[119]();
    call Service.init[120]();
    call Service.init[121]();
    call Service.init[122]();
    call Service.init[123]();
    call Service.init[124]();
    call Service.init[125]();
    call Service.init[126]();
    call Service.init[127]();
    call Service.init[128]();
    call Service.init[129]();
    call Service.init[130]();
    call Service.init[131]();
    call Service.init[132]();
    call Service.init[133]();
    call Service.init[134]();
    call Service.init[135]();
    call Service.init[136]();
    call Service.init[137]();
    call Service.init[138]();
    call Service.init[139]();
    call Service.init[140]();
    call Service.init[141]();
    call Service.init[142]();
    call Service.init[143]();
    call Service.init[144]();
    call Service.init[145]();
    call Service.init[146]();
    call Service.init[147]();
    call Service.init[148]();
    call Service.init[149]();
    call Service.init[150]();
    call Service.init[151]();
    call Service.init[152]();
    call Service.init[153]();
    call Service.init[154]();
    call Service.init[155]();
    call Service.init[156]();
    call Service.init[157]();
    call Service.init[158]();
    call Service.init[159]();
    call Service.init[160]();
    call Service.init[161]();
    call Service.init[162]();
    call Service.init[163]();
    call Service.init[164]();
    call Service.init[165]();
    call Service.init[166]();
    call Service.init[167]();
    call Service.init[168]();
    call Service.init[169]();
    call Service.init[170]();
    call Service.init[171]();
    call Service.init[172]();
    call Service.init[173]();
    call Service.init[174]();
    call Service.init[175]();
    call Service.init[176]();
    call Service.init[177]();
    call Service.init[178]();
    call Service.init[179]();
    call Service.init[180]();
    call Service.init[181]();
    call Service.init[182]();
    call Service.init[183]();
    call Service.init[184]();
    call Service.init[185]();
    call Service.init[186]();
    call Service.init[187]();
    call Service.init[188]();
    call Service.init[189]();
    call Service.init[190]();
    call Service.init[191]();
    call Service.init[192]();
    call Service.init[193]();
    call Service.init[194]();
    call Service.init[195]();
    call Service.init[196]();
    call Service.init[197]();
    call Service.init[198]();
    call Service.init[199]();
    call Service.init[200]();
    call Service.init[201]();
    call Service.init[202]();
    call Service.init[203]();
    call Service.init[204]();
    call Service.init[205]();
    call Service.init[206]();
    call Service.init[207]();
    call Service.init[208]();
    call Service.init[209]();
    call Service.init[210]();
    call Service.init[211]();
    call Service.init[212]();
    call Service.init[213]();
    call Service.init[214]();
    call Service.init[215]();
    call Service.init[216]();
    call Service.init[217]();
    call Service.init[218]();
    call Service.init[219]();
    call Service.init[220]();
    call Service.init[221]();
    call Service.init[222]();
    call Service.init[223]();
    call Service.init[224]();
    call Service.init[225]();
    call Service.init[226]();
    call Service.init[227]();
    call Service.init[228]();
    call Service.init[229]();
    call Service.init[230]();
    call Service.init[231]();
    call Service.init[232]();
    call Service.init[233]();
    call Service.init[234]();
    call Service.init[235]();
    call Service.init[236]();
    call Service.init[237]();
    call Service.init[238]();
    call Service.init[239]();
    call Service.init[240]();
    call Service.init[241]();
    call Service.init[242]();
    call Service.init[243]();
    call Service.init[244]();
    call Service.init[245]();
    call Service.init[246]();
    call Service.init[247]();
    call Service.init[248]();
    call Service.init[249]();
    call Service.init[250]();
    call Service.init[251]();
    call Service.init[252]();
    call Service.init[253]();
    call Service.init[254]();
    call Service.init[255]();

    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    if( call Service.start[ G_Config.initial_service ]() == SUCCESS )
    {
      G_Config.running_service = G_Config.initial_service;
    }
    else
    {
      G_Config.running_service = 0;
    }
    m_is_running = TRUE;
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    m_is_running = FALSE;
    call Service.stop[ G_Config.running_service ]();
    G_Config.invoke_service = G_Config.running_service;
    G_Config.running_service = 0;
    return SUCCESS;
  }

  event void Config_invoke_service.updated()
  {
    if( m_is_running != FALSE )
      post change_service();
  }

  default command result_t Service.init[ uint8_t service ]()
  {
    return FAIL;
  }

  default command result_t Service.start[ uint8_t service ]()
  {
    return FAIL;
  }

  default command result_t Service.stop[ uint8_t service ]()
  {
    return FAIL;
  }

  void service_control( TOS_MsgPtr msg )
  {
    uint8_t i;
    uint8_t imax = msg->length & 0xfe; //round down to an even number
    for( i=0; i<imax; i+=2 )
    {
      switch( msg->data[i] )
      {
	case SERVICE_INIT:
	  call Service.init[msg->data[i+1]]();
	  break;
	case SERVICE_START:
	  call Service.start[msg->data[i+1]]();
	  break;
	case SERVICE_STOP:
	  call Service.stop[msg->data[i+1]]();
	  break;
      }
    }
  }

  task void service_control_task()
  {
    service_control( m_msg );
    call MsgBuffers.free( m_msg );
    m_msg = NULL;
  }

  event TOS_MsgPtr ServiceControlMsg.receive( TOS_MsgPtr msg )
  {
    TOS_MsgPtr retmsg = msg;
    if( m_msg == NULL )
    {
      if( (retmsg = call MsgBuffers_alloc_for_swap(msg)) == NULL )
      {
	// no swap buffers available, perform service control within receive
	retmsg = msg;
	service_control( msg );
      }
      else
      {
	// swap buffers available, perform service control within a task
	m_msg = msg;
	post service_control_task();
      }
    }
    return retmsg;
  }
}

