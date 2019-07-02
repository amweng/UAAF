clear all;
clear functions;
cd('~');
aa_ver5;

aap = aarecipe('/Users/peellelab/aa_parameters.xml','aa_temp.m');
aap.acq_details.root = '/Users/andrewweng/Data/ds001497';
aap.directory_conventions.rawdatadir = '/Users/andrewweng/Data/ds001497';
aap.acq_details.numdummies = 0;
aap.options.autoidentifystructural = 1;

aa_doprocessing(aap);
aa_close(aap);
