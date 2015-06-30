Author/Contact
		janos.sallai@vanderbilt.edu (Janos Sallai, ISIS, Vanderbilt)
		miklos.maroti@vanderbilt.edu (Miklos Maroti, ISIS, Vanderbilt)
		gyorgy.balogh@vanderbilt.edu (Gyorgy Balogh, ISIS, Vanderbilt)
		
DESCRIPTION: 

The package isis.nest.acousticlocalization contains the java part of the 
AcousticLocalization application. AcousticLocalization.class is a MessageCenter 
module that controls the ranging measurement and calculates the mote positions 
from the measurement results and from the known mote positions.

USAGE:

- UPLOADING THE APPLICATION
Upload motes with the acoustic localization application 
(apps/AcousticLocalization), equip them with standard sensor boards. Distribute 
them in an outdoor environment.

- UPLOADING THE BASE STATION
Upload a mote with GenericBase to be used as the base station. We suggest using 
our version of GenericBase, which can be found in the same app directory as 
AcousticLocalization.

- STARTING MESSAGECENTER
Start MessageCenter (java isis.nest.messageCenter.CenterFrame) and start 
SerialConnector with the appropriate port parameters. For details, see the 
README.txt for the isis.nest.messageCenter package.

- LAUNCHING THE ACOUSTICLOCALIZATION MODULE
Launch the AcousticLocalization module. Either choose AcousticLocalization from 
the app list of AppLoader, or, if it is not there, load it by entering 
isis.nest.acousticlocalization.AcousticLocalization into the text field below 
and click the LoadApp button. After the first usage the modul will appear in the 
list of applications.

- INITIALIZING ROUTING
The AcousticRouting application on the motes relies on FloodRounting 
(tos/lib/FloodRouting) to route the ranging results back to the base station. 
The routing needs to be initialized, specifying a single mote towards which the 
messages should be routed. This mote should be the the closest one to the base 
station. To do this, enter the ID of the root mote in the "ID of root mote" 
field and click the "Initialize FloodRouting button".

- STARTING RANGING
Click on the "Start Ranging" button to start the measurement. It takes about 3 
minutes for the algorithm to finish. While the ranging is running valid 
measurement results are being displayed in the "Ranging Measurements" table. 
Ranging can be stopped any time with the "Stop Ranging" button.

- TIME SLOT NEGOTIATION
The acoustic localization application uses a two phase algorithm. First the 
motes chose a time slot (integer between 0 and a fixed positive number, by 
default 32), then they emit an acoustic beacon message in their time slots. Time 
slots of motes that are close to each other should not be the same, beacuse it 
would cause overhearings and possibly false measurement results. The time slot 
negotiation algorith is responsible for the uniqueness of the time slots within 
the hearing distance of each mote. By default it runs when the network is idle 
(i.e., no ranging measurements are going on). Time slot negotiation can be 
disabled by the "Stop Time Slot Negotiation" button, and enabled by clicking 
"Start Time Slot Negotiation". For details see README.txt in 
apps/TimeSlotNegotiation.

- SAVING/LOADING RANGING MEASUREMENT
Ranging measurements, as well as known positions (see later) can be saved 
to/loaded from a text file by clicking on the "Save"/"Load" button. Click on 
".." to choose a file or enter the file name (with complete path) into the text 
field. A sample file "test_input_file.txt" can be found in this directory.

- SPECIFYING KNOWN POSITIONS
Specify the known mote positions on the fixed positions tab. The localization 
algorithm requires the search space specification and the known mote positions 
in the following form:
The first two lines specify the search space (3 coordinates per each line). In 
the following example the x coordinates of the motes will be searched in [0.0, 
100.0], the y coordinates in [10.0, 200.0], and the z coordinates in [-20.0, 
20.0] respectively.
Example:
0.0     10.0     20.0
100.0   200.0    -20.0

Mote positions can be specified with the 'pos' label followed by the mote ID and 
the 3 (x, y, z)coordinates.
Example:
pos	213	10.0	10.0	10.0

Use the flag 'x' instead of the coordinate if the coordinate is unknown.
Example:
pos	213	10.0	10.0	x

Use 'startpos' instead of pos if the approximate position is known, but it needs 
to be refined.
Example:
startpos	213	15.0	12.0	12.0
or, with unknown coordinates:
startpos	213	x	x	12.0

Other tokens are not allowed and may cause errors. All whitespace characters 
are treated as delimiters.

- RUNNING THE LOCALIZATION ALGORITHM
Click on the "Calculate Positions" button on the "Localization" tab to calculate 
the mote positions. Using the anchor points (i.e. known positions) the 
localization algorithm tries to find the position of the rest of the motes with 
a stochastic search based on a simple spring model. Motes that have less than 3 
neigbors cannot be localized and discarded by the algorithm. If there are more 
than one measurements between a pair of motes, their average is used in the 
spring model. The localization algorithm may run for up to a few minutes, 
depending on the number of motes and mote-to-mote measurements. The button 
remains pressed while it is running. A map of motes is displayed in the "Map of 
calculated positions" area after the algorithm finishes. Motes with known 
positions are displayed as big circles, the ones with unknown positions are 
represented by small circles. Lines between motes mean that there were valid 
measurements between the end point motes.

- SAVING CALCULATED POSITIONS
Calculated positions can be saved to a text file by clicking on the "Write positions to 
file" button. Click on ".." to choose a file or enter the file name (with 
complete path) into the text field. A sample file "test_output_file.txt" can be found
in this directory.

REQUIREMENTS

Java JRE 1.4.0 or newer. (1.4.1 recommended)
MessageCenter rev1.1 or newer

LIMITATIONS

The precision of acoustic ranging measurements depends on the speed of sound, 
which further depends on air temperature, relative humidity, etc. On the 
mica2 platform measurement results are calculated with the speed of sound of 340 
m/s. If using mica2 motes, if the speed of sound is significantly different from 
the hard coded value the measurement results can be linearly scaled (i.e. 
divided by 340 and multiplied by the actual speed of sound, given is m/s). 
Scaling is not yet supported on other platforms, nor is it supported by the java 
application.

The java application does not apply any sophisticated filtering mechanisms on 
the measured data. To do this, save the measured data to a text file, edit the 
measurements, then load it back and do the localization.
