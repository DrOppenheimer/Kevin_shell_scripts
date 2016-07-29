#!/bin/bash
LOG="/home/ubuntu/.DNASeq.install_log.txt"

chmod -R 777 /mnt
mkdir -p /mnt/SCRATCH
mkdir -p /mnt/SCRATCH/images
mkdir -p /mnt/SCRATCH/tmp
mkdir -p /mnt/SCRATCH/coclean
mkdir -p /mnt/SCRATCH/grch38
mkdir -p /mnt/SCRATCH/genoMel_harmon
cd ~
ln -s /mnt/SCRATCH/ SCRATCH

### create log file
touch $LOG
chmod 777 $LOG

### set proxy vars
export http_proxy=http://cloud-proxy:3128; export https_proxy=http://cloud-proxy:3128
#echo "export http_proxy=http://cloud-proxy:3128; export https_proxy=http://cloud-proxy:3128" >> ~/.profile

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
cd /mnt/SCRATCH/
wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/grch38.tar.gz --no-check-certificate
tar -xzf grch38.tar.gz
rm grch38.tar.gz
cd /mnt/SCRATCH/genoMel_harmon
wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/genoMel.KHP_4.json --no-check-certificate
wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/genoMel.GDNA_50.json --no-check-certificate
wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/CTRL_NA12878_CL_UNK_GDNA_50_NA.bam --no-check-certificate
wget https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data/CTRL_NA12878_GDNA_HSV4_KHP_4.bam --no-check-certificate

### copy images from cleversafe to /mnt/SCRATCH/images
# did this by hand for now -- are in PDC /home/KKEEGAN/temp/genomel_DNASeq_dockers.7-25-16
# think I can host them on genomel cleversafe -- or public versions of dockers on a repo with version control/tagging but does not require auth?

### (1) install current version of docker
#aptitude install -y apt-transport-https ca-certificates
apt-key adv --keyserver http://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install htop docker-engine virtualenvwrapper nodejs
mkdir -p /mnt/SCRATCH/docker
usermod -G docker -a ubuntu
echo "DOCKER_OPTS=\"--dns 8.8.8.8 --dns 8.8.4.4 -g /mnt/SCRATCH/docker/\"" >> /etc/default/docker
echo "export http_proxy=http://cloud-proxy:3128; export https_proxy=http://cloud-proxy:3128" >> /etc/default/docker


### run docker daemon
service docker restart

### install the images
cd /mnt/SCRATCH/images
for i in `ls`; do sudo docker load -i $i; echo "loaded $i"; done;
cd ~

### (3) configure virtualenvwrapper
echo "source /usr/share/virtualenvwrapper/virtualenvwrapper.sh" >> ~/.bashrc
source ~/.bashrc


### (5) --- alternative step 5
# (5) Instead of step 5, on 172.16.165.255, do
cd ~
rsync -av --progress .virtualenvs new_vm

# (6) When virtualenv is first created (3), the vitualenv will be activated. To activate virtualenv on later login sessions:
workon cwl

### (7) upgrade pip
pip install --upgrade pip

### (8-10) Skip steps 8-9, 10 is edited below

### (10) Instead of step 10, on 172.16.165.255, do
rsync -av --progress cocleaning-cwl new_vm
