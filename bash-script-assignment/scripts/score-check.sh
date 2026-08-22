#!/bin/bash
 
full_name="Maneetta Antony"
score=55
 
echo "Full Name: $full_name"
echo "Score: $score"
 
if [ "$score" -ge 70 ]
then
    echo "Result: Pass"
else
    echo "Result: Retry"
fi
