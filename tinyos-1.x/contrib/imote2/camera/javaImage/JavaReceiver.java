/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2005 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * @author Konrad Lorincz
 * @version 1.0, August 15, 2005
 */
import net.tinyos.util.*;
import net.tinyos.message.*;
import java.util.*;
import java.io.*;
import java.awt.*;




class BayerImage
{
    final int MAX_BAYER_VALUE = 1024; // 10-bit
    final int MAX_RGB_VALUE = 255; // 8-bit
    final int GREEN_PIXEL = 1;
    final int RED_PIXEL = 2;
    final int BLUE_PIXEL = 3;

    int xSize = 0;
    int ySize = 0;
    private ArrayList<Integer> pixels = null;


    BayerImage(int xSize, int ySize)
    {
        this.xSize = xSize;
        this.ySize = ySize;
        pixels = new ArrayList<Integer>();
        for (int i = 0; i < xSize * ySize; ++i)
            pixels.add(i, MAX_BAYER_VALUE / 2);
    }


    boolean add(int index, int value)
    {
        if (index < 0 || pixels.size() <= index) {
            System.err.println("BayerImage.add() - ERROR, index is outside valid range, index= " + index + ", maxIndexValue= " + (pixels.size() - 1));
            //System.exit(1);
            return false;
        }
        else if (value < 0 || MAX_BAYER_VALUE < value) {
            System.err.println("BayerImage.add() - WARNING, value is outside valid range, index= " + index + ", value= " + value + "!");
            return false;
        }
        else {
            pixels.set(index, value);
            return true;
        }
    }

    int getXCoord(int index)
    {
        return index % xSize;
    }

    int getYCoord(int index)
    {
        return index / xSize;
    }

    Point getCoord(int index)
    {
        return new Point(getXCoord(index), getYCoord(index));
    }

    int getPixelValue(Point pt)
    {
        int index = pt.y * xSize + pt.x;
        return pixels.get(index);
    }

    int scaleValueBayerToRGB(int bayerValue)
    {
        int val = (int) Math.round((double) bayerValue * (double) MAX_RGB_VALUE / (double) MAX_BAYER_VALUE);

        if (val > 255) {
            System.out.println("scaleValueBayerToRGB() - ERROR, val= " + val);
            return 254;
        }
        else
            return val;
    }

    int getPixelType(int index)
    {
        if (index % 2 == 0)
            return GREEN_PIXEL;
        else if (getYCoord(index) % 2 == 0)
            return RED_PIXEL;
        else
            return BLUE_PIXEL;
    }


    Color getBayerColor(int index)
    {
        int scaledValue = scaleValueBayerToRGB(pixels.get(index));

        if (getPixelType(index) == GREEN_PIXEL)
            return new Color(0, scaledValue, 0);
        else if (getPixelType(index) == RED_PIXEL)
            return new Color(scaledValue, 0, 0);
        else // Blue
            return new Color(0, 0, scaledValue);
    }

    Color getRGBColor(int index)
    {
        return new Color(rgbRedEstimate(index),
                         rgbGreenEstimate(index),
                         rgbBlueEstimate(index));
    }

    boolean isInsideImage(Point point)
    {
        return (0 <= point.x && point.x < this.xSize &&
                0 <= point.y && point.y < this.ySize);
    }

    private int averageValue(ArrayList<Point> points)
    {
        double sum = 0;
        int nbrPointsInSum = 0;

        for (int i = 0; i < points.size(); ++i) {
            Point pt = points.get(i);
            if (isInsideImage(pt)) {
                sum += getPixelValue(pt);
                nbrPointsInSum++;
            }
        }

        if (nbrPointsInSum == 0) {
            System.err.println("averageValue() - WARNING, zero point to average, sum= " + sum + "!, POINTS:");
            for (int i = 0; i < points.size(); ++i)
                System.out.println(points.get(i));
            return 0;
        }
        else
            return (int) Math.round(sum / nbrPointsInSum);
    }


