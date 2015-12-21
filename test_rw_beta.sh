#!/bin/bash

# number of times to perform the operation
NUMREPEATS=2;
MYLOG="rw_log.txt";
MYBUCKET="test_bucket"
PARCELSERVERIPPORT="192.170.232.76:9000";
PARCELLOCALHOSTPORT="parcel.opensciencedatacloud.org:9000"



#FILE1="ERR188416_2.fastq.gz"
FILE0="ERR_tar.12Mb.gz"
FILE1="ERR_tar.1Gb.gz"
FILE2="ERR_tar.11Gb.gz"
FILE3="ERR_tar.59Gb.gz"

DENOM=`echo 2^30 | bc` # i.e. bytes in GB

echo -e "# test_rw.sh log\t"`date` > $MYLOG
echo -e "# File\tDate_stamp\tsize(Gb)\tOperation\tTransfer_time\tTransfer_rate(Gb/s)\tRepeat" >> $MYLOG 

# upload file 1 (no parcel)

# FUNCTION DEFS

# function to upload data (using s3cmd sync without parcel)
upload_file(){
    BUCKET=$1
    FILE=$2
    NUMREPEATS=$3
    LOG=$4
    DENOM=$5
    OPERATION="s3cmd_sync.download_without_parcel"

    # check to make sure the file exists locally, if not, exit
    if [[ -e $FILE ]]; then
	echo -e "$\n$FILE exists locally, proceeding to upload\n"
    else
	echo -e "\n$FILE Does not exist locally\n" >> $LOG
	echo -e "\n$FILE Does not exist locally\n"
	exit 1 
    fi

    # Perform upload NUMREPEAT times
    for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
    do
	
	# delete the file in the bucket if it already exists in the bucket
	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
	if [[ $file_check -gt 0 ]]; then
	    s3cmd del s3://$BUCKET/$FILE
	    echo -e "\n$FILE exists in bucket, delete before proceeding with upload\n"
	fi
	my_size=`ls -ltr $FILE | cut -d " " -f 5`
	my_size_gb=`echo "$my_size/$DENOM"|bc -l`
	START_TIME=$SECONDS
	#s3cmd sync -P ./$FILE s3://$BUCKET/
	s3cmd put -P ./$FILE s3://$BUCKET/ # note - upload is -P -- public access
	ELAPSED_TIME=$(($SECONDS - $START_TIME))
	my_transfer_rate=`echo "$my_size_gb/$ELAPSED_TIME"|bc -l`
	echo -e $FILE"\t"`date`"\t"$my_size_gb"\t"$OPERATION"\t"$ELAPSED_TIME"\t"$my_transfer_rate"\t"$i >> $LOG

	# delete the uploaded file every iteration except the last
	if [[ $i -lt $NUMREPEATS ]]; then
	    s3cmd del s3://$BUCKET/$FILE    
	fi

    done
}

# function to download data (using s3cmd get without parcel)
download_file(){
    BUCKET=$1
    FILE=$2
    NUMREPEATS=$3
    LOG=$4
    DENOM=$5
    OPERATION="s3cmd_get.download_without_parcel"

    # check to make sure the file does not exist locally, delete it if it does
    if [[ -e $FILE ]]; then
	rm $FILE
	echo -e "\nDeleted $FILE (locally) before proceeding with download from the bucket\n"
    else
	echo -e "\n$FILE is not present locally, proceeding with download from the bucket.\n"
    fi

    # Perform download NUMREPEAT times
    for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
    do

	# check to make sure the file exists before downloading
	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
	if [[ $file_check -gt 0 ]]; then
	    #s3cmd get s3://Onel_lab/test
	    START_TIME=$SECONDS
	    echo -e "\nRunning \"s3cmd get s3://$BUCKET/$FILE\"\n"
	    s3cmd get s3://$BUCKET/$FILE
	    ELAPSED_TIME=$(($SECONDS - $START_TIME))
	    my_transfer_rate=`echo "$my_size_gb/$ELAPSED_TIME"|bc -l`
	    my_size=`ls -ltr $FILE | cut -d " " -f 5`
	    my_size_gb=`echo "$my_size/$DENOM"|bc -l`
	    echo -e $FILE"\t"`date`"\t"$my_size_gb"\t"$OPERATION"\t"$ELAPSED_TIME"\t"$my_transfer_rate"\t"$i >> $LOG
	else
	    echo -e $FILE"\tERROR, file does not exist in bucket: "$BUCKET >> $LOG 
	fi

	# delete the local file every iteration except the last
	if [[ $i -lt $NUMREPEATS ]]; then
	    rm $FILE
	fi
	
    done
}



