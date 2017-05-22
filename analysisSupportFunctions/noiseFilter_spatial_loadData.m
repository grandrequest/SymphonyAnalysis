
%% load data
% load cellData/102816Ac3.mat
% epochIndices = 311:319;

% load cellData/102516Ac2.mat
% epochIndices = [167];

% load cellData/110216Ac19.mat
% epochIndices = 218:251;

% spiking WFDS
% load cellData/121616Ac2.mat 
% epochIndices = 133:135;

% spiking On Off DS
% load cellData/121616Ac4.mat 
% epochIndices = 30;

% WC on wfds
% load cellData/121616Ac7.mat 
% epochIndices = 63;

% WC F mini Off
% load cellData/051617Bc4.mat
epochIndicesNoise = 661:671; % wc -60
% epochIndicesNoise = 672:679; % wc 20
epochIndicesColor = 216:251; % center, wc -60
responseScaleColor = 0.2;

allEpochs = [epochIndicesColor,epochIndicesNoise];

%% color iso epochs
numberOfEpochs = length(epochIndicesColor);
stimulusColorIso = [];
for ei = 1:numberOfEpochs
    fprintf('Loading epoch %g Color Iso\n', ei);
    epoch = cellData.epochs(epochIndicesColor(ei)); 
    
    startTime = epoch.get('preTime') / 1000;
    endTime = epoch.get('stimTime') / 1000 + startTime;
    tailTime = epoch.get('tailTime') / 1000;
    totalTime = endTime + tailTime;
    
%     sr = epoch.get('sampleRate');
    sr = 60;
%     t = (1:length(epoch.getData('Amplifier_Ch1')));
%     t = (t-1) ./ sr;
    t = 0:1/sr:(totalTime-.0001);
    on = t > startTime & t <= endTime;
    %                 stim = vertcat(e.parameters('intensity1') * on + e.parameters('baseIntensity1') * ~on, e.parameters('intensity2') * on + e.parameters('baseIntensity2') * ~on);
    meanStim = zeros(size(t));
    if epoch.get('spotDiameter') < 300 && ~epoch.get('annulusMode')
        % center only
        stim = vertcat(epoch.get('contrast1') * on, epoch.get('contrast2') * on, meanStim, meanStim);
    end
    stimulusColorIso = horzcat(stimulusColorIso, stim);
    
end
stimulusAllEpochs = stimulusColorIso';

%% noise epochs

% locationByEpoch = [];
% numberOfEpochs = length(epochIndices);
% for ei=1:numberOfEpochs
% 
%     epoch = cellData.epochs(epochIndices(ei));
%     centerNoiseSeed = epoch.get('centerNoiseSeed');
%     stimulusAreaMode = epoch.get('currentStimulus');
% 
%     if strcmp(stimulusAreaMode, 'Center')
%         centerEpochs(end+1) = epochIndices(ei);
%     end
% end
% epochIndices = centerEpochs;

