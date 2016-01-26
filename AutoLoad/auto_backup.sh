#/bin/bash 
#Usage:auto_backup.sh back_date 
#Author:
#History:

#define variables
v_user="scetl"
v_password="scetl"
v_sid="scdmdbs"

v_limit_num=7
v_backup_dir="/sc/etl/bin/sqlscripts"
v_date=`date +"%Y%m%d"`
v_old_date=`date +"%Y%m%d" -d "7 days ago"`

#need log
v_log_dir="/sc/etl/log/msg"


#define function
#execute sql output content
function sql_exec(){
}

#begin
v_back_dir="${v_back_dir}/${v_date}"
[ -d ${v_back_dir} ]||mkdir ${v_back_dir}
v_old_dir="${v_back_dir}/${v_date}"
[ -d ${v_old_dir} ]||rm -rf ${v_old_dir}

all_tables=`sql_exec "select table_name from user_tables"`
for v_tab in ${all_tables}
do
  `sql_exec "select dbms_metadata.get_ddl(${v_tab}) from dual"` > "${v_backup_dir}/${v_tab}.SQL"
done
all_procedure=`sql_exec "select name from user_procedures"`
for v_proc in ${all_procedures}
do
  `sql_exec "select dbms_metadata.get_ddl(${v_proc}) from dual"` > "${v_backup_dir}/${v_proc}.SQL"
done