########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################

# # function to upload data (using wput with parcel)
# upload_file_wp(){
#     BUCKET=$1
#     FILE=$2
#     NUMREPEATS=$3
#     LOG=$4
#     DENOM=$5
#     PARCELSERVERIPPORT=$6
#     PARCELLOCALHOSTPORT=$7
#     OPERATION="wget.download_with_parcel"


#     curl -X PUT -T $FILE \
# 	     -H "Host: $bucket.s3.amazonaws.com" \
# 	     #-H "Date: $date" \
# 	     #-H "Content-Type: $content_type" \
# 	     -H "x-amz-acl:public-read" \
# 	     -H "Authorization: AWS ${S3KEY}:$signature" \
# 	     "https://$bucket.s3.amazonaws.com$aws_path$file"



#     wget https://parcel.opensciencedatacloud.org:9000/asgc-geuvadis/ERR188021.tar.gz
    
#     function putS3
#     {
# 	path=$1
# 	file=$2
# 	aws_path=$3
# 	bucket='my-aws-bucket'
# 	date=$(date +"%a, %d %b %Y %T %z")
# 	acl="x-amz-acl:public-read"
# 	content_type='application/x-compressed-tar'
# 	string="PUT\n\n$content_type\n$date\n$acl\n/$bucket$aws_path$file"
# 	signature=$(echo -en "${string}" | openssl sha1 -hmac "${S3SECRET}" -binary | base64)
# 	curl -X PUT -T "$path/$file" \
# 	     -H "Host: $bucket.s3.amazonaws.com" \
# 	     -H "Date: $date" \
# 	     -H "Content-Type: $content_type" \
# 	     -H "$acl" \
# 	     -H "Authorization: AWS ${S3KEY}:$signature" \
# 	     "https://$bucket.s3.amazonaws.com$aws_path$file"
#     }

    
#     # start the parcel service
#     echo -e "\nparcel sever_port: "$PARCELSERVERIPPORT"\n"
#     parcel-tcp2udt $PARCELSERVERIPPORT &
#     parcel-udt2tcp $PARCELLOCALHOSTPORT &
    
#      # check to make sure the file exists locally, delete it if it does
#     if [[ -e $FILE ]]; then
# 	rm $FILE
# 	echo -e "\nDeleting $FILE (locally) before proceeding with download from the bucket\n"
#     else
# 	echo -e "\n$FILE is not present locally, proceeding with download from the bucket.\n"
#     fi

#     # Perform test NUMREPEAT times
#     for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
#     do
	
# 	# delete the file if it already exists in the bucket
# 	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
# 	if [[ $file_check -gt 0 ]]; then
# 	    s3cmd del s3://$BUCKET/$FILE
# 	    echo -e "\n$FILE exists in bucket, delete before proceeding with upload\n"
# 	fi



# for file in "$path"/*; do
#   putS3 "$path" "${file##*/}" "/path/on/s3/to/files/"
# done



	

# S3KEY="my aws key"
# S3SECRET="my aws secret" # pass these in

# ~/.s3cfg



# access_key=RNC0
# secret_key=bRb8osnG7rpvyof0
# host_bucket_name=asg
# host_base=griffin-objstore.opensciencedatacloud.org




