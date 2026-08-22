#!/bin/bash
 
full_name="Maneetta Antony"
directory_path="../test-folder"
file_path="../test-folder/student-info.txt"
 
echo "Full Name: $full_name"
echo "Starting file and directory validation..."
 
if [ -d "$directory_path" ]
then
    echo "Directory exists: $directory_path"
else
    echo "Directory does not exist: $directory_path"
fi
 
if [ -f "$file_path" ]
then
    echo "File exists: $file_path"
else
    echo "File does not exist: $file_path"
fi
