function aa_frontend(xmlfile)
%
% generate aa userscript and tasklist from a unified aa analysis file (UAAF)
%
[tree,~,~] = xml_read('UAAF_demo.xml');

fid = fopen('aa_temp_demo.m','w');
if (fid < 0); cleanup_and_exit(1); end
generate_userscript(fid,tree);
fclose(fid);

fid = fopen('aa_temp_demo.xml','w');
if (fid < 0); cleanup_and_exit(2); end
generate_tasklist(fid,tree);
fclose(fid);

% if (do_preflight); preflight_scripts; end
%
% run "aa_temp" here...
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
    fprintf(fid,'\n%s\n','<main>');
    
    for index = 1:numel(tree.tasklist.main.module)
        module_name = tree.tasklist.main.module(index).name;
        switch(module_name)
            case 'aamod_segment8_multichan'
                   fprintf(fid,'\t<module><name>%s</name>\n', module_name);
                   sampling_interval(fid,tree);
            case 'aamod_smooth'
                   fprintf(fid,'\t<module><name>%s</name>\n', module_name);
                   smooth_FWHM(fid,tree);
            case 'aamod_norm_write'
                   fprintf(fid,'\t<module><name>%s</name></module>\n', module_name);
                   norm_write_warning(fid,tree);
            otherwise
                   fprintf(fid,'\t<module><name>%s</name></module>\n', module_name);
        end
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
   %fprintf(fid,'%s\n','clear functions;');
   %fprintf(fid,'%s\n','cd(''~'');');
    fprintf(fid,'%s\n\n','aa_ver5;');
    fprintf(fid,'\n\n');
    FSLhack(fid);
    
    tasklist_fieldnames = fieldnames(tree.tasklist.settings);
  
    for index = 1:numel(tasklist_fieldnames)
        thisfieldname = tasklist_fieldnames{index};
    
        switch (thisfieldname)
            case 'default_parameters'
                parameters_fname = getfield(tree.tasklist.settings, 'default_parameters');
                tasklist_fname = 'aa_temp_demo.xml';
                fprintf(fid,'aap = aarecipe(''%s'',''%s'');\n', parameters_fname, tasklist_fname);

            case 'root'
                root_directory = getfield(tree.tasklist.settings, 'root');
                fprintf(fid,'aap.acq_details.root = ''%s'';\n', root_directory);
            
            case 'result_directory'
                result_directory = getfield(tree.tasklist.settings, 'result_directory');
                fprintf(fid,'aap.directory_conventions.analysisid = ''%s'';\n', result_directory);
                      
            case 'data_directory'
                data_directory = getfield(tree.tasklist.settings, 'data_directory');
                fprintf(fid,'aap.directory_conventions.rawdatadir = ''%s'';\n', data_directory);  
            
            case 'identify_options'
                identify_dataset = getfield(tree.tasklist.settings, 'identify_options');
                inputParams(fid,identify_dataset);
                
            case 'task_units'
                task_units = getfield(tree.tasklist.settings, 'task_units');              
        end
    end
    
    renameStream(fid,tree); 
    generate_processBIDS(fid);
    specify_task_units(fid,task_units);   
   %modeling
    defineContrasts(fid);
    fprintf(fid,'\n%s\n','aa_doprocessing(aap);');
   %if (do_report); fprintf(fid,'%s\n','aa_report(fullfile(aas_getstudypath(aap),aap.directory_conventions.analysisid));'); end
    fprintf(fid,'%s\n','aa_close(aap);');
    jpeg_crawler(fid);
   
end

% -------------------------------------------------------------------
% Function toolbox                                -------------------
% -------------------------------------------------------------------
%----------------------------------------------------------------------------------------------------------------------------------
% function to specify task units if different than default
%----------------------------------------------------------------------------------------------------------------------------------

function specify_task_units(fid,task_units)
       fprintf(fid,'\n\naap.tasksettings.aamod_firstlevel_model.xBF.UNITS = ''%s'';\n\n', task_units);
end  
%-----------------------------------------------------------------------------------------------------------------------------------
% function to specify segmentation sampling interval
%-----------------------------------------------------------------------------------------------------------------------------------

