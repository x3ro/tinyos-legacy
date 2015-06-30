
//!! Config 20 { uint8_t ConfigWriteCount = 0; }
//!! ConfigStoreCmd = CreateCommand[SystemCommand]( CommandHood, uint8_t, Void_t, 11, 12 );

module ConfigStoreServiceM
{
  provides interface StdControl;
  uses interface ConfigStoreControl;
  uses interface ConfigWrite;
  uses interface ConfigRead;
  uses interface ConfigStoreCmd;
}
implementation
{
  enum
  {
    CONFIG_DEFAULT = 0,
    CONFIG_READ = 1,
    CONFIG_WRITE = 2,
  };

  command result_t StdControl.init()
  {
    return call ConfigStoreControl.init( sizeof(G_Config) );
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  void read()
  {
    call ConfigRead.read( (uint8_t*)(&G_Config), sizeof(G_Config) );
  }

  event void ConfigStoreControl.initializedNoData()
  {
  }

  event void ConfigStoreControl.initializedDataPresent()
  {
    read();
  }

  event void ConfigRead.readFail( uint8_t* buffer )
  {
    G_Config = G_DefaultConfig;
  }

  event void ConfigRead.readSuccess( uint8_t* buffer )
  {
    if( G_Config.ConfigHash != G_DefaultConfig.ConfigHash )
      G_Config = G_DefaultConfig;
  }

  void write()
  {
    if( ++G_Config.ConfigWriteCount == 0 )
      G_Config.ConfigWriteCount = 1;
    call ConfigWrite.write( (uint8_t*)(&G_Config), sizeof(G_Config) );
  }

  event void ConfigWrite.writeFail( uint8_t* buffer )
  {
    if( --G_Config.ConfigWriteCount == 0 )
      G_Config.ConfigWriteCount = ~0u;
  }

  event void ConfigWrite.writeSuccess( uint8_t* buffer )
  {
  }

  event void ConfigStoreCmd.receiveCall( uint8_t cmd )
  {
    switch( cmd )
    {
      case CONFIG_DEFAULT:
	G_Config = G_DefaultConfig;
	break;

      case CONFIG_READ:
	read();
	break;

      case CONFIG_WRITE:
	write();
	break;
    }

    call ConfigStoreCmd.dropReturn();
  }

  event void ConfigStoreCmd.receiveReturn( nodeID_t node, Void_t rets )
  {
  }
}

