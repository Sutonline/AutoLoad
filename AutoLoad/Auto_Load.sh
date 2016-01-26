#/bin/bash
#Usage:Auto_Load.sh datafile tabname
#Author:sut
#Create at 2016.01.26
#Note


. ./setenv.sh

#define variable
datafile=$1
tabname=$2
ctl_file=""

if [ $# -lt 2 ];then
  echo "Auto_Load.sh datafile tabname"
  exit 1
fi


#begin
tabname=$(echo $tabname|tr [a-z] [A-Z])

#According to the tabname then generate ctl 
sh ./Gen_Control_File.sh $tabname

#check whether ctl file exists and ctl file size great than zero.
ctl_file="$tabname.ctl"
if [ -e $ctl_file ]&&[ ! -z $ctl_file ];then
  sqlldr ${db_user}/${db_password}@${db_sid} control=${ctl_file} data=${datafile} 
  rm $ctl_file
  rm Gen_Control_File.txt
  rm $tabname.log
fi
