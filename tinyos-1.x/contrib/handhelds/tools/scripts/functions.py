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


Process function declaration files

February 2005
Andrew Christian
'''

import sys, time, common
from common import Token, AST, dump_token_list, dump_ast
from spark import GenericScanner, GenericASTBuilder, GenericASTMatcher, GenericASTTraversal

################################################################

class FuncScanner(GenericScanner):
    '''
    Process external function declarations
    '''
    def __init__(self,lineno):
        GenericScanner.__init__(self)
        self.lineno = lineno
    
    def tokenize(self, input):
        self.rv = []
        GenericScanner.tokenize(self, input)
        return self.rv
    
    def t_acomment(self,s):
        r''' //.*'''
        pass
    
    def t_bop(self,s):
        r''' string(?!\w) | int(?!\w) | any(?!\w) | ; | , '''
        self.rv.append(Token(type=s,lineno=self.lineno))
    
    def t_lp(self,s):
        r' \( '
        self.rv.append(Token(type='LEFTP',lineno=self.lineno))

    def t_rp(self,s):
        r' \) '
        self.rv.append(Token(type='RIGHTP',lineno=self.lineno))

    def t_name(self, s):
        r' [a-zA-Z]\w* '
        t = Token(type='NAME', attr=s,lineno=self.lineno)
        self.rv.append(t)

    def t_default(self,s):
        r' \n '
        pass

    def t_whitespace(self, s):
        r' \s+ '
        pass

################################################################

class FuncParser(GenericASTBuilder):
    def __init__(self, AST, start='func_list'):
            GenericASTBuilder.__init__(self, AST, start)

    def p_func_list(self,args):
        '''
            func_list ::= func_list func
            func_list ::= func
        '''
        
    def p_func(self,args):
        '''
            func ::= return_type NAME LEFTP arg_list RIGHTP ;
            func ::= return_type NAME LEFTP RIGHTP ;
        '''

    def p_return_type(self,args):
        '''
            return_type ::= int
            return_type ::= string
            return_type ::= any
        '''

    def p_arg_list(self,args):
        '''
            arg_list ::= arg_list , arg
            arg_list ::= arg
        '''

    def p_arg(self,args):
        '''
            arg ::= string
            arg ::= int
            arg ::= any
        '''

    def terminal(self, token):
        rv = AST(token.type)
        rv.attr = token.attr
        rv.lineno = token.lineno
        return rv

    def nonterminal(self, type, args):
        if len(args) == 1:
            return args[0]
        return GenericASTBuilder.nonterminal(self, type, args)

################################################################

class Function:
    def __init__(self,rtype,name,arglist):
        self.rtype   = rtype
        self.name    = name
        self.arglist = arglist

    def __str__(self):
        return "%s(%s);" % (self.name,",".join(self.arglist))

class FunctionList:
    def __init__(self,flist=[]):
        self.flist = flist

    def __len__(self):
        return len(self.flist)

    def __getitem__(self,index):
        return self.flist[index]

    def __iadd__(self,other):
        'Add two function lists: fl1 += fl2'
        self.flist += other.flist
        return self

    def __add__(self,other):
        fl = FunctionList( self.flist + other.flist )
        return fl

    def add(self,rtype,name,arglist=[]):
        self.flist.append( Function(rtype,name,arglist))

    def dump(self):
        for f in self.flist:
            print f

    def index(self,fname):
        offset = 0
        for f in self.flist:
            if f.name == fname:
                return offset
            offset += 1
        return -1
    
    def verify(self,fname,lineno,argcount=0):
        for f in self.flist:
            if f.name == fname:
                if len(f.arglist) != argcount:
                    print 'Function',fname,'called with wrong number of arguments line', lineno
                    raise SystemExit
                return
            
        print 'Unable to location function name', fname, 'in dictionary line', lineno
        raise SystemExit
        
    def toEnumList(self):
        'Convert the function dictionary to an enumeration'
        result = "enum {\n"
        i = 0
        for f in self.flist:
            result += "    FUNCTION_%-20s = %2d,  // " % (f.name.upper(), i)
            result += "%-6s %s(%s);\n" % (f.rtype, f.name, ",".join(f.arglist)) 
            i += 1
        
        result += "};\n"
        return result
    
    def toInclude(self,filename):
        'Convert the funcation dictionary to a *.h file'
        result = '''
/*
 * This file was autogenerated by functions.py
 * from the file '%s' on %s
 *
 * These functions must be implemented in your code loop.
 */

#ifndef __FUNC_DICT
#define __FUNC_DICT

''' % (filename,time.asctime())
        result += self.toEnumList()
        result += '''
#endif // __FUNC_DICT
'''
        return result

################################################################

class FuncCompiler(GenericASTMatcher):
    '''Convert a tree into a dictionary of functions
       mapped to a list of what arguments they take
    '''
    
    def __init__(self,ast):
        GenericASTMatcher.__init__(self,'V',ast)
        self.flist = FunctionList()
        self.match()
        
    def p_func_list(self,tree):
        ' V ::= func_list ( V V ) '
        pass

    def p_func(self,tree):
        ' V ::= func ( V V LEFTP RIGHTP ; ) '
        self.flist.add(tree[0].value[0], tree[1].value)

    def p_func_with_args(self,tree):
        ' V ::= func ( V V LEFTP V RIGHTP ; ) '
        self.flist.add(tree[0].value[0], tree[1].value, tree[3].value)

    def p_arg_list(self,tree):
        ' V ::= arg_list ( V , V ) '
        tree.value = tree[0].value + tree[2].value

    def p_arg_int(self,tree):
        ' V ::= int '
        tree.value = ['int']

    def p_arg_string(self,tree):
        ' V ::= string '
        tree.value = ['string']

    def p_arg_any(self,tree):
        ' V ::= any '
        tree.value = ['any']

    def p_arg_name(self,tree):
        ' V ::= NAME '
        tree.value = tree.attr


################################################################

def makeFunctionList(filename,verbose=False):
    'Convert a .fun file into a function dictionary'
    tlist = common.tokenize_by_line( FuncScanner, filename )

    if verbose: dump_token_list(tlist)
    if verbose: print '***** Tree ******'

    atree = common.parse_tokens( FuncParser, tlist )

    if verbose: dump_ast(atree)
    if verbose: print '**** Compile ****'

    fc = FuncCompiler(atree)

    if verbose:
        fc.flist.dump()

    return fc.flist
    
################################################################

def makeInclude(filename,verbose=False):
    'Convert a .fun file into a .h file'
    flist = makeFunctionList(filename,verbose)

    if verbose: print '***************************'
    return flist.toInclude(filename)

################################################################

if __name__=='__main__':
    import getopt

    def usage():
        print """
        Usage:  functions.py [-v] FILENAME
        """
        sys.exit(1)
    
    try:
        (options,argv) = getopt.getopt(sys.argv[1:], 'vh', ['verbose', 'help'])
    except Exception, e:
        print e
        usage()

    verbose = False
    for (k,v) in options:
        if k in ('-v', '--verbose'):
            verbose = True
        elif k in ('-h', '--help'):
            usage()
        else:
            usage()

    if len(argv) != 1:
        usage()
    print makeInclude(argv[0],verbose)
