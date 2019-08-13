function [noise,labels,RL] = dt_ship_signal(pwr,wIdx)

% tbin          - time bin average for spectra (s)
% nave          - number of spectral averages
% freqvec       - frequency band
% freqBinSz     - frequency bin size
% stimRaw       - start raw file
% thrClose      - threshold for close noise
% thrDistant    - threshold for distant ships
% thrRL         - threshold received levels to distinguish weather noise

global REMORA

% ltsa file parameters
tbin = REMORA.ship_dt.ltsa.tave;
nave = REMORA.ship_dt.ltsa.nave;
freqvec = REMORA.ship_dt.ltsa.fimin:REMORA.ship_dt.ltsa.fmax;
freqBinSz = REMORA.ship_dt.ltsa.dfreq;
f = REMORA.ship_dt.ltsa.freq;

% user settings
thrClose = REMORA.ship_dt.settings.thrClose;
thrDistant = REMORA.ship_dt.settings.thrDistant;
thrRL = REMORA.ship_dt.settings.thrRL; 
addtime = REMORA.ship_dt.settings.buffer/tbin;
minPassage = REMORA.ship_dt.settings.minPassage/tbin;

%identify disk writing noise
if REMORA.ship_dt.settings.diskWrite
    ipeak = (round(7.5/tbin):nave:size(pwr,2));
    ipeak(ipeak<0) = 0;
    exclude = sort([ipeak-2,ipeak-1, ipeak,ipeak+1, ipeak+2 ]);
    exclude(exclude<=0 | exclude>size(pwr,2))=[];
    
    % exclude disk noise
    pwr(:,exclude) = NaN;
    
end
% -------------------------------------

%account for bin width
sub=10*log10(freqBinSz);
pwr = pwr - sub;

% get pwr for each frequency bands
%  |Band 1: 1-5 kHz
% -|Band 2: 5-10 kHz
%  |Band 3: 10-50 kHz
% get edges of bands
[~,lowB1] = min(abs(f-REMORA.ship_dt.settings.lowBand(1)));
[~,hiB1] = min(abs(f-REMORA.ship_dt.settings.lowBand(2)));
[~,lowB2] = min(abs(f-REMORA.ship_dt.settings.mediumBand(1)));
[~,hiB2] = min(abs(f-REMORA.ship_dt.settings.mediumBand(2)));
[~,lowB3] = min(abs(f-REMORA.ship_dt.settings.highBand(1)));
[~,hiB3] = min(abs(f-REMORA.ship_dt.settings.highBand(2)));


pwrB1 = pwr(lowB1:hiB1,:);
pwrB2 = pwr(lowB2:hiB2,:);
pwrB3 = pwr(lowB3:hiB3,:);

%apply appropriate transfer function to the data
% Get transfer function
if ischar(REMORA.ship_dt.settings.tfFullFile)
    fidtf = fopen(REMORA.ship_dt.settings.tfFullFile,'r');
    [transferFn,~] = fscanf(fidtf,'%f %f',[2,inf]);
    fclose(fidtf);
    
    tf = interp1(transferFn(1,:),transferFn(2,:),freqvec,'linear','extrap');
    for i=1:size(pwr,2)
        pwrB1(:,i) = pwrB1(:,i)+tf(lowB1:hiB1).';
        pwrB2(:,i) = pwrB2(:,i)+tf(lowB2:hiB2).';
        pwrB3(:,i) = pwrB3(:,i)+tf(lowB3:hiB3).';
    end
elseif isnumeric(REMORA.ship_dt.settings.tfFullFile)
    % singular gain
    tf = REMORA.ship_dt.settings.tfFullFile;
    for i=1:size(pwr,2)
        pwrB1(:,i) = pwrB1(:,i)+tf;
        pwrB2(:,i) = pwrB2(:,i)+tf;
        pwrB3(:,i) = pwrB3(:,i)+tf;
    end
else
    error('Provide a transfer function file or a singular gain value')
end

avg_pwrB1 = nanmean(pwrB1,1);
avg_pwrB2 = nanmean(pwrB2,1);
avg_pwrB3 = nanmean(pwrB3,1);

% exclude gaps with missing data (it can vary). Outlier considered as value
% 50% less than the average dB
if REMORA.ship_dt.settings.dutyCycle
    outliersB1 = nanmean(avg_pwrB1) - (nanmean(avg_pwrB1)*0.5);
    outliersB2 = nanmean(avg_pwrB2) - (nanmean(avg_pwrB2)*0.5);
    outliersB3 = nanmean(avg_pwrB3) - (nanmean(avg_pwrB3)*0.5);
    avg_pwrB1(avg_pwrB1 <= outliersB1) = nan;
    avg_pwrB2(avg_pwrB2 <= outliersB2) = nan;
    avg_pwrB3(avg_pwrB3 <= outliersB3) = nan;