# function putS3
# {
#   path=$1
#   file=$2
#   aws_path=$3
#   bucket='my-aws-bucket'
#   date=$(date +"%a, %d %b %Y %T %z")
#   acl="x-amz-acl:public-read"
#   content_type='application/x-compressed-tar'
#   string="PUT\n\n$content_type\n$date\n$acl\n/$bucket$aws_path$file"
#   signature=$(echo -en "${string}" | openssl sha1 -hmac "${S3SECRET}" -binary | base64)
#   curl -X PUT -T "$path/$file" \
#     -H "Host: $bucket.s3.amazonaws.com" \
#     -H "Date: $date" \
#     -H "Content-Type: $content_type" \
#     -H "$acl" \
#     -H "Authorization: AWS ${S3KEY}:$signature" \
#     "https://$bucket.s3.amazonaws.com$aws_path$file"
# }

# for file in "$path"/*; do
#   putS3 "$path" "${file##*/}" "/path/on/s3/to/files/"
# done
	

	

# 	# file=/path/to/file/to/upload.tar.gz
#         # bucket=your-bucket
#         # resource="/${bucket}/${file}"
# # contentType="application/x-compressed-tar"
# # dateValue=`date -R`
# # stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
# # s3Key=xxxxxxxxxxxxxxxxxxxx
# # s3Secret=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# # signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`
# # curl -X PUT -T "${file}" \
# #   -H "Host: ${bucket}.s3.amazonaws.com" \
# #   -H "Date: ${dateValue}" \
# #   -H "Content-Type: ${contentType}" \
# #   -H "Authorization: AWS ${s3Key}:${signature}" \
# #   https://${bucket}.s3.amazonaws.com/${file}





	
# 	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
# 	if [[ $file_check -gt 0 ]]; then
# 	    #s3cmd get s3://Onel_lab/test
# 	    START_TIME=$SECONDS
# 	    #s3cmd get s3://$BUCKET/$FILE
# 	    echo -e "\nRunning: \"wget https://$PARCELLOCALHOSTPORT/$MYBUCKET/$FILE\" \n"
# 	    wget https://$PARCELLOCALHOSTPORT/$MYBUCKET/$FILE
# 	    ELAPSED_TIME=$(($SECONDS - $START_TIME))
# 	    my_transfer_rate=`echo "$my_size_gb/$ELAPSED_TIME"|bc -l`
# 	    my_size=`ls -ltr $FILE | cut -d " " -f 5`
# 	    my_size_gb=`echo "$my_size/$DENOM"|bc -l`
# 	    echo -e $FILE"\t"`date`"\t"$my_size_gb"\t"$OPERATION"\t"$ELAPSED_TIME"\t"$my_transfer_rate"\t"$i >> $LOG
# 	else
# 	    echo -e $FILE"\tERROR, file does not exist in bucket: "$BUCKET >> $LOG 
# 	fi

# 	# delete the local file every iteration except the last
# 	if [[ $i -lt $NUMREPEATS ]]; then
# 	    rm $FILE
# 	fi
	
#     done

#     # Kill child process (parcel)
#     #kill $PPID
#     pkill -P $$
# }




# # file=/path/to/file/to/upload.tar.gz
# # bucket=your-bucket
# # resource="/${bucket}/${file}"
# # contentType="application/x-compressed-tar"
# # dateValue=`date -R`
# # stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
# # s3Key=xxxxxxxxxxxxxxxxxxxx
# # s3Secret=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# # signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`
# # curl -X PUT -T "${file}" \
# #   -H "Host: ${bucket}.s3.amazonaws.com" \
# #   -H "Date: ${dateValue}" \
# #   -H "Content-Type: ${contentType}" \
# #   -H "Authorization: AWS ${s3Key}:${signature}" \
# #   https://${bucket}.s3.amazonaws.com/${file}



########################################################################################
########################################################################################
########################################################################################
########################################################################################
########################################################################################


