dbFileName = 'dendritePolygonDatabase.mat';
if isfile(dbFileName)
    load(dbFileName)
    fprintf('Loaded %g cells from db\n', size(dendritePolygonDatabase, 1));
else
    disp('no db found')
    return
end

db = dendritePolygonDatabase;

for ci = 1:size(db,1)

    cellName = db.Properties.RowNames{ci};
    soma = db{ci, 'soma'};
    dendriticPolygon = db{ci, 'polygon'}{1};
    dendriticPolygonResampled = resamplePolygon(dendriticPolygon,1000);

    center = centroid(dendriticPolygonResampled); %find center of major axis
%     rectangle('Position',10 * [-.5, -.5, 1, 1] + [center(1), center(2), 0, 0],'Curvature',1, 'FaceColor', [.3 .5 0]);

%     drawPolygon(dendriticPolygonResampled(:,1), dendriticPolygonResampled(:,2), 'b', 'LineWidth',2);

    %DSI and OSI
    [theta,rho] = cart2pol(dendriticPolygonResampled(:,1),dendriticPolygonResampled(:,2)); %rad
    R=0;
    RDirn=0;
    ROrtn=0;
    for j=1:length(theta)
        R=R+rho(j);
        RDirn = RDirn + rho(j)*exp(sqrt(-1)*theta(j));
        ROrtn = ROrtn + rho(j)*exp(2*sqrt(-1)*theta(j));
    end

    DSI = abs(RDirn/R);
    OSI = abs(ROrtn/R);
    DSang = angle(RDirn/R)*180/pi; %deg
    OSang = angle(ROrtn/R)*90/pi; %deg

    if DSang < 0
        DSang = DSang + 360;
    end
    if OSang < 0
        OSang = OSang + 360;
    end

    %DS
%     [x,y] = pol2cart(DSang*pi/180, max(rho)*DSI); %rad
%     line([0 x] + center(1), [0 y] + center(2), 'Color', 'r', 'LineWidth', 3);
    %OS
%     [x,y] = pol2cart(OSang*pi/180, max(rho)*OSI); %rad
%     line([-x x] + center(1), [-y y] + center(2), 'Color', 'g', 'LineWidth', 3);

    %Area
    Area = abs(polygonArea(dendriticPolygonResampled));

    [COM_angle, COM_length] = cart2pol((center(1) - soma(1)), (center(2) - soma(2)));
    COM_angle = mod(COM_angle * 180/pi, 360);
    db{ci, 'angle_somaToCenterOfMass'} = COM_angle;
%     line([x_soma center(1)], [y_soma center(2)], 'Color', 'blue', 'LineWidth', 3)
end