end

% fill missing data
fillavg_pwrB1 = fn_fillmiss(avg_pwrB1);
fillavg_pwrB3 = fn_fillmiss(avg_pwrB3);
fillavg_pwrB2 = fn_fillmiss(avg_pwrB2);
% -------------------------------------

% obtain reference value - to select relevant noise
% statelevels: get lower/upper levels by the mode of each region of a histogram
stateLevsB1 = statelevels(fillavg_pwrB1);
stateLevsB2 = statelevels(fillavg_pwrB2);
stateLevsB3 = statelevels(fillavg_pwrB3);

midRefB1 = mean(stateLevsB1);
midRefB2 = mean(stateLevsB2);
midRefB3 = mean(stateLevsB3);

% get crossing positions from reference level(midRef)
icrB1 = fn_crossing(fillavg_pwrB1,[],midRefB1);
icrB2 = fn_crossing(fillavg_pwrB2,[],midRefB2);
icrB3 = fn_crossing(fillavg_pwrB3,[],midRefB3);
% -------------------------------------

% select times on each band:
% start/end points of pwr above reference level
% band 1
sels = fillavg_pwrB1(icrB1) < midRefB1;
selsm = fillavg_pwrB1(icrB1) == midRefB1 & fillavg_pwrB1(icrB1-1) <= midRefB1 & fillavg_pwrB1(icrB1+1) > midRefB1;
sele = fillavg_pwrB1(icrB1) > midRefB1;
selem = fillavg_pwrB1(icrB1) == midRefB1 & fillavg_pwrB1(icrB1-1) > midRefB1 & fillavg_pwrB1(icrB1+1) <= midRefB1;
sels = sels|selsm;
sele = sele|selem;
sposB1 = icrB1(sels);
eposB1 = icrB1(sele);
% check for equal start and ends
if find(sele,1,'first') < find(sels,1,'first'); eposB1(1) = []; end
if find(sels,1,'last') > find(sele,1,'last'); sposB1(end) = []; end
if length(eposB1) < length(sposB1); sposB1(end) = []; end
if length(eposB1) > length(sposB1); eposB1(1) = []; end

% band 2
sels = fillavg_pwrB2(icrB2) < midRefB2;
selsm = fillavg_pwrB2(icrB2) == midRefB2 & fillavg_pwrB2(icrB2-1) <= midRefB2 & fillavg_pwrB2(icrB2+1) > midRefB2;
sele = fillavg_pwrB2(icrB2) > midRefB2;
selem = fillavg_pwrB2(icrB2) == midRefB2 & fillavg_pwrB2(icrB2-1) > midRefB2 & fillavg_pwrB2(icrB2+1) <= midRefB2;
sels = sels|selsm;
sele = sele|selem;
sposB2 = icrB2(sels);
eposB2 = icrB2(sele);
if find(sele,1,'first') < find(sels,1,'first'); eposB2(1) = []; end
if find(sels,1,'last') > find(sele,1,'last'); sposB2(end) = []; end
if length(eposB2) < length(sposB2); sposB2(end) = []; end
if length(eposB2) > length(sposB2); eposB2(1) = []; end

% band 3
sels = fillavg_pwrB3(icrB3) < midRefB3;
selsm = fillavg_pwrB3(icrB3) == midRefB3 & fillavg_pwrB3(icrB3-1) <= midRefB3 & fillavg_pwrB3(icrB3+1) > midRefB3;
sele = fillavg_pwrB3(icrB3) > midRefB3;
selem = fillavg_pwrB3(icrB3) == midRefB3 & fillavg_pwrB3(icrB3-1) > midRefB3 & fillavg_pwrB3(icrB3+1) <= midRefB3;
sels = sels|selsm;
sele = sele|selem;
sposB3 = icrB3(sels);
eposB3 = icrB3(sele);
if find(sele,1,'first') < find(sels,1,'first'); eposB3(1) = []; end
if find(sels,1,'last') > find(sele,1,'last'); sposB3(end) = []; end
if length(eposB3) < length(sposB3); sposB3(end) = []; end
if length(eposB3) > length(sposB3); eposB3(1) = []; end
% -------------------------------------

% make sure that we have the start and the end, if only one than exclude
% detection


% select times of close ships:
% close ship defined as pwr duration (above reference level) > seconds in the
% three different bands
thrClosebins = thrClose/tbin; % convert thr(s) in bins

