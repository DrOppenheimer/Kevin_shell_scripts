#!/bin/bash

# Script to be run once (initial boot) on genomel VMs to install Jeremiah's DNASeq pipeline
# adapted from https://github.com/NCI-GDC/cocleaning-cwl/tree/master/workflows/dnaseq with additional notes from Jeremiah, 7-25-16
# (numbers correspond to those in the above repo 7-25-16; several edited or omitted based on Jeremiah's notes)
# check to see if install already ran (i.e. on reboot)

# assumes that the following two directories are already present in the image
#      /home/ubuntu/cocleaning-cwl # from https://github.com/NCI-GDC/cocleaning-cwl
#      /home/ubuntu/.virtualenvs # .virtualenvs # from originals that Jeremiah configured (on genomel-dev, 172.16.165.255)
#      /home/ubuntu/images # contains docker images in tar files that Jeremiah created (on genomel-dev, 172.16.165.255, 7-25-16)
#           I took the tar'ed images and placed them in a bucket on PDC, and made the individual objects public read
#################################################################################################
# jeremiah notes (7-25-16)
# [11:15 AM]There's a few steps that may cause issues with the tools installed on 172.16.165.255

# [11:16]Step 5, 8, 9, 10 should be skipped

# [11:18]Instead of step 5, on 172.16.165.255, do
# rsync -av --progress .virtualenvs new_vm:

# [11:19]Instead of step 10, on 172.16.165.255, do
# rsync -av --progress cocleaning-cwl new_vm:

# [11:21]I'm saving the docker images on 172.16.165.255 to /mnt/SCRATCH/images as
# .tar
# files

# [11:24]There will be 10 tar files that should be loaded after step 1

# [11:25]such as,
# docker load -i bwa_tool.tar

# Kyle suggested to not host this script on the image, but to us it when the
# VM is booted up (nova boot ... --user-data $some_dir/script_to_run_at_boot.sh)
# I want to use this idea by creating a script run from /etc/rc.local that will
# just check to see if there is a hidden install log (~/.DNASeq.install_log.txt)
# If not - then it will download the install script and then run it
# So two scripts -- one run from /etc/rc.local to see if installation has occured, download and installer if it has not (NOT THIS SCRIPT)
# a second script to actually perform the installation (THIS SCRIPT)

# Jeremiah notes (7-26-16) 
# [12:12] `workon` has to be done everytime: the top three commands always have to be done after the initial setup.
#   
#     $ workon cwl
#     $ cd /mnt/SCRATCH/genoMel_harmon
#     $ nohup cwltool --tmpdir-prefix /mnt/SCRATCH/tmp/ --tmp-outdir-prefix /mnt/SCRATCH/tmp/  --debug ~/cocleaning-cwl/workflows/dnaseq/dnaseq_workflow.cwl.yaml  ~/cocleaning-cwl/workflows/dnaseq/genoMel.json &

# Jeremiah notes (7-27-16)
# [2:03]  `pip install --upgrade pip` without `sudo`
# In https://github.com/NCI-GDC/cocleaning-cwl/tree/master/workflows/dnaseq
# any step preceeded by a `$` should be performed by `ubuntu`
# while any step preceeded by a `#` should be performed by `root`

# Reference data
# /mnt/SCRATCH/grch38/GRCh38.d1.vd1.fa (on 172.16.165.255)
# /mnt/SCRATCH/coclean/dbsnp_144.hg38.vcf.gz (on 172.16.165.255)

# the following files were placed as public read on Griffin Object Store
GRCh38.d1.vd1.fa
dbsnp_144.hg38.vcf.gz

bam_readgroup_to_json.tar
biobambam_tool.tar
fastqc_db.tar
merge_sqlite.tar
readgroup_json_db.tar
bam_reheader.tar
bwa_tool.tar
fastqc_tool.tar
picard_tool.tar
samtools_tool.tar

# Tested on VM started like this
## nova boot --image 673d28c9-6b33-4e13-84a0-52e3776685e8 --flavor 30 --key-name kevin_PDC_genomel genomel_GDC_port
# This to get the ip
## nova show genomel_GDC_port | grep "private network"

#################################################################################################


