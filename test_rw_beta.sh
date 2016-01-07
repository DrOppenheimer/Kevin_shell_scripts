#!/bin/bash

# number of times to perform the operation
NUMREPEATS=5;
MYLOG="rw_results.txt";
ERRORLOG="rw_running_log.txt"
MYBUCKET="test_bucket"
PARCELSERVERIPPORT="192.170.232.76:9000";
PARCELLOCALHOSTPORT="parcel.opensciencedatacloud.org:9000"
ACCESSKEY="$ACCESSKEY"
SECRETKEY="$SECRETKEY"
GATEWAY="$GATEWAY"

echo "ACCESSKEY = $ACCESSKEY"
echo "SECRETKEY = $SECRETKEY"
echo "GATEWAY   = $GATEWAY"

# Here is a list of the protocol combinations that we want to be able to test
# I've creatd a function for each, then call them in the main section beneath
# the functions defs
# (1) Add s3cmd dl               # DONE
# (2) Add s3cmd ul               # DONE
# (3) Add s3cmd dl with parcel   # possible?
# (4) Add s3cmd ul with parcel   # possible?
# (5) Add wget dl                # possible? # under development 
# (6) Add wput ul                # possible?
# (7) Add wget dl with parcel    # DONE
# (8) Add wput ul with parcel    # possible?
# (9) Add boto dl                # DONE
# (10) Add boto ul               # DONE
# (11) Add boto dl with parcel   # DONE? # But ask a shell or parcel guru about weirdness with port argument in boto_dl.py
# (12) Add boto ul with parcel   # DONE? # But ask a shell or parcel guru about weirdness with port argument in boto_dl.py
# ...
# with udr?
# with rsync?

# Files to use for the upload and download tests
#FILE1="ERR188416_2.fastq.gz"
FILE0="ERR_tar.12Mb.gz"
FILE1="ERR_tar.1Gb.gz"
FILE2="ERR_tar.11Gb.gz"
#FILE3="ERR_tar.59Gb.gz"

# Insert a sub to check that all of the test files are already in the bucket, if not, get them from some other backup location
# There are backup copies of the files in s3://test_files/
# s3://test_bucket/ is used for the tests below

DENOMGB=`echo 2^30 | bc` # i.e. bytes in GB
DENOMMB=`echo 2^20 | bc` # i.e. bytes in MB

echo -e "# test_rw.sh log\t"`date` > $MYLOG
echo -e "# File\tDate_stamp\tsize(Gb)\tOperation\tTransfer_time\tTransfer_rate(Gb/s)\tTransfer_rate(Mb/s)\tRepeat" >> $MYLOG 

# upload file 1 (no parcel)
########################################################################################################
### FUNCTION DEFS
########################################################################################################

########################################################################################################
# (1) function to download data (using s3cmd get without parcel) # THIS WORKS
download_file_s3cmd(){

    echo "Performing download with s3cmd (no parcel)" >> $ERRORLOG
    
    BUCKET=$1
    FILE=$2
    NUMREPEATS=$3
    LOG=$4
    ERRORLOG=$5
    DENOMGB=$6
    DENOMMB=$7
    OPERATION="s3cmd_get.download_without_parcel"

    # check to make sure the file does not exist locally, delete it if it does
    if [[ -e $FILE ]]; then
	rm $FILE
	echo -e "Deleted $FILE (locally) before proceeding with download from the bucket" >> $ERRORLOG
    else
	echo -e "$FILE is not present locally, proceeding with download from the bucket." >> $ERRORLOG
    fi

    # Perform download NUMREPEAT times
    for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
    do

	# check to make sure the file exists before downloading
	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
	if [[ $file_check -gt 0 ]]; then
	    #s3cmd get s3://Onel_lab/test
	    #START_TIME=$SECONDS
	    START_TIME=`date +%s.%N`
	    echo -e "Running \"s3cmd get s3://$BUCKET/$FILE" >> $ERRORLOG
	    s3cmd get s3://$BUCKET/$FILE
	    FINISH_TIME=`date +%s.%N`
	    ELAPSED_TIME=`echo "$FINISH_TIME - $START_TIME" | bc -l`

	    my_size=`ls -ltr $FILE | cut -d " " -f 5`
	    my_size_gb=`echo "$my_size/$DENOMGB"| bc -l`
	    my_size_mb=`echo "$my_size/$DENOMMB"| bc -l`

	    my_transfer_rate_gps=`echo "$my_size_gb/$ELAPSED_TIME"| bc -l`
	    my_transfer_rate_mps=`echo "$my_size_mb/$ELAPSED_TIME"| bc -l`
	    echo -e $FILE"\t"`date`"\t"$my_size_gb"\t"$OPERATION"\t"$ELAPSED_TIME"\t"$my_transfer_rate_gps"\t"$my_transfer_rate_mps"\t"$i >> $LOG
	else
	    echo -e $FILE"\tERROR, file does not exist in bucket: "$BUCKET >> $ERRORLOG 
	fi

	# delete the local file every iteration except the last
	if [[ $i -lt $NUMREPEATS ]]; then
	    echo "REP $i DELETING $FILE LOCALLY" >> $ERRORLOG
	    rm $FILE
	fi
	
    done
}
########################################################################################################