# function to download data (using wget with parcel)
download_file_wp(){
    BUCKET=$1
    FILE=$2
    NUMREPEATS=$3
    LOG=$4
    DENOM=$5
    PARCELSERVERIPPORT=$6
    PARCELLOCALHOSTPORT=$7
    OPERATION="wget.download_with_parcel"

    # kill parcel if it is already running
    #pkill parcel-tcp2udt
    #pkill parcel-udt2tcp
    pkill parcel-*
    sleep 5s
    # start the parcel service
    echo -e "\nparcel sever_port: "$PARCELSERVERIPPORT"\n"
    parcel-tcp2udt $PARCELSERVERIPPORT & # > ./parcel.log 2>&1 & # <--- script dies here
    sleep 5s
    parcel-udt2tcp $PARCELLOCALHOSTPORT &
    sleep 5s
    
     # check to make sure the file does not exist locally, delete it if it does
    if [[ -e $FILE ]]; then
	rm $FILE
	echo -e "\nDeleted $FILE (locally) before proceeding with download from the bucket\n"
    else
	echo -e "\n$FILE is not present locally, proceeding with download from the bucket.\n"
    fi

    # Perform test NUMREPEAT times
    for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
    do
	
	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
	if [[ $file_check -gt 0 ]]; then
	    #s3cmd get s3://Onel_lab/test
	    START_TIME=$SECONDS
	    #s3cmd get s3://$BUCKET/$FILE
	    echo -e "\nRunning: \"wget https://$PARCELLOCALHOSTPORT/$MYBUCKET/$FILE\" \n"
	    wget https://$PARCELLOCALHOSTPORT/$MYBUCKET/$FILE
	    ELAPSED_TIME=$(($SECONDS - $START_TIME))
	    my_transfer_rate=`echo "$my_size_gb/$ELAPSED_TIME"|bc -l`
	    my_size=`ls -ltr $FILE | cut -d " " -f 5`
	    my_size_gb=`echo "$my_size/$DENOM"|bc -l`
	    echo -e $FILE"\t"`date`"\t"$my_size_gb"\t"$OPERATION"\t"$ELAPSED_TIME"\t"$my_transfer_rate"\t"$i >> $LOG
	else
	    echo -e $FILE"\tERROR, file does not exist in bucket: "$BUCKET >> $LOG 
	fi

	# delete the local file every iteration except the last
	if [[ $i -lt $NUMREPEATS ]]; then
	    rm $FILE
	fi
	
    done

    # Kill child process (parcel)
    #kill $PPID
    #pkill -P $$
    pkill parcel*
}

# use s3 command
# create bucket that is public read/write?



# # function to upload data (using wput with parcel)
# upload_file_wp(){
#     BUCKET=$1
#     FILE=$2
#     NUMREPEATS=$3
#     LOG=$4
#     DENOM=$5
#     PARCELSERVERIPPORT=$6
#     PARCELLOCALHOSTPORT=$7
#     OPERATION="wget.download_with_parcel"

#     # start the parcel service
#     # parcel-tcp2udt 192.170.232.76:9000 &
#     echo -e "\nparcel sever_port: "$PARCELSERVERIPPORT"\n"
#     parcel-tcp2udt $PARCELSERVERIPPORT &# > ./parcel.log 2>&1 & # <--- script dies here
#     #PPID=$!
#     parcel-udt2tcp $PARCELLOCALHOSTPORT &
#     #PID_2=$!
    
#      # check to make sure the file exists locally, delete it if it does
#     if [[ -e $FILE ]]; then
# 	rm $FILE
# 	echo -e "\nDeleting $FILE (locally) before proceeding with download from the bucket\n"
#     else
# 	echo -e "\n$FILE is not present locally, proceeding with download from the bucket.\n"
#     fi

#     # Perform test NUMREPEAT times
#     for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
#     do
	
