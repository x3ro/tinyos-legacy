/*
 * Copyright (c) 1993-1999 David Gay and Gustav Hållberg
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software for any
 * purpose, without fee, and without written agreement is hereby granted,
 * provided that the above copyright notice and the following two paragraphs
 * appear in all copies of this software.
 * 
 * IN NO EVENT SHALL DAVID GAY OR GUSTAV HALLBERG BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF DAVID GAY OR
 * GUSTAV HALLBERG HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * DAVID GAY AND GUSTAV HALLBERG SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN
 * "AS IS" BASIS, AND DAVID GAY AND GUSTAV HALLBERG HAVE NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 */

#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <glob.h>
#include <string.h>
#include <stdlib.h>
#include <sys/socket.h>
#ifdef linux
#include <linux/un.h>
#else
#include <sys/un.h>
#define UNIX_PATH_MAX 108
#endif
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#include "runtime/runtime.h"
#include "print.h"
#include "utils.h"
#include "mparser.h"
#include "interpret.h"
#include "runtime/files.h"
#include "call.h"
#include "lexer.h"
#include "compile.h"

struct load_frame
{
  struct generic_frame g;
  FILE *f;
};

static void load_action(frameact action, u8 **ffp, u8 **fsp)
{
  struct load_frame *frame = (struct load_frame *)*ffp;
  u8 ok;

  switch (action)
    {
    case fa_unwind:
      throw_handled();
      ok = FALSE;
      goto done;
    case fa_execute:
      ok = TRUE;
    done:
      fclose(frame->f);

      /* Pop frame */
      FA_POP(&fp, &sp);
      stack_push(makebool(ok));
      break;
    case fa_print:
      break;
    case fa_gcforward:
      /* fall through */
    case fa_pop:
      pop_frame(ffp, fsp, sizeof(struct load_frame));
      break;
    default: abort();
    }
}

OPERATION("load", load, "s -> b. Loads file s. True if successful", 
	  1, (struct string *name), 0)
{
  char *fname;
  FILE *f;
  struct load_frame *frame;

  TYPEIS(name, type_string);
  LOCALSTR(fname, name);

  if (!(f = fopen(fname, "r")))
    RUNTIME_ERROR(error_bad_value);

  frame = push_frame(load_action, sizeof(struct load_frame));
  frame->f = f;

  read_from_file(f);
  compile_and_run(NULL, globals, fname, NULL, FALSE);

  return PRIMITIVE_STOLE_CC;
}

UNSAFEOP("mkdir", mkdir, "s n1 -> n2. Make directory s (mode n1)",
	 2, (struct string *name, value mode),
	 OP_LEAF | OP_NOALLOC)
{
  TYPEIS(name, type_string);
  ISINT(mode);

  return makeint(mkdir(name->str, intval(mode)));
}

UNSAFEOP("directory_files", directory_files, 
"s -> l. List all files of directory s (returns false if problems)",
	 1, (struct string *dir),
	 OP_LEAF)
{
  DIR *d;

  TYPEIS(dir, type_string);

  if ((d = opendir(dir->str)))
    {
      struct dirent *entry;
      struct list *files = NULL;

      GCPRO1(files);
      while ((entry = readdir(d)))
	{
	  struct string *fname = alloc_string(entry->d_name);

	  files = alloc_list(fname, files);
	}
      GCPOP(1);
      closedir(d);

      return files;
    }
  return makebool(FALSE);	  
}

UNSAFEOP("glob_files", glob_files, 
"s n -> l. Returns a list of all files matched by the glob pattern s, using\n\
flags in n (GLOB_xxx). Returns FALSE on error", 
	 2, (struct string *pat, value n), OP_LEAF)
{
  glob_t files;
  struct list *l = NULL;
  char **s;
  ivalue flags = intval(n);
  TYPEIS(pat, type_string);

#ifndef GLOB_NOESCAPE
#define GLOB_NOESCAPE 0
#endif
#ifdef _GNU_GLOB_
  if (flags & ~(GLOB_TILDE | GLOB_BRACE | GLOB_MARK | GLOB_NOCHECK |
		GLOB_NOESCAPE | GLOB_PERIOD | GLOB_NOMAGIC | GLOB_ONLYDIR))
#else
  if (flags & ~( GLOB_MARK | GLOB_NOCHECK | GLOB_NOESCAPE ))
#endif
    RUNTIME_ERROR(error_bad_value);

  if (glob(pat->str, flags, NULL, &files))
    {
      globfree(&files);
      return makebool(FALSE);
    }

  GCPRO1(l);
  for (s = files.gl_pathv; *s; ++s)
    {
      struct string *f = alloc_string(*s);

      GCPRO1(f);
      l = alloc_list(f, l);
      GCPOP(1);
    }
  GCPOP(1);
  globfree(&files);
  return l;
}

