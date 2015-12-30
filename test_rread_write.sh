#!/bin/bash


STREAMS=1;
# MEM=`free -m -t | tail -n 1 | cut -d " " -f5` # mem in bytes
MEM=`free -m -t | tail -n 1 | cut -d " " -f8` # mem in Mb



bonnie++ -d /mnt -r $MEM -u ubuntu



# test read
for i in {1..$STREAMS}
do
    testdir
    bonnie++ -d /dev/null -r $MEM -u root
done

# test write

# https://bugs.launchpad.net/plainbox-provider-checkbox/+bug/993951	 
sudo bonnie++ -d ./ -u root


# script will execute specified number of processing

# three types of for iteration:
# for i in 1 2 3 4 5
# for i in {1..10}
# for i in {0..10..2} # 1 to 10 by 2

process1 &
process2 &
process3 &
process4 &
wait
process5 &
process6 &
process7 &
process8 &
wait




# dd write
time sh -c "dd if=/dev/zero of=[PATH] bs=[BLOCK_SIZE]k count=[LOOPS] && sync"

time sh -c "dd if=/dev/zero of=/mnt/mount1/test.tmp bs=4k count=2000000 && sync"
    time – times the overall process from start to finish
    of= this is the path which you would like to test. The path must be read/ writable.
    bs= is the block size to use. If you have a specific load which you are testing for, make this value mirror the write size which you would expect.
    sync – forces the process to write the entire file to disk before completing. Note, that dd will return before completing but the time command will not, therefore the time output will include the sync to disk.

The below example uses a 4K block size and loops 2000000 times. The resulting write size will be around 7.6GB.
(8192000000 / 1024 / 1024) / ((2 * 60) + 41.618)

Bytes converted to MB / (2 minutes + 41.618 seconds)

This gives us an average of 48.34 megabytes per second over the duration of the test.

    
# dd read
time sh -c "dd if=/mnt/mount1/test.tmp of=/dev/null bs=4k"







# dd WRITE # http://www.jamescoyle.net/how-to/599-benchmark-disk-io-with-dd-and-bonnie
time sh -c "dd if=/dev/zero of=[PATH] bs=[BLOCK_SIZE]k count=[LOOPS] && sync"

    time – times the overall process from start to finish
    of= this is the path which you would like to test. The path must be read/ writable.
    bs= is the block size to use. If you have a specific load which you are testing for, make this value mirror the write size which you would expect.
    sync – forces the process to write the entire file to disk before completing. Note, that dd will return before completing but the time command will not, therefore the time output will include the sync to disk.

1
2
3
4
	
time sh -c "dd if=/dev/zero of=/mnt/mount1/test.tmp bs=4k count=2000000 && sync"
2000000+0 records in
2000000+0 records out
8192000000 bytes transferred in 159.062003 secs (51501929 bytes/sec)

1
2
3
	
real 2m41.618s
user 0m0.630s
sys 0m14.998s

Now, let’s do the math. dd tells us how many bytes were written, and the time command tells us how long it took – use the real output at the bottom of the output. Use the formula BYTES / SECONDS. For these larger tests, convert bytes to KB or MB to make more sensible numbers.
(8192000000 / 1024 / 1024) / ((2 * 60) + 41.618)

Bytes converted to MB / (2 minutes + 41.618 seconds)

This gives us an average of 48.34 megabytes per second over the duration of the test.



# dd READ
1
	
dd if=/dev/zero of=/mnt/mount1/clearcache.tmp bs=4k count=524288

Now for the read test of our original file.
1
	
time sh -c "dd if=/mnt/mount1/test.tmp of=/dev/null bs=4k"



