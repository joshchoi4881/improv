#!/bin/sh
# Automate making test files and corresponding .out/.err files


echo 'func int main() {
  return 0;
}' > tests/$1.impv

if [[ "$1" == *"test-"* ]]; then
    touch tests/$1.out
fi

if [[ "$1" == *"fail-"* ]]; then
    touch tests/$1.err
fi