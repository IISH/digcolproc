#!/bin/bash
#
# unpack.sh
#
# See if we find a package and unpack it.
# If so, there must be only one file that ends with .rar, .tar, .tar.gz or zip


for package_extension in rar tar tar.gz zip
do
    package="${archiveID}.${package_extension}"
    if [ -f "$package" ]
    then
        number_of_files=$(ls | wc -l)
        if [[ $number_of_files != 1 ]]
        then
            echo "Found ${number_of_files} files, but only expect a single one: ${package}"
            exit 1
        fi

        cmd="a command"
        target_dir="${work}/package"
        case "$package_extension" in
            rar)
                cmd="unrar x ${package}"
            ;;
            tar)
                cmd="tar xvf ${package}"
            ;;
            tar.gz)
                cmd="tar xvzf ${package}"
            ;;
            zip)
                cmd="unzip ${package}"
            ;;
        esac

        eval "$cmd"
        rc=$?
        if [[ $rc == 0 ]]
        then
            # Keep the original name as a marker for the package.
            echo -n "$package" "${work_base}/package.name"
            rm "$package"
        else
            echo "Unable to unpack ${rc}: ${cmd}" >> $log
            echo "Remove all unpacked files first before attempting to make a new backup." >> $log
            exit 1
        fi
    fi
done