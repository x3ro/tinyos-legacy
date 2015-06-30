
tosmsg:
	latex tosmsg
	dvips -o tosmsg.ps tosmsg.dvi
	dvipdfm tosmsg.dvi

sensor_power:
	latex sensor_power
	dvips -o sensor_power.ps sensor_power.dvi
	dvipdfm sensor_power.dvi


all: sensor_power tosmsg

clean:
	rm -rf *~ *.aux *.dvi *.ps *.log 