########################################################################################################
# (2) function to upload data (using s3cmd sync without parcel) # THIS WORKS
upload_file_s3cmd(){
    BUCKET=$1
    FILE=$2
    NUMREPEATS=$3
    LOG=$4
    ERRORLOG=$5
    DENOMGB=$6
    DENOMMB=$7
    OPERATION="s3cmd_sync.upload_without_parcel"

    echo "Performing upload with s3cmd (no parcel)" >> $ERRORLOG

    # check to make sure the file exists locally, if not, exit
    if [[ -e $FILE ]]; then
	echo -e "$FILE exists locally, proceeding to upload" >> $ERRORLOG
    else
	echo -e "$FILE Does not exist locally: exiting" >> $ERRORLOG
	exit 1 
    fi

    # Perform upload NUMREPEAT times
    for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
    do
	
	# delete the file in the bucket if it already exists in the bucket
	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
	if [[ $file_check -gt 0 ]]; then
	    s3cmd del s3://$BUCKET/$FILE
	    echo -e "REP $i $FILE exists in bucket, delete before proceeding with upload"  >> $ERRORLOG
	fi

	my_size=`ls -ltr $FILE | cut -d " " -f 5`
	my_size_gb=`echo "$my_size/$DENOMGB"| bc -l`
	my_size_mb=`echo "$my_size/$DENOMMB"| bc -l`

	START_TIME=`date +%s.%N`
	#s3cmd sync -P ./$FILE s3://$BUCKET/
	s3cmd put -P ./$FILE s3://$BUCKET/ # note - upload is -P -- public access
	FINISH_TIME=`date +%s.%N`
	ELAPSED_TIME=`echo "$FINISH_TIME - $START_TIME" | bc -l`

	my_transfer_rate_gps=`echo "$my_size_gb/$ELAPSED_TIME"| bc -l`
	my_transfer_rate_mps=`echo "$my_size_mb/$ELAPSED_TIME"| bc -l`
	echo -e $FILE"\t"`date`"\t"$my_size_gb"\t"$OPERATION"\t"$ELAPSED_TIME"\t"$my_transfer_rate_gps"\t"$my_transfer_rate_mps"\t"$i >> $LOG

	# delete the uploaded file every iteration except the last
	if [[ $i -lt $NUMREPEATS ]]; then
	    echo "REP $i DELETING $FILE ON THE OBJECT STORE" >> $ERRORLOG
	    s3cmd del s3://$BUCKET/$FILE    
	fi

    done
}
########################################################################################################

########################################################################################################
# (3) function to download with s3cmd through parcel (Is this possible?)

########################################################################################################

########################################################################################################
# (4) function to upload with s3cmd through parcel (Is this possible?)

########################################################################################################

########################################################################################################
# (5) function to download with wget (no parcel) # This function doesn't work yet
# download_file_wget(){
#     BUCKET=$1
#     FILE=$2
#     NUMREPEATS=$3
#     LOG=$4
#     DENOM=$5
#     OPERATION="wget.download_without_parcel"

#     # kill parcel if it is already running
#     #pkill parcel-tcp2udt
#     #pkill parcel-udt2tcp
#     pkill parcel-*
#     sleep 5s
#     # start the parcel service
#     #echo -e "\nparcel sever_port: "$PARCELSERVERIPPORT"\n"
#     #parcel-tcp2udt $PARCELSERVERIPPORT & # > ./parcel.log 2>&1 & # <--- script dies here
#     #sleep 5s
#     #parcel-udt2tcp $PARCELLOCALHOSTPORT &
#     #sleep 5s
    