% band 1
if ~isempty (sposB1) && ~isempty (eposB1)
    sB1 = sposB1(eposB1 - sposB1 > thrClosebins);
    eB1 = eposB1(eposB1 - sposB1 > thrClosebins);
    durB1 = (eB1-sB1)*tbin;
else
    sB1 = nan; eB1 = nan; durB1= nan;
end

% band 2
if ~isempty (sposB2) && ~isempty (eposB2)
    sB2 = sposB2(eposB2 - sposB2 > thrClosebins);
    eB2 = eposB2(eposB2 - sposB2 > thrClosebins);
    durB2 = (eB2-sB2)*tbin;
    centB2 = floor(mean([sB2;eB2]));
else
    sB2 = nan; eB2 = nan; durB2 = nan; centB2 = nan;
end

% band 3
if ~isempty (sposB3) && ~isempty (eposB3)
    sB3 = sposB3(eposB3 - sposB3 > thrClosebins);
    eB3 = eposB3(eposB3 - sposB3 > thrClosebins);
    durB3 = (eB3-sB3)*tbin;
    centB3 = floor(mean([sB3;eB3]));
else
    sB3 = nan; eB3 = nan; durB3 = nan; centB3 = nan;
end

sCloseShip = [];
eCloseShip = [];
for i = 1: length(sB1)
    % pwr duration above 200s in the 3 bands
    if ~isempty (centB2) && ~isempty (centB3) && ...
            sum((centB2 >= sB1(i) & centB2 <= eB1(i))) > 0  && ...
            sum((centB3 >= sB1(i) & centB3 <= eB1(i))) > 0
        
        seldurB2 = durB2(centB2 >= sB1(i) & centB2 <= eB1(i));
        seldurB3 = durB3(centB3 >= sB1(i) & centB3 <= eB1(i));
        
        % ship duration in 3rd band must be smaller than 2nd band
        % (if cetacean present, 3rd band has longer durations).
        if length(seldurB3) == length(seldurB2)
            if sum(seldurB3 <= seldurB2) && sum(seldurB2*2/3 <= durB1(i))
                s= sB1(i)-addtime;
                e = eB1(i)+addtime-1;
                if s<=0;s = 1;end
                if e>size(pwr,2);e = size(pwr,2);end
                sCloseShip = [sCloseShip; s];
                eCloseShip = [eCloseShip; e];
            end
        else
            continue
        end
    end
end
% -------------------------------------

% select distant ships:
% distant ship defined as pwr duration (above reference level) > seconds in
% the 1st and 2nd bands
thrDistantbins = thrDistant/tbin;

% band 1
if ~isempty (sposB1) && ~isempty (eposB1)
    sB1far = sposB1(eposB1 - sposB1 > thrDistantbins);
    eB1far = eposB1(eposB1 - sposB1 > thrDistantbins);
    durB1far = (eB1far-sB1far)*tbin;
else
    sB1far = []; eB1far = []; durB1far = [];
end

% band 2
if ~isempty (sposB2) && ~isempty (eposB2)
    sB2far = sposB2(eposB2 - sposB2 > thrDistantbins);
    eB2far = eposB2(eposB2 - sposB2 > thrDistantbins);
    durB2far = (eB2far-sB2far)*tbin;
    centB2far = floor(mean([sB2far;eB2far]));
else
    sB2far = []; eB1far = []; durB2far = []; centB2far = [];
end

sFarShip = [];
eFarShip = [];
for i = 1: length(sB1far)
    % pwr duration above 500s in the 1st and 2nd bands
    if ~isempty (centB2far) && ...
            sum((centB2far >= sB1far(i) & centB2far <= eB1far(i))) > 0
        
        seldurB2far = durB2far(centB2far >= sB1far(i) & centB2far <= eB1far(i));
        
        % ship duration in 2nd band must be smaller than 1st band
        % (if sperm whale present, 2nd band could have longer durations).
        if seldurB2far*2/3 <= durB1far(i)
            sfar = sB1far(i)-addtime;
            efar = eB1far(i)+addtime-1;
            if sfar<=0;sfar = 1;end
            if efar>size(pwr,2);efar = size(pwr,2);end
            sFarShip = [sFarShip; sfar];
            eFarShip = [eFarShip; efar];
        end
        
    end
end
% -------------------------------------

% populate close and distant detections
s = sort([sCloseShip; sFarShip]);
e = sort([eCloseShip; eFarShip]);
noise = [s,e];
noise = unique(noise,'rows');

