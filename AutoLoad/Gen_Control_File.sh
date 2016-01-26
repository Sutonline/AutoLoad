#!/bin/bash
#Usage:Gen_Control_File.sh tabName
#Author:sut
#Created at 2016.01.26
#Note

. ./setenv.sh

#input
tabname=$1

#oracle sid
dbname=${db_sid}
#oracle db user
etluser=${db_user}
#oracle db passwd
etlpwd=${db_password}
#ctl生成文件路径
input=.
#日志路径
logdir=./log
#包含所有表名为生成CTL文件做准备的路径
ctrl_path=.
pmid="SC"
tmptable=""
colstr=""
tmpcolstr=""
jobnm=1
etldate=`date +"%Y%m%d"`


[ -d $logdir ]||mkdir -p $logdir
logfile=$logdir/Gen_Control_File.log

#这里生成所有表的CTL文件，需要对sql进行修改
sqlplus -S $etluser/$etlpwd@$dbname << EOF
   set pagesize 0 feedback off verify off heading off echo off;
   spool '${ctrl_path}/Gen_Control_File.txt';
   set linesize 200;
   col table_name format a50;
   col column_name format a50;
   col data_type format a20;
   select A.TABLE_NAME, A.COLUMN_NAME, A.DATA_TYPE, decode(A.DATA_TYPE,'NUMBER',A.DATA_PRECISION,A.DATA_LENGTH) as data_length,DECODE(A.DATA_TYPE,'NUMBER',A.DATA_SCALE,0) as DATA_SCALE
   from user_tab_columns a where a.table_name in (select s.object_name from all_objects  s where s.OBJECT_TYPE='TABLE') and a.table_name like '${tabname}' order by a.table_name,a.column_id;
   spool off
   exit 0;
EOF

while read tabname colname coltype collen colsca
do
  if [ "$tmptable" != "$tabname" -a "$tmptable" != "" ] ; then
     echo `date +%Y-%m-%d-%T` "create load control file : ${tmptable}.ctl" >> $logfile
     colstr=`echo "${tmpcolstr#*,}"`
     echo "load data "$'\n'"CHARACTERSET ZHS16GBK infile ''"$'\n'"truncate into ${tmptable} "$'\n'"fields terminateed by '|' "$'\n'"trailing nullcols (""$colstr"$'\n'")" >${ctrl_path}/${tmptable}.ctl
     tmpcolstr=""
  fi
  
  case "${coltype}" in
  DATE)
    tmpcolstr="${tmpcolstr},"$'\n'"${colname} DATE 'YYYY-MM-DD'"
  ;;
  TIMESTAMP\(0\)|TIMESTAMP\(6\))
    tmpcolstr="${tmpcolstr},"$'\n'"${colname} TIMESTAMP 'YYYY-MM-DD HH24:MI:SS'"
  ;;
  CHAR|VARCHAR2)
    if [ $collen -gt 255 ] ; then
      tmpcolstr="${tmpcolstr},"$'\n'"${colname} char($collen) \"trim(:$colname)\""
    else
      tmpcolstr="${tmpcolstr},"$'\n'"${colname} \"trim(:$colname)\""
    fi
  ;;
  NUMBER)
    Is_cr=$(echo $tabname|grep "T_ARMC")
    if [ $colsca -gt 0 ]  && [ ! -z $Is_cr  ] ; then
      tmpcolstr="${tmpcolstr},"$'\n'"${colname} \"decode(trim(:$colname),'', null,:$colname)/power(10,$colsca)\""
    else
      tmpcolstr="${tmpcolstr},"$'\n'"${colname} DECIMAL EXTERNAL  NULLIF $colname=BLANKS"
    fi      
  ;;
  *)
    tmpcolstr="${tmpcolstr},"$'\n'"${colname}"
  ;;
  esac
  
  tmptable=$tabname
done < ${ctrl_path}/Gen_Control_File.txt

  echo `date +%Y-%m-%d-%T` "create load control file : ${tmptable}.ctl" >> $logfile
  colstr=`echo "${tmpcolstr#*,}"`
  echo "load data "$'\n'"CHARACTERSET ZHS16GBK infile ''"$'\n'"replace into table ${tmptable}"$'\n'"fields terminated by '|' "$'\n'"trailing nullcols ("$'\n'"$colstr"$'\n'")" >${ctrl_path}/${tmptable}.ctl

#if [$? -eq 0 ] ; then
#   sqlplus -S $etluser/$etlpwd@$dbname <<EOF
#   set pagesize 0 feedback off verify off heading off echo off;
#   insert into etl_rwa.t1_pub_etl_log(record_date,job_nm,err_code,err_msg) values(to_date('$etldate','YYYY-MM-DD'),'$jobnm','0','Job Execute Sucessful');
#   exit 0;
#EOF
#else
#   sqlplus -S $etluser/$etlpwd@$dbname <<EOF
#   set pagesize 0 feedback off verify off heading off echo off;
#   insert into etl_rwa.t1_pub_etl_log(record_date,job_nm,err_code,err_msg) values(to_date('$etldate','YYYY-MM-DD'),'$jobnm','-2','Job Execute Failed');
#   exit 0;
#EOF
#fi 
