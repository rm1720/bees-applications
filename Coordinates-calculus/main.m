%% Global function for finding the consecutive coordinates
%% version 2 ; 17/01/2020 : improvement of the detection algorithm, new functions to organize the code

function main(imagesDirectories, calibrationImagesDirectory, max_speed, FR, squareSize)

    %Keep in mind that the origin point of coordinates is in the left upper
    %corner.

    %Parameters calculated by the function allow us to remove the distorsion
    [camParameters,scale] = parametersRemoveDistortion(calibrationImagesDirectory, squareSize);

    Vx_max = max_speed; %in m/s
    Vz_max = Vx_max; % in this case both are equal

    Vx_maxP = Vx_max/scale; %in px/s
    Vz_maxP = Vz_max/scale;

    %FR = 100; %Frame Rate image/s
    FD = 1/FR; %Frame Duration

    thresholdValue = 0.03;

    % for each directory selected
    for k=1:length(imagesDirectories)
        % remove the distorsion of all images in the current folder and save
        % these new images in a new folder names "UndistortedImages"
        removeDistorsion(imagesDirectories{k}, 'UndistortedImages',camParameters);
        
        dossierEnCours = split(imagesDirectories{k},'\');
        dossierEnCours = string(dossierEnCours(end))
        
        %get all the images undistorted
        link=dir([fullfile(imagesDirectories{k}, 'UndistortedImages') '/*.tif']);
        numberOfImages = size(link, 1);

        coordinates = {};
        error_plotting = 0;
        % For the first image, we search the entrance all.

        %Reading of images
        referenceImage = imread(fullfile(link(1).folder, link(1).name));

        imageWidth = length(referenceImage(1,:));
        imageHeight = length(referenceImage(:,1));

        treatedImage = imread(fullfile(link(2).folder, link(2).name));

        % We substract the treated image to the reference image. Because the
        % insect appears darker than the background, this operation allows to
        % have a white spot in place of the insect from the treated image. We
        % make a threshold to obtain a balck & white image.
        treatedImage = imbinarize(referenceImage-treatedImage, thresholdValue);

        %We search all the centroids for all the white spots.
        regionProperties = regionprops(treatedImage, 'area', 'centroid', 'orientation');
        possibleCenters = {};


        for j=1:length(regionProperties)
            % To find the entrance all, we search the spot in the right part of
            % the image (the 10% right).
            if (regionProperties(j).Centroid(1)>0.9*imageWidth && regionProperties(j).Area>2)
                %We add this center to the possible centers
                possibleCenters(end+1).Area = regionProperties(j).Area;
                possibleCenters(end).x = regionProperties(j).Centroid(1);
                possibleCenters(end).z = regionProperties(j).Centroid(2);
            end
        end

        %if we have at least one possible spot
        if(length(possibleCenters)>0)
            possibleCenters = struct2table(possibleCenters);
            %we sort the list of possibleCenters by their area sizes
            %the biggest spot will be first in the list
            possibleCenters = sortrows(possibleCenters, 1, 'descend');

            %case where we have more than one possible center
            if(height(possibleCenters)>=2)
                %if the second possible center is at least smaller than 90% of
                %the size of the first (to avoid false error in the case where
                %two spots may be possible)
                if(possibleCenters.Area(2)<0.9*possibleCenters.Area(1))   
                    coordinates.t = 0;
                    coordinates.x = (imageWidth-possibleCenters.x(1))*scale;
                    coordinates.z = (imageHeight-possibleCenters.z(1))*scale;
                    position_ref = struct('x',possibleCenters.x(1),'z',possibleCenters.z(1));
                % else we ask to the user to select the spot
                else
                    error_plotting = error_plotting + 1;
                    figure;
                    imshow(imread(fullfile(link(1).folder, link(1).name)));
                    position_ref = struct('x',0,'z',0);
                    [position_ref.x, position_ref.z] = ginput(1);
                    coordinates.t = 0;
                    coordinates.x = (imageWidth-position_ref.x)*scale;
                    coordinates.z = (imageHeight-position_ref.z)*scale;
                    close;
                end
            %case where only one spot is possible
            else
                coordinates.t = 0;
                coordinates.x = (imageWidth-possibleCenters.x(1))*scale;
                coordinates.z = (imageHeight-possibleCenters.z(1))*scale;
                position_ref = struct('x',possibleCenters.x(1),'z',possibleCenters.z(1));
            end
        %impossible to find the spot, we ask to the user
        else
            h = msgbox('Impossible to find the entrance hole!', dossierEnCours, 'error');
            %'Impossible to find the bee'
                %We inform the user of the issue
                error_plotting = error_plotting + 1;
                %And we ask him to select the insect on the image
                figure;
                imshow(imread(fullfile(link(1).folder, link(1).name)));
                [position_ref.x, position_ref.z] = ginput(1);
                coordinates.t = 0;
                coordinates(end).x = (imageWidth-position_ref.x)*scale;
                coordinates(end).z = (imageHeight-position_ref.z)*scale;
                close;
        end
    w=waitbar(0, 'Calculus of the coordonates...', 'Name', dossierEnCours);
    %mkdir(fullfile(calibrationImagesDirectory, 'Test'));
    
    %That part will treat all the others images
    for i = 2:numberOfImages-1
        waitbar(i/(numberOfImages-1))
        %For the n image ; we use the (n-1) image as a reference
        referenceImage = imread(fullfile(link(i).folder, link(i).name));
        treatedImage = imread(fullfile(link(i+1).folder, link(i+1).name));
        treatedImage = imbinarize(referenceImage-treatedImage, thresholdValue);
        %imwrite(treatedImage, fullfile(calibrationImagesDirectory, 'Test', sprintf('n%d.tif', i)));
        regionProperties = regionprops(treatedImage, 'centroid', 'orientation', 'area');

        possibleCenters = {};
        
        %If we find at least one spot
        if(length(regionProperties)>0)
            for j=1:length(regionProperties)
                %If the calculated center is in the window of possible values
                if (regionProperties(j).Centroid(1)>position_ref.x-Vx_maxP*FD && regionProperties(j).Centroid(1)<=position_ref.x+Vx_maxP*FD && regionProperties(j).Centroid(2)<position_ref.z+Vz_maxP*FD && regionProperties(j).Centroid(2)>position_ref.z-Vz_maxP*FD && regionProperties(j).Area>2)
                    %We add this center to the possible centers
                    possibleCenters(end+1).Area = regionProperties(j).Area;
                    possibleCenters(end).x = regionProperties(j).Centroid(1);
                    possibleCenters(end).z = regionProperties(j).Centroid(2);
                end
            end

            %if we have at least one possible spot
            if(length(possibleCenters)>0)
                possibleCenters = struct2table(possibleCenters);
                %we sort the list of possibleCenters by their area sizes
                %the biggest spot will be first in the list
                possibleCenters = sortrows(possibleCenters, 1, 'descend');
                
                %case where we have more than one possible center
                if(height(possibleCenters)>=2)
                    %if the second possible center is at least smaller than 90% of
                    %the size of the first (to avoid false error in the case where
                    %two spots may be possible)
                    if(possibleCenters.Area(2)<0.9*possibleCenters.Area(1))
                        position_ref.x = possibleCenters.x(1);
                        position_ref.z = possibleCenters.z(1);
                        coordinates(end+1).t = i*FD;
                        coordinates(end).x = (imageWidth-possibleCenters.x(1))*scale;
                        coordinates(end).z = (imageHeight-possibleCenters.z(1))*scale;
                        coordinates(end).pitch = regionProperties(1).Orientation;
                    else
                        %if we don't find the spot thanks to the difference
                        %between the n and n+1 image, we try with the n+2
                        %image
                        [i,numberOfImages, link, calibrationImagesDirectory, Vx_maxP, Vz_maxP, FD, imageWidth, imageHeight, scale, coordinates, thresholdValue, position_ref, error_plotting] = testNplus2(i,numberOfImages, link, calibrationImagesDirectory, Vx_maxP, Vz_maxP, FD, imageWidth, imageHeight, scale, coordinates, thresholdValue, position_ref, error_plotting);
                    end
                else
                    position_ref.x = possibleCenters.x(1);
                    position_ref.z = possibleCenters.z(1);
                    coordinates(end+1).t = i*FD;
                    coordinates(end).x = (imageWidth-possibleCenters.x(1))*scale;
                    coordinates(end).z = (imageHeight-possibleCenters.z(1))*scale;
                    coordinates(end).pitch = regionProperties(1).Orientation;
                end
                
            %Case where it is impossible to find the insect
            else
                %if we don't find the spot thanks to the difference
                %between the n and n+1 image, we try with the n+2
                %image
                [i,numberOfImages, link, calibrationImagesDirectory, Vx_maxP, Vz_maxP, FD, imageWidth, imageHeight, scale, coordinates, thresholdValue, position_ref, error_plotting] = testNplus2(i,numberOfImages, link, calibrationImagesDirectory, Vx_maxP, Vz_maxP, FD, imageWidth, imageHeight, scale, coordinates, thresholdValue, position_ref, error_plotting);
            end
        else
            [i, error_plotting, link, position_ref, FD, imageWidth, imageHeight, scale, coordinates] = userSelection(i, error_plotting, link, position_ref, FD, imageWidth, imageHeight, scale, coordinates);
        end
                
        clear center;
    end
    delete(w);
    %axis([0 imageWidth*scale 0 imageHeight*scale])
    h = msgbox(sprintf('Number of plot errors : %d',error_plotting),dossierEnCours,'warn');
    %Coordinates saved in a coordinates.mat file in the directory selected
    save(fullfile(imagesDirectories{k}, 'coordinates.mat'), 'coordinates');
    end
end

%% Function to let the user select the spot
function [i, error_plotting, link, position_ref, FD, imageWidth, imageHeight, scale, coordinates] = userSelection(i, error_plotting, link, position_ref, FD, imageWidth, imageHeight, scale, coordinates)
    i
    error_plotting = error_plotting + 1;
    %And we ask him to select the insect on the image
    figure;
    imshow(imread(fullfile(link(i+1).folder, link(i+1).name)));
    [position_ref.x, position_ref.z] = ginput(1);
    coordinates(end+1).t = i*FD;
    coordinates(end).x = (imageWidth-position_ref.x)*scale;
    coordinates(end).z = (imageHeight-position_ref.z)*scale;
    close;
end

%% Function to search the spot by substracting images n+2 and n
function [i,numberOfImages, link, calibrationImagesDirectory, Vx_maxP, Vz_maxP, FD, imageWidth, imageHeight, scale, coordinates, thresholdValue, position_ref, error_plotting] = testNplus2(i,numberOfImages, link, calibrationImagesDirectory, Vx_maxP, Vz_maxP, FD, imageWidth, imageHeight, scale, coordinates, thresholdValue, position_ref, error_plotting)
    if(i<numberOfImages-3)
        'test n+2'
        referenceImage = imread(fullfile(link(i).folder, link(i).name));
        treatedImage = imread(fullfile(link(i+2).folder, link(i+2).name));
        treatedImage = imbinarize(referenceImage-treatedImage, thresholdValue);
        %imwrite(treatedImage, fullfile(calibrationImagesDirectory, 'Test', sprintf('n%d.tif', i)));
        regionProperties = regionprops(treatedImage, 'centroid', 'orientation', 'area');

        possibleCenters = {};

        %If we find at least one possible spot
        if(length(regionProperties)>0)
            for j=1:length(regionProperties)
                %If the calculated center is in the window of possible values
                if (regionProperties(j).Centroid(1)>position_ref.x-Vx_maxP*FD && regionProperties(j).Centroid(1)<=position_ref.x+Vx_maxP*FD && regionProperties(j).Centroid(2)<position_ref.z+Vz_maxP*FD && regionProperties(j).Centroid(2)>position_ref.z-Vz_maxP*FD && regionProperties(j).Area>2)
                    %We add this center to the possible centers
                    possibleCenters(end+1).Area = regionProperties(j).Area;
                    possibleCenters(end).x = regionProperties(j).Centroid(1);
                    possibleCenters(end).z = regionProperties(j).Centroid(2);
                end
            end

            %if we have at least one possible spot
            if(length(possibleCenters)>0)

                possibleCenters = struct2table(possibleCenters);
                %we sort the list of possibleCenters by their area sizes
                %the biggest spot will be first in the list
                possibleCenters = sortrows(possibleCenters, 1, 'descend');

                %case where we have more than one possible center
                if(height(possibleCenters)>=2)
                    %if the second possible center is at least smaller than 90% of
                    %the size of the first (to avoid false error in the case where
                    %two spots may be possible)
                    if(possibleCenters.Area(2)<0.9*possibleCenters.Area(1))
                        position_ref.x = possibleCenters.x(1);
                        position_ref.z = possibleCenters.z(1);
                        coordinates(end+1).t = i*FD;
                        coordinates(end).x = (imageWidth-possibleCenters.x(1))*scale;
                        coordinates(end).z = (imageHeight-possibleCenters.z(1))*scale;
                        coordinates(end).pitch = regionProperties(1).Orientation;
                    else
                        [i, error_plotting, link, position_ref, FD, imageWidth, imageHeight, scale, coordinates] = userSelection(i, error_plotting, link, position_ref, FD, imageWidth, imageHeight, scale, coordinates);
                    end
                else
                    position_ref.x = possibleCenters.x(1);
                    position_ref.z = possibleCenters.z(1);
                    coordinates(end+1).t = i*FD;
                    coordinates(end).x = (imageWidth-possibleCenters.x(1))*scale;
                    coordinates(end).z = (imageHeight-possibleCenters.z(1))*scale;
                    coordinates(end).pitch = regionProperties(1).Orientation;
                end
            else
                [i, error_plotting, link, position_ref, FD, imageWidth, imageHeight, scale, coordinates] = userSelection(i, error_plotting, link, position_ref, FD, imageWidth, imageHeight, scale, coordinates);
            end
        else
            [i, error_plotting, link, position_ref, FD, imageWidth, imageHeight, scale, coordinates] = userSelection(i, error_plotting, link, position_ref, FD, imageWidth, imageHeight, scale, coordinates);
        end
    else
        [i, error_plotting, link, position_ref, FD, imageWidth, imageHeight, scale, coordinates] = userSelection(i, error_plotting, link, position_ref, FD, imageWidth, imageHeight, scale, coordinates);
    end
end