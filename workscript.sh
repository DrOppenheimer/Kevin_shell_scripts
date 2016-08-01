#!/bin/bash
LOG="/home/ubuntu/.DNASeq.install_log.txt"

chmod -R 777 /mnt
mkdir -p /mnt/SCRATCH
mkdir -p /mnt/SCRATCH/tmp
mkdir -p /mnt/SCRATCH/grch38
cd ~
ln -s /mnt/SCRATCH/ SCRATCH


### create log file
touch $LOG
chmod 777 $LOG
echo "DNASeq_not_ready_yet" >> $LOG

### set proxy vars
export http_proxy=http://cloud-proxy:3128; export https_proxy=http://cloud-proxy:3128
#echo "export http_proxy=http://cloud-proxy:3128; export https_proxy=http://cloud-proxy:3128" >> ~/.profile

GRIFFIN=https://griffin-objstore.opensciencedatacloud.org/genome_supplemental_data

# copy accessory files
TARGET=/home/ubuntu
mkdir -p $TARGET
for f in virtualenvs.tar.gz cocleaning-cwl.tar.gz
do
	curl -k $GRIFFIN/$f -o $TARGET/$f
	tar -C /home/ubuntu -xzf $TARGET/$f && rm -f /home/ubuntu/$f
done

TARGET=/mnt/SCRATCH/images
mkdir -p $TARGET
for f in bam_readgroup_to_json.tar fastqc_db.tar readgroup_json_db.tar bam_reheader.tar fastqc_tool.tar samtools_tool.tar biobambam_tool.tar merge_sqlite.tar bwa_tool.tar picard_tool.tar
do
	curl -k $GRIFFIN/$f -o $TARGET/$f
done

TARGET=/mnt/SCRATCH/coclean
mkdir -p $TARGET
curl -k $GRIFFIN/dbsnp_144.hg38.vcf.gz -o $TARGET/dbsnp_144.hg38.vcf.gz

TARGET=/mnt/SCRATCH/
mkdir -p $TARGET
curl -k $GRIFFIN/grch38.tar.gz -o $TARGET/grch38.tar.gz
tar -C $TARGET -xzf $TARGET/grch38.tar.gz && rm $TARGET/grch38.tar.gz

TARGET=/mnt/SCRATCH/genoMel_harmon
mkdir -p $TARGET
for f in genoMel.KHP_4.json genoMel.GDNA_50.json CTRL_NA12878_CL_UNK_GDNA_50_NA.bam CTRL_NA12878_GDNA_HSV4_KHP_4.bam
do
	curl -k $GRIFFIN/$f -o $TARGET/$f
done

chown -R ubuntu:ubuntu /mnt/SCRATCH

### copy images from cleversafe to /mnt/SCRATCH/images
# did this by hand for now -- are in PDC /home/KKEEGAN/temp/genomel_DNASeq_dockers.7-25-16
# think I can host them on genomel cleversafe -- or public versions of dockers on a repo with version control/tagging but does not require auth?

### (1) install current version of docker
apt-get install -y apt-transport-https ca-certificates
apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y htop docker-engine virtualenvwrapper nodejs
mkdir -p /mnt/SCRATCH/docker
usermod -G docker -a ubuntu
echo "DOCKER_OPTS=\"--dns 8.8.8.8 --dns 8.8.4.4 -g /mnt/SCRATCH/docker/\"" >> /etc/default/docker
echo "export http_proxy=http://cloud-proxy:3128; export https_proxy=http://cloud-proxy:3128" >> /etc/default/docker


### run docker daemon
service docker restart

### install the images
for i in /mnt/SCRATCH/images/*; do sudo docker load -i $i; echo "loaded $i"; done;

su - ubuntu -c 'rsync -av /home/ubuntu/cocleaning-cwl /home/ubuntu/new_vm'
su - ubuntu -c 'rsync -av /home/ubuntu/.virtualenvs /home/ubuntu/new_vm'


### (3) configure virtualenvwrapper
echo "source /usr/share/virtualenvwrapper/virtualenvwrapper.sh" >> /home/ubuntu/.bashrc
su - ubuntu -c 'source /usr/share/virtualenvwrapper/virtualenvwrapper.sh;workon cwl;pip install --upgrade pip'

echo "Installer completed" >> $LOG

echo touch "DNASeq_is_ready" >> $LOG

sudo reboot

