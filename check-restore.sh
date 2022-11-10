HOME=`pwd`
SERVER1="/containers/pyserver"
SERVER2="/containers/pyserver2"

# Clean up already existing checkpoints
sudo rm -rf $SERVER1/checkpoint
sudo rm -rf $SERVER2/checkpoint

# Before checkpointing container
echo "============================================ Before migration ==============================================================="
sudo runc list
echo "============================================================================================================================="

# Start the request
echo "Starting request..."
OUTFILE="curl_check_restore.txt"
curl -s localhost:8000 > ${OUTFILE} &

sleep 2

# Start checkpoint
cd $HOME$SERVER1
echo "Running checkpoint..."
sudo runc checkpoint --tcp-established --shell-job pyserver

# Start restore
cd $HOME$SERVER2
TRANSFER_RATE="100M"
echo "Copying file at $TRANSFER_RATE/s..."
sudo rsync -a --bwlimit=$TRANSFER_RATE $HOME$SERVER1/checkpoint .

echo "Restoring into container..."
sudo runc restore -d --shell-job --tcp-established pyserver

# Wait for curl to finish
echo "Waiting for curl to finish..."
sleep 15

echo -e "Done.\n"
echo "curl output written to ${OUTFILE}"

# After restoring container
echo -e "\n============================================ After migration ================================================================"
sudo runc list
echo "============================================================================================================================="