function phitter_v02(mode,filePath,manualFit)
% First attempt at reliably fitting the line profiles from the PhC cavities
% Version 0.2

%% INPUT
%   - mode [int32]: 0-2
%                  -1 | Test mode
%                   0 | File mode: fit one specific line profile, either file specified by 'filePath' or one specified
%                       by user query
%                   1 | Directory mode: fit all .csv-files in directory
%                   2 | List mode: fit all files specified by the .csv-list
%                       specified by 'filePath'
%   - filePath [string]: directory/file to fit
%   - manualFit
%% OUTPUT
%% NOTES
%   - Overmodulated measurements will throw an error.

%% HEADER
%% Available methods to estimate the initial guess:
%   - 'file'        | not implemented
%   - 'peakfind'    |
guessMethod = 'findpeaks';
aguess = @(x) x(1,2);
bguess = @(x) sqrt(x);
phiguess = -1.5;

%% Highest order sidebands to include
maxsbOrder = 1;

% Function pause time in seconds
ptime = 0;


%% Standard directories and naming schemes
% Standard input directory
stdDir = '\\carafe\Nanophotonics\Andrew\Lab\GUI\Python\jupyter-notebooks\release20180724\L3Eight\fine';

% Standard output directory & file name
outDir = 'C:\Users\sns45\Desktop\tempdata\analysis_0818';
outName = 'PNCanalysis';

%% Fit functions
% Ensure that linewidth is notated as 'gamma' and resonance frequency as
% 'omega0' in order to prevent issues with functions downstream

% Fano resonance expression / spectral expression
%% Andrew, 2018
varNames = {'a(1)','alpha',[0 0];...
    'a(2)','beta',[0 0];...
    'a(3)','gamma',[0 0];...
    'a(4)','omega0',[0 0];...
    'a(5)','phi',[0 0]};
% Raw & ugly
lorh = @(a,x)...
    a(1)^2+a(2)^2*a(3)^2./((x-a(4)).^2+a(3)^2)...
    +a(1)*a(2)*exp(1i*a(5))*a(3)./((x-a(4))-1i*a(3))...
    +a(1)*a(2)*exp(-1i*a(5))*a(3)./((x-a(4))+1i*a(3));

% Arithmetically different
% lorh = @(a,x)...
%     a(1)^2+a(3)^2/((x-a(4)).^2+a(3)^2)*...
%     (a(2)^2+2*a(1)*a(2)*a(3)*((x-a(4))/a(3)*cos(a(5))-sin(a(5))));

%% Galli, Appl. Phys. 2009
% varNames = {'a(1)','alpha',[0 0];...
%             'a(2)','beta',[0 0];...
%             'a(3)','gamma',[0 0];...
%             'a(4)','omega0',[0 0];...
%             'a(5)','q',[0 0]};
% lorh = @(a,x)...
%     a(1)+a(2)*(a(5)+2*(x-(a(4)))/a(3)).^2/(1+2*((x-a(4))/a(3)).^2);

%% Fano resonance expression / detuning expression
lorhd = @(a,x)    a(1)^2+a(2)^2*a(3)^2./(x.^2+a(3)^2)...
    +a(1)*a(2)*exp(1i*a(4))*a(3)./(x-1i*a(3))...
    +a(1)*a(2)*exp(-1i*a(4))*a(3)./(x+1i*a(3));
% lorhd = @(a,x)...
%     a(1)^2+a(2)^2*a(3)^2./(x.^2+a(3)^2)...
%     +2*a(1)*a(2)*(x*a(3)*cos(a(4))-a(3)^2*sin(a(4)))/(x.^2+a(3)^2);

%% Spectral piezo-behaviour
piezoh = @(a,x) (a(1)*x.^2+a(2)*x+a(3));

%% SECTION I: Opening the files
if ~exist('manualFit','var')
    manualFit = 1;
end

if manualFit
    namId = '_man';
else
    namId = '_auto';
end
outName = [outName,namId];

% fields 'alpha' through 'phi' are 2-element vesctors, with i.e. alpha(1)
% containing the guess value for the alpha parameter and alpha(2) the error
% value.
data = struct('fileName','','sbFreq','','lsb_err',-99,'rsb_err',-99,...
    'stepWave','','centerWave',1550,'fineTune','','fineWave','','int_step','','int_fine','','int_wsb','',...
    'Q',[0 0],...
    'cavity','unknown','relDate','','row',-99.9,'col',-99.9,'measDate','','measTime','','rem','');
