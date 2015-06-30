function [float_data, sampleRecord] = openRawSampleRecord(filename)

            disp(sprintf('Processing filed %s',filename));
            fid_dat = fopen(sprintf('%s.dat', filename));
            fid_raw = fopen(sprintf('%s.raw', filename));

            if fid_dat == -1
               disp(sprintf('Unable to open %s.dat', filename));
                return;
            end;

            if fid_raw == -1
                disp('unable to open file %s.raw', filename);
                return;
            end;

            [float_data,float_count] = fread(fid_dat,inf, 'float32');

            i=0;
            while 1
                i= i+1;

                [logicalNodeId] = fread(fid_raw,1, 'uint8');

                if feof(fid_raw)
                    break;
                end

                sampleHeader = struct( 'logicalNodeId', logicalNodeId,...
                    'channelId', fread(fid_raw,1, 'uint8'),...
                    'acquisitionNum', fread(fid_raw,1, 'uint8'),...
                    'gSEFilterType', fread(fid_raw,1, 'uint8'),...
                    'sensorType', fread(fid_raw,1, 'uint8'),...
                    'sampleWidth', fread(fid_raw,1, 'uint8'),...
                    'queryGroupId', fread(fid_raw,1, 'uint16'),...
                    'acquisitionCount', fread(fid_raw,1, 'uint8'),...
                    'desiredUOM', fread(fid_raw,1, 'uint8'),...
                    'outputUOM', fread(fid_raw,1, 'uint8'),...
                    'engineeringUOM', fread(fid_raw,1, 'uint8'),...b
                    'conversionVal', fread(fid_raw,1, 'float'),...
                    'sensorZero', fread(fid_raw,1, 'float'),...
                    'samplingRate', fread(fid_raw,1, 'uint32'),...
                    'numSamples', fread(fid_raw,1, 'uint32'),...
                    'Function', fread(fid_raw,1, 'uint32'),...
                    'microSecTimeStampLow', fread(fid_raw,1, 'uint32'),...
                    'microSecTimeStampHigh', fread(fid_raw,1, 'uint32'),...
                    'wallClockTimeStamp', fread(fid_raw,1, 'uint32'),...
                    'ADCScale', fread(fid_raw,1, 'float'),...
                    'ADCOffset', fread(fid_raw,1, 'float'),...
                    'sequenceID', fread(fid_raw,1, 'uint32'),...
                    'sampleOffset', fread(fid_raw,1, 'uint32'),...
                    'totalSamples', fread(fid_raw,1, 'uint32'));


                %disp(sprintf('Found a sampleRecord for node %#x containing %d samples:  Current progress = %d/%d\n',sampleHeader.logicalNodeId, sampleHeader.numSamples, sampleHeader.sampleOffset, sampleHeader.totalSamples));
                sampleRecord(1,i) = struct('sampleHeader', sampleHeader,...
                    'data', fread(fid_raw,sampleHeader.numSamples,'int16'));

            end
            fclose(fid_dat);
            fclose(fid_raw);
    
    % read in sampleHeader
    %   unsigned char logicalNodeId;		/* Intel logical nodeId, mote generating sample*/
    %   unsigned char channelId; 		/* channelId generating the sample.  This is VirtualChannel */
    %   unsigned char acquisitionNum;	/* Ordinal # of the acquisition for the query: e.g.1st, 2nd, 3rd */
    %   unsigned char gSEFilterType;        	/* filler for header due to 32 bit boundary */
    %   unsigned char sensorType;		/* sensorType - Robbie creating enum */
    %   unsigned char sampleWidth;	        	/* bit width of sample data used for parsing sample body */
    %   unsigned short queryGroupId;  	/* UniqueId of the query group being satisfied by this sample record */
    %   unsigned char acquisitionCount;	/* Total # of acquisitions needed to satisfy the query group */
    %   unsigned char desiredUOM; 	        	/* Unit of Measure the user wants. See EngineeringUnits.h */
    %   unsigned char outputUOM; 		/* Unit of Measure of the data on this sample record. See EngineeringUnits.h   */
    %   unsigned char engineeringUOM;	/* Native UOM the sensor takes its readings in. See EngineeringUnits.h */
    %   float conversionVal;	       	 /* Conversion of volts/EU to convert voltage reading the EU for the sensor */
    %   float sensorZero;		/* Zero stop of the sensor.  */
    %   unsigned long samplingRate;	/* Rate at which samples are taken */
    %   unsigned long numSamples; 	        	/* numSamples in this chunk */
    %   unsigned long function;		/* post processing function applied to data.  Robbie creating function bitmap */
    %   unsigned long long microSecTimeStamp;		/* micro-second accurate time stamp using time sync*/
    %   unsigned long wallClockTimeStamp;	/* second accurate wall clock stamp */
    %
    %   float ADCScale;		/* Scaling used for Analog to Digital conversion */
    %   float ADCOffset;		/* Offset used for Analog to Digital conversion */
    %   unsigned long sequenceID;		/* unique number identifying the capture */
    %   unsigned long sampleOffset;		/* The offset of the 1st sample of this block within the total number of samples */
    %   unsigned long totalSamples; 		/* total number of samples in an acquisition */


    