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


Convert Tiny Server Page files into byte-code compiled scripts
suitable for running on a mote.

February 2005
Andrew Christian
'''

import sys
from common import Token, AST, dump_token_list, dump_ast
from functions import makeFunctionList
from spark import GenericScanner, GenericASTBuilder, GenericASTMatcher, GenericASTTraversal

#####################################################

class LineScanner(GenericScanner):
    'Keep track of our position on each line. We scan one line at a time'
    def error(self, s, pos):
        print "Lexical error at position %s, line %d" % (pos,self.lineno)
        raise SystemExit

    def process_lines(self,f):
        self.rv = []
        s = f.readline()
        self.lineno = 1

        while s:
            self.tokenize(s)
            s = f.readline()
            self.lineno += 1

        return self.rv

class BaseScanner(LineScanner):
    '''
    Scan for regions of code enclosed in <% %> blocks
    This version uses global pattern matching

    Note that the alphabetical order of the "t_names"
    is critical.  In particular, t_code needs to come
    before t_up_to_code.
    '''
    def t_code(self,s):
        r' <% | %> '
        t = Token(type=s, lineno=self.lineno)
        self.rv.append(t)

    def t_up_to_code(self,s):
        r' .+?(?=(<%|%>)) '
        t = Token(type='data', attr=s, lineno=self.lineno)
        self.rv.append(t)

    def t_default(self,s):
        r' (.|\n)+ '
        t = Token(type='data', attr=s, lineno=self.lineno)
        self.rv.append(t)



#####################################################

class SimpleScanner(GenericScanner):
    '''
    Process the TSP language
    '''
    def __init__(self,lineno):
        GenericScanner.__init__(self)
        self.lineno = lineno
    
    def tokenize(self, input):
        self.rv = []
        GenericScanner.tokenize(self, input)
        return self.rv
    
    def t_whitespace(self, s):
        r' \s+ '
        pass

    def t_acomment(self,s):
        r''' //.*'''
        pass
    
    def t_binop(self,s):
        r'''
           \+= | \-= | ~ | not |
           \+ | \-  | \* | /  |
           == | \!= | <= | >= |
           <  | >   | and | or | \% |
          = | while | if | else | elif | for | \, |
          ; | \{ | \} | print           
           '''
        self.rv.append(Token(type=s,lineno=self.lineno))

    def t_lp(self,s):
        r' \( '
        self.rv.append(Token(type='LEFTP',lineno=self.lineno))

    def t_rp(self,s):
        r' \) '
        self.rv.append(Token(type='RIGHTP',lineno=self.lineno))

    def t_number(self, s):
        r' \d+ '
        t = Token(type='NUMBER', attr=s,lineno=self.lineno)
        self.rv.append(t)

    def t_name(self, s):
        r' [a-zA-Z]\w* '
        t = Token(type='NAME', attr=s,lineno=self.lineno)
        self.rv.append(t)

    def t_string(self, s):
        r' "[^"\\]*(?:\\.[^"\\]*)*" '
        t = Token(type='STRING', attr=eval(s),lineno=self.lineno)
        self.rv.append(t)

    def t_default(self,s):
        r' \n '
        pass

#####################################################
# Convert a series of tokens into a tree
#####################################################

