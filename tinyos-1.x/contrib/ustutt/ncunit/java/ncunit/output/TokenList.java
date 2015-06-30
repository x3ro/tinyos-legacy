/**
 * Copyright (c) 2007, Institute of Parallel and Distributed Systems
 * (IPVS), Universität Stuttgart. 
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the
 *    distribution.
 * 
 *  - Neither the names of the Institute of Parallel and Distributed
 *    Systems and Universität Stuttgart nor the names of its contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */
package ncunit.output;

import java.io.IOException;
import java.io.InputStream;
import java.io.PipedInputStream;
import java.io.PipedOutputStream;
import java.io.PrintWriter;

import ncunit.parser.Token;

/**
 * 
 * 
 * @author lachenas
 */
public class TokenList {

	private Token head;

	private Token tail;

	public TokenList(Token head, Token tail) {
		this.head = head;
		this.tail = tail;
	}

	public void print(PrintWriter pw) {
		for (Token p = head; true; p = p.next) {
			printSpecialTokens(pw, p.specialToken);
			pw.print(p.image);
			if (p == tail) {
				break;
			}
		}
		pw.close();
	}

	private void printSpecialTokens(PrintWriter pw, Token st) {
		if (st != null) {
			printSpecialTokens(pw, st.specialToken);
			pw.print(st.image);
		}
	}

	public void printWithSpecials(PrintWriter pw) {
		for (Token p = head; p != tail; p = p.next) {
			printSpecialTokens(pw, p.specialToken);
			pw.print(p.image);
		}
	}
	
	public InputStream getOutputAsInputStream() throws IOException {
		PipedOutputStream outputStream = new PipedOutputStream();
		final PrintWriter outputWriter = new PrintWriter(outputStream);
		PipedInputStream result =  new PipedInputStream(outputStream);
		new Thread() {
			public void run() {
				print(outputWriter);
				outputWriter.close();
			}
		}.start();
		return result;
	}

}
