% ------------------------------------------------------------------------------
%   Zeevo Application Dynamic Configuration Script 
%
%   Copyright (c) 2002 Zeevo Inc. All rights reserved.
%
% ------------------------------------------------------------------------------

% ------------------------------------------------------------------------------
%   Application Configuration
% ------------------------------------------------------------------------------

% application data buffer configuration                     
App_LongBufferNum                      uint16 ,  0 >
                                       4      @  Interface_EMBEDDED >
                                       4      @  Interface_ZERIAL   >
                                       4      @  Interface_AGENT   ;

App_LongBufferSize                     uint16 ,  0 >
                                       400    @  Interface_EMBEDDED >
                                       400    @  Interface_ZERIAL   >
                                       400    @  Interface_AGENT    ;


App_MidBufferNum                       uint16 ,  0 >
                                       4      @  Interface_EMBEDDED >
                                       8      @  Interface_ZERIAL   >
                                       8      @  Interface_AGENT    ;

App_MidBufferSize                      uint16 ,  0 >
                                       150    @  Interface_EMBEDDED >
                                       150    @  Interface_ZERIAL   >
                                       150    @  Interface_AGENT    ;

App_ShortBufferNum                     uint16 ,  0 >
                                       8      @  Interface_EMBEDDED >
                                       8      @  Interface_ZERIAL   >
                                       8      @  Interface_AGENT    ;

App_ShortBufferSize                    uint16 ,  0 >
                                       64     @  Interface_EMBEDDED >
                                       64     @  Interface_ZERIAL   >
                                       64     @  Interface_AGENT    ;