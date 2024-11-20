##How to use the Bioinformatic Toolkit

#ensure all the following commands are done from the bioinformatics toolkit directory, to get to this use 
cd /mnt/seaes01-data01/nixon-microbiome/shared/bioinformatic_toolkit

#note - a drawback to the current setup is that only one person can run the toolkit at one time though an unlimited number of samples can be run

----------------------
#FOR USE ON THE SERVER 

#create a snakemake environment (only needs to be created once, the environment persists when logging off)
conda create -c conda-forge -c bioconda -n snakemake snakemake

#type "y" when prompted and press enter
#activate the snakemake environment (this needs to be done every time you log in)
conda activate snakemake

#Modify the config.yaml (further instructions in the file on how to modify), choosing the directory of your data, your samples, and number of cores to use. 
nano config.yaml 

#escape the file editor by pressing and holding "control" then pressing "x"

#Create a screen so the workflow can run in the background and not terminate when logging off (note, you cant scroll in a screen)
screen -r snakemake

#activate snakemake again, if this fails you may need to use "source ~/.bashrc" first
conda activate snakemake

#run the workflow run by typing the following into the terminal 
bash bash_script

#exit the tethered screen by pressing "control" "a" and "d" simultaniously

-------------------
#FOR USE ON THE CSF

#create a snakemake environment (only needs to be created once, the environment persists when logging off)
conda create -c conda-forge -c bioconda -n snakemake snakemake

#Modify the config.yaml (further instructions in the file on how to modify), choosing the directory of your data, your samples, and number of cores to use. 
nano config.yaml

#escape the file editor by pressing and holding "control" then pressing "x"

#submit the job script to start the run 
qsub qsub_jobscript

-----------------
#TROUBLESHOOTING

#Have you forgotten to activate the snakemake environment?

#Are you running the job from the correct directory? bioinformatics_toolkit/

#Is someone else running the pipeline at the moment? Snakemake can't run twice, simultaneously, on the same folder

#Has the job cancelled for whatever reason and snakemake has locked the folder? use 
snakemake --unlock <path/to/directory>

