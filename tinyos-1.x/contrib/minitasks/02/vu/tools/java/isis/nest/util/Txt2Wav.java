/*
 * Copyright (c) 2002, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Date last modified: 3/20/03
 */

package isis.nest.util;

import java.util.*;
import java.io.*;

class Txt2Wav
{
	static final int TYPE_UNSIGNED1 = 1;
	static final int TYPE_SIGNED1 = 2;
	static final int TYPE_UNSIGNED2 = 3;
	static final int TYPE_SIGNED2 = 4;
	static final int TYPE_ZC3 = 5;

	protected String inputFile;
	protected String outputFile;
	protected int sampleType = TYPE_UNSIGNED1;
	protected int sampleSize = 1;
	protected float samplingRate = 8;
	protected int omitTokens = 0;

	protected boolean parseArguments(String[] args)
	{
		try
		{
			for(int i = 0; i < args.length; ++i)
			{
				if( args[i].equals("-help") )
				{
					System.out.println("Usage: java Txt2Wav [parameters] <input.txt> [<output.wav>]");
					System.out.println("Options:");
					System.out.println("  [-rate <jiffies>]     The sampling rate in jiffies (8)");
					System.out.println("  [-type <type>]        One of the following types: (unsigned1)");
					System.out.println("      unsigned1           unsigned byte");
					System.out.println("      signed1             signed byte");
					System.out.println("      unsigned2           unsigned word");
					System.out.println("      signed2             signed word");
					System.out.println("      zc3                 zero crossing record (length, ampitude, *)");
					System.out.println("  [-omit <tokens>]      Ignore this many leading tokens from each line (0)");
					System.out.println("  [-help]               Prints out this message");
					return false;
				}
				else if( args[i].equals("-type") )
				{
					++i;
					if( args[i].equals("unsigned1") )
					{
						sampleType = TYPE_UNSIGNED1;
						sampleSize = 1;
					}
					else if( args[i].equals("signed1") )
					{
						sampleType = TYPE_SIGNED1;
						sampleSize = 1;
					}
					else if( args[i].equals("unsigned2") )
					{
						sampleType = TYPE_UNSIGNED2;
						sampleSize = 2;
					}
					else if( args[i].equals("signed2") )
					{
						sampleType = TYPE_SIGNED2;
						sampleSize = 2;
					}
					else if( args[i].equals("zc3") )
					{
						sampleType = TYPE_ZC3;
						sampleSize = 1;
					}
					else
					{
						System.out.println("Invalid sample type.");
						return false;
					}
				}
				else if( args[i].equals("-rate") )
					samplingRate = Float.parseFloat(args[++i]);
				else if( args[i].equals("-omit") )
					omitTokens = Integer.parseInt(args[++i]);
				else if( args[i].startsWith("-") )
				{
					System.out.println("Invalid option: " + args[i]);
					return false;
				}
				else if( inputFile == null )
					inputFile = args[i];
				else if( outputFile == null )
					outputFile = args[i];
				else
				{
					System.out.println("Too many arguments.");
					return false;
				}
			}
		}
		catch(Exception e)
		{
			System.err.println("Missing or invalid parameter(s)");
			return false;
		}

		if( inputFile == null )
		{
			System.out.println("The input file must be specified.");
			return false;
		}

		if( outputFile == null )
		{
			int i = inputFile.lastIndexOf('.');
			if( i >= 0 )
				outputFile = inputFile.substring(0, i) + ".wav";
			else
				outputFile = inputFile + ".wav";
		}

		return true;
	}

	public static void main(String[] args) throws IOException
	{
		Txt2Wav obj = new Txt2Wav();
		if( obj.parseArguments(args) )
			obj.process();
	}

	public static void writeEndianInt(DataOutput stream, int a) throws IOException
	{
		stream.writeByte(a & 0xFF);
		stream.writeByte((a >> 8) & 0xFF);
		stream.writeByte((a >> 16) & 0xFF);
		stream.writeByte((a >> 24) & 0xFF);
	}

	public static void writeEndianShort(DataOutput stream, int a) throws IOException
	{
		stream.writeByte(a & 0xFF);
		stream.writeByte((a >> 8) & 0xFF);
	}

	public void process() throws IOException
	{
		out = new ByteArrayOutputStream();

		BufferedReader in = new BufferedReader(new FileReader(inputFile));

		String line;
		while( (line = in.readLine()) != null )
			decode(line);

		in.close();

		DataOutputStream wav = 
			new DataOutputStream(
				new BufferedOutputStream(
					new FileOutputStream(outputFile)));

		byte[] data = out.toByteArray();

		wav.writeBytes("RIFF");
		writeEndianInt(wav, 36 + data.length);	// total length
		wav.writeBytes("WAVE");
		wav.writeBytes("fmt ");
		writeEndianInt(wav, 0x10);				// length of fmt
		writeEndianShort(wav, 0x1);				// always
		writeEndianShort(wav, 0x1);				// mono
		int rate = (int)(32768.0/samplingRate);
		writeEndianInt(wav, rate);				// sampling rate in HZ
		writeEndianInt(wav, sampleSize * rate);	// bytes per sec
		writeEndianShort(wav, sampleSize);		// bytes per sample
		writeEndianShort(wav, sampleSize * 8);	// bits per sample
		wav.writeBytes("data");
		writeEndianInt(wav, data.length);		// length of data block
		wav.write(data, 0, data.length);

		wav.close();
	}

	ByteArrayOutputStream out;

	public void decode(String line)
	{
		StringTokenizer tokenizer = new StringTokenizer(line);

		for(int i = 0; i < omitTokens; ++i)
			tokenizer.nextToken();

		if( sampleType == TYPE_UNSIGNED1 )
		{
			while( tokenizer.hasMoreTokens() )
			{
				byte a = (byte)Integer.parseInt(tokenizer.nextToken());
				out.write(a);
			}
		}
		else if( sampleType == TYPE_SIGNED1 )
		{
			while( tokenizer.hasMoreTokens() )
			{
				byte a = (byte)Integer.parseInt(tokenizer.nextToken());

				a += 128;

				out.write(a);
			}
		}
		else if( sampleType == TYPE_UNSIGNED2 )
		{
			while( tokenizer.hasMoreTokens() )
			{
				byte a = (byte)Integer.parseInt(tokenizer.nextToken());
				byte b = (byte)Integer.parseInt(tokenizer.nextToken());

				out.write(a);
				out.write(b);
			}
		}
		else if( sampleType == TYPE_SIGNED2 )
		{
			while( tokenizer.hasMoreTokens() )
			{
				byte a = (byte)Integer.parseInt(tokenizer.nextToken());
				byte b = (byte)Integer.parseInt(tokenizer.nextToken());

				b -= 128;

				out.write(a);
				out.write(b);
			}
		}
		else if( sampleType == TYPE_ZC3 )
		{
			boolean sign = true;

			while( tokenizer.hasMoreTokens() )
			{
				int a = Integer.parseInt(tokenizer.nextToken()) & 0xFF;
				int b = Integer.parseInt(tokenizer.nextToken()) & 0xFF;
				int c = Integer.parseInt(tokenizer.nextToken());

				if( sign )
					b = 128 + b;
				else
					b = 128 - b;

				if( b > 255)
					b = 255;
				else if( b < 0 )
					b = 0;

				for(int i = 1; i <= a; ++i)
					out.write(b);

				sign = ! sign;
			}
		}
	}
}
