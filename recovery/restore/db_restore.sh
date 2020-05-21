#!/bin/bash

read -p "Machine Name (e.g. th810): " machine_name
read -p "Database Name: " db_name
read -p "Date Filter (YYYY, YYYY-mm, YYYY-mm-dd): " date_filter

grep -i ${date_filter} .s3_manifest | grep -i ${machine_name} | grep -i ${db_name}
echo "Pick a key to download..."

read -p "Enter S3 Key: " key
echo "Downloading $key from S3 bucket"

num_delims_in_key=`fgrep -o / <<< ${key} | wc -l`
filename_pos=$((num_delims_in_key + 1))
filename=`cut -d'/' -f${filename_pos} <<< ${key}`

aws s3api get-object --bucket ${S3_BUCKET_NAME} --key ${key} ${filename}
tar -xvf ${filename}
rm ${filename}

echo "${filename} is located in data/backup/"