static value build_file_stat(struct stat *sb)
{
  struct vector *info = alloc_vector(13);
  
  info->data[0] = makeint((int)sb->st_dev);
  info->data[1] = makeint(sb->st_ino);
  info->data[2] = makeint(sb->st_mode);
  info->data[3] = makeint(sb->st_nlink);
  info->data[4] = makeint(sb->st_uid);
  info->data[5] = makeint(sb->st_gid);
  info->data[6] = makeint((int)sb->st_rdev);
  info->data[7] = makeint(sb->st_size);
  info->data[8] = makeint(sb->st_atime);
  info->data[9] = makeint(sb->st_mtime);
  info->data[10] = makeint(sb->st_ctime);
  info->data[11] = makeint(sb->st_blksize);
  info->data[12] = makeint(sb->st_blocks);
  
  return info;
}

UNSAFEOP("file_stat", file_stat, 
"s -> v. Returns status of file s (returns false for failure). See the\n\
FS_xxx constants and file_lstat().",
	 1, (struct string *fname),
	 OP_LEAF)
{
  struct stat sb;

  TYPEIS(fname, type_string);
  if (!stat(fname->str, &sb))
    return build_file_stat(&sb);
  else
    return makebool(FALSE);
}

UNSAFEOP("file_lstat", file_lstat, 
"s -> v. Returns status of file s (not following links). Returns FALSE for\n\
failure. See the FS_xxx constants and file_stat()",
	 1, (struct string *fname),
	 OP_LEAF)
{
  struct stat sb;

  TYPEIS(fname, type_string);
  if (!lstat(fname->str, &sb))
    return build_file_stat(&sb);
  else
    return makebool(FALSE);
}

UNSAFEOP("readlink", readlink, 
"s1 -> s2. Returns the contents of symlink s, or FALSE "
	 "for failure", 1, (struct string *lname), OP_LEAF)
{
  struct stat sb;
  struct string *res;

  TYPEIS(lname, type_string);
  if (lstat(lname->str, &sb) ||
      !S_ISLNK(sb.st_mode))
    return makebool(FALSE);
  
  GCPRO1(lname);
  res = alloc_string_n(sb.st_size);
  GCPOP(1);

  if (readlink(lname->str, res->str, sb.st_size) < 0)
    return makebool(FALSE);
  res->str[sb.st_size] = '\0';

  return res;
}

UNSAFEOP("file_regular?", file_regularp, 
"s -> b. Returns TRUE if s is a regular file (null "
	 "for failure)",
	 1, (struct string *fname),
	 OP_LEAF | OP_NOALLOC)
{
  struct stat sb;

  TYPEIS(fname, type_string);
  if(!stat(fname->str, &sb))
    return makebool(S_ISREG(sb.st_mode));
  else
    return NULL;
}

UNSAFEOP("remove", remove, "s -> b. Removes file s, returns TRUE if success",
	  1, (struct string *fname),
	  OP_LEAF)
{
  TYPEIS(fname, type_string);

  return makebool(unlink(fname->str) == 0);
}

UNSAFEOP("rename", rename, "s1 s2 -> n. Renames file s1 to s2. Returns the\n\
 Unix error number or 0 for success",
	  2, (struct string *oldname, struct string *newname),
	  OP_LEAF)
{
  TYPEIS(oldname, type_string);
  TYPEIS(newname, type_string);

  return makeint(rename(oldname->str, newname->str) ? errno : 0);
}

