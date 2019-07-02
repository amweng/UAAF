clear all;
clear functions;
cd('~');
aa_ver5;



FSL_binaryDirectory = '/usr/local/fsl/bin';
currentPath = getenv('PATH');
if ~contains(currentPath,FSL_binaryDirectory)
	correctedPath = [ currentPath ':' FSL_binaryDirectory ];
	setenv('PATH', correctedPath);
end


aap = aarecipe('/Users/andrewweng/Repositories/automaticanalysis_andrew/aa_parametersets/aap_parameters_ANDREW.xml','aa_temp_demo.m');
aap.acq_details.root = '/Users/andrewweng/Data/ds001497';
aap.directory_conventions.rawdatadir = '/Users/andrewweng/Data/ds001497';
aap.directory_conventions.analysisid = 'RESULTS';


aap.options.autoidentifystructural_choosefirst = 1;
aap.options.autoidentifystructural_chooselast = 0;

aap.options.NIFTI4D = 1;
aap.acq_details.numdummies = 0;
aap.acq_details.intput.correctEVfordummies = 0;

aap = aas_processBIDS(aap, [], [], {'sub-01', 'sub-02', 'sub-03', 'sub-04', 'sub-05', 'sub-06', 'sub-07', 'sub-08', 'sub-09'});

aap.tasksettings.aamod_firstlevel_model.xBF.UNITS = 'secs';

aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*','*','sameforallsessions', [1,0,0], 'faces','T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*','*','sameforallsessions', [0,1,0], 'objects','T');
aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts_*','*','sameforallsessions', [0,0,1], 'places','T');

aa_doprocessing(aap);
aa_close(aap);
