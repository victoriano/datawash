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

# Ask the user if they want to filter by a column
read -p "Do you want to filter by a column? (y/n) " filter_choice

FILTER_COLUMN=""
FILTER_VALUE=""
FILTER_CONDITION=""

if [[ "$filter_choice" == "y" || "$filter_choice" == "Y" ]]; then
    python -c "
import pandas as pd

if '$FILE_EXT' == 'csv':
    df = pd.read_csv('$FILE_PATH', low_memory=False)
elif '$FILE_EXT' == 'xlsx':
    df = pd.read_excel('$FILE_PATH', engine='openpyxl')
elif '$FILE_EXT' == 'parquet':
    df = pd.read_parquet('$FILE_PATH')

print('Columns:', ', '.join(df.columns))
"
    read -p "Enter the column to filter by: " FILTER_COLUMN
    read -p "Enter the condition (contains, does not contain, >, <, =): " FILTER_CONDITION
    read -p "Enter the value to filter by: " FILTER_VALUE
fi

# Ask the user if they want to sample
read -p "Do you want to take a random sample? (y/n) " sample_choice

N_SAMPLES=""

if [[ "$sample_choice" == "y" || "$sample_choice" == "Y" ]]; then
    read -p "Enter the number of samples to be taken: " N_SAMPLES
fi

# Get the current date and time
DATE_TIME=$(date "+%Y%m%d-%H%M%S")

# Convert file to desired format, with or without sampling
python -c "
import pandas as pd

if '$FILE_EXT' == 'csv':
    df = pd.read_csv('$FILE_PATH', low_memory=False)
elif '$FILE_EXT' == 'xlsx':
    df = pd.read_excel('$FILE_PATH', engine='openpyxl')
elif '$FILE_EXT' == 'parquet':
    df = pd.read_parquet('$FILE_PATH')

if '$filter_choice' == 'y' or '$filter_choice' == 'Y':
    if '$FILTER_CONDITION' == 'contains':
        df = df[df['$FILTER_COLUMN'].str.contains('$FILTER_VALUE')]
    elif '$FILTER_CONDITION' == 'does not contain':
        df = df[~df['$FILTER_COLUMN'].str.contains('$FILTER_VALUE')]
    elif '$FILTER_CONDITION' == '>':
        df = df[df['$FILTER_COLUMN'] > float('$FILTER_VALUE')]
    elif '$FILTER_CONDITION' == '<':
        df = df[df['$FILTER_COLUMN'] < float('$FILTER_VALUE')]
    elif '$FILTER_CONDITION' == '=':
        df = df[df['$FILTER_COLUMN'] == float('$FILTER_VALUE')]

if '$sample_choice' == 'y' or '$sample_choice' == 'Y':
    df = df.sample(n=int('$N_SAMPLES'))

output_file = '${FILE_PATH%.*}'

if '$filter_choice' == 'y' or '$filter_choice' == 'Y':
    output_file += '_filtered'

if '$sample_choice' == 'y' or '$sample_choice' == 'Y':
    output_file += '_sample_$N_SAMPLES'

output_file += '_$DATE_TIME.$OUTPUT_FORMAT'

if '$OUTPUT_FORMAT' == 'csv':
    df.to_csv(output_file, index=False)
elif '$OUTPUT_FORMAT' == 'parquet':
    df.to_parquet(output_file, engine='pyarrow')
elif '$OUTPUT_FORMAT' == 'xlsx':
    df.to_excel(output_file, engine='openpyxl')
"

# Check if the command was successful
if [ $? -eq 0 ]; then
    if [[ "$sample_choice" == "y" || "$sample_choice" == "Y" ]]; then
        echo "File with $N_SAMPLES samples created successfully at ${FILE_PATH%.*}_sample_$N_SAMPLES_$DATE_TIME.$OUTPUT_FORMAT!"
    else
        echo "File created successfully at ${FILE_PATH%.*}_$DATE_TIME.$OUTPUT_FORMAT!"
    fi
else
    echo "Failed to create file!"
fi