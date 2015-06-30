
includes Ident;
//!! IdentCmd = CreateCommand[SystemCommand]( CommandHood, Void_t, Ident_t, 1, 2 );

module IdentM
{
  uses interface IdentCmd;
  uses interface XnpConfig;
}
implementation
{
  // static consts to make the values easily accessible in the object code
  static const char program_name[] = IDENT_PROGRAM_NAME;
  static const uint16_t install_id = IDENT_INSTALL_ID;
  static const uint32_t unix_time = IDENT_UNIX_TIME;

  event void IdentCmd.receiveCall( IdentCmdArgs_t args )
  {
    Ident_t ident;
    uint8_t i = 0;

    while( (i < IDENT_MAX_PROGRAM_NAME_LENGTH) && (i < sizeof(program_name)) )
    {
      ident.program_name[i] = program_name[i];
      i++;
    }

    while( i < IDENT_MAX_PROGRAM_NAME_LENGTH )
      ident.program_name[i++] = 0;

    ident.xnp_program_id = call XnpConfig.getProgramID();
    ident.install_id = install_id;
    ident.unix_time = unix_time;

    call IdentCmd.sendReturn( ident );
  }

  event void IdentCmd.receiveReturn( nodeID_t node, IdentCmdReturn_t rets )
  {
  }
}

