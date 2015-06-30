
includes Ident;

#if !( defined(IDENT_PROGRAM_NAME) && defined(IDENT_INSTALL_ID) && defined(IDENT_UNIX_TIME) )
#  if !defined(IDENT_PROGRAM_NAME)
#    warning "*****   IDENT_PROGRAM_NAME is not defined   *****"
#  endif
#  if !defined(IDENT_INSTALL_ID)
#    warning "*****   IDENT_INSTALL_ID is not defined   *****"
#  endif
#  if !defined(IDENT_UNIX_TIME)
#    warning "*****   IDENT_UNIX_TIME is not defined   *****"
#  endif
#  error "****   The Ident service requires the above preprocessor variables to be defined.  cat ../System/Ident.txt for more info.   *****"
#endif

configuration IdentC
{
}
implementation
{
  components IdentM
           , IdentCmdC
	   , XnpC
	   ;

  IdentM.IdentCmd -> IdentCmdC;
  IdentM.XnpConfig -> XnpC;
}