function sampling_interval(fid,tree)

      tasklist_fieldnames = fieldnames(tree.tasklist.settings);
      sampling_interval = 0;  
      for index = 1:numel(tasklist_fieldnames)
        thisfieldname = tasklist_fieldnames{index};      
        switch(thisfieldname)
            case 'segment_samp'
                sampling_interval = num2str(getfield(tree.tasklist.settings, 'segment_samp'));
        end
      end
     fprintf(fid,'\t\t<extraparameters>\n');
     fprintf(fid,'\t\t\t<aap><tasklist><currenttask><settings>\n');
     fprintf(fid,'\t\t\t\t<samp>%s</samp>\n',sampling_interval);
     fprintf(fid,'\t\t\t</settings></currenttask></tasklist></aap>\n');
     fprintf(fid,'\t\t</extraparameters>\n');
     fprintf(fid,'\t</module>\n\n\n');
end
%-----------------------------------------------------------------------------------------------------------------------------------
% print warning for aamod_norm_write.xml
%-----------------------------------------------------------------------------------------------------------------------------------
function norm_write_warning(fid,tree)
    fprintf(fid,'\n\n\t<!-- you may need to change domain=''*'' to domain=''session'' in aamod_norm_write.xml! -->\n\n');
end
%-----------------------------------------------------------------------------------------------------------------------------------
% function to specify extra smoothing options
%-----------------------------------------------------------------------------------------------------------------------------------

function smooth_FWHM(fid,tree)

      default_FWHM = 10;

      tasklist_fieldnames = fieldnames(tree.tasklist.settings);
      user_FWHM = 0;
   
      for index = 1:numel(tasklist_fieldnames)
        thisfieldname = tasklist_fieldnames{index};
        switch(thisfieldname)
            case 'smooth_FWHM'
                user_FWHM = num2str(getfield(tree.tasklist.settings, 'smooth_FWHM'));
        end
      end 
      
     if user_FWHM ~= default_FWHM
         disp("smoothing FWHM defined as " + user_FWHM + ". SPM default FWHM = " + default_FWHM);
     end
     
     
      
     fprintf(fid,'\t\t<extraparameters>\n');
     fprintf(fid,'\t\t\t<aap><tasklist><currenttask><settings>\n');
     fprintf(fid,'\t\t\t\t<FWHM>%s</FWHM>\n',user_FWHM);
     fprintf(fid,'\t\t\t</settings></currenttask></tasklist></aap>\n');
     fprintf(fid,'\t\t</extraparameters>\n');
     fprintf(fid,'\t</module>\n\n\n');
end
%-----------------------------------------------------------------------------------------------------------------------------------
%placeholder while i figure out .txt(or other) specification for contrasts and modeling
%-----------------------------------------------------------------------------------------------------------------------------------
function defineContrasts(fid)
        fprintf(fid,'aap = aas_addcontrast(aap, ''aamod_firstlevel_contrasts_*'',''*'',''sameforallsessions'', [1], ''test-contrast'',''T'');\n');
end
%-----------------------------------------------------------------------------------------------------------------------------------
%call aa_jpeg_cralwer
%-----------------------------------------------------------------------------------------------------------------------------------
function jpeg_crawler(fid)
        fprintf(fid, 'aa_jpeg_crawler(aap);');
