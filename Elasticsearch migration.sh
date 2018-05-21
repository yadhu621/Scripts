#######################################################################################################################
## The script needs to be run from graylog1.1.4. It migrates the specified elaticsearch indices to the target cluster.

## graylog1.1.4         10.90.47.220
## LB001347             10.90.41.117

## Pre-requisites
## Register a elasticsearch repo on LB001347 by running steps a,b,c,d
# a. mkdir /appdata/elasticsearch/repo
# b. chown -R elasticsearch:elasticsearch /appdata/elasticsearch/repo
# c. write path.repo = /appdata/elasticsearch/repo in /etc/elasticsearch/elasticsearch.yml file
# d. systemctl restart elasticsearch

## Register a elasticsearch repo on graylog 1.1.4 by running a,b,c
# a. mkdir /var/backups/ESbackups
# b. chown -R graylog:graylog /var/backups/ESbackups
# c. make path.repo = /var/backups/ESbackups in /etc/elasticsearch/elasticsearch.yml file

#######################################################################################################################


## Create a brand new elasticsearch cluster 'graylog'on LB001347 
## ( This step removes all old indices and re-creates a new 'graylog' cluster with a single new index 'graylog_0')
echo "$(date) Creating brand new graylog cluster on LB001347." >> /home/ubuntu/migration.log
ssh LB001347 'rm -rf /appdata/elasticsearch/data/graylog-old'
ssh LB001347 'systemctl stop elasticsearch'
ssh LB001347 'systemctl stop graylog-server'
ssh LB001347 'mv /appdata/elasticsearch/data/graylog /appdata/elasticsearch/data/graylog-old'
ssh LB001347 'systemctl start elasticsearch'
ssh LB001347 'systemctl start graylog-server'
echo "$(date) Brand new graylog cluster created on LB001347." >> /home/ubuntu/migration.log

######################## Elasticsearch backup and restore - 1.1.4 to LB001347 ########################

## Create a backup 'ES_backup_1' at the registered repo /var/backups/ESbackups on graylog1.1.4
curl -XPOST http://10.90.47.220:9200/_snapshot/ES_backup_1 -H 'Content-Type:application/json' -d' 
{
  "type": "fs",
  "settings": {
                "compress" : true,
                "location": "/var/backups/ESbackups" 
   }
}'

## Verify
# curl -XGET http://10.90.47.220:9200/_snapshot/_all?pretty

## Check for existing snapshots
# curl -XGET http://10.90.47.220:9200/_snapshot/ES_backup_1/_all

## Clears contents of ESbackups/
rm -rf /var/backups/ESbackups/*

## Create a snapshot 'snapshot_114' on graylog1.1.4
echo "$(date) Starting to snapshot on graylog1.1.4" >> /home/ubuntu/migration.log
curl -XPUT http://10.90.47.220:9200/_snapshot/ES_backup_1/snapshot_114?wait_for_completion=true -H 'Content-Type:application/json' -d' 
{
  "indices": "graylog_1374,graylog_1375,graylog_1376,graylog_1377,graylog_1378,graylog_1379,graylog_1380,graylog_1381,graylog_1382,graylog_1383"
}'
echo "$(date) Snapshot operation completed on graylog1.1.4." >> /home/ubuntu/migration.log


## Copy the ES snapshot to target server LB001347
ssh LB001347 'rm -rf /appdata/elasticsearch/repo/*'
echo "$(date) Copying ES snapshot to LB001347." >> /home/ubuntu/migration.log
scp -r /var/backups/ESbackups/* LB001347:/appdata/elasticsearch/repo
echo "$(date) Copy operation to LB001347 completed." >> /home/ubuntu/migration.log
ssh LB001347 'chown -R elasticsearch:elasticsearch /appdata/elasticsearch/repo/'



## Create a backup 'ES_backup_1' at the registered repo /appdata/elasticsearch/repo on LB001347
curl -XPUT http://LB001347.rwest.local:9200/_snapshot/ES_backup_1 -H 'Content-Type:application/json' -d' 
{
  "type": "fs",
  "settings": {
                "compress" : true,
                "location": "/appdata/elasticsearch/repo" 
   }
}'


## Verify
# curl -XGET http://LB001347.rwest.local:9200/_snapshot/_all?pretty

## Check for existing snapshots
# curl -XGET http://LB001347.rwest.local:9200/_snapshot/ES_backup_1/_all


## Restore 'snapshot_114' on LB001347
echo "$(date) Starting ES restore on LB001347." >> /home/ubuntu/migration.log
curl -XPOST http://LB001347.rwest.local:9200/_snapshot/ES_backup_1/snapshot_114/_restore?wait_for_completion=true -H 'Content-Type:application/json' -d' 
{
  "indices": "graylog_1374,graylog_1375,graylog_1376,graylog_1377,graylog_1378,graylog_1379,graylog_1380,graylog_1381,graylog_1382,graylog_1383"
}'
echo "$(date) ES Restore operation completed on LB001347." >> /home/ubuntu/migration.log
echo "----------------------------------------------------" >> /home/ubuntu/migration.log




