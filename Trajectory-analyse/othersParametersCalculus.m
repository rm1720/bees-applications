function insect = othersParametersCalculus(fileDirectory, calculateOFVD, sampleTime, tunnelHeight, floorAltitude, insectLateralPosition)
load(fileDirectory);
numberOfCordinates = length(coordinates);

insect(length(coordinates)) = struct;
for i = 1:length(coordinates)
    insect(i).t = coordinates(i).t;
    insect(i).pitch = coordinates(i).pitch;
end

insect(1).Vx = (coordinates(2).x - coordinates(1).x) / sampleTime;
insect(1).Vz = (coordinates(2).z - coordinates(1).z) / sampleTime;
insect(2).Vx = (coordinates(3).x - coordinates(1).x) / (2*sampleTime);
insect(2).Vz = (coordinates(3).z - coordinates(1).z) / (2*sampleTime);
insect(numberOfCordinates-1).Vx = (coordinates(numberOfCordinates).x-coordinates(numberOfCordinates-2).x)/(2*sampleTime);
insect(numberOfCordinates-1).Vz = (coordinates(numberOfCordinates).z-coordinates(numberOfCordinates-2).z)/(2*sampleTime);
insect(numberOfCordinates).Vx = (coordinates(numberOfCordinates).x-coordinates(numberOfCordinates-1).x)/sampleTime;
insect(numberOfCordinates).Vz = (coordinates(numberOfCordinates).z-coordinates(numberOfCordinates-1).z)/sampleTime;

for n = 3:numberOfCordinates-2
    insect(n).Vx = (2*coordinates(n+2).x + coordinates(n+1).x - coordinates(n-1).x - 2*coordinates(n-2).x)/(10*sampleTime);
    insect(n).Vz = (2*coordinates(n+2).z + coordinates(n+1).z - coordinates(n-1).z - 2*coordinates(n-2).z)/(10*sampleTime);
    
%     figure(1)
%     plot(coordinates(n).t, insect(n).Vz, '+g')
%     hold on
%     plot(coordinates(n).t, insect(n).Vx, '+r')
%     hold on
end

if(calculateOFVD == 1)
    for n = 1:numberOfCordinates
    insect(n).V = sqrt(insect(n).Vx^2 + insect(n).Vz^2);
    insect(n).h = coordinates(n).z - floorAltitude;
    
%     figure(2)
%     plot(coordinates(n).t, insect(n).V, '+b')
%     hold on
    insect(n).OFV = insect(n).Vx / insect(n).h;
    insect(n).OFD = insect(n).Vx / (tunnelHeight - insect(n).h);
    insect(n).OFL = insect(n).Vx / insectLateralPosition;
%     figure(3)
%     plot(coordinates(n).t, insect(n).OFV, '+b')
%     hold on
%     plot(coordinates(n).t, insect(n).OFD, '+r')
%     hold on
%     plot(coordinates(n).t, insect(n).OFL, '+g')
%     hold on
    
    insect(n).S = atan(insectLateralPosition/coordinates(n).z);
%     figure(4)
%     plot(coordinates(n).t, insect(n).S, '+b')
%     hold on
    end
else
    for n = 1:numberOfCordinates
        insect(n).V = sqrt(insect(n).Vx^2 + insect(n).Vz^2);
        insect(n).h = coordinates(n).z - floorAltitude;
        
        insect(n).OFL = insect(n).Vx / insectLateralPosition;
        insect(n).S = atan(insectLateralPosition/coordinates(n).z);
    end
end