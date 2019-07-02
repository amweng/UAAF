function aa_frontend(xmlfile)
%
% generate aa userscript and tasklist from a unified aa analysis file (UAAF)
%
% usage: aa_frontend('/Users/peellelab/UAAF.xml');
%
%
%

[tree,~,~] = xml_read('UAAF.xml');

fid = fopen('aa_temp.m','w');
if (fid < 0); cleanup_and_exit(1); end
generate_userscript(fid,tree);
fclose(fid);

fid = fopen('aa_temp.xml','w');
if (fid < 0); cleanup_and_exit(2); end
generate_tasklist(fid,tree);
fclose(fid);

% if (do_preflight); preflight_scripts; end

%
% run "aa_temp" here...
%
% aa_temp

% delete aa_temp.m and aa_temp.xml on exit

cleanup_and_exit(0);

end

%-----------------------------------------------------------------------------------------------------------------------------------
% generate_tasklist 
%-----------------------------------------------------------------------------------------------------------------------------------

function generate_tasklist(fid, tree)
	
    fprintf(fid,'%s\n','<?xml version="1.0" encoding="utf-8"?>');
    fprintf(fid,'%s\n','<aap>');
    fprintf(fid,'%s\n','<tasklist>');
    
    % initialization block
    
    fprintf(fid,'\n%s\n','<initialisation>');
    
	for index = 1:numel(tree.tasklist.initialisation.module)
        module_name = tree.tasklist.initialisation.module(index).name;
       fprintf(fid,'\t<module><name>%s</name></module>\n', module_name);
     end

    fprintf(fid,'%s\n','</initialisation>');

    % tasklist block
    
    
    % FINISH ME -- text sub <extraparameters><aap><tasklist><currenttask><settings> for <option>
    
    fprintf(fid,'\n%s\n','<main>');
    
    for index = 1:numel(tree.tasklist.main.module)
        module_name = tree.tasklist.main.module(index).name;
        fprintf(fid,'\t<module><name>%s</name></module>\n', module_name);
    end
    
    fprintf(fid,'%s\n\n','</main>');

    fprintf(fid,'%s\n','</tasklist>');
    fprintf(fid,'%s\n','</aap>');
    
end


%-----------------------------------------------------------------------------------------------------------------------------------
% generate_userscript 
%-----------------------------------------------------------------------------------------------------------------------------------

function generate_userscript(fid, tree)

    fprintf(fid,'%s\n','clear all;');
    fprintf(fid,'%s\n','clear functions;');
    fprintf(fid,'%s\n','cd(''~'');');
    fprintf(fid,'%s\n\n','aa_ver5;');
   
    tasklist_fieldnames = fieldnames(tree.tasklist.settings);
    
    for index = 1:numel(tasklist_fieldnames)
        
        thisfieldname = tasklist_fieldnames{index};
    
        switch (thisfieldname)

            case 'default_parameters'

                parameters_fname = getfield(tree.tasklist.settings, 'default_parameters');
                tasklist_fname = 'aa_temp.m';
                fprintf(fid,'aap = aarecipe(''%s'',''%s'');\n', parameters_fname, tasklist_fname);

            case 'root'

                root_directory = getfield(tree.tasklist.settings, 'root');
                fprintf(fid,'aap.acq_details.root = ''%s'';\n', root_directory);

            case 'data_directory'

                data_directory = getfield(tree.tasklist.settings, 'data_directory');
                fprintf(fid,'aap.directory_conventions.rawdatadir = ''%s'';\n', data_directory);

            case 'numdummies'

                numdummies = getfield(tree.tasklist.settings, 'numdummies');
                fprintf(fid,'aap.acq_details.numdummies = %d;\n', numdummies);

            case 'autoidentifystructural'

                autoidentifystructural = getfield(tree.tasklist.settings, 'autoidentifystructural');
                fprintf(fid,'aap.options.autoidentifystructural = %d;\n',strcmp(autoidentifystructural,'true'));

        end
    
    end
    
    fprintf(fid,'\n%s\n','aa_doprocessing(aap);');
%     if (do_report); fprintf(fid,'%s\n','aa_report(fullfile(aas_getstudypath(aap),aap.directory_conventions.analysisid));'); end
    fprintf(fid,'%s\n','aa_close(aap);');
    
end


%-----------------------------------------------------------------------------------------------------------------------------------
% cleanup_and_exit 
%-----------------------------------------------------------------------------------------------------------------------------------

function cleanup_and_exit(ierr)

% 	system('rm -f aa_temp.m');
% 	system('rm -f aa_temp.xml');
    if (ierr); disp(aap, true, sprintf('\n%s: Script generation failed (ierr = %d).\n', mfilename, ierr)); end
	
end