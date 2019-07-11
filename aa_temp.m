clear all;
clear functions;
cd('~');
aa_ver5;

aap = aarecipe('/Users/peellelab/aa_parameters.xml','aa_temp.m');
aap.acq_details.root = '/Users/peellelab/DATA/NAMWords';
aap.directory_conventions.rawdatadir = '/Users/peellelab/DATA/NAMWords/SUBJECTS';
aap.acq_details.numdummies = 4;
aap.options.autoidentifystructural = 1;

aa_doprocessing(aap);
aa_close(aap);