# 	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
# 	if [[ $file_check -gt 0 ]]; then
# 	    #s3cmd get s3://Onel_lab/test
# 	    START_TIME=$SECONDS
# 	    #s3cmd get s3://$BUCKET/$FILE
# 	    echo -e "\nRunning: \"wget https://$PARCELLOCALHOSTPORT/$MYBUCKET/$FILE\" \n"
# 	    wput https://$PARCELLOCALHOSTPORT/$MYBUCKET/$FILE
# 	    ELAPSED_TIME=$(($SECONDS - $START_TIME))
# 	    my_transfer_rate=`echo "$my_size_gb/$ELAPSED_TIME"|bc -l`
# 	    my_size=`ls -ltr $FILE | cut -d " " -f 5`
# 	    my_size_gb=`echo "$my_size/$DENOM"|bc -l`
# 	    echo -e $FILE"\t"`date`"\t"$my_size_gb"\t"$OPERATION"\t"$ELAPSED_TIME"\t"$my_transfer_rate"\t"$i >> $LOG
# 	else
# 	    echo -e $FILE"\tERROR, file does not exist in bucket: "$BUCKET >> $LOG 
# 	fi

# 	# delete the local file every iteration except the last
# 	if [[ $i -lt $NUMREPEATS ]]; then
# 	    rm $FILE
# 	fi
	
#     done

#     # Kill child process (parcel)
#     #kill $PPID
#     pkill -P $$
# }


###########################################################################
###########################################################################
###########################################################################

# # check to make sure the file exists locally, if not, exit
#     if [[ -e $FILE ]]; then
# 	echo -e "$\n$FILE exists locally, proceeding to upload\n"
#     else
# 	echo -e "\n$FILE Does not exist locally" >> $LOG
# 	exit 1 "$FILE Does not exist locally"
#     fi

#     # Perform test NUMREPEAT times
#     for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
#     do
	
# 	# delete the file if it already exists in the bucket
# 	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
# 	if [[ $file_check -gt 0 ]]; then
# 	    s3cmd del s3://$BUCKET/$FILE
# 	    echo -e "\n$FILE exists in bucket, delete before proceeding with upload\n"
# 	fi

###########################################################################
###########################################################################
###########################################################################
















# download_file_wp(){}


# start process and siave pid to kill it later
# foo &
# FOO_PID=$!
# # do other stuff
# kill $FOO_PID

# # Download and install parcel and its requirements:
# sudo apt-get install python-pip
# sudo python setup.py develop
# git clone https://github.com/LabAdvComp/parcel
# cd parcel
# sudo ./install
# # add this to known hosts
# sudo bash
# echo "127.0.0.1 parcel.opensciencedatacloud.org" >> /etc/hosts
# exit
# # start parcel in a terminal session:
# parcel-tcp2udt 192.170.232.76:9000
# # in another session, use curl, wget or the like -- this is a test -- address is for an S3 object in a bucket
# curl https://parcel.opensciencedatacloud.org:9000/imabucket/testobject.txt
##########
# # # From Satish 12-3-15 # INSTALLING AND USING PARCEL
# # # Install
# # python setup.py develop
# # sudo apt-get install python-pip
# # sudo python setup.py develop
# # 
# # # Setup
# # sudo vi /etc/hosts  - add 127.0.0.1 parcel.opensciencedatacloud.org
# # parcel-tcp2udt 192.170.232.76:9000 &
# # parcel-udt2tcp localhost:9000 &
# # wget https://parcel.opensciencedatacloud.org:9000/asgc-geuvadis/ERR188021.tar.gz
# # # so if u see here.. I have  'python setup.py develop' twice.. this is because it failed first and then I had to do a apt-get install python-pip








# MAIN

# Test with file1
#upload_file $MYBUCKET $FILE0 $NUMREPEATS $MYLOG $DENOM
#download_file $MYBUCKET $FILE0 $NUMREPEATS $MYLOG $DENOM
download_file_wp $MYBUCKET $FILE0 $NUMREPEATS $MYLOG $DENOM $PARCELSERVERIPPORT $PARCELLOCALHOSTPORT

