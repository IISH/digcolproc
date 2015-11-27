#!/bin/bash
#
# run.sh
#
# Produce validation for merge

#-----------------------------------------------------------------------------------------------------------------------
# load environment variables
#-----------------------------------------------------------------------------------------------------------------------
source "${DIGCOLPROC_HOME}setup.sh" $0 "$@"
source ../call_api_status.sh
work=$fs_parent/.work/$archiveID/validate
mkdir -p $work



#-----------------------------------------------------------------------------------------------------------------------
# Lock the folder and it's contents
#-----------------------------------------------------------------------------------------------------------------------
orgOwner=$(stat -c %u $fileSet)
orgGroup=$(stat -c %g $fileSet)
chown -R root:root $fileSet



#-----------------------------------------------------------------------------------------------------------------------
# Produce a droid analysis
#-----------------------------------------------------------------------------------------------------------------------
profile=$work/profile.droid
echo "Begin droid analysis for profile ${profile}" >> $log
droid --recurse -p $profile --profile-resources $fileSet>>$log
rc=$?
if [[ $rc != 0 ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Droid profiling threw an error."
fi
if [[ ! -f $profile ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Unable to find a DROID profile."
fi



#-----------------------------------------------------------------------------------------------------------------------
# Produce a report
#-----------------------------------------------------------------------------------------------------------------------
profile_csv=$work/profile.csv
droid -p $profile --export-file $profile_csv >> $log
rc=$?
if [[ $rc != 0 ]] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Droid reporting threw an error."
fi
if [ ! -f $profile_csv ] ; then
    chown -R "$orgOwner:$orgGroup" $fileSet
    exit_error "Unable to create a droid profile: ${profile_csv}"
fi



#-----------------------------------------------------------------------------------------------------------------------
# Mark as validated
#-----------------------------------------------------------------------------------------------------------------------
md5sum $fileSet/$archiveID.csv > $work/$archiveID.csv.md5
cf=$work/concordanceValid.csv
cp $fileSet/$archiveID.csv $cf



#-----------------------------------------------------------------------------------------------------------------------
# End validation
#-----------------------------------------------------------------------------------------------------------------------
chown -R "$orgOwner:$orgGroup" $fileSet

echo "Done validate for merge." >> $log
exit 0
