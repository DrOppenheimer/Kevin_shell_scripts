#!/bin/bash
if [ ! -d /mnt/ref_data ]; then
    # set permissions for /mnt and create link /tmp to /mnt/tmp
    sudo chown ubuntu:ubuntu /mnt
    sudo chown ubuntu:ubuntu -R /home/ubuntu/.docker
    mkdir -p /mnt/tmp
    ln -s /mnt/tmp /tmp
    echo "EDITED /mnt" >> /home/ubuntu/some_log.txt;
    # get ref data
    mkdir -p /mnt/ref_data
    cd /mnt/ref_data
    aws s3 sync s3://genomel_pipe_ref_data/ . --endpoint-url https://bionimbus-objstore.opensciencedatacloud.org --profile genomel
    aws s3 sync s3://BAM_recalibration_ref_data.10-3-16/ . --endpoint-url https://bionimbus-objstore.opensciencedatacloud.org --profile genomel
    aws s3 sync s3://kevin_ref_data/ . --endpoint-url https://bionimbus-objstore.opensciencedatacloud.org --profile genomel
    echo "DOWNLOADED REF DATA" >> /home/ubuntu/some_log.txt;
    # get example data
    mkdir -p /mnt/example_data
    cd /mnt/example_data
    aws s3 sync s3://kevin_example_data . --endpoint-url https://bionimbus-objstore.opensciencedatacloud.org --profile genomel
    echo "DOWNLOADED EXAMPLE DATA" >> /home/ubuntu/some_log.txt;
    # get and install dockers
    mkdir -p /mnt/dockers
    cd /mnt/dockers
    aws s3 sync s3://docker_images . --endpoint-url https://bionimbus-objstore.opensciencedatacloud.org --profile genomel
    sudo docker load -i /mnt/dockers/genomel-primary-analysis_0.1a.tar
    sudo docker tag d8567a99d120 registry.gitlab.com/uc-cdis/genomel-primary-analysis_0.1a
    sudo docker load -i /mnt/dockers/genomel-secondary-analysis_0.1a.tar
    sudo docker tag 9e18436e398a registry.gitlab.com/uc-cdis/genomel-secondary-analysis_0.1a
    sudo docker load -i /mnt/dockers/genomel-exome-variant-detection_0.1c.tar
    sudo docker tag e9f9fc116918 registry.gitlab.com/uc-cdis/genomel-exome-variant-detection_0.1c
    echo "DOWNLOADED AND LOADED DOCKERS" >> /home/ubuntu/some_log.txt;
    # cleanup
    sudo rm -R /mnt/dockers
    sudo rm -R /home/ubuntu/.aws
    echo "PERFORMED CLEANUP" >> /home/ubuntu/some_log.txt;
fi