#      # check to make sure the file does not exist locally, delete it if it does
#     if [[ -e $FILE ]]; then
# 	rm $FILE
# 	echo -e "\nDeleted $FILE (locally) before proceeding with download from the bucket\n"
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
# 	    #echo -e "\nRunning: \"s3cmd get s3://$BUCKET/$FILE\" \n"
# 	    wget s3://$BUCKET/$FILE
# 	    #wget https://$PARCELLOCALHOSTPORT/$MYBUCKET/$FILE
# 	    # eg # wget https://parcel.opensciencedatacloud.org:9000/test_bucket/ERR_tar.12Mb.gz
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
    
# }

########################################################################################################

########################################################################################################
# (6) Upload with wput (no parcel)

########################################################################################################

########################################################################################################
# (7) Download with wget using parcel # THIS WORKS
download_file_wget_withp(){
    BUCKET=$1
    FILE=$2
    NUMREPEATS=$3
    LOG=$4
    ERRORLOG=$5
    DENOMGB=$6
    DENOMMB=$7
    PARCELSERVERIPPORT=$8
    PARCELLOCALHOSTPORT=$9
    OPERATION="wget.download_with_parcel"

    echo "Performing download with wget (with parcel)" >> $ERRORLOG

    # kill parcel if it is already running
    #pkill parcel-tcp2udt
    #pkill parcel-udt2tcp
    pkill parcel-*
    sleep 5s
    # start the parcel service
    echo -e "parcel sever_port: "$PARCELSERVERIPPORT >> $ERRORLOG
    parcel-tcp2udt $PARCELSERVERIPPORT & # > ./parcel.log 2>&1 & # <--- script dies here
    sleep 5s
    parcel-udt2tcp $PARCELLOCALHOSTPORT &
    sleep 5s
    
     # check to make sure the file does not exist locally, delete it if it does
    if [[ -e $FILE ]]; then
	rm $FILE
	echo -e "Deleted $FILE (locally) before proceeding with download from the bucket" >> $ERRORLOG
    else
	echo -e "$FILE is not present locally, proceeding with download from the bucket." >> $ERRORLOG
    fi

    # Perform test NUMREPEAT times
    for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
    do
	
	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
	if [[ $file_check -gt 0 ]]; then
	    #s3cmd get s3://Onel_lab/test
	    #START_TIME=$SECONDS

	    START_TIME=`date +%s.%N`
	    #s3cmd get s3://$BUCKET/$FILE
	    echo -e "\nRunning: \"wget https://$PARCELLOCALHOSTPORT/$MYBUCKET/$FILE\" \n"
	    wget https://$PARCELLOCALHOSTPORT/$MYBUCKET/$FILE
	    # eg # wget https://parcel.opensciencedatacloud.org:9000/test_bucket/ERR_tar.12Mb.gz
	    FINISH_TIME=`date +%s.%N`
	    ELAPSED_TIME=`echo "$FINISH_TIME - $START_TIME" |bc -l`

	    my_size=`ls -ltr $FILE | cut -d " " -f 5`
	    my_size_gb=`echo "$my_size/$DENOMGB"|bc -l`
	    my_size_mb=`echo "$my_size/$DENOMMB"|bc -l`
	    
	    my_transfer_rate_gps=`echo "$my_size_gb/$ELAPSED_TIME"|bc -l`
	    my_transfer_rate_mps=`echo "$my_size_mb/$ELAPSED_TIME"|bc -l`
	    echo -e $FILE"\t"`date`"\t"$my_size_gb"\t"$OPERATION"\t"$ELAPSED_TIME"\t"$my_transfer_rate_gps"\t"$my_transfer_rate_mps"\t"$i >> $LOG

	else
	    echo -e $FILE"\tERROR, file does not exist in bucket: "$BUCKET >> $ERRORLOG 
	fi

	# delete the local file every iteration except the last
	if [[ $i -lt $NUMREPEATS ]]; then
	    echo "REP $i DELETING $FILE LOCALLY" >> $ERRORLOG
	    rm $FILE
	fi
	
    done

    # Kill parcel processes
    pkill parcel*
}
########################################################################################################

########################################################################################################
# (8) Upload with wput using parcel

########################################################################################################

