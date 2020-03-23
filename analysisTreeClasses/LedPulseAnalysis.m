classdef LedPulseAnalysis < AnalysisTree
   % Analysis for LED PULSE, Sinha Lab
   %
   %
    properties
        StartTime = 0;
        EndTime = 0;
    end
    
    methods
        function obj = LedPulseAnalysis(cellData, dataSetName, params)
            %choose with amplifier
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
                params.holdSignalParam = 'ampHoldSignal';
            else
                params.ampModeParam = 'amp2Mode';
                params.holdSignalParam = 'amp2HoldSignal';
            end            
            
            %name for the analysis based on cellName, dataset and analysis
            %type
            nameStr = [cellData.savedFileName ': ' dataSetName ': LedPulseAnalysis'];            
            
            %obj saves the analysis tree
            obj = obj.setName(nameStr); %put in the name
            dataSet = cellData.savedDataSets(dataSetName); %get the data set 
            obj = obj.copyAnalysisParams(params); %copies analysis parameters into the object. In this case, there are no interesting ones

            %take some parameters from the first epoch and copy them into
            %the analysis tree
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'firstLightAmplitude', 'stimTime', 'preTime', 'spikes_ch1', 'Background_Amp1_value'});
            
            obj = obj.buildCellTree(1, cellData, dataSet, {'firstLightAmplitude'});
            
        end
        
        function obj = doAnalysis(obj, cellData)
           rootData = obj.get(1); %root node of analysis tree
           leafIDs = obj.findleaves(); %indices of leaf nodes
           
            L = length(leafIDs);

            for i=1:L              
                    curNode = obj.get(leafIDs(i)); %get current leaf node

                    epochInd = curNode.epochID;
                    K = length(epochInd);

                    for j=1:length(K)
                        curEpoch = cellData.epochs(epochInd(j));
                        outputStruct = struct; 
                        epochValues = curEpoch.getData(); 
                        
                        % regular variables
                        preTime = curEpoch.get('preTime');
                        stimTime = curEpoch.get('stimTime');
                        
                        epochValuesAdj = epochValues - mean(epochValues(1: preTime));
                        
                        % define units and types
                        if j==1
                            % baseline
                            outputStruct.baseline.units = 'dont know';
                            outputStruct.baseline.type = 'byEpoch';
                            outputStruct.baseline.value = ones(1,K) * NaN;
                            
                            outputStruct.meanPeakAmp.units = 'dont know';
                            outputStruct.meanPeakAmp.type = 'byEpoch';
                            outputStruct.meanPeakAmp.value = ones(1,K) * NaN;
                            
                            outputStruct.sumPeakAmp.units = 'dont know';
                            outputStruct.sumPeakAmp.type = 'byEpoch';
                            outputStruct.sumPeakAmp.value = ones(1,K) * NaN;
                            
                            outputStruct.spikeRate.units = 'dont know';
                            outputStruct.spikeRate.type = 'byEpoch';
                            outputStruct.spikeRate.value = ones(1,K) * NaN;
                        end
                        
                        % basic analysis
                        outputStruct.baseline.values(j) = mean(epochValuesAdj(1: preTime));
                        
                        outputStruct.meanPeakAmp.value(j) = mean(epochValuesAdj(1000:3000));
                        outputStruct.sumPeakAmp.value(j) = sum(epochValuesAdj(1000:3000));
                        
                        % spike rate
                        spikes = curEpoch.get('spikes_ch1');                        
                        baseSpike = length(find(spikes < preTime)) / preTime;
                        spikeRate = (length(find(spikes >= preTime & spikes < stimTime)) - baseSpike * stimTime) / (preTime + stimTime);
                        outputStruct.spikeRate.value(j) = spikeRate; 
                        
                        outputStruct = getEpochResponseStats(outputStruct);
                        curNode = mergeIntoNode(curNode, outputStruct);
                    end 
                obj = obj.set(leafIDs(i), curNode);
            end

           
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'firstLightAmplitude');
            
            %collect lists of parameters by their type, either ones that
            %have a value for each epoch or those that have a single value
            %across epochs, like the peak of the average trace
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            
            %percolate up all the computed parameters. This means you get a
            %correctly named vector of the result of each parameter at the
            %level above the leaves
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
            
            %set variables called byEpochParamList, collectedParamList and
            %stimParameterList in the node above the leaves. These are used
            %by the automatic plotting function in TreeBrowserGUI. 
            %stimParameterList should include anything you want to check
            %out as the X axis in your plots. 
            %The other param lists are things that you want to see as the Y
            %axis.
            rootData = obj.get(1);
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            rootData.stimParameterList = {'firstLightAmplitude'};
            
            %copy your changes back into the analysisTree
            obj = obj.set(1, rootData);
        end
    end
    
    methods(Static)
        function plotMeanTraces(node, cellData)
            rootData = node.get(1);
            chInd = node.getchildren(1);
            L = length(chInd);
            ax = gca;
            for i=1:L
                epochInd = node.get(chInd(i)).epochID;
                if strcmp(rootData.('Background_Amp1_value'), '0')
                    cellData.plotPSTH(epochInd, 10, rootData.deviceName, ax);
                else
                    cellData.plotMeanData(epochInd, false, [], rootData.deviceName, ax);
                end
                hold(ax, 'on');               
            end
            hold(ax, 'off');
        end
        
        function plot_currPulseSpikeCount(node, cellData)
            rootData = node.get(1);            
            chInd = node.getchildren(1);
            L = length(chInd);
            ax = gca;
            
            xvals = rootData.firstLightAmplitude;
            yvals = ones(1, L)*NaN;
            errs = ones(1, L)*NaN;
            for i=1:L
                chData = node.get(chInd(i));
                yvals(i) = chData.meanPeakAmp.value(1);              
            end
            xlabel('Light Amplitude');
            ylabel('Spike Count');
        end    
    end
end