    int rgbGreenEstimate(int index)
    {
        Point p = new Point(getCoord(index));

        if (getPixelType(index) == GREEN_PIXEL) {
            // Nothing to estimate
            return scaleValueBayerToRGB(pixels.get(index));
        }
        else { // For both Red and Blue, the Green neighbors are at the same locations
            // 4 Green pixels: up, down, left, right
            ArrayList<Point> greenPixels = new ArrayList<Point>();
            greenPixels.add(new Point(p.x - 1, p.y));
            greenPixels.add(new Point(p.x + 1, p.y));
            greenPixels.add(new Point(p.x, p.y - 1));
            greenPixels.add(new Point(p.x, p.y + 1));
            return scaleValueBayerToRGB(averageValue(greenPixels));
        }
    }

    int rgbRedEstimate(int index)
    {
        Point p = new Point(getCoord(index));

        if (getPixelType(index) == RED_PIXEL) {
            // Nothing to estimate
            return scaleValueBayerToRGB(pixels.get(index));
        }
        else if (getPixelType(index) == GREEN_PIXEL) {
            ArrayList<Point> redPixels = new ArrayList<Point>();
            if (getYCoord(index) % 2 == 0) {
                // 2 Red pixels: left, right
                redPixels.add(new Point(p.x - 1, p.y));
                redPixels.add(new Point(p.x + 1, p.y));
                return scaleValueBayerToRGB(averageValue(redPixels));
            }
            else {
                // 2 Red pixels: up, down
                redPixels.add(new Point(p.x, p.y - 1));
                redPixels.add(new Point(p.x, p.y + 1));
                return scaleValueBayerToRGB(averageValue(redPixels));
            }
        }
        else { // Blue
            // 4 Red pixels: upper-left, upper-right, lower-left, lower-right
            ArrayList<Point> redPixels = new ArrayList<Point>();
            redPixels.add(new Point(p.x - 1, p.y - 1));
            redPixels.add(new Point(p.x + 1, p.y - 1));
            redPixels.add(new Point(p.x - 1, p.y + 1));
            redPixels.add(new Point(p.x + 1, p.y + 1));
            return scaleValueBayerToRGB(averageValue(redPixels));
        }
    }

    int rgbBlueEstimate(int index)
    {
        Point p = new Point(getCoord(index));

        if (getPixelType(index) == BLUE_PIXEL) {
            // Nothing to estimate
            return scaleValueBayerToRGB(pixels.get(index));
        }
        else if (getPixelType(index) == GREEN_PIXEL) {
            ArrayList<Point> bluePixels = new ArrayList<Point>();
            if (getYCoord(index) % 2 == 0) {
                // 2 Blue pixels: up, down
                bluePixels.add(new Point(p.x, p.y - 1));
                bluePixels.add(new Point(p.x, p.y + 1));
                return scaleValueBayerToRGB(averageValue(bluePixels));
            }
            else {
                // 2 Blue pixels: left, right
                bluePixels.add(new Point(p.x - 1, p.y));
                bluePixels.add(new Point(p.x + 1, p.y));
                return scaleValueBayerToRGB(averageValue(bluePixels));
            }
        }
        else { // Red
            // 4 Blue pixels: upper-left, upper-right, lower-left, lower-right
            ArrayList<Point> bluePixels = new ArrayList<Point>();
            bluePixels.add(new Point(p.x - 1, p.y - 1));
            bluePixels.add(new Point(p.x + 1, p.y - 1));
            bluePixels.add(new Point(p.x - 1, p.y + 1));
            bluePixels.add(new Point(p.x + 1, p.y + 1));
            return scaleValueBayerToRGB(averageValue(bluePixels));
        }
    }

    private FileWriter fileOpen(String fileName)
    {
        FileWriter imageFile = null;
        try {
            imageFile = new FileWriter(fileName);
            imageFile.write("# ImageMagick pixel enumeration: " + xSize + "," + ySize + ",255,RGB\n");

        } catch (IOException e) {
            System.err.println("\nCan't open file!" + e);
            e.printStackTrace();
        }
        return imageFile;
    }

    private void fileWriteln(FileWriter file, String str)
    {
        try {
            file.write(str + "\n");
        } catch (IOException e) {
            System.err.println("Can't write to the file!" + e);
        }
    }

    private void fileClose(FileWriter file)
    {
        try {
            file.close();
        } catch (IOException e) {
            System.err.println("Can't close file!" + e);
        }
    }


