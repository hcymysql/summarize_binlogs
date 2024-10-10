#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 -f <binlog_file> [-s <start_time>] [-e <end_time>]"
    echo "  -f : MySQL binlog file (required)"
    echo "  -s : Start time (optional, format: 'YYYY-MM-DD HH:MM:SS')"
    echo "  -e : End time (optional, format: 'YYYY-MM-DD HH:MM:SS')"
    exit 1
}

# Parse command line options
while getopts "f:s:e:" opt; do
    case $opt in
        f) BINLOG_FILE="$OPTARG" ;;
        s) START_TIME="$OPTARG" ;;
        e) END_TIME="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if BINLOG_FILE is provided
if [ -z "$BINLOG_FILE" ]; then
    echo "Error: Binlog file is required."
    usage
fi

# Construct mysqlbinlog command
MYSQL_CMD="/usr/bin/mysqlbinlog --base64-output=decode-rows -vv"

if [ ! -z "$START_TIME" ]; then
    MYSQL_CMD="$MYSQL_CMD --start-datetime=\"$START_TIME\""
fi

if [ ! -z "$END_TIME" ]; then
    MYSQL_CMD="$MYSQL_CMD --stop-datetime=\"$END_TIME\""
fi

MYSQL_CMD="$MYSQL_CMD $BINLOG_FILE"

# Execute the command and process with awk
$MYSQL_CMD | awk '
BEGIN {
    s_type=""; s_count=0; count=0; insert_count=0; update_count=0; delete_count=0; flag=0;
    in_transaction = 0;
}
{
    if (match($0, /^#[0-9]+ [0-9:]+\s+server id\s+[0-9]+\s+end_log_pos [0-9]+\s+Table_map:/)) {
        if (in_transaction && (count > 0 || insert_count > 0 || update_count > 0 || delete_count > 0)) {
            print "[Transaction total : " count " Insert(s) : " insert_count " Update(s) : " update_count " Delete(s) : " delete_count "] \n+----------------------+----------------------+----------------------+----------------------+";
            count=0; insert_count=0; update_count=0; delete_count=0;
        }
        timestamp = $1 " " $2;
        table_info = $0;
        sub(/^.*Table_map: /, "", table_info);
        sub(/ mapped to number.*$/, "", table_info);
        printf "Timestamp : %s Table : %s", timestamp, table_info;
        flag = 1;
        in_transaction = 1;
    } 
    else if (match($0, /### INSERT INTO/)) {
        count++; insert_count++; s_type="INSERT"; s_count++;
    }  
    else if (match($0, /### UPDATE/)) {
        count++; update_count++; s_type="UPDATE"; s_count++;
    } 
    else if (match($0, /### DELETE FROM/)) {
        count++; delete_count++; s_type="DELETE"; s_count++;
    }  
    else if (match($0, /^# at [0-9]+/) && flag==1 && s_count>0) {
        print " Query Type : " s_type " " s_count " row(s) affected";
        s_type=""; s_count=0; flag=0;
    }
    else if (match($0, /^# End of log file/)) {
        if (in_transaction && (count > 0 || insert_count > 0 || update_count > 0 || delete_count > 0)) {
            print "[Transaction total : " count " Insert(s) : " insert_count " Update(s) : " update_count " Delete(s) : " delete_count "] \n+----------------------+----------------------+----------------------+----------------------+";
        }
    }
}
END {
    if (in_transaction && (count > 0 || insert_count > 0 || update_count > 0 || delete_count > 0)) {
        print "[Transaction total : " count " Insert(s) : " insert_count " Update(s) : " update_count " Delete(s) : " delete_count "] \n+----------------------+----------------------+----------------------+----------------------+";
    }
}
'