########################################################################################################
# (9) Boto download (without parcel)    ##### AS WRITTEN THIS WILL USE PARCEL
download_file_boto(){
    BUCKET=$1
    FILE=$2
    NUMREPEATS=$3
    LOG=$4
    ERRORLOG=$5
    DENOMGB=$6
    DENOMMB=$7
    source ~/.profile
    ACCESSKEY="$ACCESSKEY"
    SECRETKEY="$SECRETKEY"
    GATEWAY="$GATEWAY"
    OPERATION="Boto.download_without_parcel"

    echo "Performing download with boto (no parcel)" >> $ERRORLOG
    
    # check to make sure the file does not exist locally, delete it if it does
    if [[ -e $FILE ]]; then
	rm $FILE
	echo -e "Deleted $FILE (locally) before proceeding with download from the bucket" >> $ERRORLOG
    else
	echo -e "$FILE is not present locally, proceeding with download from the bucket." >> $ERRORLOG
    fi
    
    # Perform test NUMREPEAT times
    for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
    do
	
	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
	if [[ $file_check -gt 0 ]]; then
	    
	    START_TIME=`date +%s.%N`
	    #s3cmd get s3://$BUCKET/$FILE
	    echo -e "REP $i Running: \"boto_dl.py -f $FILE -a $ACCESSKEY -s $SECRETKEY -b $BUCKET -g $GATEWAY\"" >> $ERRORLOG
	    boto_dl.py -f $FILE -a $ACCESSKEY -s $SECRETKEY -b $BUCKET -g $GATEWAY
	    FINISH_TIME=`date +%s.%N`
	    ELAPSED_TIME=`echo "$FINISH_TIME - $START_TIME" | bc -l`
	    
	    my_size=`ls -ltr $FILE | cut -d " " -f 5`
	    my_size_gb=`echo  "$my_size / $DENOMGB" | bc -l`
	    my_size_mb=`echo  "$my_size / $DENOMMB" | bc -l`

	    my_transfer_rate_gps=`echo  "$my_size_gb / $ELAPSED_TIME" | bc -l`
	    my_transfer_rate_mps=`echo  "$my_size_mb / $ELAPSED_TIME" | bc -l`
	    
	    echo -e $FILE"\t"`date`"\t"$my_size_gb"\t"$OPERATION"\t"$ELAPSED_TIME"\t"$my_transfer_rate_gps"\t"$my_transfer_rate_mps"\t"$i >> $LOG
	else
	    echo -e $FILE"\tERROR, file does not exist in bucket: "$BUCKET >> $ERRORLOG 
	fi
	
	# delete the local file every iteration except the last
	if [[ $i -lt $NUMREPEATS ]]; then
	    echo "REP $i DELETING $FILE LOCALLY" >> $ERRORLOG
	    rm $FILE
	fi
	
    done
        
}
########################################################################################################

########################################################################################################
# (10) Boto upload (without parcel)
upload_file_boto(){
    BUCKET=$1
    FILE=$2
    NUMREPEATS=$3
    LOG=$4
    ERRORLOG=$5
    DENOMGB=$6
    DENOMMB=$7
    source ~/.profile
    ACCESSKEY="$ACCESSKEY"
    SECRETKEY="$SECRETKEY"
    GATEWAY="$GATEWAY"
    OPERATION="Boto.upload_without_parcel" >> $ERRORLOG

    echo "Performing upload with boto (no parcel)"
    
     # check to make sure the file exists locally, if not, exit
    if [[ -e $FILE ]]; then
	echo -e "$FILE exists locally, proceeding to upload" >> $ERRORLOG
    else
	echo -e "$FILE Does not exist locally: exiting" >> $ERRORLOG
	exit 1 
    fi
    
    # Perform test NUMREPEAT times
    for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
    do

	# delete the file in the bucket if it already exists in the bucket
	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
	if [[ $file_check -gt 0 ]]; then
	    s3cmd del s3://$BUCKET/$FILE
	    echo -e "REP $i $FILE exists in bucket, delete before proceeding with upload"  >> $ERRORLOG
	fi

	# perform the upload
	START_TIME=`date +%s.%N`
	#s3cmd get s3://$BUCKET/$FILE
	echo -e "REP $i Running: \"boto_ul.py -f $FILE -a $ACCESSKEY -s $SECRETKEY -b $BUCKET -g $GATEWAY\""  >> $ERRORLOG
	boto_ul.py -f $FILE -a $ACCESSKEY -s $SECRETKEY -b $BUCKET -g $GATEWAY
	FINISH_TIME=`date +%s.%N`
	ELAPSED_TIME=`echo "$FINISH_TIME - $START_TIME" | bc -l`
	
	my_size=`ls -ltr $FILE | cut -d " " -f 5`
	my_size_gb=`echo  "$my_size / $DENOMGB" | bc -l`
	my_size_mb=`echo  "$my_size / $DENOMMB" | bc -l`
	
	my_transfer_rate_gps=`echo  "$my_size_gb / $ELAPSED_TIME" | bc -l`
	my_transfer_rate_mps=`echo  "$my_size_mb / $ELAPSED_TIME" | bc -l`
	
	echo -e $FILE"\t"`date`"\t"$my_size_gb"\t"$OPERATION"\t"$ELAPSED_TIME"\t"$my_transfer_rate_gps"\t"$my_transfer_rate_mps"\t"$i >> $LOG
		
    done
        
}
########################################################################################################