if [ ! -f ~/.DNASeq.install_log.txt ]; then
    echo "File not found!"
    
    ### enter sudo prompt
    sudo su

    ### update
    apt-get update

    ### install emacs
    apt-get install -y emacs
    
    ### create log file
    LOG="/home/ubuntu/.DNASeq.install_log.txt"
    touch $LOG

    ### set proxy vars
    echo "Acquire::http::Proxy \"http://cloud-proxy:3128\"" >> /etc/apt/apt.conf.d/01Proxy # returns error # E: Syntax error /etc/apt/apt.conf.d/01Proxy:4: Extra junk at end of file
    echo "Acquire::http::Proxy \"http://cloud-proxy:3128\"" >> /etc/apt/apt.conf.d/01Proxy # returns error # see line above
    export http_proxy=http://cloud-proxy:3128; export https_proxy=http://cloud-proxy:3128
    
    ### create scratch space, and space for tar'ed images that will be downloaded
    chown 777 /mnt
    mkdir -p /mnt/SCRATCH
    mkdir -p /mnt/SCRATCH/images
    mkdir -p /mnt/SCRATCH/tmp
    mkdir -p /mnt/SCRATCH/coclean
    mkdir -p /mnt/SCRATCH/grch38
    mkdir -p /mnt/SCRATCH/genoMel_harmon
    cd ~
    ln -s /mnt/SCRATCH/ SCRATCH

    # copy accessory files
    cd ~
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/virtualenvs.tar.gz --no-check-certificate
    tar -xzf virtualenvs.tar.gz
    rm virtualenvs.tar.gz
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/cocleaning-cwl.tar.gz --no-check-certificate
    tar -xzf cocleaning-cwl.tar.gz
    rm cocleaning-cwl.tar.gz
    cd /mnt/SCRATCH/images
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/bam_readgroup_to_json.tar --no-check-certificate
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/fastqc_db.tar --no-check-certificate
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/readgroup_json_db.tar --no-check-certificate
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/bam_reheader.tar --no-check-certificate
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/fastqc_tool.tar --no-check-certificate
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/samtools_tool.tar --no-check-certificate
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/biobambam_tool.tar --no-check-certificate
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/merge_sqlite.tar --no-check-certificate
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/bwa_tool.tar --no-check-certificate
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/picard_tool.tar --no-check-certificate
    cd /mnt/SCRATCH/coclean
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/dbsnp_144.hg38.vcf.gz --no-check-certificate
    cd /mnt/SCRATCH/grch38
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/GRCh38.d1.vd1.fa --no-check-certificate
    cd /mnt/SCRATCH/genoMel_harmon
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/genoMel.KHP_4.json --no-check-certificate
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/genoMel.GDNA_50.json --no-check-certificate
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/CTRL_NA12878_CL_UNK_GDNA_50_NA.bam --no-check-certificate
    wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/CTRL_NA12878_GDNA_HSV4_KHP_4.bam --no-check-certificate

    ### copy images from cleversafe to /mnt/SCRATCH/images
    # did this by hand for now -- are in PDC /home/KKEEGAN/temp/genomel_DNASeq_dockers.7-25-16
    # think I can host them on genomel cleversafe -- or public versions of dockers on a repo with version control/tagging but does not require auth?
 
    ### (1) install current version of docker
    aptitude install -y apt-transport-https ca-certificates
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list
    aptitude update && aptitude install -y docker-engine       
    mkdir -p /mnt/SCRATCH/docker
    touch /home/ubuntu/.dockercfg        # added to fix error line below? 
    chown ubuntu /home/ubuntu/.dockercfg # error # No such file or directory # this file is probably not needed
    gpasswd -a ubuntu docker
    echo "DOCKER_OPTS=\"--dns 8.8.8.8 --dns 8.8.4.4 -g /mnt/SCRATCH/docker/\"" >> /etc/default/docker
    echo "export http_proxy=http://cloud-proxy:3128; export https_proxy=http://cloud-proxy:3128" >> /etc/default/docker
    #service docker restart # Kevin edit 
    exit # exit sudo
    exit # LOGOUT  

    # print something to log
    echo "PHASE I complete, one more to go" >> $LOG
    
    ### ---> AT THIS POINT LOG BACK IN <--- ###


    ### run docker daemon
    sudo restart docker
    
    ### install the images
    cd /mnt/SCRATCH/images
    for i in `ls`; do sudo docker load -i $i; echo "loaded $i"; done;
    cd ~
    
    ### (2) On VM, ensure virtualenvwrapper and nodejs are installed:
    sudo su
    apt-get update && apt-get install -y virtualenvwrapper nodejs
    exit
    
    ### (3) configure virtualenvwrapper
    echo "source /usr/share/virtualenvwrapper/virtualenvwrapper.sh" >> ~/.bashrc

    ### (4) enable proxy to access pypi.org (non sudo)
    export http_proxy=http://cloud-proxy:3128; export https_proxy=http://cloud-proxy:3128

    ### (5) --- alternative step 5
    # (5) Instead of step 5, on 172.16.165.255, do
    rsync -av --progress .virtualenvs new_vm
    
    # (6) When virtualenv is first created (3), the vitualenv will be activated. To activate virtualenv on later login sessions:
    workon cwl
    
    ### (7) upgrade pip
    sudo -E pip install --upgrade pip

    ### (8-10) Skip steps 8-9, 10 is edited below

    ### (10) Instead of step 10, on 172.16.165.255, do
    rsync -av --progress cocleaning-cwl new_vm

    ### (11) Make dir to store harmonized data
    mkdir -p /mnt/SCRATCH/genoMel_harmon
    cd /mnt/SCRATCH/genoMel_harmon

    ### (12) Run workflow (HERE FOR REFERENCE ONLY)
    # # see genomel_boto.7-20-16 for using boto to get sample data from cleversafe
    # workon cwl
    # cd /mnt/SCRATCH/genoMel_harmon
    # nohup cwltool --tmpdir-prefix /mnt/SCRATCH/tmp/ --tmp-outdir-prefix /mnt/SCRATCH/tmp/  --debug ~/cocleaning-cwl/workflows/dnaseq/dnaseq_workflow.cwl.yaml  genoMel.KHP_4.json 2> DNASeq_install.error.log.txt &
    # # for example file 1
    # nohup cwltool --tmpdir-prefix /mnt/SCRATCH/tmp/ --tmp-outdir-prefix /mnt/SCRATCH/tmp/  --debug ~/cocleaning-cwl/workflows/dnaseq/dnaseq_workflow.cwl.yaml  genoMel.GDNA_50.json 2> DNASeq_install.error.log.txt &
    