% organize epochs by seed: repeats and nonrepeats
% probably this'd be a quarter this length in Python, god help me MathWorks
numberOfEpochs = length(epochIndicesNoise);
if ~isempty(epochIndicesNoise)
    seedByEpoch = [];
    for ei=1:numberOfEpochs
        epoch = cellData.epochs(epochIndices(ei));
        centerNoiseSeed = epoch.get('centerNoiseSeed');
        surroundNoiseSeed = epoch.get('surroundNoiseSeed');
        stimulusAreaMode = epoch.get('currentStimulus');

        seedByEpoch(ei,:) = [centerNoiseSeed, surroundNoiseSeed];
    end

    uniqueCenterSeeds = unique(seedByEpoch(:,1));
    uniqueSeedCounts = [];
    for ui = 1:length(uniqueCenterSeeds)
        uniqueSeedCounts(ui) = sum(seedByEpoch(:,1) == uniqueCenterSeeds(ui));
    end

    repeatSeeds = uniqueCenterSeeds(uniqueSeedCounts > 1);
    if ~isempty(repeatSeeds)
        repeatSeed = repeatSeeds(1);
    else
        repeatSeed = [];
    end
    singleSeeds = uniqueCenterSeeds(uniqueSeedCounts == 1);
    repeatRunEpochIndices = epochIndicesNoise(seedByEpoch == repeatSeed);

    singleRunEpochIndices = [];
    for ei = 1:numberOfEpochs
        if any(singleSeeds == seedByEpoch(ei))
            singleRunEpochIndices(end+1) = epochIndicesNoise(ei);
        end
    end
    


    % frameRate = cellData.epochs(epochIndices(1)).get('patternRate');
    frameRate = 60;
    stimFilter = designfilt('lowpassfir','PassbandFrequency',6, ...          
        'StopbandFrequency',8,'PassbandRipple',0.5, 'SampleRate', frameRate, ...     
        'StopbandAttenuation',65,'DesignMethod','kaiserwin');

    sampleRate = cellData.epochs(epochIndicesNoise(1)).get('sampleRate');
    % responseFilter = designfilt('highpassiir','PassbandFrequency',3, ...          
    %     'StopbandFrequency',2,'PassbandRipple',0.5, 'SampleRate', sampleRate, ...     
    %     'StopbandAttenuation',50,'DesignMethod','butter');
end

legString = {'center green','center uv','surround green','surround uv'};

%% generate responses and stims, then glue them all together
stimulusNoise = [];
repeatMarkerFull = [];

averageRepeatSeedEpochs = false;

for ei=1:numberOfEpochs

    epoch = cellData.epochs(epochIndicesNoise(ei));
    stimulusAreaMode = epoch.get('currentStimulus');
    isRepeatSeed = any(seedByEpoch(ei,1) == repeatSeeds);
    if averageRepeatSeedEpochs && ~isRepeatSeed
        continue
    end
%     if ~strcmp(stimulusAreaMode, 'Center')
%         return
%     end

    fprintf('Starting on epoch %g mode %s w/ center seed %g surround seed %g\n', ei, stimulusAreaMode, seedByEpoch(ei,1), seedByEpoch(ei,2));

    % Generate stimulus

    stimulus = [];

    preFrames = round(frameRate * (epoch.get('preTime')/1e3));
    stimFrames = round(frameRate * (epoch.get('stimTime')/1e3));
    postFrames = round(frameRate * (epoch.get('tailTime')/1e3));
    
    if strcmp(stimulusAreaMode, 'Center')
        locations = 1;
    elseif strcmp(stimulusAreaMode, 'Surround')
        locations = 2;
    else
        locations = 1:2;
    end  
    
    if strcmp(epoch.get('colorNoiseMode'), '2 patterns')
        means = [epoch.get('meanLevel1'), epoch.get('meanLevel2')];
        contrast = epoch.get('contrastValues');
        for location = locations
            noiseStream = RandStream('mt19937ar', 'Seed', seedByEpoch(ei,location));
            
            for fi = 1:floor((stimFrames + postFrames + preFrames)/epoch.get('frameDwell'))
                for color = 1:2

                    mn = means(color);
                    
                    if fi > preFrames && fi <= preFrames + stimFrames
                    
                        stim = mn + contrast * mn * noiseStream.randn();
                        if stim < 0
                            stim = 0;
                        elseif stim > mn * 2
                            stim = mn * 2; % probably important to be symmetrical to whiten the stimulus
                        elseif stim > 1
                            stim = 1;
                        end
                    else
                        stim = mn;
                    end
                    
                    % convert to contrast
                    stim = (stim ./ mn) - 1;
                    
                    stimulus(fi, (location - 1) * 2 + color) = stim;

                end
            end
            
        end
                
        
    else
        % old one pattern mode code
        for location = locations
            stimLocation = [];
            stimLocation(1:preFrames, 1) = zeros(preFrames, 1);

            noiseStream = RandStream('mt19937ar', 'Seed', seedByEpoch(ei,location));

            for fi = preFrames+1:floor(stimFrames/epoch.get('frameDwell'))
                stimLocation(fi, 1) = noiseStream.randn;
            end
            ml = epoch.get('meanLevel');
            contrast = 1; %epoch.get('currentContrast')
            stimLocation = ml + contrast * ml * stimLocation;

            stimLocation(stimLocation < 0) = 0;
    %         stimLocation(stimLocation > ml * 2) = ml * 2;
            stimLocation(stimLocation > 1) = 1;
            stimulus(:,location) = stimLocation;

        end
    
        if strcmp(stimulusAreaMode, 'Center')
            stimulus(:,2) = epoch.get('meanLevel') + zeros(size(stimulus,1), 1);
        elseif strcmp(stimulusAreaMode, 'Surround')
            stimulus(:,1) =  epoch.get('meanLevel') + zeros(size(stimulus,1), 1);
        end 
        
    end

    stimulusNoise = [stimulusNoise; stimulus];
    
    
