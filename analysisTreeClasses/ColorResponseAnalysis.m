classdef ColorResponseAnalysis < AnalysisTree
    properties
        
    end
    
    methods
        function obj = ColorResponseAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
            else
                params.ampModeParam = 'amp2Mode';
            end
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': ContrastRespAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', params.ampModeParam});
            obj = obj.buildCellTree(1, cellData, dataSet, {'colorChangeMode', 'colorPattern2', 'intensity2'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            baseline = zeros(1,L);
            
            for i=1:L %for each leaf node
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    outputStruct = getEpochResponses_CA(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                    baseline(i) = outputStruct.baselineRate.mean_c;
                else %whole cell
                    outputStruct = getEpochResponses_WC(cellData, curNode.epochID, ...
                        'DeviceName', rootData.deviceName);
                    outputStruct = getEpochResponseStats(outputStruct);
                    curNode = mergeIntoNode(curNode, outputStruct);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'splitValue', 'contrast', 'sortColors');
                            
            [byEpochParamList, singleValParamList, collectedParamList] = getParameterListsByType(curNode);
            obj = obj.percolateUp(leafIDs, byEpochParamList, byEpochParamList);
            obj = obj.percolateUp(leafIDs, singleValParamList, singleValParamList);
            obj = obj.percolateUp(leafIDs, collectedParamList, collectedParamList);
                        
            rootData = obj.get(1);
            rootData.byEpochParamList = byEpochParamList;
            rootData.singleValParamList = singleValParamList;
            rootData.collectedParamList = collectedParamList;
            rootData.stimParameterList = {'baseColor'};
            obj = obj.set(1, rootData);
        end
    end
    
    methods(Static)
              
        function plot_ramp_ONSETspikes(tree, cellData)
            ColorResponseAnalysis.plot_ramp(tree, cellData, 'spikeCount_stimInterval');
        end

        function plot_ramp_OFFSETspikes(tree, cellData)
            ColorResponseAnalysis.plot_ramp(tree, cellData, 'OFFSETspikes');
        end
        
        function plot_ramp_ONSET_peak(tree, cellData)
            ColorResponseAnalysis.plot_ramp(tree, cellData, 'ONSET_avgTracePeak');
        end
        
        function plot_ramp_stimInterval_charge(tree, cellData)
            ColorResponseAnalysis.plot_ramp(tree, cellData, 'stimInterval_charge');
        end
        
        
%         function plot_swap_ONSETspikes(tree, cellData)
%             ColorResponseAnalysis.plot_swap(tree, cellData, 'ONSETspikes');
%         end
% 
%         function plot_swap_OFFSETspikes(tree, cellData)
%             ColorResponseAnalysis.plot_swap(tree, cellData, 'OFFSETspikes');
%         end
                
       
        function plot_swap(tree, cellData, variableName)
            warning('this doesnt work yet')
            colorNodeIds = tree.getchildren(1);
            data = {};
            colornode = 1
            colorData = struct();
            colorData.intensity = [];
            colorData.response = [];
            currentStepColorNode = tree.get(colorNodeIds(colornode));
            colors{colornode} = currentStepColorNode.splitValue;
            rampnodes = tree.getchildren(colorNodeIds(colornode));

            % get contrast from sample epoch

            for ri = 1:length(rampnodes)
                datanode = tree.get(rampnodes(ri));
                contrastepoch = cellData.epochs(datanode.epochID(1));
                contrast = contrastepoch.get('contrast');
                intensity = contrastepoch.get('intensity');
                colorData.intensity(end+1) = ((datanode.splitValue - intensity) / intensity) / contrast;
                colorData.response(end+1) = datanode.(variableName);
            end
            data{colornode} = colorData;
            
        end
            
        function plot_ramp(tree, cellData, variableName)
            colorNodeIds = tree.getchildren(1);
            data = {};
            colors = {};
            for colornode = 1:length(colorNodeIds)
                colorData = struct();
                colorData.intensity = [];
                colorData.response = [];
                colorData.responseSem = [];
                currentStepColorNode = tree.get(colorNodeIds(colornode));
                colors{colornode} = currentStepColorNode.splitValue;
                rampnodes = tree.getchildren(colorNodeIds(colornode));
                
                % get contrast from sample epoch
                
                for ri = 1:length(rampnodes)
                    datanode = tree.get(rampnodes(ri));
                    contrastepoch = cellData.epochs(datanode.epochID(1));
                    contrast = contrastepoch.get('contrast');
                    intensity = contrastepoch.get('intensity');
                    colorData.intensity(end+1) = ((datanode.splitValue - intensity) / intensity) / contrast;
                    colorData.response(end+1) = datanode.(variableName).mean;
                    colorData.responseSem(end+1) = datanode.(variableName).SEM;
                end
                data{colornode} = colorData;
            end
            for ci = 1:length(colors)
                d = data{ci};
                switch colors{ci}
                    case 'uv'
                        color = [.3, 0, .9];
                    case 'blue'
                        color = [0, .5, 1];
                    case 'green'
                        color = [0, .8, .1];
                end
               
                errorbar(d.intensity, d.response, d.responseSem, 'Color', color, 'LineWidth', 3);
               
                hold on
                
            end
%             legend(colors, 'Location', 'north')
            hold off
            xlabel('(varying : fixed) contrast ratio')
                
        end
    end
    
end