########################################################################################################
# (11) Boto download with parcel
download_file_boto_withp(){
    BUCKET=$1
    FILE=$2
    NUMREPEATS=$3
    LOG=$4
    ERRORLOG=$5
    DENOMGB=$6
    DENOMMB=$7
    PARCELSERVERIPPORT=$8
    PARCELLOCALHOSTPORT=$9
    source ~/.profile
    ACCESSKEY="$ACCESSKEY"
    SECRETKEY="$SECRETKEY"
    GATEWAY="$GATEWAY"
    OPERATION="Boto.download_with_parcel"

    PARCELLOCALHOST=`echo $PARCELLOCALHOSTPORT | cut -f 1 -d ":"`

    echo "Performing download with boto (with parcel)" >> $ERRORLOG

    # pauses below are to make sure that parcel has time to stop or start
    # kill parcel if it is already running
    #pkill parcel-tcp2udt
    #pkill parcel-udt2tcp
    pkill parcel*
    # start the parcel service
    echo -e "parcel sever_port: $PARCELSERVERIPPORT" >> $ERRORLOG
    parcel-tcp2udt $PARCELSERVERIPPORT & # > ./parcel.log 2>&1 & # <--- script dies here
    sleep 5s
    parcel-udt2tcp $PARCELLOCALHOSTPORT &
    sleep 5s
    
    # check to make sure the file does not exist locally, delete it if it does
    if [[ -e $FILE ]]; then
	rm $FILE
	echo -e "Deleted $FILE (locally) before proceeding with download from the bucket" >> $ERRORLOG
    else
	echo -e "$FILE is not present locally, proceeding with download from the bucket." >> $ERRORLOG
    fi
    
    # Perform test NUMREPEAT times
    for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
    do
	
	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
	if [[ $file_check -gt 0 ]]; then
	    # boto_dl.py -f ERR_tar.12Mb.gz -a RNC0Y3H3W9M9P4I4VAFM -s bRb8osnG7rpvyof05HGKZKwHtFSybmfVizVp0QDp -b test_bucket -g griffin-objstore.opensciencedatacloud.org
	    
	    START_TIME=`date +%s.%N`
	    #s3cmd get s3://$BUCKET/$FILE
	    echo -e "REP $i Running: \"boto_dl.py -f $FILE -a $ACCESSKEY -s $SECRETKEY -b $BUCKET -g $GATEWAY -p\"" >> $ERRORLOG
	    boto_dl.py -f $FILE -a $ACCESSKEY -s $SECRETKEY -b $BUCKET -g $GATEWAY -p
	    FINISH_TIME=`date +%s.%N`
	    ELAPSED_TIME=`echo "$FINISH_TIME - $START_TIME" |bc -l`

	    my_size=`ls -ltr $FILE | cut -d " " -f 5`
	    my_size_gb=`echo "$my_size/$DENOMGB"|bc -l`
	    my_size_mb=`echo "$my_size/$DENOMMB"|bc -l`

	    #my_transfer_rate=`echo "$my_size_gb/$ELAPSED_TIME"|bc -l`
	    my_transfer_rate_gps=`echo "$my_size_gb/$ELAPSED_TIME"|bc -l`
	    my_transfer_rate_mps=`echo "$my_size_mb/$ELAPSED_TIME"|bc -l`
	    #echo -e $FILE"\t"`date`"\t"$my_size_gb"\t"$OPERATION"\t"$ELAPSED_TIME"\t"$my_transfer_rate_gps"\t"$my_transfer_rate_mps"\t"$i >> $LOG

	    echo -e $FILE"\t"`date`"\t"$my_size_gb"\t"$OPERATION"\t"$ELAPSED_TIME"\t"$my_transfer_rate_gps"\t"$my_transfer_rate_mps"\t"$i >> $LOG
	else
	    echo -e $FILE"\tERROR, file does not exist in bucket: "$BUCKET >> $ERRORLOG 
	fi
	
	# delete the local file every iteration except the last
	if [[ $i -lt $NUMREPEATS ]]; then
	    echo "REP $i DELETING $FILE LOCALLY" >> $ERRORLOG
	    rm $FILE
	fi
	
    done

    # Kill parcel processes
    pkill parcel*
        
}
########################################################################################################