UNSAFEOP("file_read", file_read, "s1 -> s2. Reads file s1 and returns its\n\
contents (or the Unix errno value)",
	  1, (struct string *name),
	  OP_LEAF)
{
  int fd;

  TYPEIS(name, type_string);

  if ((fd = open(name->str, O_RDONLY)) >= 0)
    {
      off_t size = lseek(fd, 0, SEEK_END);

      if (size >= 0)
	{
	  struct string *s = alloc_string_n(size);

	  if (lseek(fd, 0, SEEK_SET) == 0 && read(fd, s->str, size) == size)
	    {
	      s->str[size] = '\0';
	      close(fd);
	      return s;
	    }
	}
      close(fd);
    }
  return makeint(errno);
}

UNSAFEOP("file_write", file_write, 
"s1 s2 -> n. Writes s2 to file s1. Creates s1 if it doesn't exist. Returns\n\
the Unix return code (0 for success)",
	 2, (struct string *file, struct string *data),
	 OP_LEAF)
{
  int fd;
  TYPEIS(file, type_string);
  TYPEIS(data, type_string);

  fd = open(file->str, O_WRONLY | O_CREAT | O_TRUNC, 0666);
  if (fd != -1)
    {
      int res, len;
      len = string_len(data);
      res = write(fd, data->str, string_len(data));
      close(fd);
      if (res == len)
	return makeint(0);
    }      

  return makeint(errno);
}

UNSAFEOP("file_append", file_append, 
"s1 s2 -> n. Appends string s2 to file s1. Creates s1 if nonexistent. \n\
Returns the Unix error number for failure, 0 for success.",
	 2, (struct string *file, struct string *val), 
	 OP_LEAF | OP_NOESCAPE)
{
  int fd;
  uvalue size;

  TYPEIS(file, type_string);
  TYPEIS(val, type_string);

  fd = open(file->str, O_WRONLY | O_CREAT | O_APPEND, 0666);
  if (fd != -1)
    {
      if (fchmod(fd, 0666) == 0) /* ### What's the point of this? - finnag */
	{
	  int len;
	  size = string_len(val);
	  len = write(fd, val->str, size);
	  close(fd);
	  if (len == size)
	    return makeint(0);
	}
      else
	close(fd);
    }
  return makeint(errno);
}

UNSAFEOP("unix_write", unix_write, 
"n1 s -> n2. unix: write(n1, s, string_length(s))",
	 2, (value fd, struct string *s),
	 OP_LEAF | OP_NOESCAPE | OP_NOALLOC)
{
  ISINT(fd);
  TYPEIS(s, type_string);

  return makeint(write(intval(fd), s->str, string_len(s)));
}

UNSAFEOP("unix_read", unix_read, 
"n1 s n2 -> n3. unix: read(n1, s, n2)\n\
error_bad_value if n2 > string_length(s)",
	 3, (value fd, struct string *s, value n),
	 OP_LEAF | OP_NOESCAPE | OP_NOALLOC)
{
  ivalue rn;

  ISINT(fd);
  TYPEIS(s, type_string);
  ISINT(n);

  rn = intval(n);
  if (rn > string_len(s))
    RUNTIME_ERROR(error_bad_value);

  return makeint(read(intval(fd), s->str, rn));
}

UNSAFEOP("unix_close", unix_close, "n1 -> n2. unix: close(n1)",
	 1, (value fd),
	 OP_LEAF | OP_NOESCAPE | OP_NOALLOC)
{
  ISINT(fd);

  return makeint(close(intval(fd)));
}

UNSAFEOP("unix_stream_connect", unix_stream_connect, 
"s -> n. connect to unix stream socket s",
	 1, (struct string *name),
	 OP_LEAF | OP_NOESCAPE | OP_NOALLOC)
{
  struct sockaddr_un addr;
  int req_s;

  TYPEIS(name, type_string);
  req_s = socket(PF_UNIX, SOCK_STREAM, 0);
  if (req_s != -1)
    {
      addr.sun_family = AF_UNIX;
      strncpy(addr.sun_path, name->str, UNIX_PATH_MAX - 1);
      addr.sun_path[UNIX_PATH_MAX - 1] = '\0';
      if (connect(req_s, (struct sockaddr *)&addr, sizeof addr) == -1)
	{
	  close(req_s);
	  req_s = -1;
	}
    }
  return makeint(req_s);
}

