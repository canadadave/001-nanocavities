function phitter_0.2(mode,dir)
% First attempt at reliably fitting the line profiles from the PhC cavities
% Version 0.1

%% INPUT
%   - mode [int32]: 0-2
%                   0 | File mode: fit one specific line profile, either file specified by 'dir' or one specified
%                       by user query
%                   1 | Directory mode: fit all .csv-files in directory
%                   2 | List mode: fit all files specified by the .csv-list
%                       specified by 'dir'
%   - dir [string]: directory/file to fit
%% OUTPUT
%% NOTES
%   - DISCONTINUED, use version 0.2

%% HEADER
guessFileName = 'space1.txt';
guessMethod = 'file';

%% Section 1: Opening the files
switch mode
    case 0
    case 1
    case 2
end

%% Section 2: Definition of parameter space


%% Section 3: Fitting

% Temporary values for x- and y-data
xdata = linspace(1450,1550,100);
ydata = [0.0133413793103448,0.0138142357403918,0.0143113741319871,0.0148343645396568,0.0153848933310048,0.0159647720135397,0.0165759465742090,0.0172205073034041,0.0179006990526371,0.0186189318453567,0.0193777917215168,0.0201800516462234,0.0210286822481356,0.0219268620707654,0.0228779869151299,0.0238856777202663,0.0249537862628691,0.0260863977518314,0.0272878291398479,0.0285626216639315,0.0299155257508178,0.0313514759733952,0.0328755532139093,0.0344929305759901,0.0362087988947414,0.0380282669380926,0.0399562306071229,0.0419972046889089,0.0441551100914207,0.0464330091469796,0.0488327817270713,0.0513547358673006,0.0539971487490871,0.0567557377049178,0.0596230669471289,0.0625879044978332,0.0656345557122705,0.0687422148862830,0.0718843941330179,0.0750285074359437,0.0781357046590226,0.0811610609748216,0.0840542260590245,0.0867606184807386,0.0892232091690542,0.0913848722986248,0.0931911969131069,0.0945935599688670,0.0955521798676101,0.0960388207703485,0.0960388207703485,0.0955521798676101,0.0945935599688670,0.0931911969131069,0.0913848722986248,0.0892232091690542,0.0867606184807386,0.0840542260590245,0.0811610609748216,0.0781357046590226,0.0750285074359437,0.0718843941330179,0.0687422148862830,0.0656345557122705,0.0625879044978332,0.0596230669471289,0.0567557377049178,0.0539971487490871,0.0513547358673006,0.0488327817270713,0.0464330091469796,0.0441551100914207,0.0419972046889089,0.0399562306071229,0.0380282669380926,0.0362087988947414,0.0344929305759901,0.0328755532139093,0.0313514759733952,0.0299155257508181,0.0285626216639315,0.0272878291398479,0.0260863977518314,0.0249537862628691,0.0238856777202663,0.0228779869151299,0.0219268620707654,0.0210286822481356,0.0201800516462234,0.0193777917215168,0.0186189318453567,0.0179006990526371,0.0172205073034041,0.0165759465742090,0.0159647720135397,0.0153848933310049,0.0148343645396568,0.0143113741319871,0.0138142357403918,0.0133413793103448];

%% 3.2: Define guess parameters

%guess = [0.500000000000000;0.500000000000000;20;1500;1.6]; %temporary
guess = cell(5,1);
switch guessMethod
    case 'file'
        totalFits = 1;
        gTab = readtable(guessFileName,'delimiter','\t');
        for tdx = 1:size(gTab,1)
            switch gTab.param{tdx}
                case 'alpha'
                    celldx = 1;
                    expUnit = '-';
                case 'beta'
                    celldx = 2;
                    expUnit = '-';
                case 'gamma'
                    celldx = 3;
                    expUnit = 'nm';
                case 'omega0'
                    celldx = 4;
                    expUnit = 'nm';
                case 'phi'
                    celldx = 5;
                    expUnit = 'rad';
            end
            if ~strcmp(gTab.unit{tdx},expUnit)
                gTab.first(tdx) = nrgcon(gTab.first(tdx),gTab.unit,expUnit);
                gTab.last(tdx) = nrgcon(gTab.last(tdx),gTab.unit,expUnit);
            end
            if strcmp(gTab.scale(tdx),'lin')
                guess{celldx} = linspace(gTab.first(tdx),gTab.last(tdx),gTab.steps(tdx));
            elseif strcmp(gTab.scale(tdx),'log')
                guess{celldx} = logspace(gTab.first(tdx),gTab.last(tdx),gTab.steps(tdx));
            end
            totalFits = totalFits*length(guess{celldx});
        end
    otherwise
end



%% 3.3 Find minimum
fctn = @(tCoeff) sum((eq_Lorentzian_v2(xdata,tCoeff)-ydata).^2);

lsvals = zeros(totalFits,6); %change at a later date
counter = 1;
guessMat = zeros(totalFits,6);
for idx = 1:size(guess,1)
    for jdx = 1:size(guess,1)
        for tdx = 1:size(guess{jdx},1)
            guessMat(counter)
        end
    end
end
hWait = waitbar(0,sprintf('Fit %d out of %d.',counter,totalFits),'Name','Fitting spectrum...',...
    'units','normalized','Position',[0.1 0.5 0.3 0.1]);
for idx = 1:size(guess,1)
    for jdx = 1:size(guess{idx},1)
        for kdx = 1:size(guess,1)
                waitbar(counter/totalFits,hWait,sprintf('Fit %d out of %d.',counter,totalFits));
                fitParam = fminsearch(fctn,);
                lsvals(counter,1) = fctn(fitParam);
                lsvals(counter,2:6) = fitParam;
                counter = counter + 1;
                %% Plot results
                hFig = figure('Name','Resultant fit','Units','normalized','OuterPosition',[0.5 0.5 0.5 0.5]);
                ax1 = axes(hFig,'Position',[0.1 0.1 0.8 0.8],'Box','on');
                hold(ax1,'on');
                scatter(ax1,xdata,ydata,'Marker','square','SizeData',10,'MarkerEdgeColor','none','MarkerFaceColor',[0 0 0]);
                plot(ax1,xdata,eq_Lorentzian_v2(xdata,fitParam),'Marker','none','Color',[161/255 16/255 53/255]);
                delete(hFig);
            else
            end
        end
    end
end
delete(hWait);


