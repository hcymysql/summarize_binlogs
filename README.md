# summarize_binlogs - MySQL Binlog分析统计概述
参考 [Percona博客](https://www.percona.com/blog/identifying-useful-information-mysql-row-based-binary-logs/) 并对脚本加以修改。

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
## Q1: 按照事务大小进行排序，显示出前10名 - 查看是否存在大事务，大事务是导致主从延迟的真凶！
```
# /root/summarize_binlogs.sh -f mysql-bin.000009 | awk '
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

## Q2：统计哪些表插入/更新/删除语句最多？
```
# /root/summarize_binlogs.sh -f mysql-bin.000009 | awk '
{
  # 提取包含表名的行
  if ($0 ~ /Table : `([^`]+)`\.`([^`]+)`/) {
    db = gensub(/.*Table : `([^`]+)`.*/, "\\1", "g", $0);
    tb = gensub(/.*Table : `[^`]+`\.`([^`]+)`.*/, "\\1", "g", $0);
  }
  
  # 匹配操作类型并记录操作数量
  if ($0 ~ /Query Type : INSERT/) {
    insert[db "." tb]++;
  } else if ($0 ~ /Query Type : UPDATE/) {
    update[db "." tb]++;
  } else if ($0 ~ /Query Type : DELETE/) {
    del[db "." tb]++;
  }
}

# 打印总结
END {
  # 打印标题行
  printf "%-25s %-10s %-10s %-10s %-10s\n", "Table", "INSERT", "UPDATE", "DELETE", "TOTAL";
  printf "---------------------------------------------------------------\n";
  
  # 用数组保存结果行
  for (db_tb in insert) {
    total = insert[db_tb] + update[db_tb] + del[db_tb];
    output[db_tb] = sprintf("%-25s %-10d %-10d %-10d %-10d", db_tb, insert[db_tb], update[db_tb], del[db_tb], total);
    total_count[db_tb] = total; # 用于排序
  }

  # 排序输出
  n = asorti(total_count, sorted, "@val_num_desc");
  for (i = 1; i <= n; i++) {
    db_tb = sorted[i];
    print output[db_tb];
  }
}
'

Table                     INSERT     UPDATE     DELETE     TOTAL     
---------------------------------------------------------------
test.sbtest1              37561      75106      37553      150220    
test.t1                   3          0          0          3   
```