%     stimulus = smooth(stimulus, 3);

%         stimulusFiltered = filtfilt(stimFilter, stimulus);
end

stimulusAllEpochs = [stimulusAllEpochs; stimulusNoise];


%% Responses
responseAllEpochs = [];
for ei=1:length(allEpochs)
    epoch = cellData.epochs(allEpochs(ei));

    % generate response

    if strcmp(epoch.get('ampMode'), 'Cell attached')
%         spikeTimes = epoch.get('spikes_ch1') / sampleRate;
%         response = NIM.Spks2Robs(spikeTimes, 1/frameRate, size(stimulus,1) );
%         useOutputNonlinearity = true;
    else
        useOutputNonlinearity = false;
        
        responseRaw = epoch.getData('Amplifier_Ch1');
%         response = responseRaw * sign(mean(responseRaw));
        response = responseRaw * sign(epoch.get('ampHoldSignal'));
%         response = response / max(response);
        response = response - mean(response);
        response = response - median(response);
%         response = response + 0.01*(max(response) - min(response));
%         response = response - prctile(response, 50);

        if any(allEpochs(ei) == epochIndicesColor)
            response = responseScaleColor * response;
        end

        % response = response + 2;
        %     response = zscore(response);
%         response = filtfilt(responseFilter, response);
        

        

          % get stimulus and response to the same length, but should be auto
%         m = min([size(stimulus,1), length(response)])
%         response = response(1:m);
%         stimulus = stimulus(1:m,:);
%         while length(stimulus) < length(response)
%             stimulus  = [stimulus; ml];
%         end
    end

    % compose data together

%     assert(all(size(stimulus, 1) == size(response, 1)))
%     repeatMarker = isRepeatSeed * ones(size(stimulus));

    if averageRepeatSeedEpochs
        stimulusNoise(end+1,:,:) = stimulus;
        responseAllEpochs = [response, responseAllEpochs];
%         repeatMarkerFull = [repeatMarker, repeatMarkerFull];
    else
        
        responseAllEpochs = [responseAllEpochs; response];
%         repeatMarkerFull = [repeatMarkerFull; repeatMarker];
    end

end
% 
if averageRepeatSeedEpochs
    stimulusNoise = squeeze(mean(stimulusNoise, 1));
    responseAllEpochs = mean(responseAllEpochs, 2);
%     repeatMarkerFull = mean(repeatMarkerFull, 2);
end


responseAllEpochs = resample(responseAllEpochs, frameRate, sampleRate);
responseAllEpochs = responseAllEpochs - prctile(responseAllEpochs, 10);

responseAllEpochs(responseAllEpochs < 0) = 0;


figure(6);clf;
handles = tight_subplot(2,1);
plot(handles(1), stimulusAllEpochs)
legend(handles(1), legString)
plot(handles(2), responseAllEpochs)
% hold(handles(2), 'on')
% plot(handles(2), mean(responseFull, 2), 'k')
legend(handles(2), '1','2','3','4','5','6')
% plot(handles(3), repeatMarkerFull)
linkaxes(handles, 'x')