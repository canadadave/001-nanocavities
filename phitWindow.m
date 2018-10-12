function varout = phitWindow(vargin)
%% INPUT
%
%% OUTPUT
%
%% NOTES
%   - Make sure 'varNames' first covers all the variables actually used as
%       fit parameters
varout.fitDone = 0;

% Main figure
hMain = figure(...
    'Name','Manual Fit Window',...
    'Units','normalized',...
    'OuterPosition', [0.5 0.1 0.5 0.4],...
    'MenuBar','none',...
    'ToolBar','none',...
    'WindowStyle','normal',...
    'DeleteFcn',@getvargout);


%% Initialize sliders
slid = struct('varNam','','handle','','hMin','','hMax','','hNam','','hVal','','hLC','','hRC','');

inparnum = length(vargin.varNames);

vargin.varNames = [vargin.varNames,{'LeftLimit' 'RightLimit'}];
vargin.startValues = [vargin.startValues,{min(vargin.data(:,1)),max(vargin.data(:,1))}];
tmin = min(vargin.data(:,1));
tmax = max(vargin.data(:,1));
vargin.stdBnds = [vargin.stdBnds,{[tmin,tmax],[tmin,tmax]}];

sliderNum = length(vargin.varNames);
sliderHgt = 0.05;
sliderWid = 0.4;

txtHgt = 0.08;
txtWid = 0.1;

spacing = [0.1 max((0.8-(ceil(sliderNum/2))*sliderHgt)/ceil(sliderNum/2),txtHgt)];
pfac = 0.2;

butWid = 0.15;
butHgt = 0.08;
%% SECTION II: Initialize UI controls

%% Reset to start values
hbut0 = uicontrol(hMain,'style','pushbutton','units','normalized',...
    'string','Reset values',...
    'position',[0.1 0.9 butWid butHgt],...
    'callback',@resetVals);

%% Weighing value
hedit0 = uicontrol(hMain,'style','edit','units','normalized',...
    'string','1',...
    'position',[0.1+butWid+0.01 0.9 txtWid txtHgt],...
    'callback',@updateFit);

%% Add linear component checkmark
check3 = uicontrol(hMain,'style','checkbox','units','normalized',...
    'string','Add linear',...
    'value',0,...
    'position',[0.1+butWid+txtWid+0.02 0.93 butWid butHgt],...
    'callback',@updateFit);

%% Add linear sine component checkmark
check4 = uicontrol(hMain,'style','checkbox','units','normalized',...
    'string','Add sine',...
    'value',0,...
    'position',[0.1+butWid+txtWid+0.02 0.93-butHgt/2-.02 butWid butHgt],...
    'callback',@updateFit);

%% Update Fit button
hbut1 = uicontrol(hMain,'style','pushbutton','units','normalized',...
    'string','Update Fit',...
    'position',[0.1+sliderWid/2-5*butWid/8 0.05 butWid butHgt],...
    'callback',@updateFit);

%% Continuous update checkmark
check1 = uicontrol(hMain,'style','checkbox','units','normalized',...
    'string','Continous update',...
    'value',1,...
    'position',[0.1+sliderWid/2+5*butWid/8+0.01 0.05 butWid butHgt],...
    'callback',@updateFit);

%% Plot versus fit checkmark
check2 = uicontrol(hMain,'style','checkbox','units','normalized',...
    'string','Optimizing',...
    'value',1,...
    'position',[0.1+sliderWid/2+5*butWid/8+0.01 0.05+butHgt/2+.02 butWid butHgt],...
    'callback',@updateFit);

%% Accept Fit button
hbut2 = uicontrol(hMain,'style','pushbutton','units','normalized',...
    'string','Accept Fit',...
    'position',[2*spacing(1)+1.5*sliderWid-butWid/2 0.05-butHgt/2 butWid butHgt],...
    'callback',@getvargout);

