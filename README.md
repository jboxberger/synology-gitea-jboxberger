Gitea is a community managed fork of Gogs, lightweight code hosting solution written in Go and published under the MIT license. 

Project Page: [https://gitea.io](https://gitea.io)  
Documentation: [https://docs.gitea.io/en-us/](https://docs.gitea.io/en-us/)  
**Download Gitea 1.7.3 SPK**: [here](https://github.com/jboxberger/synology-gitea-jboxberger/releases)  

## Packages:
- https://hub.docker.com/r/gitea/gitea/

## Supported Architectures
**x86 avoton bromolow cedarview braswell kvmx64 broadwell apollolake**  
Since i can't test all architectures i had to make a choice which i can cover or which i expect to work. If your architecture is not in this list, please feel free to contact me and we can give it a try.  

You can check the architecture of your device [here](https://github.com/SynoCommunity/spksrc/wiki/Architecture-per-Synology-model) 
or [here](https://www.synology.com/en-us/knowledgebase/DSM/tutorial/General/What_kind_of_CPU_does_my_NAS_have).

## Version Enumeration
```
Gitea <Gitea-Version>-<Package-Version> (Gitea 1.4)
Gitea-Version:  as expected the GitLab version
Package-Version: version of the application around GitLab, install backup an other scripts
```

## Enable / Disable SSL
After setup (install package and setup gitea) you can enable or disable self-signed-ssl connection
```
# enable
sudo ./var/packages/synology-gitea-jboxberger/scripts/gitea-ssl enable
```
```
# disable
sudo ./var/packages/synology-gitea-jboxberger/scripts/gitea-ssl disable
```

## Use MySQL/MariaDB instead of SQLite3
By default you can use SQLite3, this is a fast and reliable one file database solution. If your Gitea serves a couple of developers this should be more than sufficient but if you run your environment for more than 10 developers then you might have better performance with MySQL/MariaDB.
```
1. Install the official MairaDB10 Package from Synology repository and set the root password.
2. Create databse schema and user for gitea. If you're not familliar with mysql cli then you 
   can install phpmyadmin from official synology repository.

   CREATE DATABASE `gitea` DEFAULT CHARACTER SET `utf8mb4` COLLATE `utf8mb4_general_ci`;
   CREATE USER `gitea`@'%' IDENTIFIED BY '<mypassword>';
   GRANT ALL PRIVILEGES ON `gitea`.* TO `gitea`@`%`;

   CREATE USER `gitea`@'localhost' IDENTIFIED BY '<mypassword>';
   GRANT ALL PRIVILEGES ON `gitea`.* TO `gitea`@`localhost`;

3. Now you can selecte MariaDB during the Gitea setup and the rest of the schema will be created automatically 
   during the Gitea setup.
4. Don't forget to backup your database regulary, this schema will not be backuped in the included backup script.
```
 
## Bash into your Gitea container
```
sudo docker exec -it synology_gitea bash
```

## Backup
```
# create backup directory
sudo mkdir -p /volume1/docker/gitea/backups 
sudo chown 1000:1000 /volume1/docker/gitea/backups

# create backup
sudo /usr/local/bin/docker exec -it -u git synology_gitea bash -c "cd /data/backups && gitea dump -c /data/gitea/conf/app.ini && chmod -R 777 /data/backups/*"
```

## Restore
```
sudo docker exec -it synology_gitea bash 
cd /data/backups
rm -rf gitea-dump && mkdir gitea-dump && unzip gitea-dump-1551647895.zip -d gitea-dump/ && cd gitea-dump/
mv custom/conf/app.ini /data/gitea/conf/app.ini
rm -rf /data/gitea/attachments && mv custom/attachments/ /data/gitea

rm -rf gitea-repo && mkdir gitea-repo && unzip gitea-repo.zip -d gitea-repo/
rm -rf /data/git/repositories && mv gitea-repo/* /data/git/

# restore MYSQL
mysql -u$USER -p$PASS $DATABASE <gitea-db.sql
# restore SQLITE
rm /data/gitea/gitea.db && sqlite3 /data/gitea/gitea.db <gitea-db.sql

# set permissions
chown -R git:git /data/gitea/attachments /data/git/repositories /data/gitea/conf/app.ini /data/gitea/gitea.db

# cleanup
cd .. && rm -rf gitea-dump/
exit 

# restart gitea container
sudo /var/packages/synology-gitea-jboxberger/scripts/start-stop-status stop
sudo /var/packages/synology-gitea-jboxberger/scripts/start-stop-status start
```

## SPK Changelog
```
xx.x.x-0101
- removed custom backup scripts, added backup procedure from https://docs.gitea.io/en-us/backup-and-restore
```