end
%-----------------------------------------------------------------------------------------------------------------------------------
%generates processBIDS call ... (calls specifySubjects)
%-----------------------------------------------------------------------------------------------------------------------------------
function generate_processBIDS(fid) 
      subjectList = specifySubjects();
      if size(subjectList) == 0
            disp('no subjects specified: processBIDS takes in all available subjects by default');
            fprintf(fid,'aap = aas_processBIDS(aap);');
      elseif size(subjectList) > 0          
            s = '';           
            for idx = 1:numel(subjectList)
                A = string({subjectList(idx)});
                s = strcat(s,'''',A,'''',',');   
            end           
             fprintf(fid,'aap = aas_processBIDS(aap,[],[],{%s});',s);
      end
end
%-----------------------------------------------------------------------------------------------------------------------------------
%returns a cell array of subjects ... ['sub-01'],['sub-02']
%-----------------------------------------------------------------------------------------------------------------------------------
function [subjects] = specifySubjects()
     
    [subjectfid,msg] = fopen('subjects.txt','r');
    if subjectfid < 0
        error('Failed to open file "%s" because "%s"', 'subjects.txt', msg);
    end  
    subjects = {};
    line = fgetl(subjectfid);
    while ischar(line)
        subjects{end+1} = {line};
        line = fgetl(subjectfid);    
    end
    fclose(subjectfid); 
end
%-----------------------------------------------------------------------------------------------------------------------------------
%FSL directory specification workaround
%-----------------------------------------------------------------------------------------------------------------------------------
function FSLhack(fid)

        fprintf(fid,'FSL_binaryDirectory = ''/usr/local/fsl/bin'';\n');
        fprintf(fid,'currentPath = getenv(''PATH'');\n');
        fprintf(fid,'if ~contains(currentPath,FSL_binaryDirectory)\n');
        fprintf(fid,'\tcorrectedPath = [ currentPath '':'' FSL_binaryDirectory ];\n');
        fprintf(fid,'\tsetenv(''PATH'', correctedPath);\n');
        fprintf(fid,'end\n\n\n');

end
%-----------------------------------------------------------------------------------------------------------------------------------
%input parameters for specific datasets
%-----------------------------------------------------------------------------------------------------------------------------------
function inputParams(fid,dataset_name)
        switch(dataset_name)
            case('ds001497')
                fprintf(fid,'\n\naap.options.autoidentifystructural_choosefirst = 1;\n');
                fprintf(fid,'aap.options.autoidentifystructural_chooselast = 0;\n\n');
                fprintf(fid,'aap.options.NIFTI4D = 1;\n');
                fprintf(fid,'aap.acq_details.numdummies = 0;\n');
                fprintf(fid,'aap.acq_details.intput.correctEVfordummies = 0;\n\n');  
            case('MoAEpilot')
                fprintf(fid,'\n\naap.options.autoidentifystructural_choosefirst = 1;\n');
                fprintf(fid,'aap.options.autoidentifystructural_chooselast = 0;\n\n');
                fprintf(fid,'aap.options.NIFTI4D = 1;\n');
                fprintf(fid,'aap.acq_details.numdummies = 0;\n');
                fprintf(fid,'aap.acq_details.intput.correctEVfordummies = 0;\n\n');   
        end
end

%-----------------------------------------------------------------------------------------------------------------------------------
% allows stream-renaming. (FIXME) Assumes that user will not invoke a process >9
% times in a single pipeline.
%-----------------------------------------------------------------------------------------------------------------------------------

function renameStream(fid,tree)

      allmodules = tree.tasklist.main.module;     
      moduleList = {allmodules(:).name};
      uniqueModules = unique(moduleList);
      lengthUnique = length(uniqueModules);
      numAppearance(lengthUnique) = 0;

      for index = 1:numel(tree.tasklist.main.module)
        process = tree.tasklist.main.module(index);
        
                currentModuleIndex = 9999;      
                for uniqueIndex = 1:numel(uniqueModules)
                   match = uniqueModules(uniqueIndex);
                   if strcmp(match,process.name)
                       numAppearance(uniqueIndex) = numAppearance(uniqueIndex) + 1;
                       currentModuleIndex = uniqueIndex;
                   end
                end
                
                if isfield(process, 'renameinputstream') 
                    if ~isempty(process.renameinputstream)
                        disp("renaming input stream for " + process.name);
                        fields = fieldnames(process.renameinputstream);
                        inputStream = fields{1};
                        fprintf(fid,"aap = aas_renamestream(aap,'" + process.name + "_000" + numAppearance(currentModuleIndex) + "','" + inputStream + "','" + process.renameinputstream.(inputStream) + "');" + '\n\n');
                    end

                end
                
                if isfield(process, 'renameoutputstream')
                     if ~isempty(process.renameoutputstream)             
                        disp("renaming output of " + process.name);
                        fields = fieldnames(process.renameoutputstream);
                        outputStream = fields{1};
                        fprintf(fid,"aap = aas_renamestream(aap,'" + process.name + "_000" + numAppearance(currentModuleIndex) + "','" + outputStream + "','" + process.renameoutputstream.(outputStream) + "','output');" + '\n\n' );
                     end
                end
        end 
end
%-----------------------------------------------------------------------------------------------------------------------------------
% cleanup_and_exit 
%-----------------------------------------------------------------------------------------------------------------------------------
function cleanup_and_exit(ierr)


 	%system('rm -f aa_temp_demo.m');
 	%system('rm -f aa_temp_demo.xml');
    if (ierr); disp(aap, true, sprintf('\n%s: Script generation failed (ierr = %d).\n', mfilename, ierr)); end
	
end