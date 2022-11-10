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
curl -s localhost:8000 > curl_predump_restore.txt &

sleep 2

# Predump
cd $HOME$SERVER1
echo "Running pre-dump..."
sudo runc checkpoint --pre-dump --image-path pre1 --tcp-established --shell-job pyserver

# Transfer predump
TRANSFER_RATE="100M"
echo "Copying file at ${TRANSFER_RATE}/s..."
sudo rsync -a --bwlimit=$TRANSFER_RATE $HOME$SERVER1/pre1 $HOME$SERVER2/

# Checkpoint
echo "Running checkpoint and stopping server..."
sudo runc checkpoint --parent-path ../pre1 --tcp-established --shell-job pyserver
echo "Copying file at $TRANSFER_RATE/s..."
sudo rsync -a --bwlimit=$TRANSFER_RATE $HOME$SERVER1/checkpoint $HOME$SERVER2/

# Start restore
cd $HOME$SERVER2
echo "Restoring into container..."
sudo runc restore -d --shell-job --tcp-established pyserver

# Wait for curl to finish
echo "Waiting for curl to finish..."
sleep 15

# After restoring container
echo -e "\n============================================ After migration ================================================================"
sudo runc list
echo "============================================================================================================================="