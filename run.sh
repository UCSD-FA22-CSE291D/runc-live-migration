if [[ $# -ne 2 ]]; then
    echo "Usage: ./run.sh [test dir] [checkpoint/predump]"
    exit 1
fi

WORKDIR=`pwd`

# Get which version to run
TESTDIR=$1
echo "Running in dir ${TESTDIR}..."

# Change to test dir and copy payload
sudo runc delete -f pyserver
cp ${WORKDIR}/${TESTDIR}/server.py ${WORKDIR}/containers/pyserver/rootfs/tmp/

# Run checkpoint restore
cd ${WORKDIR}/containers/pyserver
sudo runc run pyserver -d &> /dev/null < /dev/null
sleep 3
cd ${WORKDIR}
if [[ $2 = "checkpoint" ]]; then
    ./check-restore.sh ${WORKDIR}/${TESTDIR}/curl_checkpoint_restore.txt
elif [[ $2 = "predump" ]]; then
    ./predump-restore.sh ${WORKDIR}/${TESTDIR}/curl_predump_restore.txt
else
    echo "Expect [predump] or [checkpoint]"
fi

sudo runc delete -f pyserver