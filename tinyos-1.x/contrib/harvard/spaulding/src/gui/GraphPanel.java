/*
 * Copyright (c) 2007
 *	The President and Fellows of Harvard College.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

import java.awt.*;
import javax.swing.*;
import de.progra.charting.*;
import de.progra.charting.swing.*;
import de.progra.charting.event.*;
import de.progra.charting.model.*;
import de.progra.charting.render.*;
/**
 *
 * @author  Sebastian Mueller, (extended by Konrad Lorincz)
 */
public class GraphPanel extends JPanel implements ChartDataModelListener
{
    private ChartPanel panel = null;
    private EditableChartDataModel data = null;
    private JLabel labelNoData = null;
    private String title = "";
    private String xLabel = "     ";
    private String yLabel = "                            ";  // Hack, because the rendering appears to have a bug
    private final static double TIME_WINDOW_SIZE = 30;
    //private final static int MIN_DISPLAY_ROWS = 4096;
    private int minDisplayedY = 0;
    private int maxDisplayedY = 4096;

    public GraphPanel(String title, String xLabel, String yLabel)
    {
        this.xLabel += xLabel;
        this.yLabel += yLabel;
        GraphPanelConstructor(title, xLabel, yLabel, new double[]{0.001}, new double[]{0.001});
    }

    public GraphPanel(String title, String xLabel, String yLabel, double[] xData, double[] yData)
    {
        this.xLabel += xLabel;
        this.yLabel += yLabel;
        GraphPanelConstructor(title, xLabel, yLabel, xData, yData);
    }

    private void GraphPanelConstructor(String title, String xLabel, String yLabel, double[] xData, double[] yData)
    {
        double[]    columns;
        double[][]  model;

        if (xData.length < 3) {
            columns = new double[3];
            model   = new double[1][3];

            for (int i = 0; i < columns.length; ++i) {
                if (i < xData.length) {
                    columns[i] = xData[i];
                    model[0][i] = yData[i];
                }
                else {
                    columns[i] = xData[xData.length-1] + 0.001;
                    model[0][i] = yData[xData.length-1] + 0.001;
                }
            }
        }
        else {
            columns = xData;
            model = new double[1][yData.length];
            model[0] = yData;
        }

        this.title = title;
        // --------------------------------------
        String[] rowLabels = {title};
        data = new EditableChartDataModel(model, columns, rowLabels);
        data.addChartDataModelListener(this);
        // -----------------------

        DefaultChartDataModelConstraints cdm = new DefaultChartDataModelConstraints(data, CoordSystem.FIRST_YAXIS) {
            public double getMinimumColumnValue() {
                return Math.max(0, super.getMaximumColumnValue() - TIME_WINDOW_SIZE);
            }
            public double getMaximumColumnValue() {
                return Math.max(TIME_WINDOW_SIZE, super.getMaximumColumnValue());
            }

            public Number getMinimumValue() {
                //return Math.min(0, super.getMinimumValue().doubleValue());
                return minDisplayedY;
            }
            public Number getMaximumValue() {
                //if (super.getMaximumValue().doubleValue() < MIN_DISPLAY_ROWS)
                //    return MIN_DISPLAY_ROWS + 5;
                //else
                //    return super.getMaximumValue();
                return maxDisplayedY;
            }
        };
        data.setChartDataModelConstraints(CoordSystem.FIRST_YAXIS, cdm);

        // -------------------------
        panel = new ChartPanel(data, title, DefaultChart.LINEAR_X_LINEAR_Y);
        Font font = new Font("Helvetica", Font.PLAIN, 1);
        panel.setTitle(new Title(title, font));
        // -------------------------

        panel.getCoordSystem().setXAxisUnit(xLabel);
        panel.getCoordSystem().setYAxisUnit(yLabel);

        panel.addChartRenderer(new LineChartRenderer(panel.getCoordSystem(), data), 1);

        if (labelNoData != null)
            this.remove(labelNoData);

        this.setLayout(new BorderLayout());
        this.add(panel, BorderLayout.CENTER);
    }

    public void setYDisplayRange(int minY, int maxY) {
        assert (maxY > minY);
        minDisplayedY = minY;
        maxDisplayedY = maxY;
    }

    public void setMaxNbrValues(int maxNbrValues)
    {
        if (data != null)
            data.setMaxNbrValues(maxNbrValues);
    }

    synchronized void addData(final double xValue, final double yValue)
    {
        javax.swing.SwingUtilities.invokeLater(new Runnable() {
            public void run() {
                if (data == null)
                    GraphPanelConstructor(title, xLabel, yLabel, new double[] {xValue}, new double[] {yValue});
                else {
                    data.insertValue(0, new Double(yValue), new Double(xValue));
                }
            }
        });
    }

    public void setTitle(String newTitle)
    {
        panel.getTitle().setText(newTitle);
    }

    public void chartDataChanged(ChartDataModelEvent evt)
    {
        // The DataModel changed -> update display
        panel.revalidate();
        repaint();
    }
}
