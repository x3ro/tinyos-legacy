
//!! Config 42 { MagPosition_t MagPositionDefault = { x:0, y:0 }; }
//!! Config 43 { Affine2_int16_t MagPositionAffine = { r11:0x0200, r12:0, r13:0, r21:0, r22:0x0200, r23:0 }; }

module MagPositionM
{
  provides interface StdControl;

  uses interface MagPositionAttr;
  uses interface Valid as MagPositionValid;
  uses interface EvaderDemoStore;
  uses interface Config_MagPositionDefault;
  uses interface Config_MagPositionAffine;

#if defined(PLATFORM_PC)
  uses interface Poll;
#endif//if defined(PLATFORM_PC)
}
implementation
{
  MagPosition_t transform_address( Affine2_int16_t a )
  {
    int16_t x = (TOS_LOCAL_ADDRESS>>4) & 0x0f;
    int16_t y = (TOS_LOCAL_ADDRESS>>0) & 0x0f;
    MagPosition_t pos = {
      x : x*a.r11 + y*a.r12 + a.r13,
      y : x*a.r21 + y*a.r22 + a.r23,
    };
    return pos;
  }

  task void position_update()
  {
    MagPosition_t pos = transform_address( G_Config.MagPositionAffine );
    call MagPositionAttr.set( pos );
    call MagPositionValid.set( TRUE );
    call EvaderDemoStore.setHardcodedPosition( pos.x, pos.y );
  }

  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    post position_update();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  event void MagPositionAttr.updated()
  {
#if defined(PLATFORM_PC)
    MagPosition_t pos = call MagPositionAttr.get();
    dbg( DBG_USR2, "[MagPosition.updated] [x=%04x] [y=%04x]\n", pos.x, pos.y );
#endif//if defined(PLATFORM_PC)
  }

  event void Config_MagPositionDefault.updated()
  {
    call MagPositionAttr.set( G_Config.MagPositionDefault );
  }

  event void Config_MagPositionAffine.updated()
  {
    post position_update();
  }

#if defined(PLATFORM_PC)
  event void Poll.fired()
  {
    if( adcValues[TOS_LOCAL_ADDRESS][130] == 1 )
    {
      //int16_t x = generic_adc_read( TOS_LOCAL_ADDRESS, 128, 0 );
      //int16_t y = generic_adc_read( TOS_LOCAL_ADDRESS, 129, 0 );
      //G_Config.MagPositionDefault.x = x;
      //G_Config.MagPositionDefault.y = y;
      //set_adc_value( TOS_LOCAL_ADDRESS, 130, 0 );

      G_Config.MagPositionDefault.x = adcValues[TOS_LOCAL_ADDRESS][128];
      G_Config.MagPositionDefault.y = adcValues[TOS_LOCAL_ADDRESS][129];
      adcValues[TOS_LOCAL_ADDRESS][130] = 0;

      signal Config_MagPositionDefault.updated();
    }
  }
#endif//if defined(PLATFORM_PC)
}

