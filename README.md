# Automatic Deployment of Masternode on docker

Deployment of Masternode for Ubuntu
On simple run you'll need to enter Master Node Private Key - "MNPK" that you generated on your wallet
Check how to generate MNPK it on video: "VIVO Masternodes - Multiple Masternodes Cold Wallet Guide"
https://www.youtube.com/watch?v=WH_ABrwduZo&t=290s

### Setup Masternode Server 
1. Setup VPS with Ubuntu v.16+ 
2. Login to server
3. Run the following commands
    -  sudo apt-get update -y
    -  sudo apt-get install -y git
    -  mkdir vivocoin
    -  cd vivocoin/
    -  git clone https://github.com/vivocoin/docker.git
    -  cd docker/
    -  chmod a+x setup-aio.sh
    -  sudo ./setup-aio.sh

4. Follow the instructions (You'll need to enter your MNPK here). By default it will create and start container named vivo-mn-1

5. The Masternode Server should be up and running. Use docker commands to check status and logs
    -  sudo docker pd -a
    -  sudo docker logs --tail 50 --follow --timestamps vivo-mn-1

6. Be patient since Masternode Server started it'll take some time while (hours) you'll see it in your wallet in ENABLED status.


Simple and Easy.
