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

module BluSHM {
  provides
    {
      interface StdControl;
    }

    uses
      {
        interface StdControl as UartControl;
        interface SendVarLenPacket as UartSend;
        interface ReceiveData as UartReceive;
        
        interface NetworkCommand;
        interface BluSH_AppI[uint8_t id];
      }
}


implementation
{
#include "cmdlinetools.c"
#include "BluSH_types.h"

#define BLUSH_PROMPT_LENGTH 32
  char blush_prompt[ BLUSH_PROMPT_LENGTH ];


  // Index 0 is the current command line.
#define BLUSH_HISTORY_LENGTH 2
#define BLUSH_CMDLINE_LENGTH 40
  char blush_history[ BLUSH_HISTORY_LENGTH ][ BLUSH_CMDLINE_LENGTH ];
  uint16_t blush_cmdline_idx;
  uint16_t blush_history_idx;

  uint8_t funcIdx;
  uint8_t funcIdxInUse;
  char funcCmd[ BLUSH_CMDLINE_LENGTH ];

#define MAX_RETURN_STRING 255


  // Internal commands: help, ls, prompt, readmem, writemem.
  void TraceCallback(char *buf, uint16 buflen) __attribute__((C, spontaneous)){
      call UartSend.send(buf,buflen);
  }
  
  command result_t StdControl.init()
    {
      uint16_t i;
      uint32_t my_nodeid;
 
      blush_cmdline_idx = 0;
      blush_history_idx = 0;

      funcIdxInUse = 0;

      // Clear history.
      for( i = 0; i < BLUSH_HISTORY_LENGTH; i++ )
        {
          blush_history[i][0] = '\0';
        }

      trace_set(DBG_USR1|DBG_USR2|DBG_USR3);
      call UartControl.init();
      call NetworkCommand.GetMoteID(&my_nodeid);
      snprintf(blush_prompt,BLUSH_PROMPT_LENGTH, "%.5x>",my_nodeid);
      //strncpy( blush_prompt, "BluSH>", BLUSH_PROMPT_LENGTH );
      return SUCCESS;
    }
    
  command result_t StdControl.start(){
      call UartControl.start();
      call UartSend.send( "\r\n", strlen("\r\n") );
      call UartSend.send( blush_prompt, strlen(blush_prompt) );
      return SUCCESS;
  }

  command result_t StdControl.stop(){
      call UartControl.stop();
      return SUCCESS;
  }
  
  default command BluSH_result_t BluSH_AppI.getName[uint8_t id](char* buff, uint8_t len )
    {
      buff[0] = '\0';
      return BLUSH_SUCCESS_DONE;
    }

  default command BluSH_result_t BluSH_AppI.callApp[uint8_t id]( char* cmdBuff, uint8_t cmdLen,
                                                                 char* resBuff, uint8_t resLen )
    {
      resBuff[0] = '\0';
      return BLUSH_SUCCESS_DONE;
    }


  task void ls()
    {
      uint8_t i;
      char temp[ BLUSH_CMDLINE_LENGTH ];

      for( i = 0; i < BLUSH_APP_COUNT; i++ )
        {
          call BluSH_AppI.getName[i]( temp, BLUSH_CMDLINE_LENGTH );
          call UartSend.send( temp, strlen(temp) );
          call UartSend.send( "\r\n", 2 );
        }
    } 


  task void help()
    {
      call UartSend.send( "Blue Shell v1.0 (BluSH)\r\n", 
                          strlen("Blue Shell v1.0 (BluSH)\r\n") );
      call UartSend.send( "help - Display this list\r\n", 
                          strlen("help - Display this list\r\n") );
      call UartSend.send( "ls - Display all application commands\r\n", 
                          strlen("ls - Display all application commands\r\n") );
      call UartSend.send( "history - Display the command history\r\n", 
                          strlen("history - Display the command history\r\n") );
      call UartSend.send( "prompt - Allows you to change the prompt\r\n", 
                          strlen("prompt - Allows you to change the prompt\r\n") );
    }


  task void history()
    {
      uint16_t hist_idx;
      for( hist_idx = BLUSH_HISTORY_LENGTH-1; hist_idx > 0; hist_idx-- )
        {
          if( blush_history[ hist_idx ][0] != '\0' )
            {
              call UartSend.send( blush_history[ hist_idx ], 
                                  strlen(blush_history[ hist_idx ]) );
                              
              call UartSend.send( "\r\n", strlen("\r\n") );
            }
        }
    }

  /*
  task void prompt()
    {
      uint16_t frstSpc;
      frstSpc = firstSpace( blush_history[0], 0 );
      if( frstSpc == 0 )
        {
          call UartSend.send( "prompt <new prompt string>\r\n",
                              strlen("prompt <new prompt string>\r\n") );
        }
      else
        {
          strncpy( blush_prompt, &(blush_history[0][frstSpc+1]), BLUSH_PROMPT_LENGTH );
        }
    }
  */


  task void printCmdLine()
    {
      // Print out prompt.
      call UartSend.send( blush_prompt, strlen(blush_prompt) );
      // Last but not least, null terminate the command line.
      blush_history[0][0] = '\0';
      blush_cmdline_idx = 0;
      blush_history_idx = 0;
    }


  task void callFunc()
    {
      char retStr[ MAX_RETURN_STRING ];
      call BluSH_AppI.callApp[funcIdx]( funcCmd, BLUSH_CMDLINE_LENGTH, 
                                        retStr, MAX_RETURN_STRING );

      // Watch out for buffer overflow.
      retStr[ MAX_RETURN_STRING - 1 ] = '\0';
      
      call UartSend.send( retStr, strlen(retStr) );

      funcIdxInUse = 0;
    }

#define UP_ARROW 0x41
#define DOWN_ARROW 0x42
  
  event result_t UartReceive.receive( uint8_t* buff, uint32_t numBytesRead )
    {
      uint16_t i, hist_idx, cmd_idx;
      char temp[ BLUSH_CMDLINE_LENGTH ];

      uint8_t frstSpc;
      static uint8 uSpecialChar=0;
      
      for( i = 0; i < numBytesRead; i++ )
        {
            // Need to look for special characters:
            
          // ENTER is 0x0d
          if( buff[i] == 0x0d )
            {
              // Append \0
              blush_history[0][ blush_cmdline_idx ] = '\0';

              // Output new line.
              call UartSend.send( "\r\n", 2 );

              // Get rid of whitespace.
              killWhiteSpace( blush_history[0] );

              // check if there is anything meaningful
              if( blush_history[0][ 0 ] == '\0' )
                {
                  // Do nothing.
                  post printCmdLine();
                }
              else
                {              
                  // Copy history
                  for( hist_idx = BLUSH_HISTORY_LENGTH-1; hist_idx > 0; hist_idx-- )
                    {
                      // Rollover to 65535 is intentional.
                      cmd_idx = -1;
                      do
                        {
                          cmd_idx++;
                          blush_history[ hist_idx ][ cmd_idx ] = 
                            blush_history[ hist_idx-1 ][ cmd_idx ];
                        }
                      while( cmd_idx < BLUSH_CMDLINE_LENGTH
                             && blush_history[ hist_idx-1 ][ cmd_idx ] != '\0' );
                    }

                  // Process cmdline.
                  // Look for internal commands first, then blush_app commands.
                  if( 0 == strncmp( "help", blush_history[0], strlen("help") ) )
                    {
                      post help();
                      post printCmdLine();
                      
                      /*
                        call UartSend.send( "Blue Shell v1.0 (BluSH) Native Commands\r\n", 
                        strlen("Blue Shell (BluSH) Native Commands\r\n") );

                        call UartSend.send( "help - Display this list\r\n", 
                        strlen("help - Display this list\r\n") );
                        call UartSend.send( "ls - Display all application commands\r\n", 
                        strlen("ls - Display all application commands\r\n") );
                        call UartSend.send( "history - Display the command history\r\n", 
                        strlen("history - Display the command history\r\n") );
                        call UartSend.send( "prompt - Allows you to change the prompt\r\n", 
                        strlen("prompt - Allows you to change the prompt\r\n") );
                      */
                    }
                  else if( 0 == strncmp( "ls", blush_history[0], strlen("ls") ) )
                    {
                      post ls();
                      post printCmdLine();
                      /*
                        for( i = 0; i < BLUSH_APP_COUNT; i++ )
                        {
                        call BluSH_AppI.getName[i]( temp, BLUSH_CMDLINE_LENGTH );
                        call UartSend.send( temp, strlen(temp) );
                        call UartSend.send( "\r\n", 2 );
                        }
                      */
                    }
                  else if( 0 == strncmp( "prompt", blush_history[0], strlen("prompt") ) )
                    {
                      //post prompt();
                      //post printCmdLine();

                      
                      frstSpc = firstSpace( blush_history[0], 0 );
                      if( frstSpc == 0 )
                        {
                          call UartSend.send( "prompt <new prompt string>\r\n",
                                              strlen("prompt <new prompt string>\r\n") );
                        }
                      else
                        {
                          strncpy( blush_prompt, &(blush_history[0][frstSpc+1]), BLUSH_PROMPT_LENGTH );
                        }

                      post printCmdLine();
                      
                    }
                  else if( 0 == strncmp( "history", blush_history[0], strlen("history") ) )
                    {
                      post history();
                      post printCmdLine();

                      /*
                        for( hist_idx = BLUSH_HISTORY_LENGTH-1; hist_idx > 0; hist_idx-- )
                        {
                        if( blush_history[ hist_idx ][0] != '\0' )
                        {
                        call UartSend.send( blush_history[ hist_idx ], 
                        strlen(blush_history[ hist_idx ]) );
                              
                        sprintf( temp, "%d", strlen(blush_history[ hist_idx ]) );
                              
                        //call UartSend.send( temp,
                        //strlen(temp) );
                              

                        call UartSend.send( "\r\n", strlen("\r\n") );
                        }
                        }
                      */
                    }
                  else
                    {
                      if( funcIdxInUse == 0 )
                        {
                          // Loop through app commands.
                          for( i = 0; i < BLUSH_APP_COUNT; i++ )
                            {
                              call BluSH_AppI.getName[i]( temp, BLUSH_CMDLINE_LENGTH );
                              if( (strncmp( temp,
                                            blush_history[0],
                                            strlen(temp)) == 0)
                                  && ((blush_history[0][strlen(temp)] == ' ')
                                      || (blush_history[0][strlen(temp)] == '\0')) )
                                {
                                  funcIdx = i;
                                  funcIdxInUse = 1;
                                  strcpy( funcCmd, blush_history[0] );
                              
                                  post callFunc();
                                  
                                  /*
                                    call BluSH_AppI.callApp[i]( blush_history[0], BLUSH_CMDLINE_LENGTH, 
                                    temp2, BLUSH_CMDLINE_LENGTH );
                                    call UartSend.send( temp2, strlen(temp2) );
                                  */
                                  break;
                                }
                            }

                          if( i == BLUSH_APP_COUNT )
                            {
                              call UartSend.send( "Bad command\r\n", strlen("Bad command\r\n") );
                            }
                        }
                      else
                        {
                          call UartSend.send( "Shell Busy\r\n",
                                              strlen("Shell Busy\r\n") );
                        }
                      post printCmdLine();
                    }
                }

              /*
              // Print out prompt.
              call UartSend.send( blush_prompt, strlen(blush_prompt) );
              // Last but not least, null terminate the command line.
              blush_history[0][0] = '\0';
              blush_cmdline_idx = 0;
              blush_history_idx = 0;
              */
            }
          // CTRL-C
          else if( buff[i] == 0x03 )
            {
              // Discard history.
              blush_cmdline_idx = 0;
              blush_history_idx = 0;
              blush_history[0][0] = '\0';

              // print out new line and prompt.
              call UartSend.send( "\r\n", 2 );
              call UartSend.send( blush_prompt, strlen(blush_prompt) );

            }
          // TAB is 0x09
          else if( buff[i] == 0x09 )
            {
              // Tab completetion.
              // Search through list of available names.
              // Ouput correct one, or beep.
              for( i = 0; i < BLUSH_APP_COUNT; i++ )
                {
                  call BluSH_AppI.getName[i]( temp, BLUSH_CMDLINE_LENGTH );
                  if( strncmp( blush_history[0],
                               temp,
                               strlen(blush_history[0])) == 0 )
                    {
                      call UartSend.send( temp+strlen(blush_history[0]),
                                          strlen(temp)-strlen(blush_history[0]) );
                      call UartSend.send( " ", 1 );
                      strcat( blush_history[0], temp+strlen(blush_history[0]) );
                      strcat( blush_history[0], " " );
                      blush_cmdline_idx = strlen(temp)+1;

                      // add NULL.
                      blush_history[0][blush_cmdline_idx] = '\0';
                      break;
                    }
                }

              if( i >= BLUSH_APP_COUNT )
                {
                  // No match found.  Send beep.
                  call UartSend.send( "\a", 1 );
                }
            }
          // Arror keys.
          else if( buff[i] == 0x1b  || uSpecialChar!=0 ){
              static int special_i=0;
              //check to see if the current char is part of the escape sequence
              switch(special_i){
              case 0:
                  uSpecialChar=1;
                  special_i++;
                  break;
              case 1:
                  if(buff[i]!=0x5b){
                      uSpecialChar=0;
                      special_i=0;
                      //at this point, we know that our escape sequence was invalid, so we should treat
                      //the current character as a normal character...need to fall through on the outer loop
                      //at the moment, I'm happy with losing a character if the escape key is pressed
                      continue;
                  }
                  
                  special_i++;
                  break;
              case 2:
                  uSpecialChar=buff[i];
              case 3:
              case 4:
              case 5:
                  //pretty much need to assume that these characters are 0's
                  special_i++;
              }
              
              
              
              if( special_i == 6 && uSpecialChar == UP_ARROW ){
                  // Then it is an up arrow.
                  if( blush_history_idx < BLUSH_HISTORY_LENGTH-1 ){
                      blush_history_idx++;
                      
                      // Erase what's currently there.
                      for( i = 0; i < blush_cmdline_idx; i++ ){
                          // send backspace space backspace sequenence
                          call UartSend.send("\b \b", 3 );         
                      }
                      
                      // Copy history index.
                      strcpy( blush_history[0], blush_history[ blush_history_idx ] );
                      call UartSend.send( blush_history[0], strlen(blush_history[0]) );  
                      blush_cmdline_idx = strlen(blush_history[0]);
                  }
                  else{
                      call UartSend.send( "\a", 1 );
                  }
              } // Check for up arrow.
              else if( special_i == 6 && uSpecialChar == DOWN_ARROW ){
                  // Then it is a down arrow.
                  if( blush_history_idx > 0 ){
                      blush_history_idx--;
                      if( blush_history_idx == 0 ){
                          // Erase what's currently there.
                          for( i = 0; i < blush_cmdline_idx; i++ ){
                              // send backspace space backspace sequence
                              call UartSend.send("\b \b", 3 );         
                          }
                          blush_cmdline_idx = 0;
                          blush_history[0][0] = '\0';
                      }
                      else{
                          // Erase what's currently there.
                          for( i = 0; i < blush_cmdline_idx; i++ ){
                              // send backspace space backspace sequence
                              call UartSend.send("\b \b", 3 );         
                          }
                          
                          // Copy history index.
                          strcpy( blush_history[0], blush_history[ blush_history_idx ] );
                          call UartSend.send( blush_history[0], strlen(blush_history[0]) );  
                          blush_cmdline_idx = strlen(blush_history[0]);
                      }
                  }
                  else{
                      call UartSend.send( "\a", 1 );
                  }
              } // check for down arrow.
              if(special_i==6){
                  special_i=0;
                  uSpecialChar=0;
              }
          } // Special char check.
          
          // Backspace
          else if( buff[i] == '\b' )
            {
              if( blush_cmdline_idx > 0 )
                {
                  // Echo the character back.
                  call UartSend.send( &buff[i], 1 );         
                  // Print a space
                  call UartSend.send( " ", 1 );         
                  // Echo the character back.
                  call UartSend.send( &buff[i], 1 );         
                  blush_cmdline_idx--;
                  
                  blush_history[0][blush_cmdline_idx] = '\0';
                }
              else
                {
                  call UartSend.send( "\a", 1 );         
                }
            }
          else // Normal character.
            {
              // By this time we know that it's not a special character.
              // Copy it into our buffer.
              if( blush_cmdline_idx < BLUSH_CMDLINE_LENGTH - 1 )
                {
                  blush_history[0][ blush_cmdline_idx ] = buff[ i ];
                  blush_cmdline_idx++;
                  // Put a \0 on the end for safety.
                  blush_history[0][ blush_cmdline_idx ] = '\0';

                  // Echo the character back.
                  call UartSend.send( &buff[i], 1 );         
                }
              else
                {
                  // Send bell back, avoid buffer overflow.
                  //buff[i] = '\a';
                  call UartSend.send( "\a", 1 );         
                }
            }
        }
      
      return SUCCESS;
    }

  event result_t UartSend.sendDone(uint8_t* packet, result_t success)
    {
      // This function does nothing.
      return SUCCESS;
    }

/*
 * Start of NetworkCommand interface.
 */

  event result_t NetworkCommand.CommandResult( uint32 Command, uint32 value) {
     return SUCCESS;
  }


}
