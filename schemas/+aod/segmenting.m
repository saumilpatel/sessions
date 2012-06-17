
% Conditions for the pre volume:
% 1. Most recent volume before scan
% 2. Started within 3 minutes of scan starting (?)
% 3. Distance no more than 10 micron from scan start (identical?)
vol = pro(acq.AodVolume,'x_coordinate->volume_x_coordinate','y_coordinate->volume_y_coordinate','z_coordinate->volume_z_coordinate');

as = fetch(acq.AodScan & sess)
as = as(6)

pre_vol = pro(acq.AodScan & as, (acq.AodScan * pro(acq.AodVolume)) & 'aod_volume_start_time <  aod_scan_start_time', 'MAX(aod_volume_start_time)->aod_volume_start_time');
post_vol = pro(acq.AodScan & as, (acq.AodScan * pro(acq.AodVolume)) & '(aod_volume_start_time >  aod_scan_stop_time)', 'MIN(aod_volume_start_time)->aod_volume_start_time')

pre = fetch(acq.AodVolume & pre_vol, '*');
post = fetch(acq.AodVolume(post_vol), '*');

%% Checks over the volumes
as = fetch(acq.AodScan(as), '*');
if (as.aod_scan_start_time - pre.aod_volume_start_time) > (4 * 60000)
    warning('Pre scan volume stale')
end

if (post.aod_volume_start_time - as.aod_scan_stop_time) > (4 * 60000)
    warning('Post scan volume stale')
end

if pre.x_coordinate == 0 || pre.y_coordinate == 0 || pre.z_coordinate == 0
    warning('No coordinate in the pre scan');
    pre_dist = NaN;
else
    pre_dist = sqrt((pre.x_coordinate - as.x_coordinate).^2 + (pre.y_coordinate - as.y_coordinate).^2 + ...
        (pre.z_coordinate - as.z_coordinate).^2);
end

if post.x_coordinate == 0 || post.y_coordinate == 0 || post.z_coordinate == 0
    warning('No coordinate in the pre scan');
    post_dist = NaN;
else
    post_dist = sqrt((post.x_coordinate - as.x_coordinate).^2 + (post.y_coordinate - as.y_coordinate).^2 + ...
        (post.z_coordinate - as.z_coordinate).^2);
end

if pre_dist > 10
    warning('Pre scan too far away')
end

if post_dist > 10
    warning('Post scan too far away')
end

%% Segment cells
asr = getFile(acq.AodScan(as))
coordinates = asr.coordinates;

