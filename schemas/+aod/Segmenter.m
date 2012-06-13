classdef Segmenter
    
    properties (Constant)
        range_x_um = 10;
        range_y_um = 10;
        range_z_um = 10;       
    end
    
    properties
        x = [];
        y = [];
        z = [];
        
        dx = [];
        dy = [];
        dz = [];
        
        numCells = 0;

        dat = [];
        dat_smoothed = [];
        click_coordinates = [];
        centered_coordinates = [];
    end
    
    methods 
        function self = Segmenter(dat,x,y,z)
            % Store the volume information in this object
            self.dat = dat;
            self.x = x;
            self.y = y;
            self.z = z;
           
            % Get the pixel spacing
            self.dx = mean(diff(self.x));
            self.dy = mean(diff(self.y));
            self.dz = mean(diff(self.z));
            
            self.numCells = 0;
            self = smoothVolume(self);
        end

        function mask = generateMask(self, radius, zind)
            % Generates a 3D mask of the selected points that extends the
            % selected radius
            
            if nargin < 3
                zind = ':';
            end
            
            zval = self.z(zind);
            mask = zeros(length(self.x),length(self.y),length(zval));
            
            [gy gx gz] = meshgrid(self.y,self.x,zval);
            for i = 1:size(self.centered_coordinates,1)
                x = self.centered_coordinates(i,1);
                y = self.centered_coordinates(i,2);
                z = self.centered_coordinates(i,3);
                mask(((gx(:) - x).^2 + (gy(:) - y).^2 + (gz(:) - z).^2) < radius^2) = 1;
            end
        end
            
        function self = smoothVolume(self)
            % Apply a smoothing filter over the volume

            x_grid = (0:10) * self.dx;
            x_grid = (x_grid-mean(x_grid));
            y_grid = (0:10) * self.dx;
            y_grid = (y_grid-mean(y_grid));
            z_grid = (0:4) * self.dx;
            z_grid = (z_grid-mean(z_grid));
            [x_grid y_grid z_grid] = meshgrid(x_grid,y_grid,z_grid);
            
            % Compute a fairly small gaussian
            h = exp(-(x_grid.^2 + y_grid.^2 + z_grid.^2) / 2 / 0.3^2);
            h  = h / sum(h(:));
            
            dat = self.dat - min(self.dat(:));
            dat = dat / max(dat(:));
            dat = bsxfun(@rdivide,dat,mean(mean(dat,1),2));
            
            self.dat_smoothed = imfilter(dat, h, 'replicate');
        end
        
        function self = addClick(self, x, y, z)
            % Find the center of a cell given a click location
            
            self.numCells = self.numCells + 1;
            self.click_coordinates(self.numCells,1:3) = [x y z];
            
            % Extract a subvolume 
            x_r = -round(self.range_x_um / 2 / self.dx):round(self.range_x_um / 2 / self.dx);
            y_r = -round(self.range_y_um / 2 / self.dy):round(self.range_y_um / 2 / self.dy);
            z_r = -round(self.range_z_um / 2 / self.dz):round(self.range_z_um / 2 / self.dz);

            % Find the index within the volume where the click was
            [~,idx1] = min(abs(x - self.x));
            [~,idx2] = min(abs(y - self.y));
            [~,idx3] = min(abs(z - self.z));

            % Cover the condition where the pixels hit the edge of the
            % volume
            x_pos = idx1 + x_r;
            x_pos(x_pos < 1) = [];
            x_pos(x_pos > size(self.dat,1)) = [];
            y_pos = idx2 + y_r;
            y_pos(y_pos < 1) = [];
            y_pos(y_pos > size(self.dat,2)) = [];
            z_pos = idx3 + z_r;
            z_pos(z_pos < 1) = [];
            z_pos(z_pos > size(self.dat,3)) = [];

            % Extract the subvolue
            sub_vol = self.dat_smoothed(x_pos,y_pos,z_pos);

            % grid for fitting gaussian
            [y_gauss x_gauss z_gauss] = meshgrid(self.y(y_pos), self.x(x_pos), self.z(z_pos));

            % Optimize a gaussian fit of the subvolume
            m = @(x,y,z,low,max) low + exp(max)*exp(-((x_gauss(:)-x).^2 + (y_gauss(:)-y).^2 + (z_gauss(:)-z).^2) / 2 / 3.^2);
            f = @(x,y,z,low,max) sum((sub_vol(:) - m(x,y,z,low,max)).^2);
            g = @(x) f(x(1),x(2),x(3),x(4),x(5));
                                    
            opt = optimset('Display','off','LargeScale','off');
            x1 = fminunc(g,[x y z min(sub_vol(:)) log(range(sub_vol(:)))],opt);
            
            cent_x = x1(1);
            cent_y = x1(2);
            cent_z = x1(3);

            self.centered_coordinates(self.numCells,1:3) = [cent_x cent_y cent_z];
        end
        
        function self = updateVolume(self, dat, x, y, z)
            self.dat = dat;
            self.x = x;
            self.y = y;
            self.z = z;
           
            % Get the pixel spacing
            self.dx = mean(diff(self.x));
            self.dy = mean(diff(self.y));
            self.dz = mean(diff(self.z));
            
            self = smoothVolume(self);
            
            clicks = self.click_coordinates;
            self.click_coordinates = [];
            self.centered_coordinates = [];
            self.numCells = 0;
            for i = 1:size(clicks,1)
                self = addClick(self, clicks(i,1), clicks(i,2), clicks(i,3));
            end
        end
        
        function [p1 p2 p3] = centeredCutOut(self, cellNum)
            [p1 p2 p3] = cutOut(self, self.centered_coordinates, cellNum);
        end

        function [p1 p2 p3] = originalCutOut(self, cellNum)
            [p1 p2 p3] = cutOut(self, self.click_coordinates, cellNum);
        end

        function [p1 p2 p3] = cutOut(self, coordinates, cellNum)
            assert(cellNum > 0 & cellNum <= self.numCells & length(cellNum) == 1, 'Bad input');

            % Find the index into the volume
            [~,i1] = min(abs(coordinates(cellNum,1)-self.x));
            [~,i2] = min(abs(coordinates(cellNum,2)-self.y));
            [~,i3] = min(abs(coordinates(cellNum,3)-self.z));
            
            r = -round(self.range_x_um / self.dx / 2):round(self.range_x_um / self.dx / 2);
            i1_r = i1 + r;
            i1_r(i1_r < 1) = [];
            i1_r(i1_r > size(self.dat,1)) = [];
            
            r = -round(self.range_y_um / self.dy / 2):round(self.range_y_um / self.dy / 2);
            i2_r = i2 + r;
            i2_r(i2_r < 1) = [];
            i2_r(i2_r > size(self.dat,2)) = [];
            
            r = -round(self.range_z_um / self.dz / 2):round(self.range_z_um / self.dz / 2);
            i3_r = i3 + r;
            i3_r(i3_r < 1) = [];
            i3_r(i3_r > size(self.dat,3)) = [];
            
            p1 = squeeze(self.dat_smoothed(i1,i2_r,i3_r));
            p2 = squeeze(self.dat_smoothed(i1_r,i2,i3_r));
            p3 = squeeze(self.dat_smoothed(i1_r,i2_r,i3));
        end
    end
end