%% Individual variable sliders
for idx = 1:sliderNum
    pos = [0 0 sliderWid sliderHgt];
    if idx <= ceil(sliderNum/2)
        pos(1) = spacing(1);
        pos(2) = 0.8-spacing(2)*(idx-1);
    else
        pos(1) = 2*spacing(1)+sliderWid;
        pos(2) = 0.8-spacing(2)*(idx-ceil(sliderNum/2)-1);
    end
    val = vargin.startValues{idx};
    slid(idx).hNam = uicontrol(hMain,'style','text','units','normalized',...
        'string',vargin.varNames{idx},...
        'position',[pos(1)-txtWid pos(2)-txtHgt txtWid txtHgt],...
        'tag',[vargin.varNames{idx},'_htxt']);
    slid(idx).hVal = uicontrol(hMain,'style','edit','units','normalized',...
        'callback',@setVal,...
        'position',[pos(1)+sliderWid/2-txtWid/2 pos(2)-txtHgt txtWid txtHgt],...
        'string',num2str(val),...
        'tag',[vargin.varNames{idx},'_hval']);
    
    slid(idx).hMin = uicontrol(hMain,'style','edit','units','normalized',...
        'callback',@setMinMax,...
        'position',[pos(1) pos(2)-txtHgt txtWid txtHgt],...
        'string',num2str(vargin.stdBnds{idx}(1)),...
        'tag',[vargin.varNames{idx},'_hmin']);
    slid(idx).hLC = uicontrol(hMain,'style','checkbox','units','normalized',...
        'string','',...
        'value',1,...
        'position',[pos(1)+txtWid+0.005 pos(2)-txtHgt 0.03 txtHgt],...
        'tag',[vargin.varNames{idx},'_hlc'],...
        'callback',@updateFit);
    
    slid(idx).hMax = uicontrol(hMain,'style','edit','units','normalized',...
        'position',[pos(1)+sliderWid-txtWid pos(2)-txtHgt txtWid txtHgt],...
        'callback',@setMinMax,...
        'string',num2str(vargin.stdBnds{idx}(2)),...
        'tag',[vargin.varNames{idx},'_hmax']);
    slid(idx).hRC = uicontrol(hMain,'style','checkbox','units','normalized',...
        'string','',...
        'value',1,...
        'position',[pos(1)+sliderWid-txtWid-0.03 pos(2)-txtHgt 0.03 txtHgt],...
        'tag',[vargin.varNames{idx},'_hrc'],...
        'callback',@updateFit);
    
    slid(idx).handle = uicontrol(hMain,'Style','slider','units','normalized',...
        'position',pos,'Callback',@sliderCallback,...
        'Value',vargin.startValues{idx},...
        'max',str2double(slid(idx).hMax.String),...
        'min',str2double(slid(idx).hMin.String),...
        'tag',[vargin.varNames{idx},'_slid']);
    setMinMax(slid(idx).handle);
end
updateFit(slid(1).handle);

