# for local use only
# why: to source the env file to the current terminal session
# usage: type this in terminal: $source ./source.sh

export $(cat env | xargs)