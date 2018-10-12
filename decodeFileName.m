function argout = decodeFileName(fileName,project)

switch project
    case 'PNC'
        %% PCN scans created through 'jphelperv.ipbny' after July 30th, 2018
        argout = struct('indicator','','relDate','','row',-99.9,'col',-99.9,...
            'cavity','','measDate','','measTime','','rem','');
        cavityLookup = {...
            {'A' 'AAH' 'Bichromatic'},'Bichromatic';...
            {'B' 'l43'},'L43';...
            {'C' 'l3five'},'L3five';...
            {'D' 'l3eight'},'L3eight'};
        
        % Check if it is a standard expression
        expr = '(?<ind>[a-z]*[0-9]*)_(?<cav>[\w*])_(?<row>[0-9]*)_(?<col>[0-9]*)_(?<rest>\w.+)';
        res = regexpi(fileName,expr,'names');
        
        if isempty(res)
            fnam = fieldnames(res);
            for idx = 1:length(fnam)
                if ~exist(['res.',fnam{idx}],'var')
                    switch fnam{idx}
                        case 'ind'
                            %% Determnine indicator
                            expr = '(?<rid>r[a-z]*[0-9_-]+)';
                            res2 = regexpi(fileName,expr,'names');
                            if isempty(res2)
                                res(1).ind = 'release0000';
                            else
                                res(1).ind = res2.rid;
                            end
                        case 'cav'
                        case 'row'
                            %% Determnine row & column
                            expr = '_(?<row>[0-9]{1,2})[-_]*(?<col>[0-9])[_\.]';
                            res2 = regexpi(strrep(fileName,res.ind,''),expr,'names');
                            if isempty(res2)
                                res2 = struct('row',-1','col',-1);
                            end
                            res.row = res2.row;
                            res.col = res2.col;
                            
                        case 'col'
                        case 'rest'
                            tstr = fileName;
                            for jdx = 1:length(fnam)
                                if ~sum(strcmp(fnam{jdx},{'rest' 'cav'}))
                                    remstr = res.(fnam{jdx});
                                    if isnumeric(remstr)
                                        remstr = str2double(remstr);
                                    end
                                    tstr = strrep(tstr,remstr,'');
                                end
                            end
                            tstr = strrep(tstr,'__','_');
                            res.rest = tstr;
                    end
                end
                
            end
        end
        
        %% Determine cavity type from 'fileName'
        expr = '_(?<cavid>[a-z])_|_(?<cavid>L[0-9]+[a-z]*)_';
        res2 = regexpi(fileName,expr,'names');
        for jdx = 1:size(cavityLookup,1)
            for kdx = 1:length(cavityLookup{jdx,1})
                if strcmpi(res2.cavid,cavityLookup{jdx,1}{kdx}) ||...
                        (strsearch(fileName,cavityLookup{jdx,1}{kdx}) && kdx > 1)
                    argout.cavity = cavityLookup{jdx,2};
                end
            end
            if ~isempty(argout.cavity)
                break;
            end
        end
        if isempty(argout.cavity)
            argout.cavity = 'unknown';
        end
        
        argout.indicator = res.ind;
        argout.row = res.row;
        argout.col = res.col;
        
        % Parse release indicator into release date if not obvious
        expr = '(?<title>r[elas]*)[_-]*(?<month>[0-9]{1,2})[-]*(?<day>[0-9]{1,2})';
        res4 = regexpi(res.ind,expr,'names');
        if strcmpi(res4.title,'R')
            switch str2double(res.num)
                case 1
                    res4.month = '06';
                    res4.day = '26';
                case 2
                    res4.month = '07';
                    res4.day = '19';
                case 3
                    res4.month = '07';
                    res4.day = '24';
                case 4
                    res4.month = '08';
                    res4.day = '08';
                case 5
                    res4.month = '08';
                    res4.day = '17';
                otherwise
                    res4.month = '00';
                    res4.day = '00';
            end
        end
        month = str2double(res4.month);
        day = str2double(res4.day);
        
        %% Find the measurement time and date
        expr = '(?<year>[0-9]{4})(?<month>[0-9]{2})(?<day>[0-9]{2})-(?<hour>[0-9]{2})(?<min>[0-9]{2})(?<sec>[0-9]{2})';
        [res3,remstr] = regexpi(res.rest,expr,'names','match');
        if isempty(res3)
            res3 = struct('year','1969','month','07','day','20','hour','20','min','17','sec','0');
        end
        % Assumes fabrication and measurement occurred in same year
        argout.relDate = sprintf('%s-%d-%d',res3.year,month,day);
        argout.measDate = sprintf('%s-%s-%s',res3.year,res3.month,res3.day);
        argout.measTime = sprintf('%s-%s-%s',res3.hour,res3.min,res3.sec);
        % Put remainder in 'rem' field
        argout.rem = strrep(res.rest,remstr,'');
    otherwise
end