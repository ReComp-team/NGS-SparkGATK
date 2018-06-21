#!/bin/bash

for n in `seq -w 1 20` ; do
	echo "Node $n"
	ssh node${n} "find /scratch -user $USER"
done

