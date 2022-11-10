# Need runc and oci-runtime-tool installed
echo -n "Runc Path:"
which runc
echo -n "oci-runtime-tool Path:"
which oci-runtime-tool

HOME=`pwd`

# Create rootfs
echo "Generating python container images..."
SERVERPATH1="$HOME/containers/pyserver"
SERVERPATH2="$HOME/containers/pyserver2"
mkdir -p ${SERVERPATH1}/rootfs
mkdir ${SERVERPATH2}

cd ${SERVERPATH1}
sudo docker export $(docker run -d python) |tar -C rootfs -x
sudo oci-runtime-tool generate --args "python" --args "/tmp/server.py" --linux-namespace-remove network --rootfs-readonly > config.json

# Make a copy for migration
cp -R ${SERVERPATH1}/* ${SERVERPATH2}/

# Copy python payload to pyserver1 and run
cp ${HOME}/server.py ${SERVERPATH1}/rootfs/tmp/

# Run server
# sudo runc run pyserver -d &> /dev/null < /dev/null