class TSPParser(GenericASTBuilder):
    def __init__(self, AST, start='stmt_list'):
            GenericASTBuilder.__init__(self, AST, start)

    def p_stmt_list(self,args):
        '''
            stmt_list ::= stmt_list stmt
            stmt_list ::= stmt
        '''
        
    def p_stmt(self,args):
        '''
            stmt ::= simple_stmt ;
            stmt ::= complex_stmt
        '''

    def p_simple_stmt(self,args):
        '''
            simple_stmt ::= print print_list
            simple_stmt ::= NAME = test 
            simple_stmt ::= NAME += test 
            simple_stmt ::= NAME -= test
            simple_stmt ::= test
            simple_stmt ::= 
         '''

    def p_complex_stmt(self,args):
        '''
            complex_stmt ::= if LEFTP test RIGHTP suite else suite
            complex_stmt ::= if LEFTP test RIGHTP suite 
            complex_stmt ::= while LEFTP test RIGHTP suite
            complex_stmt ::= for LEFTP simple_stmt ; test ; simple_stmt RIGHTP suite
        '''

    def p_suite(self,args):
        '''
            suite ::= { stmt_list }
            suite ::= simple_stmt ;
        '''

    def p_print_list(self,args):
        '''
            print_list ::= print_list , test
            print_list ::= test
        '''

    def p_test(self,args):
        '''
            test ::= test or and_test
            test ::= and_test
        '''

    def p_and_test(self,args):
        '''
            and_test ::= and_test and not_test
            and_test ::= not_test
        '''

    def p_not_test(self,args):
        '''
            not_test ::= not not_test
            not_test ::= comparison
        '''

    def p_comparison(self,args):
        '''
            comparison ::= comparison comp_op expr
            comparison ::= expr
        '''

    def p_comp_op(self,args):
        '''
            comp_op ::= <
            comp_op ::= >
            comp_op ::= ==
            comp_op ::= !=
            comp_op ::= >=
            comp_op ::= <=
        '''

    def p_expr(self,args):
        '''
            expr ::= expr + term
            expr ::= expr - term
            expr ::= term
        '''

    def p_term(self,args):
        '''
            term ::= term * factor
            term ::= term / factor
            term ::= term % factor
            term ::= factor
        '''

    def p_factor(self,args):
        '''
            factor ::= + factor
            factor ::= - factor
            factor ::= atom
        '''

    def p_atom(self,args):
        '''
            atom ::= NAME LEFTP arg_list RIGHTP
            atom ::= NAME LEFTP RIGHTP
            atom ::= LEFTP test RIGHTP
            atom ::= LEFTP RIGHTP
            atom ::= NAME
            atom ::= NUMBER
            atom ::= STRING
        '''

    def p_arg_list(self,args):
        '''
            arg_list ::= arg_list , test
            arg_list ::= test
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


#####################################################
# Convert print statements of multiple children to
# a list of individual print statements.  Specifically:
#
#         simple_stmt
#           print
#             printlist
#               child1
#               ,
#               child2
#
#  is converted to:
#
#         simple_stmt
#           auto_print
#           auto_print_list
#             simple_stmt
#               print
#               child1
#             simple_stmt
#               print
#               child2
#####################################################

class PrintInversion(GenericASTTraversal):
    'Push print down under the print_list'
    def __init__(self, ast):
        GenericASTTraversal.__init__(self, ast)
        self.preorder()
        
    def n_simple_stmt(self, node):
        '''
                             
        '''
        if len(node) == 2 and node[0].type == 'print' and node[1].type == 'print_list':
            # Push the print into the printlist (which has two elements)
            plistnode = node[1]  # The print_list node
            child1 = plistnode[0]
            child2 = plistnode[2]

            ss1 = AST('simple_stmt')
            ss1[:] = (AST('print'), child1)
            ss2 = AST('simple_stmt')
            ss2[:] = (AST('print'), child2)

            apl = AST('auto_print_list')
            apl[:] = (ss1,ss2)
            apl_header = AST('auto_print')

            node[:] = (apl_header,apl)

#####################################################
# Convert a tree into a list of byte codes
#####################################################

def make_stackless(tree):
    result = tree.value
    if tree.stack:
        result += [('POP', tree.stack)]
    return result
    
class TSPCompiler(GenericASTMatcher):
    def __init__(self,ast,flist):
        GenericASTMatcher.__init__(self,'V',ast)
        self.labels = -1
        self.flist = flist
        self.ast = ast

    def do_parse(self):
        self.match()
        return self.ast.value
        
    def make_label(self):
        self.labels += 1
        return self.labels

    def p_stmt_list(self,tree):
        ' V ::= stmt_list ( V V ) '
        tree.value = tree[0].value + tree[1].value
        tree.stack = 0

    def p_stmt(self,tree):
        ' V ::= stmt ( V ; ) '
        tree.value = make_stackless(tree[0])
        tree.stack = 0

    def p_complex_stmt_if(self,tree):
        ' V ::= complex_stmt ( if LEFTP V RIGHTP V ) '
        label, label2  = (self.make_label(), self.make_label())
        tree.value = tree[2].value + [ ('JUMP_IF_FALSE', label) ]
        tree.value += [('POP',1)] + make_stackless(tree[4])
        tree.value += [('JUMP',label2), ('LABEL', label), ('POP', 1), ('LABEL', label2)]
        tree.stack = 0

    def p_complex_stmt_if_else(self,tree):
        ' V ::= complex_stmt ( if LEFTP V RIGHTP V else V ) '
        label, label2  = (self.make_label(), self.make_label())
        tree.value = tree[2].value + [ ('JUMP_IF_FALSE', label) ]
        tree.value += [('POP',1)] + make_stackless(tree[4])
        tree.value += [('JUMP',label2), ('LABEL', label), ('POP', 1)]
        tree.value += make_stackless(tree[6])
        tree.value += [ ('LABEL', label2) ]
        tree.stack = 0

    def p_complex_stmt_while(self,tree):
        ' V ::= complex_stmt ( while LEFTP V RIGHTP V ) '
        label, label2  = (self.make_label(), self.make_label())
        tree.value = [('LABEL', label)] + tree[2].value + [('JUMP_IF_FALSE', label2)]
        tree.value += [('POP', 1)] + make_stackless(tree[4])
        tree.value += [('JUMP', label), ('LABEL', label2), ('POP', 1) ]
        tree.stack = 0

    def p_complex_stmt_for(self,tree):
        ' V ::= complex_stmt ( for LEFTP V ; V ; V RIGHTP V ) '
        label, label2  = (self.make_label(), self.make_label())
        tree.value = make_stackless(tree[2])
        tree.value += [('LABEL', label)] + tree[4].value + [('JUMP_IF_FALSE', label2)]
        tree.value += [('POP', 1)] + make_stackless(tree[8]) + make_stackless(tree[6])
        tree.value += [('JUMP', label), ('LABEL', label2), ('POP',1) ]
        tree.stack = 0

    def p_simple_stmt_print(self,tree):
        ' V ::= simple_stmt ( print V ) '
        tree.value = tree[1].value + [ ('PRINT', tree[1].stack) ]
        tree.stack = 0

    def p_simple_stmt_auto_print_list(self,tree):
        ' V ::= simple_stmt ( auto_print V ) '
        tree.value = tree[1].value
        tree.stack = tree[1].stack

    def p_print_list(self,tree):
        ' V ::= print_list ( V , V ) '
        tree.value = tree[0].value + tree[2].value
        tree.stack = tree[0].stack + tree[2].stack

    def p_simple_stmt_assign(self,tree):
        ' V ::= simple_stmt ( NAME = V ) '
        tree.value = tree[2].value + [ ('ASSIGN', tree[0].attr) ]
        tree.stack = 0

    def p_simple_stmt_addeq(self,tree):
        ' V ::= simple_stmt ( NAME += V ) '
        tree.value = tree[2].value + [('PUSH_VAR', tree[0].attr), ('ADD',), ('ASSIGN', tree[0].attr)]
        tree.stack = 0
        
    def p_simple_stmt_minuseq(self,tree):
        ' V ::= simple_stmt ( NAME -= V ) '
        tree.value = [('PUSH_VAR', tree[0].attr)] + tree[2].value + [('SUBTRACT',), ('ASSIGN', tree[0].attr)]
        tree.stack = 0

    def p_simple_stmt_null(self,tree):
        ' V ::= simple_stmt '
        tree.value = []
        tree.stack = 0
        
    def p_suite_braces(self,tree):
        ' V ::= suite ( { V } ) '
        tree.value = tree[1].value
        tree.stack = 0

    def p_suite_semicolon(self,tree):
        ' V ::= suite ( V ; ) '
        tree.value = make_stackless(tree[0])
        tree.stack = 0

    def p_test(self,tree):
        ' V ::= test ( V or V ) '
        label = self.make_label()
        tree.value = tree[0].value + [('JUMP_IF_TRUE', label)]
        tree.value += [('POP',1)] + tree[2].value + [('LABEL', label)]
        tree.stack = tree[0].stack + tree[2].stack - 1

    def p_and_test(self,tree):
        ' V ::= and_test ( V and V ) '
        label = self.make_label()
        tree.value = tree[0].value + [('JUMP_IF_FALSE', label)]
        tree.value += [('POP',1)] + tree[2].value + [('LABEL', label)]
        tree.stack = tree[0].stack + tree[2].stack - 1

    def p_not_test(self,tree):
        ' V ::= not_test ( not V ) '
        tree.value = tree[1].value + [('LOGICAL_NOT',)]
        tree.stack = tree[1].stack

    def p_comparison_lt(self,tree):
        ' V ::= comparison ( V < V ) '
        tree.value = tree[0].value + tree[2].value + [ ('LT',) ]
        tree.stack = tree[0].stack + tree[2].stack - 1

    def p_comparison_gt(self,tree):
        ' V ::= comparison ( V > V ) '
        tree.value = tree[0].value + tree[2].value + [ ('GT',) ]
        tree.stack = tree[0].stack + tree[2].stack - 1

    def p_comparison_eq(self,tree):
        ' V ::= comparison ( V == V ) '
        tree.value = tree[0].value + tree[2].value + [ ('EQ',) ]
        tree.stack = tree[0].stack + tree[2].stack - 1
        
    def p_comparison_neq(self,tree):
        ' V ::= comparison ( V != V ) '
        tree.value = tree[0].value + tree[2].value + [ ('NE',) ]
        tree.stack = tree[0].stack + tree[2].stack - 1
        
    def p_comparison_le(self,tree):
        ' V ::= comparison ( V <= V ) '
        tree.value = tree[0].value + tree[2].value + [ ('LE',) ]
        tree.stack = tree[0].stack + tree[2].stack - 1
        
    def p_comparison_ge(self,tree):
        ' V ::= comparison ( V >= V ) '
        tree.value = tree[0].value + tree[2].value + [ ('GE',) ]
        tree.stack = tree[0].stack + tree[2].stack - 1

    def p_expr_add(self,tree):
        ' V ::= expr ( V + V ) '
        tree.value = tree[0].value + tree[2].value + [ ('ADD',) ]
        tree.stack = tree[0].stack + tree[2].stack - 1

    def p_expr_subtract(self,tree):
        ' V ::= expr ( V - V ) '
        tree.value = tree[0].value + tree[2].value + [ ('SUBTRACT',) ]
        tree.stack = tree[0].stack + tree[2].stack - 1

    def p_term_multiply(self,tree):
        ' V ::= term ( V * V ) '
        tree.value = tree[0].value + tree[2].value + [ ('MULTIPLY',) ]
        tree.stack = tree[0].stack + tree[2].stack - 1

    def p_term_divide(self,tree):
        ' V ::= term ( V / V ) '
        tree.value = tree[0].value + tree[2].value + [ ('DIVIDE',) ]
        tree.stack = tree[0].stack + tree[2].stack - 1

    def p_term_mod(self,tree):
        ' V ::= term ( V % V ) '
        tree.value = tree[0].value + tree[2].value + [ ('MOD',) ]
        tree.stack = tree[0].stack + tree[2].stack - 1

    def p_factor_unary_minus(self,tree):
        ' V ::= factor ( - V ) '
        tree.value = tree[1].value + [ ('UNARY_MINUS',) ]
        tree.stack = tree[1].stack

    def p_factor_unary_plus(self,tree):
        ' V ::= factor ( + V ) '
        tree.value = tree[1].value
        tree.stack = tree[1].stack

    # We assume all functions return a single value
    def verify_func(self,fname,lineno,argcount=0):
        if self.flist:
            self.flist.verify(fname,lineno,argcount)
        
    def p_atom_func_with_args(self,tree):
        ' V ::= atom ( V LEFTP V RIGHTP ) '
        tree.value = tree[2].value
        fname = tree[0].value[0][1]
        self.verify_func(fname,tree[0].lineno,tree[2].stack)
        tree.value += [('CALLFUNC',fname)]
        tree.stack = 1

    def p_atom_func(self,tree):
        ' V ::= atom ( V LEFTP RIGHTP ) '
        fname = tree[0].value[0][1]
        self.verify_func(fname,tree[0].lineno)
        tree.value = [('CALLFUNC',fname)]
        tree.stack = 1

    def p_atom_group(self,tree):
        ' V ::= atom ( LEFTP V RIGHTP ) '
        tree.value = tree[1].value
        tree.stack = tree[1].stack

    def p_atom_name(self,tree):
        ' V ::= NAME '
        tree.value = [ ('PUSH_VAR', tree.attr) ]
        tree.stack = 1

    def p_atom_string(self,tree):
        ' V ::= STRING '
        tree.value = [ ('PUSH_STRING', tree.attr) ]
        tree.stack = 1

    def p_atom_number(self,tree):
        ' V ::= NUMBER '
        tree.value = [ ('PUSH_CONST', int(tree.attr)) ]
        tree.stack = 1

    def p_arg_list(self,tree):
        ' V ::= arg_list ( V , V ) '
        tree.value = tree[0].value + tree[2].value
        tree.stack = tree[0].stack + tree[2].stack

    # auto print list processing
    def p_auto_print_list(self,tree):
        ' V ::= auto_print_list ( V V ) '
        tree.value = tree[0].value + tree[1].value
        tree.stack = 0
                                                                     
        
#####################################################

def basic_parse(tlist):
    final_list = []
    state = 'echo'
    current = ""

    for t in tlist:
        if state == 'echo':
            if t.type == '<%':
                state = 'code'
                if current:
                    final_list += [ Token(type='print'),
                                    Token(type='STRING', attr=current),
                                    Token(type=';') ]
                    current = ""
            elif t.type == '%>':
                print 'Error: %> without leading <% at line', t.lineno
                sys.exit(1)
            else:
                current += t.attr
        else:
            if t.type == '%>':
                state = 'echo'
            elif t.type == '<%':
                print 'Error: <% in code block', t.lineno
                sys.exit(1)
            else:
                ss = SimpleScanner(t.lineno)
                final_list += ss.tokenize(t.attr)

    if current:
        final_list += [ Token(type='print'),
                        Token(type='STRING', attr=current),
                        Token(type=';') ]

    return final_list

def dump_pseudo_byte_code(pcode):
    for k in pcode:
        if k[0] == 'LABEL':
            print "%d:" % k[1]
        else:
            print "    ", k


#####################################################

g_ByteCodes = {
    'EOF'           : 0,    # Stops execution
    'PRINT'         : 1,    # output TOS
    'POP'           : 2,    # Drop TOS
    'JUMP_IF_FALSE' : 3,    # Branch on false to LOCATION (2 bytes)
    'JUMP_IF_TRUE'  : 4,    # Branch on true to LOCATION (2 bytes)
    'JUMP'          : 5,    # Branch always to LOCATION (2 bytes)
    'ASSIGN'        : 6,    # Store TOS in global N (byte)
    'PUSH_VAR'      : 7,    # Copy global N (byte)               -> TOS
    'PUSH_CONST'    : 8,    # Copy 2 bytes as int                -> TOS
    'PUSH_STRING'   : 9,    # Copy LOCATION (2 bytes) as string  -> TOS
    'ADD'           : 10,   # TOS1 + TOS  -> TOS
    'SUBTRACT'      : 11,   # TOS1 - TOS  -> TOS
    'LOGICAL_NOT'   : 12,   # not TOS     -> TOS
    'LT'            : 13,   # TOS1 < TOS  -> TOS
    'GT'            : 14,   # TOS1 > TOS  -> TOS
    'EQ'            : 15,   # TOS1 == TOS -> TOS
    'NE'            : 16,   # TOS1 != TOS -> TOS
    'LE'            : 17,   # TOS1 <= TOS -> TOS
    'GE'            : 18,   # TOS1 >= TOS -> TOS
    'MULTIPLY'      : 19,   # TOS1 * TOS  -> TOS
    'DIVIDE'        : 20,   # TOS1 / TOS  -> TOS
    'MOD'           : 21,   # TOS1 % TOS  -> TOS
    'UNARY_MINUS'   : 22,   # - TOS       -> TOS
    'CALLFUNC'      : 23,   # Execute function N (byte)
    'PUSH'          : 24,   # Push N (byte) cleared items on the stack
    }

def make_int( v ):
    return [ (v & 0xff00) >> 8, (v & 0xff) ]

class ByteCodeCompiler:
    def __init__(self,flist):
        'Convert pseudo byte code to compiled byte code'
        self.flist      = flist  # FunctionList (maps function names to constants)

    def compile(self,pcode):
        self.labels     = {}   # Map a label to an offset
        self.globals    = []
        self.jump_fixup = []   # Bcode offsets of labels to be fixed
        self.string_fixup = []
        self.strings      = []

        # Add a PUSH for the globals at the start (fix up length later)
        self.bcode = [ g_ByteCodes['PUSH'], 0 ]

        # Build the basic byte code
        for k in pcode:
            if k[0] in g_ByteCodes:
                self.bcode.append(g_ByteCodes[k[0]])
            name = 'c_' + k[0]
            if hasattr(self, name):
                func = getattr(self,name)
                func(k[1])

        self.bcode.append(g_ByteCodes['EOF'])

        # Add strings to the end
        string_offsets = []
        for s in self.strings:
            string_offsets.append( len(self.bcode) )
            self.bcode += [ord(x) for x in s]
            self.bcode.append(0)   # Null-terminate

        # Fixup the initial clear
        self.bcode[1] = len(self.globals)

        # Fixup the jump list
        for j in self.jump_fixup:
            label = self.bcode[j]
            self.bcode[j:j+2] = make_int(self.labels[label])  # ABSOLUTE!

        # Fixup the string list
        for j in self.string_fixup:
            s = self.bcode[j]
            self.bcode[j:j+2] = make_int(string_offsets[s])  # ABSOLUTE

        return self.bcode

    def c_LABEL(self,arg):
        'Store the position of this label'
        self.labels[arg] = len(self.bcode)
        
    def c_JUMP_IF_FALSE(self,arg):
        '''Next two bytes are relative offset.
           We stash the label number in the first byte and add it to the fixup list'''
        self.jump_fixup.append(len(self.bcode))
        self.bcode += [ arg, 0 ]

    def c_JUMP_IF_TRUE(self,arg):
        '''Next two bytes are relative offset.
           We stash the label number in the first byte and add it to the fixup list'''
        self.jump_fixup.append(len(self.bcode))
        self.bcode += [ arg, 0 ]

    def c_JUMP(self,arg):
        '''Next two bytes are relative offset.
           We stash the label number in the first byte and add it to the fixup list'''
        self.jump_fixup.append(len(self.bcode))
        self.bcode += [ arg, 0 ]

    def c_ASSIGN(self,arg):
        ' One byte indicating stack offset of variable '
        if arg not in self.globals:
            self.globals.append(arg)
        self.bcode.append(self.globals.index(arg))
    
    def c_PUSH_VAR(self,arg):
        ' One byte indicating stack offset of variable '
        if arg not in self.globals:
            self.globals.append(arg)
        self.bcode.append(self.globals.index(arg))
    
    def c_PUSH_CONST(self,arg):
        ' A two byte integer '
        self.bcode += make_int(arg)
    
    def c_PUSH_STRING(self,arg):
        self.string_fixup.append(len(self.bcode))
        if arg not in self.strings:   # Avoid duplications
            self.strings.append(arg)
        self.bcode += [ self.strings.index(arg), 0 ]

    def c_CALLFUNC(self,arg):
        try:
            self.bcode.append( self.flist.index(arg) )
        except:
            print 'Error: unable to locate function "%s" in the function table' % arg
            sys.exit(1);
    

#####################################################

def compileTSP(filename,function_dict,stop_after=None,verbose=0):
    fd = open(filename)
    bs = BaseScanner()
    tlist = bs.process_lines(fd)

    if verbose:
        print '********** First tokenizing pass *************'
        dump_token_list(tlist)

    final_list = basic_parse(tlist)

    if verbose:
        print '********** Second tokenizing pass *************'
    if verbose or stop_after == 'token':
        dump_token_list(final_list)
    if stop_after == 'token': return

    parser = TSPParser(AST)
    atree = parser.parse(final_list)

    if verbose:
        print '***** Initial Parse Tree ******'
    if verbose or stop_after == 'buildtree':
        dump_ast(atree)
    if stop_after == 'buildtree': return

    PrintInversion(atree)
    if verbose:
        print '***** Print inversion parse tree *****'
    if verbose or stop_after == 'checktree':
        dump_ast(atree)
    if stop_after == 'checktree': return
    
    tspc = TSPCompiler(atree,function_dict)
    pseudo_byte_code = tspc.do_parse()

    if verbose:
        print '**** Generated Byte Code ****'
    if verbose or stop_after == 'pseudocode':
        dump_pseudo_byte_code(pseudo_byte_code)
    if stop_after == 'pseudocode': return

    bcc = ByteCodeCompiler(function_dict)
    return bcc.compile(pseudo_byte_code)

################################################################

if __name__=='__main__':
    import getopt

    stages = ('token','buildtree','checktree','pseudocode')

    def usage():
        print """
        Usage:  compileTSP.py [OPTS] FILENAME

        Valid options:
             -v, --verbose
             -f, --functions FUNCTION_FILE      A file with defined external functions
             -s, --stop STAGE                   Stop after a stage of compilation.  Valid
                                                stages are %s
        """ % ", ".join(["'%s'" % x for x in stages])
        sys.exit(1)
    
    try:
        (options,argv) = getopt.getopt(sys.argv[1:], 'vhf:s:', ['verbose', 'help', 'functions=', 'stop='])
    except Exception, e:
        print e
        usage()

    verbose    = 0
    ffile      = []
    stop_after = None
    
    for (k,v) in options:
        if k in ('-v', '--verbose'):
            verbose += 1
        elif k in ('-f', '--functions'):
            ffile.append(v)
        elif k in ('-h', '--help'):
            usage()
        elif k in ('-s', '--stop'):
            if v not in stages:
                usage()
            stop_after = v
        else:
            usage()

    if len(argv) != 1:
        usage()

    fflist = None
    for f in ffile:
        flist = makeFunctionList(f,verbose)
        
    byte_code = compileTSP(argv[0],flist,stop_after,verbose)
    print byte_code

    from decompileTSP import Decompiler
    d = Decompiler(flist)
    d.decompile(byte_code)
    

