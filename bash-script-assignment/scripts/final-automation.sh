#!/bin/bash
 
full_name="Maneetta Antony"
assignment_name="Bash Script Automation Drill"
directory_path="../test-folder"
file_path="../test-folder/student-info.txt"
 
tools=("bash" "nano" "chmod" "echo" "ls" "pwd")
 
print_header() {
    echo "===================================="
    echo "$assignment_name"
    echo "===================================="
}
 
print_user_details() {
    echo "Full Name: $full_name"
    echo "Assignment: $assignment_name"
}
 
check_files() {
    echo "Checking required files and directories..."
 
    if [ -d "$directory_path" ]
    then
        echo "Directory check passed: $directory_path"
    else
        echo "Directory check failed: $directory_path"
    fi
 
    if [ -f "$file_path" ]
    then
        echo "File check passed: $file_path"
    else
        echo "File check failed: $file_path"
    fi
}
 
print_tools() {
    echo "Printing tools checklist..."
 
    for tool in "${tools[@]}"
    do
        echo "Tool: $tool"
    done
}
 
print_header
print_user_details
check_files
print_tools
 
echo "Final Bash automation script completed"
