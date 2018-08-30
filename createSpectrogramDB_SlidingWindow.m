% parameters
windowTimeLength = 3;% number of seconds of signal to convert into image
windowTimeFFT = 0.25;
overlap = 0.8;
max_freq_range = 250;
total_positives = 0;
total_negatives = 0;
window_overlap = 0.5; %NEW

SAVE_PATH = ['/media/SSD2/paujil/Datos/slindingWindow/noOverlapAnnotations/spectrogramMatlab',num2str(windowTimeLength) ,'s',num2str(max_freq_range),'Hz_windowFFT',num2str(windowTimeFFT), 'slindigOverlap', num2str(window_overlap)];
disp(SAVE_PATH)

mkdir(SAVE_PATH);
FOLDER_PATH = '/home/labravo/paujil/Datos/Cantos';
ANNOTATION_PATH = '/home/labravo/paujil/Datos/anotaciones';
%folder_names = {'ojara_sin_filtro', 'ojara_filtrados', 'songmetersWav', 'xc', 'xc_filtrados'};
folder_names = {'train','val'};

mkdir(fullfile(SAVE_PATH,'train','positives'));
mkdir(fullfile(SAVE_PATH,'train','negatives'));
mkdir(fullfile(SAVE_PATH,'val','positives'));
mkdir(fullfile(SAVE_PATH,'val','negatives'));

% read train and val files
for i = 1:length(folder_names)

	% get all .wav files in current folder
	file_names = dir(fullfile(FOLDER_PATH,folder_names{i},'*.wav'));
	file_names = {file_names.name};
	for fil = 1:length(file_names)
		full_file_name = fullfile(FOLDER_PATH,folder_names{i},file_names{fil});
		
		% read wav file and get sampling freq. Fs
		[fullSignal, Fs] = audioread(full_file_name);
		windowFFT =  windowTimeFFT * Fs;
		
		%if signal is stereo convert to mono
		if size(fullSignal,2) == 2 
		   ceroIndex = ~sum(fullSignal == 0, 2); % Rows Without Zeros (Logical Vector)
                   fullSignal = sum(fullSignal, 2); % Sum Across Columns
                   fullSignal(ceroIndex) = fullSignal(ceroIndex)/2; % Divide Rows Without Zeros By 2 To Get Mean 
		end

		% Slinding Window

		% get first window and spectrogram 
		w = 1; % init window counter
		startIndex(w) = 1;
		endIndex(w) = windowTimeLength*Fs;
		delta = windowTimeLength*Fs - round(window_overlap*windowTimeLength*Fs); %calculate delta for moving window indicies
		windowSignal = fullSignal(startIndex(w):endIndex(w));

		spec{w} = getSpectrogram(windowSignal, windowFFT, overlap*windowFFT, Fs);
		%imwrite(spec, fullfile(SAVE_PATH,folder_names{i},'temp',[file_names{fil}(1:end-4),'_',num2str(w),'.png']));

		% get all posible windows and their spectrogram 
		while endIndex < length(fullSignal)
			% update window counter
			w = w+1;
			% update window 
			startIndex(w) = startIndex(w-1) + delta;
			endIndex(w) = endIndex(w-1) + delta;
			windowSignal = fullSignal(startIndex(w):endIndex(w));

			spec{w} = getSpectrogram(windowSignal, widnowFFT, overlap*windowFFT, Fs);
			%imwrite(spec, fullfile(SAVE_PATH,folder_names{i},'temp',[file_names{fil}(1:end-4),'_',num2str(w),'.png']));
		end

		% get annotations for every signal window
		% staring and ending time for each portion is found in portioned time vector
    	current_annotation_filename = fullfile(ANNOTATION_PATH,folder_names{i},[file_names{fil}(1:end-4),'.txt']);
    	annotations = getAnnotation(current_annotation_filename,startIndex/Fs, endIndex/Fs);
		%save(fullfile(SAVE_PATH,[file_names{fil}(1:end-4),'.mat']),'annotations');

    	total_positives = total_positives + sum(annotations);
    	total_negatives = total_negatives + length(annotations) - sum(annotations);
    	
    	% Save created window spectrograms to appropriate folder (positives or negatives)
    	for win = 1:length(w)
    		if annotations(win) == 1
				imwrite(spec{win}, fullfile(SAVE_PATH,folder_names{i},'positives',[file_names{fil}(1:end-4),'_',num2str(win),'.png']));
			else
				imwrite(spec{win}, fullfile(SAVE_PATH,folder_names{i},'negatives',[file_names{fil}(1:end-4),'_',num2str(win),'.png']));
			end
		end

    disp(['Total positives: ',num2str(total_positives)])
    disp(['Total negatives: ',num2str(total_negatives)])
	end
end




