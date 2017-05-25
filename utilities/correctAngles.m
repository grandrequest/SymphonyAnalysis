function cd = correctAngles(cd, cellName)

%     if isKey(cd.attributes, 'anglesCorrected')
%         fprintf('%s angles already corrected\n', cellName);
%         cd = 1;
%         return
%     end

    % calculate rig angle offset
    if strfind(cellName,'A')
%         rig = 'A';
        rigAngle = 180;
    elseif strfind(cellName,'B')
%         rig = 'B';
        rigAngle = 270;
    else
        rigAngle = 0; % 
    end
    
    %% loop through epochs
    for ei = 1:length(cd.epochs)

        epoch = cd.epochs(ei);
        if isempty(epoch.parentCell)
            continue
        end
        
        displayName = epoch.get('displayName');
        
        switch displayName
            case 'Moving Bar'
                sourceAngleName = 'barAngle';
                angleOffsetForStimulus = 0;
                
            case 'Drifting Gratings'
                sourceAngleName = 'gratingAngle';
                
                if epoch.get('version') < 3
                    angleOffsetForStimulus = 180;
                else
                    angleOffsetForStimulus = 0; % fixed in version 3
                end
                
            case 'Flashed Bars'
                sourceAngleName = 'barAngle';
                angleOffsetForStimulus = 0;
                
            case 'Drifting Texture'
                sourceAngleName = 'textureAngle';
                angleOffsetForStimulus = 0;
                
            case 'Bars multiple speeds'
                sourceAngleName = 'offsetAngle';
                angleOffsetForStimulus = 0;
            
            case 'Auto Center'
                sourceAngleName = 'rigOffsetAngle';
                angleOffsetForStimulus = 0;
                
            otherwise
                continue
        end
        destinationAngleName = sourceAngleName;

        
        
        % check if the rig included an angle for the offset
        if isKey(epoch.attributes, 'angleOffsetFromRig')
            rigAngle = epoch.attributes('angleOffsetFromRig');
            
            if isKey(epoch.attributes, 'angleOffsetForRigAndStimulus')
                if epoch.attributes('angleOffsetFromRig') ~= epoch.attributes('angleOffsetForRigAndStimulus')
                    disp('wrong correction for rig B upper, fixing now');
                    sourceAngleName = 'originalAngle';
                end
            end
        end
                
        
        % add epoch parameter to store the amount of offset made
%         if isKey(epoch.attributes, 'angleOffsetForRigAndStimulus')
% %             disp('already did this epoch')
%             continue
%         end
    
        % calculate displayName angle offset
        overallOffset = angleOffsetForStimulus + rigAngle;
        
        epoch.attributes('angleOffsetForRigAndStimulus') = overallOffset;
        
        % change epoch angle values (danger zone)
        originalAngle = epoch.get(sourceAngleName);
        if isnan(originalAngle) % for old autocenter
            originalAngle = 0;
%             disp('add autocenter angle')
        end
        epoch.attributes('originalAngle') = originalAngle;
        correctedAngle = mod(originalAngle + overallOffset, 360);
        epoch.attributes(destinationAngleName) = correctedAngle;
    end
    
    fprintf('%s angles corrected\n', cellName);
    cd.attributes('anglesCorrected') = 1;
    
end