%% SECTION III: Other functions
    function getvargout(hObj,eventdata)
        for jdx = 1:inparnum
            varout.endParams(jdx) = str2double(get(findobj('tag',[vargin.varNames{jdx},'_hval']),'string'));
        end
        varout.fitDone = 1;
        delete(hMain);
    end

    function updateFit(hObj,eventdata)
        
        %% Data
        llim = str2double(get(findobj('tag','LeftLimit_hval'),'string'));
        ulim = str2double(get(findobj('tag','RightLimit_hval'),'string'));
        
        for jdx = 1:length(vargin.varNames)
            if ~strsearch(vargin.varNames{jdx},'Limit')
                startParams(jdx) = str2double(get(findobj('tag',[vargin.varNames{jdx},'_hval']),'string'));
                if get(findobj('tag',[vargin.varNames{jdx},'_hlc']),'value')
                    lowerBnd(jdx) = str2double(get(findobj('tag',[vargin.varNames{jdx},'_hmin']),'string'));
                else
                    lowerBnd(jdx) = -Inf;
                end
                if get(findobj('tag',[vargin.varNames{jdx},'_hrc']),'value')
                    upperBnd(jdx) = str2double(get(findobj('tag',[vargin.varNames{jdx},'_hmax']),'string'));
                else
                    upperBnd(jdx) = +Inf;
                end
            end
        end
        
        %% Write fitting function [UPDATE PLEASE: THIS IS SUPER FUCKING UGLY.]
        ffunc = vargin.fitfun;
        
        if get(check3,'value') && ~get(check4,'value')
            ffunc =  @(a,x)...
                a(1)^2+a(2)^2*a(3)^2./((x-a(4)).^2+a(3)^2)...
                +a(1)*a(2)*exp(1i*a(5))*a(3)./((x-a(4))-1i*a(3))...
                +a(1)*a(2)*exp(-1i*a(5))*a(3)./((x-a(4))+1i*a(3))...
                +a(6)*x+a(7);
        elseif get(check4,'value') && ~get(check3,'value')
            ffunc =  @(a,x)...
                a(1)^2+a(2)^2*a(3)^2./((x-a(4)).^2+a(3)^2)...
                +a(1)*a(2)*exp(1i*a(5))*a(3)./((x-a(4))-1i*a(3))...
                +a(1)*a(2)*exp(-1i*a(5))*a(3)./((x-a(4))+1i*a(3))...
                +a(6)*sin(a(7)*x+a(8));
        elseif get(check4,'value') && get(check3,'value')
            ffunc =  @(a,x)...
                a(1)^2+a(2)^2*a(3)^2./((x-a(4)).^2+a(3)^2)...
                +a(1)*a(2)*exp(1i*a(5))*a(3)./((x-a(4))-1i*a(3))...
                +a(1)*a(2)*exp(-1i*a(5))*a(3)./((x-a(4))+1i*a(3))...
                +a(6)*x+a(7)...
                +a(8)*sin(a(9)*x+a(10));
        end
        
        if get(check3,'value')
            % Add linear term
            %ffunc = @(a,x) ffunc(a,x)+eval(['a(',num2str(length(startParams)+1),')*x+a(',num2str(length(startParams)+2),')']);
            slope = (vargin.data(length(vargin.data(:,1)),2)-vargin.data(1,2))/...
                (vargin.data(length(vargin.data(:,1)),1)-vargin.data(1,1));
            intercept = vargin.data(1,2)-slope*vargin.data(1,1);
            startParams = [startParams,slope,intercept];
        end
        if get(check4,'value')
            % Add sinusoidal term
            %ffunc = @(a,x) ffunc(a,x)+eval(['a(',num2str(length(startParams)+1),')*sin(a(',num2str(length(startParams)+2),')*x+a(',num2str(length(startParams)+3),'))']);
            amplitude = min(vargin.data(:,2));
            period = 1/(abs(vargin.data(length(vargin.data(:,1)),1)-vargin.data(1,1)));
            phase = 0;           
            startParams = [startParams,amplitude,period,phase];
        end
        plotax = vargin.axes;

        %% Fit or merely plot
        if get(check2,'value')
            wgts = [vargin.data(:,1),ones(length(vargin.data(:,1)),1)];
            wgts(wgts(:,1)>=llim,:) = str2double(get(hedit0,'string'));
            wgts(wgts(:,1)>ulim,:) = 1;
            fitarg.fitOptions = {'Weights',wgts(:,2);'Upper',upperBnd;'Lower',lowerBnd};
            [endParams,varout.confbnd] = ppfit(ffunc,vargin.data,startParams,fitarg);
        else
            endParams = startParams;
        end
        
        chld = get(plotax,'Children');
        for jdx=1:length(chld)
            if strcmp(get(chld(jdx),'UserData'),'toDelete')
                delete(chld(jdx));
            end
        end
        plot(plotax,vargin.data(:,1),ffunc(endParams,vargin.data(:,1)),...
            'Color',RWTHColor(3),'LineWidth',1.5,'UserData','toDelete');
        line(plotax,'XData',[llim llim],'YData',plotax.YLim,'UserData','toDelete');
        line(plotax,'XData',[ulim ulim],'YData',plotax.YLim,'UserData','toDelete');
        
        for jdx = 1:inparnum
            set(findobj('tag',[vargin.varNames{jdx},'_hval']),'string',num2str(endParams(jdx)));
        end
    end

    function sliderCallback(hObj,eventdata)
        setVal(hObj,eventdata);
    end

    function nam = getVarNam(hObj)
        tag = get(hObj,'tag');
        t = regexpi(tag,'(?<var>[a-z0-9]+)_(?<tag>\w{4})','names');
        nam = t.var;
    end

    function setVal(hObj,eventdata)
        varnam = getVarNam(hObj);
        
        minval = str2double(get(findobj('tag',[varnam,'_hmin']),'String'));
        maxval = str2double(get(findobj('tag',[varnam,'_hmax']),'String'));
        if strcmp(get(hObj,'style'),'slider')
            val = get(hObj,'value');
            set(findobj('tag',[varnam,'_hval']),'string',num2str(val));
        else
            val = str2double(get(findobj('tag',[varnam,'_hval']),'String'));
        end
        
        if val < minval
            minval = val;
        elseif val > maxval
            maxval = val;
        end
        
        updateSlider(varnam,[minval val maxval]);
        if get(check1,'value')
            updateFit;
        end
    end

    function updateSlider(varname,vals)
        set(findobj('tag',[varname,'_slid']),'min',vals(1),'max',vals(3),'value',vals(2));
        set(findobj('tag',[varname,'_hval']),'string',num2str(vals(2)));
        set(findobj('tag',[varname,'_hmin']),'string',num2str(vals(1)));
        set(findobj('tag',[varname,'_hmax']),'string',num2str(vals(3)));
    end
    
    function resetVals(hObj,eventdata)
        for jdx = 1:length(vargin.varNames)
            set(findobj('tag',[vargin.varNames{jdx},'_hval']),'string',num2str(vargin.startValues{jdx}));
        end
        updateFit;
    end

    function setMinMax(hObj,eventdata)
        varnam = getVarNam(hObj);
        
        minval = str2double(get(findobj('tag',[varnam,'_hmin']),'String'));
        maxval = str2double(get(findobj('tag',[varnam,'_hmax']),'String'));
        val = str2double(get(findobj('tag',[varnam,'_hval']),'String'));
        
        %% SPECIFIC TO SPECTRUM FITS
        switch varnam
            case {'LeftLimit' 'RightLimit' 'omega0'}
                minval = min(vargin.data(:,1));
                maxval = max(vargin.data(:,1));
            otherwise
        end
        
        if minval > val
            val = minval;
        elseif maxval < val
            val = maxval;
        end
        
        if minval > maxval
            tval = minval;
            minval = maxval;
            maxval = tval;
            val = minval;
        end
        
        updateSlider(varnam,[minval val maxval]);
    end

    function hMainWindowButtonUpFcn(hObject,eventdata)
    end

    function hMainWindowButtonDownFcn(hObject,eventdata)
    end

    function hMainWindowButtonMotionFcn(hObject,eventdata)
    end

    uiwait(hMain);
end
