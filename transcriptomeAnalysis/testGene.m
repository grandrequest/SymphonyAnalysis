>> imagesc(log(D_full))
ax=gca;
set(ax,'yTickLabel',allGeneNames)
set(ax,'ytick', (1:size(D_full,1)))
set(ax,'xTickLabel',uniqueTypes_sorted)
set(ax,'xtick', xtickByCellType+.5)
set(ax,'xTickLabelRotation',45)
rectangle('Position', [12.5 0 11 70.5])
rectangle('Position', [33.5 0 8 70.5])
rectangle('Position', [49.5 0 7 70.5])
rectangle('Position', [63.5 0 5 70.5])
rectangle('Position', [72.5 0 4 70.5])
rectangle('Position', [80.5 0 3 70.5])
rectangle('Position', [86.5 0 3 70.5])
rectangle('Position', [91.5 0 1 70.5])
rectangle('Position', [93.5 0 1 70.5])
rectangle('Position', [0 0 93.5 70.5])
rectangle('Position', [0 0.5 94.5 5])
rectangle('Position', [0 10.5 94.5 5])
>> rectangle('Position', [0 20.5 94.5 5])
>> rectangle('Position', [0 30.5 94.5 5])
>> rectangle('Position', [0 40.5 94.5 5])
>> rectangle('Position', [0 50.5 94.5 5])
>> rectangle('Position', [0 60.5 94.5 5])