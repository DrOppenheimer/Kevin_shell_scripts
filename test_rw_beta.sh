#!/bin/bash

# number of times to perform the operation
NUMREPEATS=5;
MYLOG="rw_log.txt";

MYBUCKET="test_bucket"


#FILE1="ERR188416_2.fastq.gz"
FILE1="ERR_tar.1Gb.gz"
FILE2="ERR_tar.11Gb.gz"
FILE3="ERR_tar.59Gb.gz"

DENOM=`echo 2^30 | bc` # i.e. bytes in GB

echo -e "# test_rw.sh log\t"`date` > $MYLOG
echo -e "# File\tsize(Gb)\tTransfer_time\tTransfer_rate(Gb/s)\tRepeat\tParcel(?)" >> $MYLOG 

# upload file 1 (no parcel)


upload_file $MYBUCKET $FILE1 $NUMREPEATS $MYLOG $DENOM
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
upload_file $MYBUCKET $FILE2 $MYLOG $DENOM
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
upload_file $MYBUCKET $FILE3 $MYLOG $DENOM
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



upload_file(){
    BUCKET=$1
    FILE=$2
    NUMREPEATS=$3
    LOG=$4
    DENOM=$5

    for (( i=1; i<=$NUMREPEATS; i++ )); # tried using NUMREPEAT var here -- does not work
    do
	file_check=`s3cmd ls s3://$BUCKET/$FILE | wc -l`
	if [[ $file_check -gt 0 ]]; then
	    s3cmd del s3://$BUCKET/$FILE
	fi
	my_size=`ls -ltr $FILE | cut -d " " -f 5`
	my_size_gb=`echo "$my_size/$DENOM"|bc -l`
	START_TIME=$SECONDS
	s3cmd sync ./$FILE s3://$BUCKET/
	ELAPSED_TIME=$(($SECONDS - $START_TIME))
	my_transfer_rate=`echo "$my_size_gb/$ELAPSED_TIME"|bc -l`
	echo -e $FILE"\t"$my_size_gb"\t"$ELAPSED_TIME"\t"$my_transfer_rate"\t"$i"\tN" >> $LOG
	s3cmd del s3://$BUCKET/$FILE
    done
}

















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
