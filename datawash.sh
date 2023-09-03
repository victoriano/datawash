#!/bin/bash

# Check if the correct number of arguments is passed
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_file>"
    exit 1
fi

FILE_PATH=$1
FILE_EXT="${FILE_PATH##*.}"

# Ask the user for the desired output format
read -p "Enter the desired output format (csv, excel, parquet): " OUTPUT_FORMAT

# Ask the user if they want to sample
read -p "Do you want to take a random sample? (y/n) " choice

# Convert file to desired format, with or without sampling
if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    read -p "Enter the number of samples to be taken: " N_SAMPLES
    python -c "
import pandas as pd

if '$FILE_EXT' == 'csv':
    df = pd.read_csv('$FILE_PATH', low_memory=False)
elif '$FILE_EXT' == 'xlsx':
    df = pd.read_excel('$FILE_PATH', engine='openpyxl')
elif '$FILE_EXT' == 'parquet':
    df = pd.read_parquet('$FILE_PATH')

sample_df = df.sample(n=int('$N_SAMPLES'))

if '$OUTPUT_FORMAT' == 'csv':
    sample_df.to_csv('${FILE_PATH%.*}_sample_$N_SAMPLES.$OUTPUT_FORMAT', index=False)
elif '$OUTPUT_FORMAT' == 'parquet':
    sample_df.to_parquet('${FILE_PATH%.*}_sample_$N_SAMPLES.$OUTPUT_FORMAT', engine='pyarrow')
elif '$OUTPUT_FORMAT' == 'xlsx':
    sample_df.to_excel('${FILE_PATH%.*}_sample_$N_SAMPLES.$OUTPUT_FORMAT', engine='openpyxl')
"
else
    python -c "
import pandas as pd

if '$FILE_EXT' == 'csv':
    df = pd.read_csv('$FILE_PATH', low_memory=False)
elif '$FILE_EXT' == 'xlsx':
    df = pd.read_excel('$FILE_PATH', engine='openpyxl')
elif '$FILE_EXT' == 'parquet':
    df = pd.read_parquet('$FILE_PATH')

if '$OUTPUT_FORMAT' == 'csv':
    df.to_csv('${FILE_PATH%.*}.$OUTPUT_FORMAT', index=False)
elif '$OUTPUT_FORMAT' == 'parquet':
    df.to_parquet('${FILE_PATH%.*}.$OUTPUT_FORMAT', engine='pyarrow')
elif '$OUTPUT_FORMAT' == 'xlsx':
    df.to_excel('${FILE_PATH%.*}.$OUTPUT_FORMAT', engine='openpyxl')
"
fi

# Check if the command was successful
if [ $? -eq 0 ]; then
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "File with $N_SAMPLES samples created successfully at ${FILE_PATH%.*}_sample_$N_SAMPLES.$OUTPUT_FORMAT!"
    else
        echo "File created successfully at ${FILE_PATH%.*}.$OUTPUT_FORMAT!"
    fi
else
    echo "Failed to create file!"
fi