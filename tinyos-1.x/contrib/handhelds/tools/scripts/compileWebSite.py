#!/usr/bin/python
'''
Copyright (c) 2005 Hewlett-Packard Company
All rights reserved

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of the Hewlett-Packard Company nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


Compile a directory into a set of web pages

Author:  Andrew Christian <andrew.christian@hp.com>
         February 2005
'''

import sys, os, time
from os.path import join
from compileTSP import compileTSP
from functions import makeFunctionList
import getopt


g_FunctionList = None

class Page:
    'A generic page of data'
    emap = { '.html' : 'WPT_STATIC_HTML',
             '.htm'  : 'WPT_STATIC_HTML',
             '.raw'  : 'WPT_STATIC_RAW',
             '.jpg'  : 'WPT_STATIC_JPEG',
             '.jpeg' : 'WPT_STATIC_JPEG',
             '.gif'  : 'WPT_STATIC_GIF',
             '.tsp'  : 'WPT_DYNAMIC_HTML' }
             
    def __init__(self,name,index):
        self.name = name
        self.type = 'WPT_BINARY'
        self.index = index

        emap = Page.emap
        for k in emap.keys():
            if name.endswith(k):
                self.type = emap[k]

    def add_data(self,filename):
        if self.type == 'WPT_DYNAMIC_HTML':
            self.data = compileTSP(filename,g_FunctionList)
        else:
            fd = open(filename,'r')
            self.data = [ord(x) for x in fd.read()]
            fd.close()

    def get_data(self,name):
        'The data of this page as a string'
        result = "const uint8_t %s_%d_data[%d] = {\n" % (name,self.index,len(self.data))
        data = ["%d" % x for x in self.data]
        while len(data) > 20:
            result += "    %s,\n" % (",".join(data[:20]))
            data = data[20:]
        result += "    %s\n" % (",".join(data))
        result += "};\n"
        return result

class WebPage(Page):
    'A named web page accessible from a GET line'
    def get_struct(self,name):
        'Dump the name and info of this page'
        return '{ "%s", %s, %d, (const uint8_t *)%s_%d_data }' % (self.name,
                                                                  self.type,
                                                                  len(self.data),
                                                                  name,
                                                                  self.index)
        
class ErrorPage(Page):
    'A numbered error page'
    def get_struct(self,name):
        return '{ NULL, %s, %d, (const uint8_t *)%s_%d_data }' % (self.type,
                                                                  len(self.data),
                                                                  name,
                                                                  self.index)

class WebSite:
    'Represent an entire website. For now we do not descend directories'
    def __init__(self,verbose=0):
        self.pages       = []
        self.error_pages = []
        self.verbose     = verbose

    def add_pages(self,topdir):
        'Load named web pages'
        index = 0

        for root, dirs, files in os.walk(topdir):
            if 'CVS' in dirs:
                dirs.remove('CVS')
            for f in files:
                if not f.endswith("~"):
                    if self.verbose: print "Adding web page '%s'" % f
                    wp = WebPage(f,index)
                    wp.add_data(join(root,f))
                    self.pages.append(wp)
                    index += 1

    def add_errors(self,topdir):
        'Load error pages'
        index = 0;
        for root, dirs, files in os.walk(topdir):
            if 'CVS' in dirs:
                dirs.remove('CVS')
            for f in files:
                if not f.endswith("~"):
                    if self.verbose: print "Adding error page '%s'" % f
                    wp = ErrorPage(f,index)
                    wp.add_data(join(root,f))
                    self.error_pages.append(wp)
                    index += 1
                    
    def find_default_page(self):
        'Try to pick the best web page to return as a default'
        best_index = -1
        index = 0
        for p in self.pages:
            if p.name in ('index.htm', 'index.html', 'index.tsp'):
                return index
            if p.type in ('WPT_STATIC_HTML', 'WPT_DYNAMIC_HTML'):
                best_index = index
            index += 1

        if best_index == -1:
            best_index = 0

        return best_index

    def dump(self,fd):
        print >>fd,"""
/*
 * This file has been automatically generated by the compileWebSite.py script.
 * Please do not edit this file by hand.
 *
 * Created: %s
 */

#ifndef __WEB_SITE_H
#define __WEB_SITE_H
        """ % time.asctime()
        
        for p in self.pages:
            print >>fd, p.get_data('page')
        for p in self.error_pages:
            print >>fd, p.get_data('error')
            
        print >>fd,'''
enum {
    WPT_BINARY = 0,     // octet-stream
    WPT_STATIC_HTML,    // HTML, no header
    WPT_STATIC_RAW,     // Does not require header
    WPT_STATIC_JPEG,    // image/jpeg
    WPT_STATIC_GIF,     // image/gif
    WPT_DYNAMIC_HTML,   // TSP (Tiny Server Page)
};
'''
        if g_FunctionList:
            print >>fd, g_FunctionList.toEnumList()
            
        print >>fd,'''
struct WebPage {
    char    *url;
    int      type;
    int      len;
    const uint8_t *data;
};
        '''
        print >>fd, "const struct WebPage g_web_page[%d] = {" % (len(self.pages) +len(self.error_pages))
        for p in self.pages:
            print >>fd, "    %s," % p.get_struct('page')

        for p in self.error_pages:
            print >>fd, "    %s," % p.get_struct('error')
        print >>fd, "};\n"

        print >>fd, "enum {"
        for p in self.error_pages:
            print >>fd, "    ERROR_PAGE_%s = %d," % (p.name.split('.')[0], p.index + len(self.pages))
        print >>fd, "};\n"

        print >>fd, """
enum {
    DEFAULT_WEB_PAGE=%d,
    NUM_WEB_PAGES=%d
};

#endif // __WEB_SITE_H
""" % (self.find_default_page(), len(self.pages))


def usage(outfile):
    print """
    Usage:  compileWebSite.py [OPTS] DIRNAME ERRDIRECTORY

    Valid options:

            -f, --functions=FILE    Name of function file (may be repeated)
            -o, --output=FILE       Name of file to write (default '%s')
            -v, --verbose           Run in verbose mode
            
    """ % outfile
    sys.exit(1)


def main(argv):
    outfile = 'web_site.h'
    verbose = 0
    
    try:
        (options,argv) = getopt.getopt(argv, 'f:o:v', ['functions=', 'output=', 'verbose'])
    except Exception, e:
        print e
        usage(outfile)

    for (k,v) in options:
        if k in ('-f', '--functions'):
            global g_FunctionList
            if g_FunctionList is None:
                g_FunctionList = makeFunctionList(v)
            else:
                g_FunctionList = makeFunctionList(v)
        elif k in ('-o', '--output'):
            outfile = v
        elif k in ('-v', '--verbose'):
            verbose += 1
        else:
            usage(outfile)
            
    if len(argv) != 2:
        usage(outfile)

    if verbose:
        print "Function list"
        g_FunctionList.dump()
        
    ws = WebSite(verbose)
    ws.add_pages(argv[0])
    ws.add_errors(argv[1])

    fd = file(outfile,'w')
    if verbose:
        print "Writing output file '%s'" % outfile
    ws.dump(fd)
    fd.close();

if __name__=='__main__':
    main(sys.argv[1:])
    