########################################################################################################
# (12) Boto upload with parcel
upload_file_boto_withp(){
    BUCKET=$1
    FILE=$2
    NUMREPEATS=$3
    LOG=$4
    ERRORLOG=$5
    DENOMGB=$6
    DENOMMB=$7
    source ~/.profile
    ACCESSKEY="$ACCESSKEY"
    SECRETKEY="$SECRETKEY"
    GATEWAY="$GATEWAY"
    OPERATION="Boto.upload_with_parcel"

    PARCELLOCALHOST=`echo $PARCELLOCALHOSTPORT | cut -f 1 -d ":"`

    echo "Performing upload with boto (with parcel)" >> $ERRORLOG

    # kill parcel if it is already running
    #pkill parcel-tcp2udt
    #pkill parcel-udt2tcp
    pkill parcel-*
    sleep 5s
    # start the parcel service
    echo -e "parcel sever_port: $PARCELSERVERIPPORT" >> $ERRORLOG
    parcel-tcp2udt $PARCELSERVERIPPORT & # > ./parcel.log 2>&1 & # <--- script dies here
    sleep 5s
    parcel-udt2tcp $PARCELLOCALHOSTPORT &
    sleep 5s
    
     # check to make sure the file exists locally, if not, exit
    if [[ -e $FILE ]]; then
	echo -e "$FILE exists locally, proceeding to upload" >> $ERRORLOG
    else
	echo -e "$FILE Does not exist locally: exiting" >> $ERRORLOG
	exit 1 
    fi
    
    # Perform test NUMREPEAT times
    for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
    do

	# delete the file in the bucket if it already exists in the bucket
	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
	if [[ $file_check -gt 0 ]]; then
	    s3cmd del s3://$BUCKET/$FILE
	    echo -e "REP $i $FILE exists in bucket, delete before proceeding with upload"  >> $ERRORLOG
	fi
	
	# perform the upload
	START_TIME=`date +%s.%N`
	#s3cmd get s3://$BUCKET/$FILE
	echo -e "REP $i Running: \"boto_ul.py -f $FILE -a $ACCESSKEY -s $SECRETKEY -b $BUCKET -g $GATEWAY -p\"" >> $ERRORLOG
	boto_ul.py -f $FILE -a $ACCESSKEY -s $SECRETKEY -b $BUCKET -g $GATEWAY -p
	FINISH_TIME=`date +%s.%N`
	ELAPSED_TIME=`echo "$FINISH_TIME - $START_TIME" | bc -l`
	    
	my_size=`ls -ltr $FILE | cut -d " " -f 5`
	my_size_gb=`echo  "$my_size / $DENOMGB" | bc -l`
	my_size_mb=`echo  "$my_size / $DENOMMB" | bc -l`

	my_transfer_rate_gps=`echo  "$my_size_gb / $ELAPSED_TIME" | bc -l`
	my_transfer_rate_mps=`echo  "$my_size_mb / $ELAPSED_TIME" | bc -l`
	
	echo -e $FILE"\t"`date`"\t"$my_size_gb"\t"$OPERATION"\t"$ELAPSED_TIME"\t"$my_transfer_rate_gps"\t"$my_transfer_rate_mps"\t"$i >> $LOG
	
    done

    # Kill parcel processes
    pkill parcel*
}




########################################################################################################


########################################################################################################
########################################################################################################
########################################################################################################
### MAIN

### Main loop interates through the list of files - cut out 56GB as it may have run into a mem error
### Need to characterize this error in the future.

