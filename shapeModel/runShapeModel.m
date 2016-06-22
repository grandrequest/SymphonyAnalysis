%% SHAPE MODEL
% Sam Cooler 2016


imgDisplay = @(X,Y,d) imagesc(X,Y,flipud(d'));
normg = @(a) (a / max(abs(a(:))));

%% Setup cell data from ephys

% generate RF map for EX and IN
% import completed maps

load rfmaps_060216Ac2_1032.mat
ephys_data_raw = data;

e_positions = {};
e_voltages = sort(voltages);
e_numVoltages = length(e_voltages);
e_intensities = intensities;
e_numIntensities = length(intensities);
clear voltages
clear intensities
s_voltageLegend = {};
for vi = 1:e_numVoltages
    s_voltageLegend{vi} = num2str(e_voltages(vi));
end
s_voltageLegend = {'ex','in'};
s_voltageLegend{end+1} = 'Combined';


sim_endTime = 1.0;
sim_timeStep = 0.001;
sim_spaceResolution = 5; % um per point
cell_radius = 250;%max(cell_rfPositions);

T = 0:sim_timeStep:sim_endTime;

% dims for: time, X, Y
sim_dims = round([length(T), cell_radius / sim_spaceResolution * 2, cell_radius / sim_spaceResolution * 2]);
e_map = nan * zeros(sim_dims(2), sim_dims(3), e_numVoltages);

ii = 1; % just use first intensity for now
for vi = 1:e_numVoltages
    e_vals(vi,:) = ephys_data_raw(vi, ii, 2);
    pos = ephys_data_raw{vi, ii, 1:2};
    e_positions{vi, ii} = pos; %#ok<*SAGROW>
end

figure(90);clf;
ha = tight_subplot(e_numVoltages, 1);


X = linspace(-0.5 * sim_dims(2) * sim_spaceResolution, 0.5 * sim_dims(2) * sim_spaceResolution, sim_dims(2));
Y = linspace(-0.5 * sim_dims(3) * sim_spaceResolution, 0.5 * sim_dims(3) * sim_spaceResolution, sim_dims(3));
[mapY, mapX] = meshgrid(Y,X);
for vi = 1:e_numVoltages
    
%     c = griddata(e_positions{vi, ii}(:,1), e_positions{vi, ii}(:,2), e_vals{vi,ii,:}, mapX, mapY);
%     e_map(:,:,vi) = c;
    
    F = scatteredInterpolant(e_positions{vi, ii}(:,1), e_positions{vi, ii}(:,2), e_vals{vi,ii,:},...
        'linear','nearest');
    e_map(:,:,vi) = F(mapX, mapY) * sign(e_voltages(vi));
    e_map(:,:,vi) = e_map(:,:,vi) - min(min(e_map(:,:,vi)));
    
    axes(ha(vi))
    imgDisplay(X,Y,e_map(:,:,vi))
    title(s_voltageLegend{vi});
    colormap parula
    colorbar
    axis equal
%     surface(mapX, mapY, zeros(size(mapX)), c)

end



% subunit locations, using generate positions

% c_subunitSpacing = 40;
% c_subunitSigma = 10;
% cell_subunitCenters = generatePositions('triangular', [cell_radius, c_subunitSpacing, 0]);
% cell_numSubunits = size(cell_subunitCenters,1);

% subunit RF profile, using gaussian w/ set radius (function)



%% Setup simulation


% sim_space = meshgrid
% convert RF maps to this simulation grid

%% Main stimulus change loop

stim_mode = 'movingBar';
numAngles = 8;
stim_barDirection = linspace(0,360,numAngles+1);
stim_barDirection(end) = [];
stim_numOptions = length(stim_barDirection);

% stim_mode = 'flashedSpot';
% numSizes = 10;
% stim_spotDiams = logspace(log10(20), log10(1000), numSizes);
% stim_numOptions = length(stim_spotDiams);

% stim_mode = 'flashedSpot';
% stim_numOptions = 1;


figure(102);clf;
outputAxes = tight_subplot(stim_numOptions, 1);

out_valsByOptions = [];

for optionIndex = 1:stim_numOptions
    fprintf('Running option %d of %d\n', optionIndex, stim_numOptions);

    %% Setup stimulus
    center = [0,0];

    stim_lightMatrix = zeros(sim_dims);


    if strcmp(stim_mode, 'flashedSpot')
        % flashed spot
%         stim_spotDiam = stim_spotDiams(optionIndex);
        stim_spotDiam = 200;
        stim_spotDuration = 0.4;
        stim_spotStart = 0.1;
        stim_intensity = 0.5;
        stim_spotPosition = [100,100];


        pos = stim_spotPosition + center;
        for ti = 1:sim_dims(1)
            t = T(ti);
            if t > stim_spotStart && t < stim_spotStart + stim_spotDuration

                for xi = 1:sim_dims(2)
                    x = X(xi);
                    for yi = 1:sim_dims(3)
                        y = Y(yi);

                        val = stim_intensity;

                        % circle shape
                        rad = sqrt((x - pos(1))^2 + (y - pos(2))^2);
                        if rad < stim_spotDiam / 2
                            stim_lightMatrix(ti, xi, yi) = val; 
                        end
                    end
                end
            end
        end




    elseif strcmp(stim_mode, 'movingBar')

        stim_barSpeed = 1000;
        stim_barLength = 300;
        stim_barWidth = 100;
%         stim_barDirection = 60; % degrees
        stim_moveTime = 0.8;
        stim_intensity = 0.5;

        for ti = 1:sim_dims(1)
            t = T(ti);

            movementVector = stim_barSpeed * [cosd(stim_barDirection(optionIndex)), sind(stim_barDirection(optionIndex))];

            barCenter = center + movementVector * (t - stim_moveTime / 2);

            for xi = 1:sim_dims(2)
                x = X(xi);
                for yi = 1:sim_dims(3)
                    y = Y(yi);

                    val = stim_intensity;

                    % circle shape
                    rad = sqrt((x - barCenter(1))^2 + (y - barCenter(2))^2);
                    if rad < stim_barWidth / 2
                        stim_lightMatrix(ti, xi, yi) = val;
                    end
                end
            end
        end
    end


    %% Run simulation

    sim_lightIntensity = [];

    %% Main loop
    for ti = 1:length(T)
        curTime = T(ti);

    %% Calculate illumination for each subunit
    %     for si = 1:cell_numSubunits
    %         subunitCenter = cell_subunitCenters(si,:);        

        sim_light = squeeze(stim_lightMatrix(ti, :, :));

%         figure(101);
%         imgDisplay(X,Y,sim_light);
%         colormap gray
%         caxis([0,1])
%         colorbar
%         title(sprintf('stimulus at %.3f sec', curTime));
%         drawnow

        %% Determine rf response

        for vi = 1:e_numVoltages
            % multiply rf map by stim
            % time filter here later
            rfmap = e_map(:,:,vi);

            sim_lightIntensity(ti, vi) = sum(sum(sim_light .* rfmap));
        end


        %% Combine subunit responses

    end
    % end time loop

    
    %% output temporal filter
%     figure(103)
    sim_response = [];
    for vi = 1:e_numVoltages
%         sim_current(vi,:) = 

        
        a = sim_lightIntensity(:,vi);
        d = diff(a);
        d(end+1) = 0;
        d(d < 0) = 0;
        lightOnNess = cumsum(d);
        
        
        filter_resampled = resample(filterOn{vi}, round(1/sim_timeStep), 1000);
        r = conv(lightOnNess, filter_resampled);
        sim_response(vi,:) = r(1:length(lightOnNess));
        
%         subplot(2,1,vi)
%         hold on
%         plot(normg(sim_lightIntensity(:,vi)));
%         plot(normg(lightOnNess))       
%         plot(normg(filter_resampled))
%         plot(normg(sim_response(vi,:)));
%         title(sprintf('light convolved with filter v = %d', e_voltages(vi)))
%         hold off
%         legend('light','light On','filter','filtered')
        
    end
    

    %% Output scale
    sim_responseScaled = sim_response;
    for vi = 1:e_numVoltages
        v = e_voltages(vi);
        if v == -60
            M = 7;
        else
            M = 1;
        end
        sim_responseScaled(vi,:) = M * sim_response(vi,:);
    end
    
    
    %% combine Ex and In
    sim_responseCombined = sum(sim_responseScaled,1);
    
    out_valsByOptions(optionIndex) = -1*sum(sim_responseCombined(sim_responseCombined < 0));

    % output nonlinearity

    %% Display output
    figure(102)
    axes(outputAxes(optionIndex));

    plot(T, sim_responseScaled)

    hold on
    plot(T, sim_responseCombined);
    hold off

%     title('Whole cell Response')
%     xlabel('time')
    xlim([min(T), max(T)]);
    legend(s_voltageLegend);
    
end

%% display combined output over stim options

figure(110);clf;
a = deg2rad(stim_barDirection);
p = out_valsByOptions ./ max(out_valsByOptions);

a(end+1) = a(1);
p(end+1) = p(1);
polar(a, p)

% plot(stim_spotDiams, out_valsByOptions)


%% Cry