    void genBayerImage()
    {
        FileWriter imageFile = fileOpen("bayerImage.txt");

        for (int i = 0; i < pixels.size(); ++i) {
            String str = pixelToString(getCoord(i), getBayerColor(i));
            fileWriteln(imageFile, str);
        }

        fileClose(imageFile);

        runSystemCommand("convert.exe bayerImage.txt bayerImage.bmp");
    }

    void genRGBImage()
    {
        FileWriter imageFile = fileOpen("rgbImage.txt");

        for (int i = 0; i < pixels.size(); ++i) {
            String str = pixelToString(getCoord(i), getRGBColor(i));
            fileWriteln(imageFile, str);
        }

        fileClose(imageFile);

        runSystemCommand("convert.exe rgbImage.txt rgbImage.bmp");
    }

    String pixelToString(Point coord, Color color)
    {
        return coord.x + "," + coord.y + ":  ( " + color.getRed() + ", " + color.getGreen() + ", " + color.getBlue() + ")";
    }

    private void runSystemCommand(String cmd)
    {
        Process childProcess = null;
        try {
            childProcess = Runtime.getRuntime().exec(cmd);
            childProcess.waitFor(); // wait for the chile process to complete before continuing
        } catch (Exception e) {
            System.err.println("Error on exec() method");
            e.printStackTrace();
        }

    }
}




/**
 *
 * @author Konrad Lorincz
 * @version 1.0, August, 2005
 */
public class JavaReceiver implements MessageListener
{
    BayerImage image = new BayerImage(128, 128);

    JavaReceiver()
    {
        MoteIF mote = new MoteIF(PrintStreamMessenger.err); // uses MOTECOM!
        mote.registerListener(new ImageMsg(), this);
    }

    static long byteArrayToLong(short[] byteArray, int startIndex, int nbrBytes)
    {
        int longValue = 0;
        for (int i = 0; i < nbrBytes; ++i)
            longValue |= ((byteArray[startIndex+i] & 0xff) << (i*8));

        return longValue;
    }

    static String toBitString(long nbr)
    {
        String str = "";
        for (int i = 0; i < 32; ++i) {
            if (i % 16 == 0)
                str = "    " + str;
            else if (i % 8 == 0)
                str = "  " + str;
            else if (i % 4 == 0)
                str = " " + str;

            str = ((nbr >> i) & 1) + str;
        }

        return str;
    }


    public void messageReceived(int dstaddr, Message msg)
    {
        if (msg instanceof ImageMsg) {
            ImageMsg imageMsg = (ImageMsg) msg;

            //System.out.print("startIndex= " + imageMsg.get_startIndex() +
            //                   "  dataSize= " + imageMsg.get_dataSize());

            short dataSize = imageMsg.get_dataSize();
            short[] startIndexByteArray = imageMsg.get_startIndex();
            short[] dataByteArray = imageMsg.get_data();

            long startIndex = byteArrayToLong(startIndexByteArray, 0, 4);

            System.out.println("startIndex= " + startIndex +
                               "  dataSize= " + dataSize);


//            System.out.println("dataByteArray.length= " + dataByteArray.length +
//                               "dataSize= " + dataSize);
            for (int i = 0; i < dataByteArray.length && i < dataSize*4; i += 2) {
                int pixelValue = (int) byteArrayToLong(dataByteArray, i, 2);
                int pixelIndex = (int) startIndex*2 + i/2;
                System.out.println("pixel[" + pixelIndex + "] = " + pixelValue + "   " + toBitString(pixelValue));
                image.add(pixelIndex, pixelValue);
            }

            // Are we done
            if (startIndex >= (image.xSize * image.ySize / 2) - 4) {
                System.out.println("**** Generating output files ****");
                image.genBayerImage();
                image.genRGBImage();
            }
        }
    }

    public static void main(String args[])
    {
        JavaReceiver myapp = new JavaReceiver();
//        BayerImage image = new BayerImage(16, 8);
//        image.add(0, 128);
//        image.add(22, 1000);
//        image.add(32, 500);
//        image.add(60, 529);
//        image.add(80, 36);
//        image.add(100, 725);
//        image.add(120, 55);
//
//        image.genBayerImage();
//        image.genRGBImage();
    }
}
