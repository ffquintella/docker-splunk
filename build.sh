
if test "$#" -ne 2; then
    echo "please use build.sh <<repo>> <<version>>"
else
    docker build -t $1/docker-splunk:$2 --target production .
fi


