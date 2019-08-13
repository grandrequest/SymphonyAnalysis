% process auto center offline simply
global CELL_DATA_FOLDER;

load([CELL_DATA_FOLDER, '010418Ac4']) % HD1 vclamp offset
sessionId = {'2018141423'};
timeOffset = .03;

epochData = cell(1);
ei = 1;
for i = 1:length(cellData.epochs)
    epoch = cellData.epochs(i);
    if ~isnan(timeOffset)
        epoch.attributes('timeOffset') = timeOffset;
    end
    sid = epoch.get('sessionId');
    
    matched = 0;
    
    if iscell(sessionId)
        for a = 1:length(sessionId)
            if strcmp(sid, num2str(sessionId{a}))
                matched = 1;
            end
        end
        
    else 
        
        if sid == sessionId | strcmp(sid, num2str(sessionId))
            matched = 1;
        end
    end
    
    if matched
%         if epoch.get('presentationId') > 2
%             continue
%         end
        sd = ShapeData(epoch, 'offline');
        epochData{ei, 1} = sd;
        ei = 1 + ei;
%         epoch.attributes('timeOffset')

    end
end

if length(epochData{1}) > 0 %#ok<ISMT>
    % analyze shapedata
    analysisData = processShapeData(epochData);
    disp('analysis done');
else
    disp('no epochs found');
    return
end


%% normal plots
figure(10);clf;
plotShapeData(analysisData, 'plotSpatial_mean');
%% 
figure(11);clf;
plotShapeData(analysisData, 'temporalResponses');

%%
% figure(12);clf;
% plotShapeData(analysisData, 'currentVoltage');

%% new plots
% figure(13);clf;
% plotShapeData(analysisData, 'spatialOffset_onOff');
%%
figure(15);clf;
plotShapeData(analysisData, 'responsesByPosition');
%%
% figure(11);clf;
% plotShapeData(analysisData, 'temporalComponents');


%%
% figure(17);clf;
% plotShapeData(analysisData, 'overlap');


%% save maps
% plotShapeData(analysisData, 'plotSpatial_saveMaps');