else
    echo "It looks as though install already ran, delete ~/.DNASeq.install_log.txt and try again if you wish to run this installer"
fi


# ran this successfully -- with the corrected files









Fix up Docker

$ sudo su
## ensure following lines in /etc/apt/apt.conf.d/01Proxy:
          Acquire::http::Proxy "http://cloud-proxy:3128";
          Acquire::https::Proxy "http://cloud-proxy:3128";
# mkdir /mnt/SCRATCH
# chown 777 /mnt/SCRATCH
# aptitude install apt-transport-https ca-certificates
# export http_proxy=http://cloud-proxy:3128; export https_proxy=http://cloud-proxy:3128
# apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
# echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list
# aptitude update && aptitude install docker-engine -y
# mkdir /mnt/SCRATCH/docker
# chown ubuntu /home/ubuntu/.dockercfg
# gpasswd -a ubuntu docker
# echo "DOCKER_OPTS=\"--dns 8.8.8.8 --dns 8.8.4.4 -g /mnt/SCRATCH/docker/\"" >> /etc/default/docker
# echo "export http_proxy=http://cloud-proxy:3128; export https_proxy=http://cloud-proxy:3128" >> /etc/default/docker
# service docker restart
# exit
$ exit (only gain group access to docker when exit/login)
On VM, ensure virtualenvwrapper and nodejs are installed:

$ sudo su -
# apt-get update && apt-get install virtualenvwrapper nodejs -y
# exit
configure virtualenvwrapper

$ grep virtualenvwrapper.sh ~/.bashrc
if there is no result:
      $ echo "source /usr/share/virtualenvwrapper/virtualenvwrapper.sh" >> ~/.bashrc
      $ exit
enable proxy to access pypi.org

$ export http_proxy=http://cloud-proxy:3128; export https_proxy=http://cloud-proxy:3128;
create a virtualenv for cwltool

$ mkvirtualenv --python /usr/bin/python2 cwl
When virtualenv is first created (3), the vitualenv will be activated. To activate virtualenv on later login sessions:

$ workon cwl
To deactive a virtualenv:
      $ deactivate
upgrade pip

$ pip install --upgrade pip
get the CDIS patched version of cwltool

$ wget https://github.com/jeremiahsavage/cwltool/archive/0.1.tar.gz
install cwltool and its dependencies

$ pip install 0.1.tar.gz --no-cache-dir
get the DNASeq CWL Workflow

$ cd ${HOME}
$ git clone git@github.com:NCI-GDC/cocleaning-cwl.git
$ cd cocleaning-cwl/
$ git checkout feat/dnaseq_workflow
Make dir to store harmonized data

$ mkdir -p /mnt/SCRATCH/genoMel_harmon
$ cd /mnt/SCRATCH/genoMel_harmon
Run workflow

$  cwltool --tmpdir-prefix /mnt/SCRATCH/tmp/ --tmp-outdir-prefix /mnt/SCRATCH/tmp/  --debug ~/cocleaning-cwl/workflows/dnaseq/dnaseq_workflow.cwl.yaml  ~/cocleaning-cwl/workflows/dnaseq/genoMel.json