#upload_file $MYBUCKET $FILE2 $NUMREPEATS $MYLOG $DENOM
#download_file $MYBUCKET $FILE2 $NUMREPEATS $MYLOG $DENOM
#download_file_wp $MYBUCKET $FILE2 $NUMREPEATS $MYLOG $DENOM $PARCELSERVERIPPORT $PARCELLOCALHOSTPORT

#upload_file $MYBUCKET $FILE3 $NUMREPEATS $MYLOG $DENOM
#download_file $MYBUCKET $FILE3 $NUMREPEATS $MYLOG $DENOM
#download_file_wp $MYBUCKET $FILE3 $NUMREPEATS $MYLOG $DENOM $PARCELSERVERIPPORT $PARCELLOCALHOSTPORT




# S3 set to public read
# -P, --acl-public      Store objects with ACL allowing read for anyone.




#for key in bucket.list():
#key.set_acl('public-read')



# for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
# do
#     file_check=`s3cmd ls s3://$MYBUCKET/$FILE1 | wc -l`
#     if [[ $file_check -gt 0 ]]; then
# 	s3cmd del s3://$MYBUCKET/$FILE1
#     fi
#     my_size=`ls -ltr $FILE1 | cut -d " " -f 5`
#     my_size_gb=`echo "$my_size/$DENOM"|bc -l`
#     START_TIME=$SECONDS
#     s3cmd sync ./$FILE1 s3://$MYBUCKET/
#     ELAPSED_TIME=$(($SECONDS - $START_TIME))
#     my_transfer_rate=`echo "$my_size_gb/$ELAPSED_TIME"|bc -l`
#     echo -e $FILE1"\t"$my_size_gb"\t"$ELAPSED_TIME"\t"$my_transfer_rate"\t"$i"\tN" >> $MYLOG
#     s3cmd del s3://$MYBUCKET/$FILE1
# done

# # upload file 2 (no parcel)
###upload_file $MYBUCKET $FILE2 $NUMREPEATS $MYLOG $DENOM
###download_file $MYBUCKET $FILE2 $NUMREPEATS $MYLOG $DENOM
# for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
# do
#     file_check=`s3cmd ls s3://$MYBUCKET/$FILE2 | wc -l`
#     if [[ $file_check -gt 0 ]]; then
# 	s3cmd del s3://$MYBUCKET/$FILE2
#     fi
#     my_size=`ls -ltr $FILE2 | cut -d " " -f 5`
#     my_size_gb=`echo "$my_size/$DENOM"|bc -l`
#     START_TIME=$SECONDS
#     s3cmd sync ./$FILE2 s3://$MYBUCKET/
#     ELAPSED_TIME=$(($SECONDS - $START_TIME))
#     my_transfer_rate=`echo "$my_size_gb/$ELAPSED_TIME"|bc -l`
#     echo -e $FILE2"\t"$my_size_gb"\t"$ELAPSED_TIME"\t"$my_transfer_rate"\t"$i"\tN" >> $MYLOG
#     s3cmd del s3://$MYBUCKET/$FILE2
# done

# # upload file 3 (no parcel)
### upload_file $MYBUCKET $FILE3 $NUMREPEATS $MYLOG $DENOM
### download_file $MYBUCKET $FILE3 $NUMREPEATS $MYLOG $DENOM
# for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
# do
#     file_check=`s3cmd ls s3://$MYBUCKET/$FILE3 | wc -l`
#     if [[ $file_check -gt 0 ]]; then
# 	s3cmd del s3://$MYBUCKET/$FILE3
#     fi
#     my_size=`ls -ltr $FILE3 | cut -d " " -f 5`
#     my_size_gb=`echo "$my_size/$DENOM"|bc -l`
#     START_TIME=$SECONDS
#     s3cmd sync ./$FILE3 s3://$MYBUCKET/
#     ELAPSED_TIME=$(($SECONDS - $START_TIME))
#     my_transfer_rate=`echo "$my_size_gb/$ELAPSED_TIME"|bc -l`
#     echo -e $FILE3"\t"$my_size_gb"\t"$ELAPSED_TIME"\t"$my_transfer_rate"\t"$i"\tN" >> $MYLOG
#     s3cmd del s3://$MYBUCKET/$FILE3
# done





















