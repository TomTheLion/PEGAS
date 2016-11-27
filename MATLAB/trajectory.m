%trajectory.m
%Displays a 3D plot of flight trajectories (distinguishing powered flight
%and coast periods). Pass target figure ID in 'fid'. Option to render a
%sphere representing Earth available in 'earth':
%   0 - no Earth
%   1 - only upper hemisphere
%   2 - render whole Earth
%Option to generate and render direction vectors of the local RNC frame of
%a burnout state for each trajectory segment available in 'vectors'
%   0 - no vectors
%   1 - only last powered state
%   2 - each segment
function [] = trajectory(powered, coast, target, earth, vectors, fid)
    global R;
    figure(fid); clf; hold on;
    %color config
    cEarth = 'g';   %the planet
    cPower = 'r';   %powered ascent trajectories
    cCoast = 'b';   %coast trajectories
    cTrack = 'k';   %ground tracks
                    %vectors defined, unfortunately, in their function
    cTarget = 'm';  %target orbit
    %vector size (no matter if desired or not) depending on Earth presence
    if earth==0
        %for no Earth, this will suffice
        scale = 100000;
    else
        %if we render the planet too, will need to make vectors a bit bigger
        scale = 3000000;
    end;
    %render Earth?
    if earth==1
        [sx,sy,sz]=sphere(20);
        if earth<2
            sx=sx(11:end,:);
            sy=sy(11:end,:);
            sz=sz(11:end,:);
        end;
        plot3(R*sx,R*sy,R*sz,cEarth);
        scatter3(0,0,0,cEarth);
    elseif earth==2
        earth_sphere('m');
        cTrack = 'y';       %ground tracks will be easier visible in yellow
    end;
    %display powered paths
    for i=1:length(powered)
        x = powered(i).Plots;
        plot3(x.r(:,1), x.r(:,2), x.r(:,3), cPower);
    end;
    for i=1:length(coast)
        x = coast(i).Plots;
        plot3(x.r(:,1), x.r(:,2), x.r(:,3), cCoast);
    end;
    %display ground tracks for all
    for i=1:length(powered)
        x = powered(i).Plots;
        gt = zeros(length(x.r),3);
        for j=1:length(x.r)
            gt(j,:) = R*x.r(j,:)/x.rmag(j);
        end;
        plot3(gt(:,1), gt(:,2), gt(:,3), cTrack);
    end;
    for i=1:length(coast)
        x = coast(i).Plots;
        gt = zeros(length(x.r),3);
        for j=1:length(x.r)
            gt(j,:) = R*x.r(j,:)/x.rmag(j);
        end;
        plot3(gt(:,1), gt(:,2), gt(:,3), cTrack);
    end;
    %optionally, vectors
    if vectors>0
        if vectors>1
            for i=1:length(powered)
                x = powered(i).Plots;
                n = length(x.r);
                dirs(x.r(n,:), x.v(n,:), scale);
            end;
            for i=1:length(coast)
                x = coast(i).Plots;
                n = length(x.r);
                dirs(x.r(n,:), x.v(n,:), scale);
            end;
        else
            x = powered(length(powered)).Plots;
            n = length(x.r);
            dirs(x.r(n,:), x.v(n,:), scale);
        end;
    end;
    %optionally, target orbit ground track
    if isfield(target, 'normal') && earth>0
        %normal vector first
        t = zeros(2,3);
        t(2,:) = target.normal*R*1.25;
        plot3(t(:,1), t(:,2), t(:,3), cTarget);
        %then a nice target ground track
        t = 1:1:360;
        tt = zeros(length(t), 3);
        %it's a little hard cause we have to rework the matrices...
        %http://math.stackexchange.com/a/476311/380921
        n = target.normal;
        a = [0 0 1];
        v = cross(a,n);
        s = norm(v);
        c = dot(a,n);
        vx = [0 -v(3) v(2); v(3) 0 -v(1); -v(2) v(1) 0];
        Rot = [1 0 0; 0 1 0; 0 0 1];
        Rot = Rot + vx + ((1-c)/s^2) * vx*vx;
        for i=1:length(tt)
            tt(i,:) = (R+100)*(Rot*[sind(t(i));cosd(t(i));0])';
        end;
        plot3(tt(:,1), tt(:,2), tt(:,3), cTarget);
    end;
    axis equal; %otherwise the whole plot looks just silly
    hold off;
end

%gets and renders direction vectors
function [] = dirs(r, v, scale)
    rnc = getCircumFrame(r, v);
    t = zeros(2,3);
    t(1,:) = r;
    t(2,:) = r + scale*rnc(1,:);
    plot3(t(:,1), t(:,2), t(:,3), 'c');
    t(2,:) = r + scale*rnc(2,:);
    plot3(t(:,1), t(:,2), t(:,3), 'c');
    t(2,:) = r + scale*rnc(3,:);
    plot3(t(:,1), t(:,2), t(:,3), 'c');
end

%FUNCTION PURELY COPIED FROM flightSim3D.m
%constructs a local reference frame in style of PEG coordinate base
function [f] = getCircumFrame(r, v)
    %pass current position under r (1x3)
    %current velocity under v (1x3)
    radial = unit(r);               %Up direction (radial away from Earth)
    normal = unit(cross(r, v));     %Normal direction (perpendicular to orbital plane)
    circum = cross(normal, radial); %Circumferential direction (tangential to sphere, in motion plane)
    f = zeros(3,3);
    %return a left(?)-handed coordinate system base
    f(1,:) = radial;
    f(2,:) = normal;
    f(3,:) = circum;
end