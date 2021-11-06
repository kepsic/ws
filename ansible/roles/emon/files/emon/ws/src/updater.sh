#!/bin/bash

DIR=`dirname "$0"`

cd $DIR

while true
do
  python main.py
  sleep 300
done