UNSAFEOP("unix_tcp_connect", unix_tcp_connect,
"s n1 -> n2. connect to tcp port n1 on server s",
	 2, (struct string *name, value port),
	 OP_LEAF | OP_NOESCAPE | OP_NOALLOC)
{
  struct sockaddr_in addr;
  int req_s;

  TYPEIS(name, type_string);
  ISINT(port);
  req_s = socket(PF_INET, SOCK_STREAM, 0);
  if (req_s != -1)
    {
      struct hostent *name_lookup_result;

      addr.sin_family = AF_INET;
      addr.sin_port = htons(intval(port));

      name_lookup_result = gethostbyname(name->str);
      if (name_lookup_result)
	{
	  char **addresses = name_lookup_result->h_addr_list;

	  while (*addresses)
	    {
	      memcpy(&addr.sin_addr, *addresses++,
		     sizeof(addr.sin_addr));
	      if (connect(req_s, (struct sockaddr *)&addr, sizeof addr) != -1)
		return makeint(req_s);
	    }
	}
    }
  return makeint(-1);
}	 

UNSAFEOP("unix_open", unix_open, "s n1 n2 -> n3. unix: open(s, n1, n2)",
	 3, (struct string *name, value opts, value mode),
	 OP_LEAF | OP_NOESCAPE | OP_NOALLOC)
{
  TYPEIS(name, type_string);
  ISINT(opts);
  ISINT(mode);

  return makeint(open(name->str, intval(opts), intval(mode)));
}

UNSAFEOP("unix_errno", unix_errno, "-> n. unix: errno",
	 0, (void),
	 OP_LEAF | OP_NOESCAPE | OP_NOALLOC)
{
  return makeint(errno);
}

#if DEFINE_GLOBALS
GLOBALS(files)
{
  system_define("FS_DEV", makeint(0));
  system_define("FS_INO", makeint(1));
  system_define("FS_MODE", makeint(2));
  system_define("FS_NLINK", makeint(3));
  system_define("FS_UID", makeint(4));
  system_define("FS_GID", makeint(5));
  system_define("FS_RDEV", makeint(6));
  system_define("FS_SIZE", makeint(7));
  system_define("FS_ATIME", makeint(8));
  system_define("FS_MTIME", makeint(9));
  system_define("FS_CTIME", makeint(10));
  system_define("FS_BLKSIZE", makeint(11));
  system_define("FS_BLOCKS", makeint(12));
  IDEF(S_IFMT);
  IDEF(S_IFSOCK);
  IDEF(S_IFLNK);
  IDEF(S_IFBLK);
  IDEF(S_IFREG);
  IDEF(S_IFDIR);
  IDEF(S_IFCHR);
  IDEF(S_IFIFO);
  IDEF(S_ISUID);
  IDEF(S_ISGID);
  IDEF(S_ISVTX);
  IDEF(S_IRWXU);
  IDEF(S_IRUSR);
  IDEF(S_IWUSR);
  IDEF(S_IXUSR);
  IDEF(S_IRWXG);
  IDEF(S_IRGRP);
  IDEF(S_IWGRP);
  IDEF(S_IXGRP);
  IDEF(S_IRWXO);
  IDEF(S_IROTH);
  IDEF(S_IWOTH);
  IDEF(S_IXOTH);

  IDEF(GLOB_MARK);
  IDEF(GLOB_NOCHECK);
  IDEF(GLOB_NOESCAPE);
#ifdef _GNU_GLOB_
  IDEF(GLOB_TILDE);
  IDEF(GLOB_BRACE);
  IDEF(GLOB_PERIOD);
  IDEF(GLOB_NOMAGIC);
  IDEF(GLOB_ONLYDIR);
#endif

  IDEF(O_RDONLY);
  IDEF(O_WRONLY);
  IDEF(O_RDWR);
  IDEF(O_CREAT);
  IDEF(O_EXCL);
  IDEF(O_NOCTTY);
  IDEF(O_TRUNC);
  IDEF(O_APPEND);
  IDEF(O_NONBLOCK);
  IDEF(O_NDELAY);
  IDEF(O_SYNC);
}
#endif
