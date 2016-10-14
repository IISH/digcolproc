#!/bin/bash
#
# run.sh
#
# Get a list of pid and url values and bind them,


source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"


#-----------------------------------------------------------------------------------------------------------------------
# Read in the file
#-----------------------------------------------------------------------------------------------------------------------
bind_pid_url="${fileSet}/bind_pid_url.csv"
if [ ! -f "$bind_pid_url" ]
then
    echo "Cannot find ${bind_pid_url}" >> "$log"
    echo "Expecting a CSV file with two columns: PID and the local url." >> "$log"
    exit 1
fi


"" >> "$bind_pid_url"
while read line
do
    IFS=";" read resolve_url pid <<< "$line"
    soapenv="<?xml version='1.0' encoding='UTF-8'?>  \
        <soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:pid='http://pid.socialhistoryservices.org/'>  \
            <soapenv:Body> \
                <pid:UpsertPidRequest> \
                    <pid:na>${na}</pid:na> \
                    <pid:handle> \
                        <pid:pid>${pid}</pid:pid> \
                        <pid:resolveUrl>${resolve_url}</pid:resolveUrl>
                    </pid:handle> \
                </pid:UpsertPidRequest> \
            </soapenv:Body> \
        </soapenv:Envelope>"


    echo "Sending ${pid} ${resolve_url}" >> "$log"
    wget -O /dev/null --header="Content-Type: text/xml" \
        --header="Authorization: bearer ${pidwebserviceKey}" --post-data "$soapenv" \
        --no-check-certificate "$pidwebserviceEndpoint"

    rc=$?
    if [[ $rc != 0 ]]; then
        echo "Error from PID webservice: ${rc}">>"$log"
        echo "$soapenv" >> "$log"
    fi
done < "$bind_pid_url"


exit 0