if size(noise,1) > 1
    remove = find((noise(2:end,1) - noise(1:end-1,2)) < minPassage)';
    if ~isempty(remove)
        selStart = noise(:,1); selStart(remove+1) = [];
        selEnd = noise(:,2); selEnd(remove) = [];
        noise = [selStart, selEnd];
    end
end

RL = {};
if ~isempty(noise)
    % Received Levels (RL)
    % calculate received levels for the 1 min period around bin
    minbin = 30;
    RLsB1 = []; RLsB2 = []; RLsB3 = []; 
    
    for x = 1:size(pwr,2)
        CumPrev = 0;        % Cumulative time previous to segment of interest
        istart = x;
        while istart > 1 && CumPrev < minbin
            CumPrev = CumPrev + tbin;
            istart = istart - 1;
        end
        istop = x;
        CumPast = 0;  % Cumulative time past the segment of interest
        while istop < size(pwr,2) && CumPast < minbin
            CumPast = CumPast + tbin;
            istop = istop + 1;
        end
        
        RLB1 = 10*log10(sum(10.^(nanmean(pwrB1(:,istart:istop-1),2)./10)));
        RLB2 = 10*log10(sum(10.^(nanmean(pwrB2(:,istart:istop-1),2)./10)));
        RLB3 = 10*log10(sum(10.^(nanmean(pwrB3(:,istart:istop-1),2)./10)));
        
        %add to complete noise vector RL for this minute
        RLsB1 = [RLsB1; RLB1];
        RLsB2 = [RLsB2; RLB2];
        RLsB3 = [RLsB3; RLB3];
    end
    
    % store parameters into file
    if wIdx == 1
        RL.B1 = RLsB1;
        RL.B2 = RLsB2;
        RL.B3 = RLsB3;
    end
    
    RLB1thr = mean(RLsB1) + (mean(RLsB1) * thrRL); 
    RLB2thr = mean(RLsB2) + (mean(RLsB2) * thrRL); 
    RLB3thr = mean(RLsB3) + (mean(RLsB3) * thrRL); 
    labels =  repmat({'unknown'},size(noise,1),1);
    for m = 1:size(noise,1)
        RLs= [mean(RLsB1(noise(m,1):noise(m,2))), mean(RLsB2(noise(m,1):noise(m,2))),...
            mean(RLsB3(noise(m,1):noise(m,2)))];
        
        if RLs (1) > RLB1thr %&& RLs(2) > RLB2thr && RLs(3) > RLB3thr % %RLs(m,1)>80 & (RLs(m,2)<60 | RLs(m,3)<60)
            labels{m} = 'ship';
        else
            if (RLs(2)< 0 || RLs(3)<0)
                noise(m,:) = [0 0];
            elseif (RLs(1) - mean(RLs(2:3))) > 15
                labels{m} = 'ship';
            else
                labels{m} = 'ambient';
            end
        end
    end
    % delete unknown
    badidx = strcmp(labels,'unknown');
    noise(badidx,:) = [];
    labels(strcmp(labels(:), 'unknown'), :) = [];
