#!/usr/bin/env bash

mkdir .build-temp

jupyter nbconvert --to markdown ./src/*.ipynb 
cp ./src/*.md .build-temp
rm ./src/*.md

cp ./md/*.md .build-temp

rm -rf build
mv .build-temp build