# make log name optional
# make wrapper script that supplies stream iterated log names



# for((i=1;i<100;i++)); do nohup bash script${i}.sh & done

# delete a non-empty bucket
# s3cmd del --recursive s3://bucket-to-delete

# delete file in bucket
# s3cmd del s3://test_bucket/ERR_tar.1Gb.gz
# File s3://test_bucket/ERR_tar.1Gb.gz deleted


# delete empty bucket
# s3cmd rb s3://logix.cz-test


# # upload

# s3cmd sync ./ERR_tar.1Gb.gz s3://test_bucket/



# # sudo apt-get install s3cmd

# # list the buckets
# s3cmd ls

# # list objects in bucket
# # s3cmd ls s3://BUCKET
# s3cmd ls s3://test_bucket

# # download a file
# # s3cmd get s3://BUCKET/OBJECT LOCAL_FILE
# s3cmd get s3://Onel_lab/test

# # upload
# # s3cmd sync LOCAL_DIR s3://BUCKET[/PREFIX] or s3://BUCKET[/PREFIX] LOCAL_DIR
# time s3cmd sync ./ERR_tar.1Gb.gz s3://test_bucket/


# process1 &
# process2 &
# process3 &
# process4 &
# wait
# process5 &
# process6 &
# process7 &
# process8 &
# wait

# # # From Satish 12-3-15 # INSTALLING AND USING PARCEL
# # # Install
# # python setup.py develop
# # sudo apt-get install python-pip
# # sudo python setup.py develop
# # # Setup
# # sudo vi /etc/hosts  - add 127.0.0.1 parcel.opensciencedatacloud.org
# # parcel-tcp2udt 192.170.232.76:9000 &
# # parcel-udt2tcp localhost:9000 &
# # wget https://parcel.opensciencedatacloud.org:9000/asgc-geuvadis/ERR188021.tar.gz
# # # so if u see here.. I have  'python setup.py develop' twice.. this is because it failed first and then I had to do a apt-get install python-pip

# START_TIME=$SECONDS
# dosomething
# ELAPSED_TIME=$(($SECONDS - $START_TIME))




# NUMSTREAMS=1

# echo "# test_rw.sh log\t"`date` > $MYLOG
# echo "# File\tsize(Gb)\tTransfer_time\tRepeat\tSTREAM\tParcel(?)" >> $MYLOG 

# for i in {1..$NUMREPEATS};
# do
#     for j in {1..$NUMSTREAMS};
#     do
	
# 	# upload file 1 (no parcel)
# 	export "my_size.${j}=`ls -ltr $FILE1 | cut -d " " -f 5`"
# 	export "my_size_gb.${j}=`echo $(($my_size / $DENOM))`"
# 	export "START_TIME.{j}=$SECONDS"
# 	s3cmd sync ./$FILE1 s3://$MYBUCKET/ &
# 	export "ELAPSED_TIME.{j}=$(($SECONDS - $START_TIME))"
	
#     done

#     wait

#     for j in {1..$NUMSTREAMS};
#     do

#     #loop to print outputs
#     echo $FILE1"\t"$my_size_gb.{$j}"\t"$ELAPSED_TIME"\t"$i"\t"$j"\tN" >> $MYLOG
    
# done









# # upload
# # s3cmd sync

# # three types of for iteration:
# # for i in 1 2 3 4 5
# # for i in {1..10}
# # for i in {0..10..2} # 1 to 10 by 2
