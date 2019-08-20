function plotRF(projFolder)

 global CELL_DATA_FOLDER
 global ANALYSIS_FOLDER

%% load excel sheet
excel = readtable('C:\Users\david\Google Drive\ReceptiveFieldProject\RFDataMine_sheet.xlsx');
rowInd = find(~ismissing(excel{:,9}));
excel = excel(rowInd,[1,7,8,9,10,11]);
excel = excel(2:end,:);
cellNames = excel{:,1};

%% loop through cellData to collect location information
Locations = [];
Count = 1;
for fi = 1:length(cellNames)
    fprintf('processing cellData %d of %d: %s\n', fi, length(cellNames), cellNames{fi})
    fname = fullfile(CELL_DATA_FOLDER, [cellNames{fi}, '.mat']);
    load(fname)
    if any(cellData.location)
        if any(cellData.location(1:2))
            LocatedCells{Count} = char(cellData.savedFileName);
            Locations(Count,1:3) = cellData.location;
            rfData(Count,1:3) = table2array(excel(fi,2:4));
            cellTypes{Count} = char(cellData.cellType);
            Count = Count + 1;
        else
            display(['location not recorded for ' cellNames{fi}])
        end
    else
        display(['No location information found for ' cellNames{fi}]);
    end
end

%% Solve for X and Y compenents of RF to plot
rfData = cellfun(@str2num,rfData);
rotInd = find(rfData(:,2) > rfData(:,1))
rfData(rotInd, 3) = rfData(rotInd, 3) + pi/2;
rfData(:,1:2) = sort(rfData(:,1:2),2); %sort into major and minor axes
amplitude = rfData(:,2) ./ rfData(:,1) - 1;
xComponent = amplitude .* cos(rfData(:,3));
yComponent = amplitude .* sin(rfData(:,3));



%% Find Indices of left and right eye
Locations(:,1) = Locations(:,1) .* -1 ;%correct X location
 
 lInd = find(Locations(:,3) == -1);
 rInd = find(Locations(:,3) == 1);
 
%% Plot Left Eye
figure(3)
clf
subplot(1,2,1)
hold on
rfPlotter(Locations(lInd, :), LocatedCells(lInd), xComponent(lInd), yComponent(lInd), cellTypes(lInd))
title('Left Eye')
hold off

 %% Plot Right Eye
subplot(1,2,2)
hold on
rfPlotter(Locations(rInd, :), LocatedCells(rInd), xComponent(rInd), yComponent(rInd), cellTypes(rInd))
title('Right Eye')
hold off

%% Mirror left location and xComponent
xComponent(lInd) = xComponent(lInd) * -1;
Locations(lInd) = Locations(lInd) * -1;
 
 %% Plot Combined Eyes (convert left eye to right eye coordinates)
figure(4)
clf
hold on
rfPlotter(Locations, LocatedCells, xComponent, yComponent, cellTypes)
title('Combined')
hold off
end
function rfPlotter(locData, locCells, xComponent, yComponent, cellTypes)
Gain = 500;
%scatter(LocData(:,1),LocData(:,2))
plot([-2500;2500],[0; 0])
plot([0;0],[-2500;2500])
plot([-2300,-2300 + (Gain*.5)],[-2300,-2300],'b','LineWidth',4) %scale bar

 for c = 1:length(locCells)
    X(1) = locData(c,1) - (xComponent(c)/2 * Gain);
    X(2) = locData(c,1) + (xComponent(c)/2 * Gain);
    Y(1) = locData(c,2) - (yComponent(c)/2 * Gain);
    Y(2) = locData(c,2) + (yComponent(c)/2 * Gain);
    plot(X,Y)
     text(locData(c,1),locData(c,2),locCells(c));
%    text(locData(c,1),locData(c,2),cellTypes(c));
    h = plot(X,Y,'k');
    set(h , 'LineWidth', 2)
 end 
end
