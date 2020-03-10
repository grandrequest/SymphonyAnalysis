function [D_sorted, D_target, D_others, D_origOrder, indexVals_sorted, geneNames_sorted, targetInd, othersInd] = selectiveExpressionMatrixFromBinary(D_tert, D_orig, cellTypes, geneNames, selection, Ngenes, method)
if ischar(selection)
    selectedType = selection;
    targetInd = find(strcmp(selectedType, cellTypes));
    disp([num2str(length(targetInd)) ' cells of type: ' selectedType]);
    othersInd = setdiff(1:length(cellTypes), targetInd);
else
    targetInd = selection;
    disp([num2str(length(targetInd)) ' cells selected.']);
    othersInd = setdiff(1:length(cellTypes), targetInd);
end

N = length(geneNames);
indexVals = zeros(N,1);

switch method
    case 'log-ratio'
        D_tert=D_tert*1000; %make the minimum about 14
        D_tert(D_tert<2) = 1;
        logD = log10(D_tert);
        for i=1:N
            targetMed = median(logD(i,targetInd));
            otherMed = median(logD(i,othersInd));
            indexVals(i) = targetMed - otherMed;
        end
        [indexVals_sorted, ind] = sort(indexVals, 'descend');
        
    case 'threshold'
        thresVal = 12;
        D_thres = D_tert>thresVal;
        falseNeg_scaling = .65;
        for i=1:N
            Nmatch = sum(D_thres(i,targetInd));
            if Nmatch < 3 %horrible hack
                targetFrac = 0;
            else
                targetFrac = sum(D_thres(i,targetInd))./length(targetInd);
            end
            otherFrac = sum(D_thres(i,othersInd))./length(othersInd);
      
            %indexVals(i) = targetFrac - otherFrac;
            indexVals(i) = falseNeg_scaling*targetFrac - (1-falseNeg_scaling)*otherFrac;
        end
        [indexVals_sorted, ind] = sort(indexVals, 'descend');
        
    case 'p-value'
        D_tert=D_tert*1000; %make the minimum about 14
        D_tert(D_tert<2) = 1;
        logD = log10(D_tert);
        for i=1:N
            targetVals = logD(i,targetInd);
            otherVals = logD(i,othersInd);
            [~, indexVals(i)] = ttest2(targetVals, otherVals, 'tail', 'right');
        end
        [indexVals_sorted, ind] = sort(indexVals, 'ascend');
        
   case 'multi-step' %p-value and then more processing after
        %D=D*1000; %make the minimum about 14
        %D(D<2) = 1;
        %logD = log10(D);
        logD = D_tert;
        
        for i=1:N
            targetVals = logD(i,targetInd);
            otherVals = logD(i,othersInd);
            [~, indexVals(i)] = ttest2(targetVals, otherVals, 'tail', 'right');
        end
        [indexVals_sorted, ind] = sort(indexVals, 'ascend');
        geneNames_sorted = geneNames(ind(1:Ngenes));
        D_origOrder = D_orig(ind(1:Ngenes), :);
        D_target = D_orig(ind(1:Ngenes), targetInd);
        D_others = D_orig(ind(1:Ngenes), othersInd);
        D_sorted = [D_target, D_others];
        
        thresVal = .1;
        D_thres = D_sorted>thresVal;
        falseNeg_scaling = 0.35;
        indexVals =zeros(1,Ngenes);
        for i=1:Ngenes
            targetFrac = sum(D_thres(i,targetInd))./length(targetInd);
            otherFrac = sum(D_thres(i,othersInd))./length(othersInd);      
            indexVals(i) = falseNeg_scaling*targetFrac - (1-falseNeg_scaling)*otherFrac;
        end
        [indexVals_sorted, ind] = sort(indexVals, 'descend');
        
        geneNames_sorted = geneNames_sorted(ind);
        D_origOrder = D_origOrder(ind, :);
        D_target = D_target(ind,:);
        D_others = D_others(ind,:);
        D_sorted = D_sorted(ind,:);
end

if ~strcmp(method, 'multi-step')
    geneNames_sorted = geneNames(ind(1:Ngenes));
    D_origOrder = D_orig(ind(1:Ngenes), :);
    D_target = D_orig(ind(1:Ngenes), targetInd);
    D_others = D_orig(ind(1:Ngenes), othersInd);
    D_sorted = [D_target, D_others];
end

%method is one of the following options:
% threshold
% log-ratio
% p-value



