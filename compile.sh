#!/usr/bin/env bash

mkdir .export-temp

jupyter nbconvert --to markdown ./src/*.ipynb 
cp ./src/*.md .export-temp
rm ./src/*.md

cp ./md/*.md .export-temp

rm -rf export
mv .export-temp export
