#!/bin/bash                                                                                                                                          
my_log="/home/ubuntu/startup_log.txt"
done_file="/home/ubuntu/done.txt"

if [ ! -f ${done_file} ]; then

    # prevent ssh login while setup is underway
    echo "PREVEN SSH LOGIN" >> ${my_log};
    sudo groupadd sshuser;
    sudo usermod -G sshuser -a root;
    sudo echo AllowGroups sshuser >> /etc/ssh/sshd_config;
    sudo service ssh restart

    # create and set permissions for directories on the VM
    sudo chown ubuntu:ubuntu -R /mnt
    sudo chown ubuntu:ubuntu -R /home/ubuntu/.docker
    
    sudo mkdir -p /mnt/tmp
    sudo mkdir -p /mnt/tmp/cwl
    sudo mkdir -p /mnt/dockers
    sudo mkdir -p /mnt/ref_data
    sudo mkdir -p /mnt/example_data
    sudo mkdir -p /mnt/example_data/giab_data
    
    sudo chmod -R 777 /mnt
    sudo chmod -R 777 /tmp
    
    if [ ! -L /tmp ]; then
	sudo ln -s /mnt/tmp /tmp
    fi
    
    # get ref data                                                                                                                                   
    ## mkdir -p /mnt/ref_data
    cd /mnt/ref_data
    sudo -u ubuntu aws s3 sync s3://genomel_pipe_ref_data/ . --endpoint-url https://bionimbus-objstore.opensciencedatacloud.org --profile genomel
    sudo -u ubuntu aws s3 sync s3://BAM_recalibration_ref_data.10-3-16/ . --endpoint-url https://bionimbus-objstore.opensciencedatacloud.org --profile genomel
    sudo -u ubuntu aws s3 sync s3://BAM_recalibration_ref_data.10-11-16/ . --endpoint-url https://bionimbus-objstore.opensciencedatacloud.org --profile genomel
    sudo -u ubuntu aws s3 sync s3://kevin_ref_data/ . --endpoint-url https://bionimbus-objstore.opensciencedatacloud.org --profile genomel

    # additional ref data
    # - Francisco two different index files -- placed in 
    # - Shenglai - new yaml (not his, genomel)


    echo "DOWNLOADED REF DATA" >> ${my_log};
    # get example data                                                                                                                               
    ## mkdir -p /mnt/example_data
    cd /mnt/example_data
    sudo -u ubuntu aws s3 sync s3://kevin_example_data . --endpoint-url https://bionimbus-objstore.opensciencedatacloud.org --profile genomel
    echo "DOWNLOADED (non GIAB) EXAMPLE DATA" >> ${my_log};
    cd /mnt/example_data/giab_data
    sudo -u ubuntu aws s3 sync s3://giab_data . --endpoint-url https://bionimbus-objstore.opensciencedatacloud.org --profile genomel
    echo "DOWNLOADED GIAB EXAMPLE DATA" >> ${my_log};
    # get and install dockers                                                                                                                        
    ## mkdir -p /mnt/dockers
    cd /mnt/dockers
    sudo -u ubuntu aws s3 sync s3://docker_images . --endpoint-url https://bionimbus-objstore.opensciencedatacloud.org --profile genomel
    #sudo -u ubuntu docker load -i /mnt/dockers/genomel-primary-analysis_0.1b.tar
    #sudo -u ubuntu docker tag 9dc9cd99cd9f registry.gitlab.com/uc-cdis/genomel-primary-analysis:0.1b
    sudo -u ubuntu docker load -i /mnt/dockers/genomel-primary-analysis_0.1d.tar
    sudo -u ubuntu docker tag 51bec18ce86f registry.gitlab.com/uc-cdis/genomel-primary-analysis:0.1d
    sudo -u ubuntu docker load -i /mnt/dockers/genomel-secondary-analysis_0.1a.tar
    sudo -u ubuntu docker tag 9e18436e398a registry.gitlab.com/uc-cdis/genomel-secondary-analysis:0.1a
    sudo -u ubuntu docker load -i /mnt/dockers/genomel-exome-variant-detection_0.1b.tar
    sudo -u ubuntu docker tag 5ded84a25098 registry.gitlab.com/uc-cdis/genomel-exome-variant-detection:0.1b
    sudo -u ubuntu docker load -i /mnt/dockers/genomel-exome-variant-detection_0.1c.tar
    sudo -u ubuntu docker tag e9f9fc116918 registry.gitlab.com/uc-cdis/genomel-exome-variant-detection:0.1c
    sudo -u ubuntu docker load -i /mnt/dockers/genomel-compare-vcf.tar
    sudo -u ubuntu docker tag 27428453b9f6 registry.gitlab.com/uc-cdis/genomel-compare-vcf:0.1

    echo "DOWNLOADED AND LOADED DOCKERS" >> ${my_log};
    # perform clone or pull the cwl repo as needed                                                                                                   
    if [ ! -d /home/ubuntu/cwl ]; then
        export https_proxy=http://cloud-proxy:3128
        cd /home/ubuntu
        git clone https://github.com/uc-cdis/cwl.git
        unset https_proxy
    else
        export https_proxy=http://cloud-proxy:3128
        cd /home/ubuntu/cwl
        git pull
        unset https_proxy
    fi
    # cleanup
    rm -R /mnt/dockers;
    rm -R /home/ubuntu/.aws;
    echo "PERFORMED CLEANUP" >> ${my_log};
    usermod -G sshuser -a ubuntu
    echo "ALLOW SSH LOGIN" >> ${my_log};
    touch ${done_file}
    echo "REBOOTING" >> ${my_log};
    sudo reboot
fi

# my_log="/home/ubuntu/startup_log.txt"
# touch ${my_log}
# sudo chmod 777 ${my_log}
# echo "Started $0 `date`" >> ${my_log}
# /home/ubuntu/genomel_vm_config.sh >> ${my_log} 2>&1;
# echo -e "\n\nFinished $0 `date`" >> ${my_log}