for FILE in $FILE0 $FILE1 $FILE2;
#for FILE in $FILE0 $FILE1
#for FILE in $FILE0
do
    # (1) Add s3cmd dl               # DONE
    download_file_s3cmd $MYBUCKET $FILE $NUMREPEATS $MYLOG $ERRORLOG $DENOMGB $DENOMMB 2>> $ERRORLOG

    # (2) Add s3cmd ul               # DONE
    upload_file_s3cmd $MYBUCKET $FILE $NUMREPEATS $MYLOG $ERRORLOG $DENOMGB $DENOMMB 2>> $ERRORLOG

    # (3) Add s3cmd dl with parcel   # possible?
    
    # (4) Add s3cmd ul with parcel   # possible?
    
    # (5) Add wget dl                # possible? # under development 
    
    # (6) Add wput ul                # possible?
    
    # (7) Add wget dl with parcel    # DONE
    download_file_wget_withp $MYBUCKET $FILE $NUMREPEATS $MYLOG $ERRORLOG $DENOMGB $DENOMMB $PARCELSERVERIPPORT $PARCELLOCALHOSTPORT 2>> $ERRORLOG 
    # (8) Add wput ul with parcel    # possible?
    
    # (9) Add boto dl                # DONE
    download_file_boto $MYBUCKET $FILE $NUMREPEATS $MYLOG $ERRORLOG $DENOMGB $DENOMMB 2>> $ERRORLOG
    
    # (10) Add boto ul               #
    upload_file_boto $MYBUCKET $FILE $NUMREPEATS $MYLOG $ERRORLOG $DENOMGB $DENOMMB 2>> $ERRORLOG

    # (11) Add boto dl with parcel   #
    download_file_boto_withp $MYBUCKET $FILE $NUMREPEATS $MYLOG $ERRORLOG $DENOMGB $DENOMMB $PARCELSERVERIPPORT $PARCELLOCALHOSTPORT  2>> $ERRORLOG # some sort of problem with this function
    
    # (12) Add boto ul with parcel   #
    upload_file_boto_withp $MYBUCKET $FILE $NUMREPEATS $MYLOG $ERRORLOG $DENOMGB $DENOMMB $PARCELSERVERIPPORT $PARCELLOCALHOSTPORT 2>> $ERRORLOG
    
done

########################################################################################################
########################################################################################################
########################################################################################################
### NOTES AND ADDITIONAL COMMENTS

# Need to check on weirdness with parcel port and boto scripts
# Specifying the port in the script works fine when I run just the script
# but does not work when the script is called by this shell - don't understand this.


#####

########################################################################################################
### From Mark 1-4-15

# #upload.py

# Host and port is just the host and port of the proxy. (For Parcel)
# Credentials file is a JSON object.

# https://gist.github.com/MurphyMarkW/14b42ce6c4abc63f8803

# #!/usr/bin/env python

# import os
# import sys
# import json
# import logging
# import argparse

# import boto
# import boto.s3.connection

# if __name__ == '__main__':

#     parser = argparse.ArgumentParser(description='Upload an object from stdin.')

#     parser.add_argument('-d', '--debug',
#         action='store_true',
#         help='Enabled debug-level logging.',
#     )

#     parser.add_argument('credentials',
#         type=argparse.FileType('r'),
#         help='Credentials file.',
#     )

#     parser.add_argument('bucket',help='Bucket to use.')
#     parser.add_argument('key',help='Object name.')

#     args = parser.parse_args()

#     logging.basicConfig(
#         level=logging.DEBUG if args.debug else logging.INFO,
#         format='%(asctime)s %(name)-6s %(levelname)-4s %(message)s',
#     )

#     credentials= json.load(args.credentials)

#     conn = boto.connect_s3(
#         aws_access_key_id     = credentials.get('access_key'),
#         aws_secret_access_key = credentials.get('secret_key'),
#         host                  = credentials.get('host'),
#         port                  = credentials.get('port'),
#         is_secure             = credentials.get('is_secure', False),
#         calling_format        = boto.s3.connection.OrdinaryCallingFormat(),
#     )

#     key = conn.get_bucket(args.bucket).get_key(args.key)
#     if key is None:
#         key = conn.get_bucket(args.bucket).new_key(args.key)

#     key.set_contents_from_file(sys.stdin)
########################################################################################################


