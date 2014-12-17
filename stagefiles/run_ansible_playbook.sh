#!/bin/bash

[ -f /media/stagefiles/ansible-oracle/group_vars/racattack ] && chmod ugo+rw /media/stagefiles/ansible-oracle/group_vars/racattack
cat /media/stagefiles/racattack.group_vars > /media/stagefiles/ansible-oracle/group_vars/racattack

for x in {a,l,n}{1..9}; do
  echo "master_node: false" > /media/stagefiles/ansible-oracle/host_vars/collab$x
done
echo "master_node: true" > /media/stagefiles/ansible-oracle/host_vars/collabn1

# Set cluster_type to 'standard' if nothing is passed to this script. Needed as we always pass cluster_type to the playbook
if [ -z $1 ]; then
  cluster_type="standard"
elif [ $1 == "standard" ] ; then
  cluster_type="standard"
else
  cluster_type="flex"
fi

GIVER=$2
DBVER=$3
PATHTOFILES=/media/stagefiles

# Using quoted json to pass in the 'oracle_databases' list to the playbook. Decided by the dbver variable
if ! [ -z $DBVER ]; then
    if [ $DBVER == "12.1.0.2" ];then
      ORAIMAGE="$PATHTOFILES/12.1.0.2-files.json"
    elif [ $DBVER == "12.1.0.1" ];then
      ORAIMAGE="$PATHTOFILES/12.1.0.1-files.json"
    elif [ $DBVER == "11.2.0.4" ];then
      ORAIMAGE="$PATHTOFILES/11.2.0.4-files.json"
    else
      echo "Error: Unknown DB Version, should be one of - 12.1.0.2, 12.1.0.1 or 11.2.0.4"
      exit 1
    fi
    else
     continue
fi

if ! [[ -z $GIVER || -z $DBVER ]]; then
  echo "Setting up cluster with GI version: $GIVER and DB version: $DBVER, cluster_type: $cluster_type"
  time ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook /media/stagefiles/ansible-oracle/racattack-full-install.yml -i /media/stagefiles/ansible-oracle/inventory/racattack -e oracle_gi_cluster_type=$cluster_type -e oracle_install_version_gi=$GIVER -e '{"oracle_databases":[{"home":"rachome1","oracle_version_db":"'"$DBVER"'","oracle_edition":"EE","oracle_db_name":"racdb","oracle_db_passwd":"Password1","oracle_db_type":"RAC","is_container":"false","pdb_prefix":"pdb","num_pdbs":"1","is_racone":"false","storage_type":"ASM", "service_name":"racdb_serv","oracle_init_params":"open_cursors=300,processes=500","oracle_db_mem_percent":"25","oracle_database_type":"MULTIPURPOSE","redolog_size_in_mb":"100 " }]}' -e "@$ORAIMAGE"
elif ! [[ -z $GIVER && -z $DBVER ]]; then
  echo "ERROR: Variables giver and dbver needs to be set in pairs. One is missing" 
  echo "e.g setup=standard giver=11.2.0.4 dbver=11.2.0.4"
  echo "e.g setup=standard giver=12.1.0.2 dbver=11.2.0.4"
  exit 1
else
  echo "Default install: GI version: 12.1.0.2 & DB version: 12.1.0.2, cluster type: $cluster_type" 
  time ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook /media/stagefiles/ansible-oracle/racattack-full-install.yml -i /media/stagefiles/ansible-oracle/inventory/racattack -e oracle_gi_cluster_type=$cluster_type 
fi

