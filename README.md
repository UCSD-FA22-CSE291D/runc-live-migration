# runc container migration with predump

This is a proof-of-concept for doing migration with `runc`.

## Result

The container runs a simple HTTP server. When a client connects to it, the client will receive 15 packets from the server over 15 seconds (one packet every second).

The container is migrated while the client uses `curl` to connect to the server.

Without predump, there is an obvious downtime of 24 seconds:
```
Start sending packets...
Format: [id] time
[0] 07:01:02
[1] 07:01:03
[2] 07:01:27    <- Downtime
[3] 07:01:29
[4] 07:01:30
...
```

With predump, there is no perceivable downtime from the client side:
```
Start sending packets...
Format: [id] time
[0] 07:14:46
[1] 07:14:47
[2] 07:14:48
[3] 07:14:49
[4] 07:14:50
[5] 07:14:51
[6] 07:14:52
[7] 07:14:53
[8] 07:14:54
[9] 07:14:55
[10] 07:14:56
[11] 07:14:57
[12] 07:14:58
[13] 07:14:59
[14] 07:15:00
```

The server holds a 300MB garbage data to make the difference in migration time obvious. Also checkpointed files are copied at 100MB/s to mimic transferring over the network.


## How to run
1. Install `runc` and `oci-runtime-tools`
   
   `runc` should already be installed by `docker`.
   
   To install `oci-runtime-tools`, follow this <a href='https://www.redhat.com/ja/blog/container-live-migration-using-runc-and-criu'>link</a>

2. Install python container images
   
   Run the following commands:
   ```
   ./pyserver-install.sh
   ```

   This should create `containers` directory with 2 subdirectories `pyserver` and `pyserver2`. These are the 2 containers for testing migration.

3. Run a container
   
   Go to `containers/pyserver` and run 
   ```
   sudo runc run pyserver -d &> /dev/null < /dev/null
   ```
   to launch container `pyserver` in detached mode.

   To show the running container, run:
   ```
   sudo runc list
   ```

   Example output:
   ```
   ID          PID         STATUS      BUNDLE                        CREATED                          OWNER
   pyserver    18288       running     /test/containers/pyserver2    2022-11-10T07:01:27.536386445Z   root
   ```

4. Run migration or migration with predump
   
   Go to the top level directory where all the scripts are.

   To migrate (checkpoint + restore), run

   ```
   ./check-restore.sh
   ```

   To migrate with predump, run

   ```
   ./predump-restore.sh
   ```

   Example output for predump:
   ```
   ID          PID         STATUS      BUNDLE                      CREATED                          OWNER
   pyserver    19028       running     /test/containers/pyserver   2022-11-10T07:14:24.659829585Z   root
   
   Starting request...
   Running pre-dump...
   Copying file at 100M/s...
   Running checkpoint and stopping server...
   Copying file at 100M/s...
   Restoring into container...
   Waiting for curl to finish...
   
   ID          PID         STATUS      BUNDLE                       CREATED                          OWNER
   pyserver    19131       running     /test/containers/pyserver2   2022-11-10T07:15:07.537072713Z   root
   ```

   Container `pyserver` should be successfully migrated from `pyserver` to `pyserver2`.

5. To delete the container, run `sudo runc delete -f pyserver`.