for idx = 1:size(varNames,1)
    data.(varNames{idx,2}) = varNames{idx,3};
end

%% 2.1: Open file(s) and write names to cell array 'fileList'
if ~exist('mode','var')
    mode = 0;
end

fileList = {};
switch mode
    case 0
        if ~exist('filePath','var')
            oldFolder = cd(stdDir);
            [fileName,filePath] = uigetfile('*.csv','Select file...');
            cd(oldFolder);
        else
            [fileName,ending] = getFileName(filePath);
            fileName = [fileName,ending];
            filePath = erase(filePath,['\',fileName]);
        end
        fileList{1} = fileName;
    case 1  % directory
        try
            oldFolder = cd(filePath);
            
        catch
            %error('phitter:DirectoryNotFound','Could not open desired directory.');
            filePath = uigetdir(stdDir);
            oldFolder = cd(filePath);
        end
        dirList = struct2cell(dir);
        dirList = dirList(1,:);
        counter = 1;
        for idx = 1:length(dirList)
            if strsearch(dirList{idx},'.csv')
                fileList{counter} = dirList{idx};
                counter = counter+1;
            end
        end
        cd(oldFolder);
    case 2  % list of files
    case -1 % test case
        data(1).fileName = 'testFile.txt';
        data(1).cavityType = 'L3eight';
        data(1).wave = linspace(1450,1550,100);
        data(1).int = [0.0133413793103448,0.0138142357403918,0.0143113741319871,0.0148343645396568,0.0153848933310048,0.0159647720135397,0.0165759465742090,0.0172205073034041,0.0179006990526371,0.0186189318453567,0.0193777917215168,0.0201800516462234,0.0210286822481356,0.0219268620707654,0.0228779869151299,0.0238856777202663,0.0249537862628691,0.0260863977518314,0.0272878291398479,0.0285626216639315,0.0299155257508178,0.0313514759733952,0.0328755532139093,0.0344929305759901,0.0362087988947414,0.0380282669380926,0.0399562306071229,0.0419972046889089,0.0441551100914207,0.0464330091469796,0.0488327817270713,0.0513547358673006,0.0539971487490871,0.0567557377049178,0.0596230669471289,0.0625879044978332,0.0656345557122705,0.0687422148862830,0.0718843941330179,0.0750285074359437,0.0781357046590226,0.0811610609748216,0.0840542260590245,0.0867606184807386,0.0892232091690542,0.0913848722986248,0.0931911969131069,0.0945935599688670,0.0955521798676101,0.0960388207703485,0.0960388207703485,0.0955521798676101,0.0945935599688670,0.0931911969131069,0.0913848722986248,0.0892232091690542,0.0867606184807386,0.0840542260590245,0.0811610609748216,0.0781357046590226,0.0750285074359437,0.0718843941330179,0.0687422148862830,0.0656345557122705,0.0625879044978332,0.0596230669471289,0.0567557377049178,0.0539971487490871,0.0513547358673006,0.0488327817270713,0.0464330091469796,0.0441551100914207,0.0419972046889089,0.0399562306071229,0.0380282669380926,0.0362087988947414,0.0344929305759901,0.0328755532139093,0.0313514759733952,0.0299155257508181,0.0285626216639315,0.0272878291398479,0.0260863977518314,0.0249537862628691,0.0238856777202663,0.0228779869151299,0.0219268620707654,0.0210286822481356,0.0201800516462234,0.0193777917215168,0.0186189318453567,0.0179006990526371,0.0172205073034041,0.0165759465742090,0.0159647720135397,0.0153848933310049,0.0148343645396568,0.0143113741319871,0.0138142357403918,0.0133413793103448];
        
end

%% 2.2: Fill 'data' with values read through [readtable]
oldFolder = cd(filePath);
counter = 1;

for idx = 1:length(fileList)
    % Disable variable modification warning because it's hella annoying.
    warning('off','MATLAB:table:ModifiedAndSavedVarnames');
    
    try
        dtab = readtable(fileList{idx});
    catch
    end
    
    if ~isempty(dtab)
        data(counter).fileName = fileList{idx};
        argout = decodeFileName(fileList{idx},'PNC');
        fnam = fieldnames(argout);
        % Merge data structures
        for jdx = 1:length(fnam)
            if ~strcmp(fnam{jdx},'indicator')
                data(counter).(fnam{jdx}) = argout.(fnam{jdx});
            end
        end
        
        if sum(contains(dtab.Properties.VariableNames,{'Var1' 'fine_tune' 'without_sidebands' 'wavelength'})) >= 4
            %% Piezo-scanned
            % Assign data
            data(counter).fineTune = dtab.fine_tune;
            data(counter).int_fine = dtab.without_sidebands;
            data(counter).centerWave = mean(dtab.wavelength);
            for jdx = 1:length(dtab.Properties.VariableNames)
                if strsearch(dtab.Properties.VariableNames{jdx},'with_') && strsearch(dtab.Properties.VariableNames{jdx},'_sidebands')
                    data(counter).int_wsb = dtab{:,jdx};
                    data(counter).sbFreq = textscan(dtab.Properties.VariableNames{jdx},'with_%fGHZ_sidebands');
                    data(counter).sbFreq = data(idx).sbFreq{1};
                end
            end
        elseif sum(contains(dtab.Properties.VariableNames,{'wavelength' 'voltage1' 'voltage2'})) >= 2
            %% Grating-scanned
            data(counter).stepWave = dtab.wavelength;
            data(counter).int_step = dtab.voltage1;
        else
            error('DataStructError:WrongInput','Unable to identify input .csv file');
        end
        
        counter = counter+1;
        clear('dtab');
    end
end
cd(oldFolder);

%% SECTION III: Fitting
% Only relevant for piezo-scanned spectra.

for idx = 1:length(data)
    % Initialize axis 1
    tlFig = figure('Name',['Main window: ',data(idx).fileName],...
        'Units','normalized','OuterPosition',[0 0.5 0.5 0.5]);
    ax1 = axes(tlFig,'Position',[0.1 0.1 0.8 0.8],'Box','on','YScale','log');
    ax1.XLabel.String = 'Piezo Position / a.u.';
    ax1.YLabel.String = 'Signal';
    
    if ~isempty(data(idx).int_wsb)        
        %% 3.1: Linearize x-scale (only relevant for piezo-scanned spectra)
        % Find peaks of scan with RF modulation of incoming light
        scatter(ax1,data(idx).fineTune,data(idx).int_wsb,...
            'Marker','square','SizeData',10,'MarkerEdgeColor','none','MarkerFaceColor',[0 0 0]);
        
        pkidx = 2*maxsbOrder + 1;
        try
            [~,peakLoc,peakWid,peakVal] = findpeaks(abs(data(idx).int_wsb),data(idx).fineTune,'SortStr','descend',...
                'MinPeakDistance',30,'MinPeakProminence',0.02*max(data(idx).int_wsb));
        catch
            peakVal = [max(data(idx).int_wsb);(0.1*max(data(idx).int_wsb))*ones(pkidx-1,1)];
            peakLoc = [0 -40 50 -70 80];
            peakWid = [20 10 10 10 10];
        end
        
        pkidx = min(pkidx,length(peakVal));
        
        peakMat_wsb = [peakVal(1:pkidx),peakLoc(1:pkidx),peakWid(1:pkidx)];
        
        tdat = [data(idx).fineTune,data(idx).int_wsb];
        
        % bandwidths in piezo-voltage space
        lsbBW = 40; %bandwidth of left sideband
        rsbBW = 40; %bandwidth of right sideband
        carBW = 40; %bandwidth of carrier
        
        % frequency difference: Assumes sub-100% modulation!
        tmat = (-maxsbOrder*data(idx).sbFreq:data(idx).sbFreq:maxsbOrder*data(idx).sbFreq);
        % Symmetrically get rid of all
        divide = peakMat_wsb(peakMat_wsb(:,1)==max(peakMat_wsb(:,1)),2);
        while length(tmat) > pkidx
            if sum(peakMat_wsb(:,2)>divide) > sum(peakMat_wsb(:,2)<divide)
                tmat(length(tmat)) = [];
            elseif sum(peakMat_wsb(:,2)>divide) == sum(peakMat_wsb(:,2)<divide)
                tmat(1) = [];
                tmat(length(tmat)) = [];
            else
                tmat(1) = [];
            end
        end
        tmat(tmat==0) = min(tmat);
        tmat = sort(tmat,'ascend');
        tmat(1) = 0;
        fitMat = [cell(pkidx,6),num2cell(tmat)'];
        
        
        %% carrier
        if rem(pkidx,2) > 0 % use mean for odd numbers of peaks
            carc = peakMat_wsb(peakMat_wsb(:,2)==median(peakMat_wsb(:,2)),2);
        else % use largest peak for even numbers of peaks (one sideband suppressed)
            carc = peakMat_wsb(peakMat_wsb(:,1)==max(peakMat_wsb(:,1)),2);
        end
        if manualFit
            prompt = 'Enter carrier position:';
            dlg_title = 'Locating bands';
            num_lines = 1;
            defaultans = {num2str(carc)};
            carc = inputdlg(prompt,dlg_title,num_lines,defaultans);
            carc = str2double(carc{1});
        end
        fitMat{1,1} = tdat(abs(tdat(:,1)-carc)<=carBW/2,:);             % data
        fitMat{1,2} = aguess(tdat);                                     % alpha
        fitMat{1,3} = bguess(peakMat_wsb(peakMat_wsb(:,2)==carc,1));    % beta
        fitMat{1,4} = peakMat_wsb(peakMat_wsb(:,2)==carc,3);            % gamma
        fitMat{1,5} = peakMat_wsb(peakMat_wsb(:,2)==carc,2);            % w0
        fitMat{1,6} = phiguess;                                         % phi
        
        peakMat_wsb(peakMat_wsb(:,2)==carc,:) = [];
        
        for jdx = 1:pkidx
            %% sidebands
            counter = 2;
            while size(peakMat_wsb,1) > 0
                sbc = peakMat_wsb(peakMat_wsb(:,2)==min(peakMat_wsb(:,2)),2);
                if sbc < carc
                    bw = lsbBW;
                    band = 'left';
                else
                    bw = rsbBW;
                    band = 'right';
                end
                if manualFit
                    prompt = ['Enter ',band,' sideband position:'];
                    dlg_title = 'Locate bands';
                    num_lines = 1;
                    defaultans = {num2str(sbc)};
                    sbc = inputdlg(prompt,dlg_title,num_lines,defaultans);
                    sbc = str2double(sbc{1});
                end
                fitMat{counter,1} = tdat(abs(tdat(:,1)-sbc)<=bw/2,:);
                fitMat{counter,2} = aguess(tdat);
                fitMat{counter,3} = bguess(peakMat_wsb(peakMat_wsb(:,2)==sbc,1));
                fitMat{counter,4} = peakMat_wsb(peakMat_wsb(:,2)==sbc,3);
                fitMat{counter,5} = peakMat_wsb(peakMat_wsb(:,2)==sbc,2);
                fitMat{counter,6} = fitMat{1,6};
                
                counter = counter+1;
                peakMat_wsb(peakMat_wsb(:,2)==min(peakMat_wsb(:,2)),:) = [];
            end
        end
        %% Initialize piezo linearization figure
        trFig = figure('Name','Piezo Linearization',...
            'Units','normalized','OuterPosition',[0.5 0.5 0.5 0.5]);
        ax2 = axes(trFig,'Position',[0.1 0.1 0.8 0.8],'Box','on','YScale','lin',...
            'XLim',[-100 100],'XLimMode','manual',...
            'YLim',[-1.1*maxsbOrder*data(idx).sbFreq 1.1*maxsbOrder*data(idx).sbFreq],'YLimMode','manual');
        ax2.XLabel.String = 'Piezo Position / a.u.';
        ax2.YLabel.String = 'Frequency Offset / GHz';
        
        % Update axis 1
        hold(ax1,'all');
        hold(ax2,'all');
        
        %% Fit carrier and sidebands using the Fano-resonance model
        for kdx = 1:pkidx
            
            % Fit each region of the graph individually with the PCN
            % response function
            if manualFit
                %% Using the window to manually adjust fit parameters
                input = struct('varNames','','startValues','','outAxes','','stdBnds','');
                input.varNames = varNames(:,2)';
                input.startValues = fitMat(kdx,2:6);
                input.data = fitMat{kdx,1};
                input.axes = ax1;
                input.fitfun = lorh;
                
                % For non-Fano
                input.stdBnds = {[1e-4,1],[0.1,5],[1e-2,10],[min(tdat(:,1)),max(tdat(:,1))],[-5,5]};
                
                argout = phitWindow(input);
                
                pvec = argout.endParams(1:length(input.varNames));
                %confbnd = argout.confbnd;
            else
                pvec = ppfit(lorh,fitMat{kdx,1},cell2mat(fitMat(kdx,2:6)));
                pvec = pvec';
            end
            
            fitMat(kdx,2:6) = num2cell(pvec);
            
            plotax1 = @(fitMat,pvec,num) ...
                plot(ax1,fitMat{kdx,1}(:,1),lorh(pvec,fitMat{kdx,1}(:,1)),'Color',RWTHColor(kdx),'LineWidth',2.5);
            plotax1(fitMat,pvec,kdx);
            %ax1.YScale = 'log';
            scatter(ax2,pvec(4),fitMat{kdx,7},...
                'Marker','^','SizeData',40,'MarkerEdgeColor','none','MarkerFaceColor',RWTHColor(kdx));
            pause(ptime);
        end
        %% Fit piezo curve
        pdat = cell2mat([fitMat(:,5),fitMat(:,7)]);
        
        xFit = linspace(-100,100,801);
        quadGuess = [0.0002,0.0615,-1.0562];
        
        % Fitting the piezo curve.
        pPara = ppfit(piezoh,pdat,quadGuess);
        
        %% Use calibration to rescale axis
        % Also converts x to nm
        xscaled = piezoh(pPara,data(idx).fineTune);
        xscaled_f = xscaled;
        xscaled = xscaled+nrgcon(data(idx).centerWave,'nm','GHz');
        data(idx).fineWave = nrgcon(xscaled,'GHz','THz');
        
        % Update axis 1
        hold(ax1,'off');
        scatter(ax1,data(idx).fineWave,data(idx).int_wsb,...
            'Marker','square','SizeData',10,'MarkerEdgeColor','none','MarkerFaceColor',[0 0 0]);
        ax1.XLabel.String = 'Frequency / THz';
        ax1.YScale = 'log';
        hold(ax1,'all');
        
        % Update axis 2
        plot(ax2,xFit,piezoh(pPara,xFit),'Color',RWTHColor(10),'LineWidth',1.5);
        
        % Initialize axis 3
        blFig = figure('Name','Linearized data',...
            'Units','normalized','OuterPosition',[0 0.1 0.5 0.4]);
        ax3 = axes(blFig,'Position',[0.1 0.1 0.8 0.8],'Box','on','YScale','lin',...
            'XLim',[-1.1*maxsbOrder*data(idx).sbFreq 1.1*maxsbOrder*data(idx).sbFreq],'XLimMode','manual');
        ax3.XLabel.String = ax2.YLabel.String;
        ax3.YLabel.String = ax1.YLabel.String;
        hold(ax3,'on');
        
        scatter(ax3,xscaled_f,data(idx).int_wsb,...
            'Marker','square','SizeData',10,'MarkerEdgeColor','none','MarkerFaceColor',[0 0 0]);
        try
            [peakVal,peakLoc,~,~] = findpeaks(data(idx).int_wsb,xscaled_f,'SortStr','descend',...
                'MinPeakHeight',0.05*max(data(idx).int_wsb));
        catch
            peakVal = [1;0.1;0.1];
            peakLoc = [0;-4;4];
        end
        peakMat = [peakVal,peakLoc];
        peakMat(peakMat(:,1)==max(peakMat(:,1)),:) = [];
        peakMat = peakMat(1:2,:);
        peakMat = sortrows(peakMat,2,'ascend');
        data(idx).lsb_err = abs(peakMat(1,2)+data(idx).sbFreq);
        data(idx).rsb_err = abs(peakMat(2,2)-data(idx).sbFreq);
    else
        data(idx).lsb_err = 0;
        data(idx).rsb_err = 0;
        data(idx).sbFreq = 0;
        hold(ax1,'all');
        ax1.YScale = 'log';
        plot(ax1,data(idx).stepWave,data(idx).int_step,...
            'Color',RWTHColor(3),'LineWidth',1.5);
    end
    
    %% 3.2: Define guess parameters
    switch guessMethod
        case 'findpeaks'
            %% Only supported guess mode currently
            if ~isempty(data(idx).int_wsb)
                wav = 'fineWave';
                int = 'int_fine';
            else
                wav = 'stepWave';
                int = 'int_step';
            end
            tdat = [data(idx).(wav),data(idx).(int)];
            tdat_asc = sortrows(tdat,'ascend');
            % Find peaks of scan without RF modulation
            try
                [peakVal,peakLoc,peakWid,~] = findpeaks(tdat_asc(:,2),tdat_asc(:,1),'SortStr','descend',...
                    'MinPeakHeight',0.2*max(tdat_asc(:,2)));
            catch
                peakVal = 1;
                peakLoc = mean(tdat_asc(:,1));
                peakWid = 0.01;
            end
            
            % Assign as initial values for fit.
            kdx=1;
            data(idx).(varNames{kdx,2}) = [aguess(tdat) 0];kdx=kdx+1;
            data(idx).(varNames{kdx,2}) = [bguess(peakVal(1)) 0];kdx=kdx+1;
            data(idx).(varNames{kdx,2}) = [peakWid(1) 0];kdx=kdx+1;
            data(idx).(varNames{kdx,2}) = [peakLoc(1) 0];kdx=kdx+1;
            data(idx).(varNames{kdx,2}) = [phiguess 0];
        otherwise
    end
    
    %% 3.3: Data conditioning
    % Selects data within n peakwidths
    nwidth=50;
    tdat_f = tdat(abs(tdat(:,1)-data(idx).omega0(1))<=nwidth*data(idx).gamma(1),:);
    % detuned
    %tdat_f(:,1) = tdat_f(:,1)-data(idx).omega0(1);
    
    %% 3.4: Fitting
    startParams = zeros(size(varNames,1),1)';
    for jdx = 1:size(varNames,1)
        startParams(jdx) = data(idx).(varNames{jdx,2})(1);
    end
    
    % Update axis 1
    scatter(ax1,tdat(:,1),tdat(:,2),...
        'Marker','square','SizeData',10,'MarkerEdgeColor','none','MarkerFaceColor',RWTHColor(5));
    
    if manualFit
        %% Using the window to manually adjust fit parameters
        input = struct('varNames','','startValues','','outAxes','','stdBnds','');
        input.varNames = varNames(:,2)';
        input.startValues = num2cell(startParams);
        input.data = tdat;
        input.axes = ax1;
        input.fitfun = lorh;
        
        % For non-Fano
        input.stdBnds = {[1e-4,1],[0.1,5],[1e-7,1e-1],[min(tdat(:,1)),max(tdat(:,1))],[-10,10]};
        
        argout = phitWindow(input);
        
        endParams = argout.endParams(1:length(startParams));
        confbnd = argout.confbnd;
    else
        %% Just let the fit algorithm work it out
        [endParams,confbnd] = ppfit(lorh,tdat_f,startParams);
        
        % Update axis 1
        plot(ax1,tdat(:,1),lorh(endParams,tdat(:,1)),...
            'Color',RWTHColor(3),'LineWidth',1.5);
        line(ax1,'XData',[min(tdat_f(:,1)) min(tdat_f(:,1))],'YData',ax1.YLim);
        line(ax1,'XData',[max(tdat_f(:,1)) max(tdat_f(:,1))],'YData',ax1.YLim);
    end
    % Assign fit parameters to 'data'
    pnam = varNames(:,2)';
    for jdx = 1:length(endParams)
        if jdx == 4 && length(endParams) == 4
            data(idx).(pnam{jdx+1})(1) = endParams(jdx);
            data(idx).(pnam{jdx+1})(2) = confbnd(jdx);
        else
            data(idx).(pnam{jdx})(1) = endParams(jdx);
            data(idx).(pnam{jdx})(2) = confbnd(jdx);
        end
    end
    
    %% 3.6: Calculate Q factor
    % factor
    data(idx).Q = [data(idx).omega0(1)/(2*data(idx).gamma(1)) 0];
    % error
    ome = data(idx).omega0(1);
    uome = data(idx).omega0(2);
    wid = data(idx).gamma(1);
    uwid = data(idx).gamma(2);
    
    data(idx).Q(2) = 1/4*sqrt((ome*uwid/wid^2)^2+(uome/wid)^2);
    tstr = {['Q: ',num2str(data(idx).Q(1),'%10.1e'),'$\pm$',num2str(data(idx).Q(2),'%10.1e')],...
        ['$\lambda_0$: ',num2str(data(idx).omega0(1)),'$\pm$',num2str(data(idx).omega0(2),'%10.2e'),' nm']};
    annotation(tlFig,'textbox',[0.15 0.8 0.2 0.1],'String',tstr,'FitBoxToText','on','interpreter','latex');
    
    %% 3.7: Save to Excel- (and eventually .mat-file)
    % Filenames
    exnam = [outName,'.xlsx'];
    shtnam = data(idx).cavity;
    matnam = [outName,data(idx).cavity,'.mat'];
    
    % Create table
    % Selection of fields to copy into new structure
    nstrucnam = {'relDate','row','col',...
        varNames{:,2},'Q',...
        'sbFreq','lsb_err','rsb_err','measDate','measTime','rem','fileName','cavity'};
    nstruc = struct;
    %% Copy existing fields from data
    for jdx = 1:length(nstrucnam)
        if isnumeric(data(idx).(nstrucnam{jdx}))
            if length(data(idx).(nstrucnam{jdx})) > 1
                nstruc.(nstrucnam{jdx}) = data(idx).(nstrucnam{jdx})(1);
                nstruc.([nstrucnam{jdx},'_err']) = data(idx).(nstrucnam{jdx})(2);
            else
                nstruc.(nstrucnam{jdx}) = data(idx).(nstrucnam{jdx});
            end
        elseif ischar(data(idx).(nstrucnam{jdx}))
            nstruc.(nstrucnam{jdx}) = data(idx).(nstrucnam{jdx});
        end
    end
    %% Add fields
    nstruc.fitDate = date;
    if ~isempty(data(idx).int_wsb)
        scanType = 'fine';
    else
        scanType = 'step';
    end
    nstruc.scanType = scanType;
    
    ntab = struct2table(nstruc);
    
    % Open existing files
    oldFolder = cd(outDir);
    if exist(exnam,'file')
        [~,prsht] = xlsfinfo(exnam);
        if sum(strcmp(shtnam,prsht))
            otab = readtable(exnam,'Sheet',shtnam);
            pfac = size(otab,1);
            iopt = detectImportOptions(exnam,'Sheet',shtnam);
            rng = iopt.DataRange;
            rng = regexpi(rng,'(?<let>[a-z]+)(?<num>\d+)','names');
            writetable(ntab,exnam,'Sheet',shtnam,'Range',[rng.let,num2str(str2double(rng.num)+pfac)],...
                'WriteVariableNames',0);
        else
            writetable(ntab,exnam,'Sheet',shtnam);
        end
    else
        writetable(ntab,exnam,'Sheet',shtnam);
        delExcessSheetsExcel(exnam,outDir)
    end
    
    %% Save figures
    if ~exist(data(idx).cavity,'dir')
        mkdir(data(idx).cavity);
    end
    cd(data(idx).cavity);
    tnam = [getFileName(data(idx).fileName),namId];
    fnam = {['all_',tnam] ['piezo_',tnam] ['lin_',tnam]};
    figNames = {'tlFig' 'trFig' 'blFig'};
    fhand = {};
    for jdx = 1:length(figNames)
        if exist(figNames{jdx},'var')
            fhand = [fhand,{eval(figNames{jdx})}];
        end
    end
    for jdx = 1:length(fhand)
        saveas(fhand{jdx},[fnam{jdx},'.fig']);
        fhand{jdx}.Color = 'white';
        export_fig(fhand{jdx},[fnam{jdx},'.png'],'-m2');
        close(fhand{jdx});
    end
    
    cd(oldFolder);
    
    %% Close figures and clean up workspace
    %pause(3);
end


%% REPOSITORY




%  hWait = waitbar(0,sprintf('Fit %d out of %d.',counter,totalFits),'Name','Fitting spectrum...',...
%       'units','normalized','Position',[2.1 0.5 0.3 0.1]);
%  waitbar(counter/totalFits,hWait,sprintf('Fit %d out of %d.',counter,totalFits));
%  delete(hWait);

% pbaspect(tAx1,[1 1 1]);
%
% tPos = tAx1.Position;
% tPos(2) = tPos(2)-.11;
% tPos(4) = 1e-12;
% tAx2=axes('Position',tPos);
% set(tAx2,'Units','normalized');
% set(tAx2,'Color','none');
%
% xL = [620 725];
% %xL = [375 550];
% set(tAx1,'XLim',xL);
% xL = [nrgcon(xL(2),'nm','eV') nrgcon(xL(1),'nm','eV')];
% set(tAx2,'XLim',xL);
% xlabel(tAx2,'Energy / eV','FontSize',35);
% set(tAx2,'FontName','FrankRuehl','FontSize',30,'LineWidth',2,'Xdir','reverse');