vol = getFile(acq.AodVolume(pre_vol));
dat = vol(:,:,:);
x = vol.x;
y = vol.y;
z = vol.z;
for i = 1:length(vol.z)
    cla
    imagesc(vol.x,vol.y,dat(:,:,i)');
    hold on
    idx = find(coordinates(:,3) == z(i));
    plot(coordinates(idx,1),coordinates(idx,2),'ow')
    title(num2str(z(i)))
    pause
end

dx = mean(diff(x));
dy = mean(diff(y));
dz = mean(diff(z));
x_grid = (0:20) * dx; x_grid = (x_grid-mean(x_grid));
y_grid = (0:20) * dx; y_grid = (y_grid-mean(y_grid));
z_grid = (0:4) * dx; z_grid = (z_grid-mean(z_grid));
[x_grid y_grid z_grid] = meshgrid(x_grid,y_grid,z_grid);
h = exp(-(x_grid.^2 + y_grid.^2 + z_grid.^2) / 2 / 0.5^2);
h  = h / sum(h(:));

dat = dat - min(dat(:));
dat = dat / max(dat(:));
dat = bsxfun(@rdivide,dat,mean(mean(dat,1),2));

%h = repmat(fspecial('gaussian',3), [1 1 3]);
%h = bsxfun(@times, h, reshape([0.2 1 0.2],[1 1 3]));
dat_smoothed = imfilter(dat, h, 'replicate');

for i = 1:length(vol.z)
    cla
    imagesc(vol.x,vol.y,dat_smoothed(:,:,i)');
    hold on
    idx = find(coordinates(:,3) == z(i));
    plot(coordinates(idx,1),coordinates(idx,2),'ow')
    title(num2str(z(i)))
    pause
end

[y_shift x_shift z_shift] = meshgrid(-8:8,-5:5,-3:3);
for i = 1:size(coordinates,1)
    [~,idx1] = min(abs(coordinates(i,1) - x));
    [~,idx2] = min(abs(coordinates(i,2) - y));
    [~,idx3] = min(abs(coordinates(i,3) - z));
    
    x_pos = idx1 + x_shift;
    y_pos = idx2 + y_shift;
    z_pos = idx3 + z_shift;
    
    if any(x_pos(:) <= 0 | y_pos(:) <= 0 | z_pos(:) <= 0 | ...
            x_pos(:) > size(dat,1) | y_pos(:) > size(dat,2) | z_pos(:) > size(dat,3))
        cent(i,1:3) = coordinates(i,:);
        continue
    end
    
    idx = sub2ind(size(dat), x_pos(:), y_pos(:), z_pos(:));
    sub_vol = reshape(dat_smoothed(idx), size(x_pos));
    
    % grid for fitting gaussian
    x_gauss = x_shift * dx;
    y_gauss = y_shift * dy;
    z_gauss = z_shift * dz;
    
    m = @(x,y,z,low,max) low + max*exp(-((x_gauss(:)-x).^2 + (y_gauss(:)-y).^2 + (z_gauss(:)-z).^2) / 2 / 2.^2)
    f = @(x,y,z,low,max) sum((sub_vol(:) - m(x,y,z,low,max)).^2);
    g = @(x) f(x(1),x(2),x(3),x(4),x(5))
    x1 = fminunc(g,[0 0 0 min(sub_vol(:)) range(sub_vol(:))])
    
    im = reshape(m(x1(1),x1(2),x1(3),x1(4),x1(5)),size(x_gauss));
    cent(i,1:3) = coordinates(i,:) + x1(1:3);
    
    z_offset = round(x1(3) / dz);
    r = [min(sub_vol(:)) max(sub_vol(:))];
    clf
    subplot(221)
    cla
    imagesc(sub_vol(:,:,end/2 + 0.5 + z_offset)',r)
    hold on
    plot(size(sub_vol,1)/2+0.5+x1(1)/dx, size(sub_vol,2)/2+0.5+x1(2)/dy,'.k')
    title('New center')
    subplot(223)
    cla
    imagesc(sub_vol(:,:,end/2+0.5)');
    hold on
    plot(size(sub_vol,1)/2, size(sub_vol,2)/2+0.5,'.k')
    title('Old center')
    subplot(222)
    imagesc(im(:,:,end/2 + 0.5 + z_offset)',r)
    subplot(224)
    imagesc(im(:,:,end/2+0.5)')
    
    drawnow
    pause(0.2)
end


sub_vol = sub_vol - min(sub_vol(:));
sub_vol = sub_vol / max(sub_vol(:));

marker = zeros(size(sub_vol));
marker(end/2+0.5,end/2+0.5,end/2+0.5) = 1;


dist = 
% Find the pre scan volume (if exists)
pairs = fetch((vol * acq.AodScan) & as & ...
    'aod_volume_start_time < aod_scan_start_time' & 'aod_volume_start_time > (aod_scan_start_time - 600000)' & ...
    '(POW(x_coordinate - volume_x_coordinate,2) + POW(y_coordinate - volume_y_coordinate,2) + POW(z_coordinate - volume_z_coordinate,2))< 5');
pairs = dj.struct.sort(pairs,'aod_volume_start_time')
pairs = pairs(end);
pre_vol = fetch(acq.AodVolume(pairs))


pairs = fetch((vol * acq.AodScan) & as & ...
    'aod_volume_start_time > aod_scan_stop_time' & 'aod_volume_start_time < (aod_scan_stop_time + 600000)' & ...
    '(POW(x_coordinate - volume_x_coordinate,2) + POW(y_coordinate - volume_y_coordinate,2) + POW(z_coordinate - volume_z_coordinate,2))< 5');
pairs = dj.struct.sort(pairs,'aod_volume_start_time')
pairs = pairs(end);
post_vol = fetch(acq.AodVolume(pairs))


as = fetch(acq.AodScan & sess)
av = fetch(acq.AodVolume & sess)