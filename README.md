# summarize_binlogs - MySQL Binlog分析统计概述
```
# /root/summarize_binlogs.sh
Error: Binlog file is required.
Usage: /root/summarize_binlogs.sh -f <binlog_file> [-s <start_time>] [-e <end_time>]
  -f : MySQL binlog file (required)
  -s : Start time (optional, format: 'YYYY-MM-DD HH:MM:SS')
  -e : End time (optional, format: 'YYYY-MM-DD HH:MM:SS')
```

### 现在我们运行脚本来获取二进制日志中记录的信息摘要
```
# /root/summarize_binlogs.sh -f mysql-bin.000009 | more
Timestamp : #240815 17:19:43 Table : `test`.`sbtest1` Query Type : UPDATE 1 row(s) affected
[Transaction total : 1 ==> Insert(s) : 0 | Update(s) : 1 | Delete(s) : 0] 
+----------------------+----------------------+----------------------+----------------------+
Timestamp : #240815 17:19:43 Table : `test`.`sbtest1` Query Type : UPDATE 1 row(s) affected
[Transaction total : 1 ==> Insert(s) : 0 | Update(s) : 1 | Delete(s) : 0] 
+----------------------+----------------------+----------------------+----------------------+
Timestamp : #240815 17:19:43 Table : `test`.`sbtest1` Query Type : DELETE 1 row(s) affected
[Transaction total : 1 ==> Insert(s) : 0 | Update(s) : 0 | Delete(s) : 1] 
+----------------------+----------------------+----------------------+----------------------+
Timestamp : #240815 17:19:43 Table : `test`.`sbtest1` Query Type : INSERT 1 row(s) affected
[Transaction total : 1 ==> Insert(s) : 1 | Update(s) : 0 | Delete(s) : 0] 
+----------------------+----------------------+----------------------+----------------------+
Timestamp : #240815 17:19:43 Table : `test`.`sbtest1` Query Type : UPDATE 1 row(s) affected
[Transaction total : 1 ==> Insert(s) : 0 | Update(s) : 1 | Delete(s) : 0] 
+----------------------+----------------------+----------------------+----------------------+
Timestamp : #240815 17:19:43 Table : `test`.`sbtest1` Query Type : UPDATE 1 row(s) affected
[Transaction total : 1 ==> Insert(s) : 0 | Update(s) : 1 | Delete(s) : 0] 
+----------------------+----------------------+----------------------+----------------------+
Timestamp : #240815 17:19:43 Table : `test`.`sbtest1` Query Type : DELETE 1 row(s) affected
[Transaction total : 1 ==> Insert(s) : 0 | Update(s) : 0 | Delete(s) : 1] 
+----------------------+----------------------+----------------------+----------------------+
Timestamp : #240815 17:19:43 Table : `test`.`sbtest1` Query Type : INSERT 1 row(s) affected
[Transaction total : 1 ==> Insert(s) : 1 | Update(s) : 0 | Delete(s) : 0] 
+----------------------+----------------------+----------------------+----------------------+
Timestamp : #240815 17:19:43 Table : `test`.`sbtest1` Query Type : UPDATE 1 row(s) affected
[Transaction total : 1 ==> Insert(s) : 0 | Update(s) : 1 | Delete(s) : 0] 
--More--
```
它会逐行对Binlog二进制日志进行分析。

------------------------------

# 使用示例
## Q1: 按照事务大小进行排序，显示出前10名
```
/root/summarize_binlogs.sh -f mysql-bin.000009 | awk '
	/Timestamp :/ {
	  timestamp = substr($0, index($0, "#"), 17)  # Capture 17 characters for full timestamp
	  match($0, /Table : `[^`]+`.`[^`]+`/)
	  table = substr($0, RSTART, RLENGTH)
	}
	/\[Transaction total :/ {
	  gsub("`", "", table)
	  print timestamp, table, $0
	}
' | sort -rn -k9,9 | head -n 10
#240816 10:38:23  Table : test.sbtest1 [Transaction total : 2716 ==> Insert(s) : 2716 | Update(s) : 0 | Delete(s) : 0] 
#240816 10:38:23  Table : test.sbtest1 [Transaction total : 2716 ==> Insert(s) : 2716 | Update(s) : 0 | Delete(s) : 0] 
#240816 10:38:23  Table : test.sbtest1 [Transaction total : 2716 ==> Insert(s) : 2716 | Update(s) : 0 | Delete(s) : 0] 
#240816 10:34:37  Table : test.sbtest1 [Transaction total : 2716 ==> Insert(s) : 2716 | Update(s) : 0 | Delete(s) : 0] 
#240816 10:34:37  Table : test.sbtest1 [Transaction total : 2716 ==> Insert(s) : 2716 | Update(s) : 0 | Delete(s) : 0] 
#240816 10:34:37  Table : test.sbtest1 [Transaction total : 2716 ==> Insert(s) : 2716 | Update(s) : 0 | Delete(s) : 0] 
#240816 10:38:23  Table : test.sbtest1 [Transaction total : 1852 ==> Insert(s) : 1852 | Update(s) : 0 | Delete(s) : 0] 
#240816 10:34:37  Table : test.sbtest1 [Transaction total : 1852 ==> Insert(s) : 1852 | Update(s) : 0 | Delete(s) : 0] 
#240816 10:56:18  Table : test.sbtest1 [Transaction total : 1 ==> Insert(s) : 1 | Update(s) : 0 | Delete(s) : 0] 
#240816 10:56:18  Table : test.sbtest1 [Transaction total : 1 ==> Insert(s) : 1 | Update(s) : 0 | Delete(s) : 0] 
```