else
    labels = int16.empty(0,1);
    noise = int16.empty(0,2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% plot window %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if wIdx
    
    red = [.85 .325 .098];
    blue = [0 .4470 .7410];
    gray = [0 0 0]+0.5;
    black = [0 0 0];
    green = [0.4660    0.6740    0.1880];%[0.9290    0.6940    0.1250];
    
    reltim = (1:length(fillavg_pwrB1))*tbin/3600; % in hours
    figure%('Position', [50, 70, 600, 700]);
    subplot(3,1,1);
    p1 = plot(reltim,fillavg_pwrB1,'Color',gray);
    hold on
    p2 = plot(reltim,avg_pwrB1,'Color',blue);
    p3 = plot(reltim,linspace(stateLevsB1(1),stateLevsB1(1),length(reltim)),'--','Color',red, 'LineWidth',.5);
         plot(reltim,linspace(stateLevsB1(2),stateLevsB1(2),length(reltim)),'--','Color',red, 'LineWidth',.5);
    p4 = plot(reltim,linspace(midRefB1,midRefB1,length(reltim)),'Color',red, 'LineWidth',2);
    p5 = plot(reltim(icrB1),linspace(midRefB1,midRefB1,length(reltim(icrB1))),'.','Color',black,'MarkerSize',7);
    if ~isempty(noise)
        p6 = plot(reltim(noise(:,1)),midRefB1,'.','Color',green,'MarkerSize',25);
             plot(reltim(noise(:,2)),midRefB1,'.','Color',green,'MarkerSize',25);
        add = 0;
        for i = 1: length(labels)
            add = add + 0.1;
        end
        if ~isempty (sCloseShip)
            p7 = plot(reltim(sCloseShip+addtime+1),midRefB1,'o','Color',black,'MarkerSize',6);
                 plot(reltim(eCloseShip-addtime-1),midRefB1,'o','Color',black,'MarkerSize',6);
        end
        if ~isempty (sFarShip)
            p9 = plot(reltim(sFarShip+addtime+1),midRefB1,'x','Color',black,'MarkerSize',6);
            	 plot(reltim(eFarShip-addtime-1),midRefB1,'x','Color',black,'MarkerSize',6);
        end
    end
    
    if isempty(noise)
        legend([p1,p2,p3,p4,p5],{'Interpolated','APSD','Levels',...
            'Threshold','Crossing','Passage','Close det.'},...
            'Location','best')
    elseif ~ isempty(sFarShip) && ~isempty(sCloseShip)
        legend([p1,p2,p3,p4,p5,p6(1),p7(1),p9(1)],{'Interpolated','APSD','Levels',...
            'Threshold','Crossing','Passage','Close det.','Far det.'},...
            'Location','best')
    elseif ~isempty(sCloseShip) && isempty(sFarShip)
        legend([p1,p2,p3,p4,p5,p6(1),p7(1)],{'Interpolated','APSD','Levels',...
            'Threshold','Crossing','Passage','Close det.'},...
            'Location','best')
    elseif isempty(sCloseShip) && ~isempty(sFarShip)
        legend([p1,p2,p3,p4,p5,p6(1),p9(1)],{'Interpolated','APSD','Levels',...
            'Threshold','Crossing','Passage','Close det.'},...
            'Location','best')
    end
    title(sprintf('Low band (%d-%d Hz)',f(lowB1),f(hiB1)))
    set(gca, 'FontName', 'Times New Roman','FontSize',10)
    
    subplot(3,1,2)
    plot(reltim,fillavg_pwrB2,'Color',gray)
    hold on
    plot(reltim,avg_pwrB2,'Color',blue)
    title(sprintf('Medium band (%d-%d Hz)',f(lowB2),f(hiB2)))
    plot(reltim,linspace(stateLevsB2(1),stateLevsB2(1),length(reltim)),'--','Color',red, 'LineWidth',.5)
    plot(reltim,linspace(stateLevsB2(2),stateLevsB2(2),length(reltim)),'--','Color',red, 'LineWidth',.5)
    plot(reltim,linspace(midRefB2,midRefB2,length(reltim)),'Color',red, 'LineWidth',2)
    plot(reltim(icrB2),linspace(midRefB2,midRefB2,length(reltim(icrB2))),'.','Color',black,'MarkerSize',7)
    if ~isempty(sCloseShip)
        plot(reltim(sB2),midRefB2,'o','Color',black,'MarkerSize',6);
        plot(reltim(eB2),midRefB2,'o','Color',black,'MarkerSize',6);
    end
    if ~isempty(sFarShip)
        plot(reltim(sB2far),midRefB2,'x','Color',black,'MarkerSize',6);
        plot(reltim(sB2far),midRefB2,'x','Color',black,'MarkerSize',6);
    end
    ylabel('Averaged PSD (dB re 1 \muPa^2/Hz)')
    set(gca, 'FontName', 'Times New Roman','FontSize',10)
    
    subplot(3,1,3)
    plot(reltim,fillavg_pwrB3,'Color',gray)
    hold on
    plot(reltim,avg_pwrB3,'Color',blue)
    title(sprintf('High band (%d-%d Hz)',f(lowB3),f(hiB3)))
    plot(reltim,linspace(stateLevsB3(1),stateLevsB3(1),length(reltim)),'--','Color',red, 'LineWidth',.5)
    plot(reltim,linspace(stateLevsB3(2),stateLevsB3(2),length(reltim)),'--','Color',red, 'LineWidth',.5)
    plot(reltim,linspace(midRefB3,midRefB3,length(reltim)),'Color',red, 'LineWidth',2)
    plot(reltim(icrB3),linspace(midRefB3,midRefB3,length(reltim(icrB3))),'.','Color',black,'MarkerSize',7)
    if ~isempty(sCloseShip)
        plot(reltim(sB3),midRefB3,'o','Color',black,'MarkerSize',6);
        plot(reltim(eB3),midRefB3,'o','Color',black,'MarkerSize',6);
    end
    xlabel('Time (Hours)')
    set(gca, 'FontName', 'Times New Roman','FontSize',10)
    hold off
    
end







