#!/bin/bash

# Check if the correct number of arguments is passed
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_csv_file>"
    exit 1
fi

CSV_PATH=$1
PARQUET_PATH="${CSV_PATH%.*}.parquet"

# Ask the user if they want to sample
read -p "Do you want to take a random sample? (y/n) " choice

# Convert CSV to Parquet, with or without sampling
if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    read -p "Enter the number of samples to be taken: " N_SAMPLES
    python -c "
import pandas as pd

df = pd.read_csv('$CSV_PATH', low_memory=False)
sample_df = df.sample(n=int('$N_SAMPLES'))
sample_df.to_parquet('$PARQUET_PATH', engine='pyarrow')
"
else
    python -c "
import pandas as pd

df = pd.read_csv('$CSV_PATH', low_memory=False)
df.to_parquet('$PARQUET_PATH', engine='pyarrow')
"
fi

# Check if the command was successful
if [ $? -eq 0 ]; then
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Parquet file with $N_SAMPLES samples created successfully at $PARQUET_PATH!"
    else
        echo "Parquet file created successfully at $PARQUET_PATH!"
    fi
else
    echo "Failed to create parquet file!"
fi
