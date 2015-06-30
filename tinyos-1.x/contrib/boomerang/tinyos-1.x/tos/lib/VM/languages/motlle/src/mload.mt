/*
 * Copyright (c) 2004-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
any usage()
{
  pformat(stderr(), "Usage: mload [-h/--help] [-s/-m] [-e] [-c] <file or command>\n");
}

any injector, mate_compile;

any is_scheme = false;
any motlle_debug = getenv("MOTLLEDEBUG");
any display_error = motlle_debug != 0;

any src = argv[1];
load(string_append(src, "utils.mt"));
load(string_append(src, "sf.mt"));
load(string_append(src, "vmconf.mt"));
load(string_append(src, "mate-interface.mt"));
load("conf.mt");

set_display_error!(display_error);
if (display_error) idebug(atoi(motlle_debug));

any file_or_cmd = false, compiler = file_compile, doinject = injector;
int len = vector_length(argv);

for (int i = 2; i < len; i++) 
  if (argv[i][0] == '-')
    {
      if (!string_cmp("-e", argv[i]))
	compiler = string_compile;
      else if (!string_cmp("-c", argv[i]))
	doinject = mate_compile;
      else if (!string_cmp("-s", argv[i]))
	is_scheme = true;
      else if (!string_cmp("-m", argv[i]))
	is_scheme = false;
      else if (!string_cmp("-h", argv[i]) ||
	       !string_cmp("--help", argv[i]))
	{
	  usage();
	  quit();
	}
      else
	pformat(stderr(), "Unknown option %s\n", argv[i]);
    }
  else
    {
      if (file_or_cmd)
	{
	  pformat(stderr(), "Unexpected argument %s\n", argv[i]);
	  usage();
	  quit();
	}
      file_or_cmd = argv[i];
    }

if (!file_or_cmd)
  usage();
else if (!doinject(fn (g, s) compiler(g, s, is_scheme), file_or_cmd))
  error(error_bad_value);
