#!/bin/bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_FILE="$CURRENT_DIR/log_backup"

rm -rf $LOG_FILE

touch $LOG_FILE

log_message() {
        echo -e $1 >> $LOG_FILE
}

log_message "\n\n\n\n\n\n\n"
for i in {1..5}
do
        log_message "====================================***********================================="
done

log_message "\n\n=========== Script start at $(date) ========================"


####### Khai bao thong tin MySQL #######
SQL_USER="root"
SQL_PASS="password"
SQL_DB="asterisk"
SQL_HOST="127.0.0.1"


####### Khai bao thong tin duong dan backup #######
CURRENT_DATE=$(date +"%Y%m%d") 
LAST_WEEK=$(date --date="7 days ago" +"%Y%m%d")
BACKUP_FOLDER="$CURRENT_DIR/databaseBackup"
CURRENT_DATE_FOLDER="$CURRENT_DIR/databaseBackup/$CURRENT_DATE"

####### Khai bao thong tin server backup #######
REMOTE_FOLDER="/backup/store-database"
REMOTE_HOST="172.16.16.100"


####### Khai bao backup asterisk hay khong #######
IS_BACKUP_ASTERISK="true"

####### Tao thu muc chua file backup #######
log_message "create CURRENT_DATE_FOLDER ==========> $CURRENT_DATE_FOLDER"
mkdir -p "$CURRENT_DATE_FOLDER"

####### Bat dau backup file #######

### backup database ###
SQL_CMD="mysqldump -u$SQL_USER -p$SQL_PASS -h$SQL_HOST $SQL_DB > $CURRENT_DATE_FOLDER/asterisk_$CURRENT_DATE.sql"
log_message "\nSQL_CMD ====> $SQL_CMD"
eval "$SQL_CMD"

### backup asterisk configuration ###
if [ "$IS_BACKUP_ASTERISK" = "true" ]; then
	log_message "backup asterisk configuration"
	log_message "Copy /etc/asterisk =============> $CURRENT_DATE_FOLDER/"
	cp -r /etc/asterisk $CURRENT_DATE_FOLDER/

	log_message "Copy /var/lib/asterisk/sounds/en/custom =============> $BACKUP_FOLDER/"
	cp -r /var/lib/asterisk/sounds/en/custom $CURRENT_DATE_FOLDER/

	log_message "Copy /var/lib/asterisk/moh =============> $BACKUP_FOLDER/"
	cp -r /var/lib/asterisk/moh $CURRENT_DATE_FOLDER/
else
	log_message "Backup database only"
fi



####### Dong goi backup file #######
cd $CURRENT_DATE_FOLDER/
TAR_CMD="tar -czf $BACKUP_FOLDER/$CURRENT_DATE.tar.gz *"
log_message "TAR_CMD ====> $TAR_CMD"
eval "$TAR_CMD"

####### Xoa thu muc temp dung de chua file backup #######
rm -rf $CURRENT_DATE_FOLDER


####### Kiem tra lai file vua tao #######
cd $BACKUP_FOLDER
log_message "List file in folder ==========================> $(pwd)"
log_message "$(ls -l)"

log_message "remove oldest local file ==========> $BACKUP_FOLDER/$LAST_WEEK.tar.gz"
rm -rf $BACKUP_FOLDER/$LAST_WEEK.tar.gz

####### Chep file vua tao len backup server #######
if [ ! "$REMOTE_HOST"  ]; then
	log_message "REMOVE_HOST is not defined, backup local only."
else
	log_message "create REMOTE_FOLDER if not existed ===> $REMOTE_FOLDER"
	ssh $REMOTE_HOST "mkdir -p $REMOTE_FOLDER"
	
	log_message "remove oldest remote file ==========> $REMOTE_HOST:$REMOTE_FOLDER/$LAST_WEEK.tar.gz"
	ssh $REMOTE_HOST "rm -rf $REMOTE_FOLDER/$LAST_WEEK.tar.gz"
	
	REMOTE_CMD="scp $BACKUP_FOLDER/$CURRENT_DATE.tar.gz $REMOTE_HOST:$REMOTE_FOLDER"
	log_message "REMOTE_CMD ===========> $REMOTE_CMD"
	eval "$REMOTE_CMD"
fi

log_message "=========================== BACKUP DONE ==========================="

<<COMMENT1
COMMENT1

cat $LOG_FILE

