#!/bin/bash
#uuid=$(uuidgen)
for i in `seq 10 99`;
do
	DIRNAME="vol$i"
	mkdir -p /mnt/local-storage/hdd/$DIRNAME
        chcon -Rt svirt_sandbox_file_t /mnt/local-storage/hdd/$DIRNAME
	chmod 777 /mnt/local-storage/hdd/$DIRNAME
	#sleep 1
	sed "s/name: vol/name: vol$i/g" vol.yaml > oc_vol.yaml
	sed -i "s/path: \/mnt\/local-storage\/hdd\/vol/path: \/mnt\/local-storage\/hdd\/vol$i/g" oc_vol.yaml
	oc create -f oc_vol.yaml
	echo "created volume $i"
done
rm oc_vol.yaml
