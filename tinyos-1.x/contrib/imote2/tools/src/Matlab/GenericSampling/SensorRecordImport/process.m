    clear all

MOTE = [{'0xc6'} {'0xbb'} {'0x5e'}];
MOTE = [{'0x15'}];
rootDir = './';
Channel = [1];

Collection = 2;

for Collection = 17:17  
    for k= 1:length(MOTE)
        for j = 1:length(Channel)
            [float_data,sampleRecord] = openRawSampleRecord(sprintf('%sMote_%s_Channel_%d_Collection_%d', rootDir, MOTE{k}, Channel(j), Collection));
            
            Fs = sampleRecord.sampleHeader.samplingRate;  
            data = sampleRecord.data * sampleRecord.sampleHeader.ADCScale + sampleRecord.sampleHeader.ADCOffset;
            f = (0:length(data)-1) * Fs/length(data);
            t = (0:length(data)-1)/Fs;
            
            
            subplot(2,1,1); plot(t,data);
            xlabel('Time [s]');
            ylabel('Amplitude [V]');
            title('Time Domain Waveform');
            
            fdata = fft(hamming(length(data)).*data);
            Fs = sampleRecord.sampleHeader.samplingRate;
            f = (0:length(data)-1) * Fs/length(data);
            subplot(2,1,2),plot(f,20*log10(abs(fdata)/length(data)));
            title('Frequency Domain Waveform after Hamming Window');
            xlabel('Frequency [Hz]');
            ylabel('Amplitude [dBV]');
        end
    end
end

        
            

