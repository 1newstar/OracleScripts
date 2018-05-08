### FRK.ksh (it uses a sourced utility pack, ill send that next);

#!/bin/ksh
#debug:
#set -x
#set -e
######################################################################
#   Disable/enable foreign keys for table operations                 #
#   args(region,system,action,qualifier,like_table,caller_id,TMESTP) #
######################################################################
######################################################################################
#
# LOAD COMMON CODE & GSU
#
######################################################################################
load_common ()
{

## load common code inline
error_proc="finalise"
sourcing_script="${this_module}"
[ ! -z "${CTL_RUN}" ] && silent="-silent" || unset silent
. common_code.conf "${silent}"

}
######################################################################################
#
# VALIDATION
#
######################################################################################
validate_sentargs ()
{

## If CTL wrapper has already validated Region/System, then no need to revalidate
## also region specific envvars should have been exported and be set
## otherwise validate those items.

: ${TMESTP:="$(gsu_datetime timestamp)"}
export TMESTP
[ -z "${VALIDATION_DONE}" ] && basic_argvalidate
[ -z "${CTL_RUN}" ] && export PNET_SETVAR_DISPLAY="true"
load_envvars

## check action is valid ##
case ${Action} in
ENA*) Action="ENABLE";;
DIS*) Action="DISABLE";;
*)    finalise 8 "Arg \$3=${Action} Action is not recognised, valid=ENA*|DIS* [ENABLE|DISABLE]";;
esac

## validate qualifier ##
case ${Qualifier} in
IN*|+*) Qualifier="INCL";;
EX*|-*) Qualifier="EXCL";;
*) finalise 8 "Arg \$4=${Qualifier} Qualifier is not recognised, valid=IN*|+*|EX*|-* [INLC|EXCL]";;
esac

## validate table ##
[ -z "${Table}" ] && finalise 8 "Arg \$5 Table is blank"

## check caller is not blank
[ -z "${Caller}" ] && finalise 8 "Arg \$6 Caller is blank"

## load database config envvars
export DBCONN_DONE= PNET_DBCONN_DISPLAY=true
load_dbconfig

case ${Table} in
+*)  Table="%"
     ;;
*%*) :
     ;;
*)   tabexists="$(gsu_oraobjexist "${PNET_SQLUSER}" "table" "${Table},FRK_CONTROL")"
     EXRC=$?
     case ${EXRC} in
     0) :
        ;;
     4) echo "${tabexists}"
        finalise 8 "Either Arg \$5 Table [${Table}] or reqd control table [FRK_CONTROL] do not exist in current schema ${PNET_TGT_SCHEMA}"
        ;;
     *) finalise 8 "${tabexists}"
        ;;
     esac
     ;;
esac

unset doretry
if [[ ! -z "$(echo "${MAX_SLEEP_TRY}"|gsu_allnum)" && ! -z "$(echo "${SLEEP_SECS}"|gsu_allnum)" ]]; then
   [ ${MAX_SLEEP_TRY} -gt 0 -a ${SLEEP_SECS} -gt 0 ] && doretry="true"
fi

}
######################################################################################
#
# MAIN PROCESSING
#
######################################################################################
do_action ()
{

## display full filenames for information ##
echo "\nInformational output:"
echo "--- General ---"
echo "System       : ${lc_system}"
echo "Region       : ${lc_region}"
echo "Action       : ${Action}"
echo "Table filter : ${Qualifier} ${Table}"
echo "Caller       : ${Caller}"
echo "key for run  : ${Shrt_caller}\n"

like="like '${Table}'"
[ "${Qualifier}" = "EXCL" ] && like="not ${like}"
if [[ "${Action}" = "ENABLE" ]]; then
   perform_enable
else
   perform_disable
fi

}
######################################################################################
# Enable foreign keys
######################################################################################
##frig
perform_enable()
{
FRKload="true"
pull_fromFRKtable
if [[ ${num_constr} -eq 0 ]]; then
   ## status="!= 'ENABLED'"
   unset FRKload
   echo "+ Zero(0) stored disabled constraints for this application(${Shrt_caller}). Table:FRK_CONTROL"
   echo "+ No work to do! run abandoned..RC=0"
   echo "\n${DASHLINE}\n"
   finalise 0
   ## pull_fromDBAtable
fi
apply_array
## [ ! -z "${FRKload}" ] && clear_FRKtable
}
######################################################################################
# Disable foreign keys
######################################################################################
perform_disable ()
{
try=1
[ -z "${doretry}" ] && max=1 || ((max=MAX_SLEEP_TRY))

echo "\n>> Checking for outstanding constraints on table FRK_CONTROL..."
while [ ${try} -lt $((max+1)) ]
do
   echo "${DASHLINE}"
   unset constr_clash
   extract_constraints
   [ -z "${constr_clash}" ] && break 1
   if [[ ${try} -le ${max} ]]; then
      echo ">> Attempt #${try} of ${max}.."
      retry_msg
   fi
   ((try+=1))
done

if [[ ! -z "${constr_clash}" ]] ; then
   finalise 8 "Outstanding constraint actions exist, please check the\n+ other process(es) before retrying this job.\n${DASHLINE}"
else
   echo "+ Zero(0) outstanding clashing constraints\n${DASHLINE}\n"
fi

## zero outstanding constraints exist; see what constraints exist from DBA table
status="= 'ENABLED'" ## status to look for
pull_fromDBAtable
save_constr
apply_array
}
######################################################################################
# Extract foreign key constraints (previously logged on FRK_CONTROL) - if any
######################################################################################
extract_constraints()
{
FKOSQL=$(sqlplus -s <<EOOFRK
       ${PNET_SQLUSER}
       ${STD_SQL_HEADER};
       select substr(rpad(prev.caller_id,12,' '),1,12),
              substr(rpad(NVL(DBA.table_name,'UKNOWN_TABLE'),30,' '),1,30),
              NVL(DBA.constraint_name,'UNKNOWN_CONSTR')
         from ALL_CONSTRAINTS DBA,
              ${PNET_TGT_SCHEMA}.FRK_CONTROL prev
        where DBA.owner = '${PNET_TGT_SCHEMA}'
          and DBA.constraint_type = 'R'
          and DBA.table_name ${like}
          and DBA.table_name = prev.table_name
          and DBA.constraint_name = prev.constraint_name
          and upper(prev.caller_id) != '${Shrt_caller}';
       exit 0
EOOFRK)

SQLRC=$(gsu_oraerror $? "${FKOSQL}")
if [[ ${SQLRC} -ne 0 ]] ; then
   echo;echo "${DASHLINE}";echo
   echo "+ Error in ${this_module} : SQL>while extracting joined constraints from tables:ALL_CONSTRAINTS & ${PNET_TGT_SCHEMA}.FRK_CONTROL"
   echo "+ Position=subr:extract_constraints () #1"
   echo "+ RC=${SQLRC}, SQLRETN:"
   echo "${FKOSQL}"|expand
   echo;echo "${DASHLINE}";echo
   finalise ${SQLRC}
fi
[ "$(echo "${FKOSQL}"|wc -w)" -eq 0 ] && unset constr_clash || constr_clash="true"
}
######################################################################################
# Display retry message (if neccessary)
######################################################################################
retry_msg ()
{
echo ">> Warning : another process has >= 1 clashing constraints $(echo "${Action}"|gsu_lc)d already;"
echo ">> Other procs|         table name          |Constraint key name"
echo ">> -----------|-----------------------------|-------------------"
echo "$(echo "${FKOSQL}"|expand|sed 's/^/>> /g')"
if [[ ${try} -lt ${max} ]]; then
   echo ">> Will retry in ${SLEEP_SECS} seconds.."
   echo ">> Sleeping..."
   sleep ${SLEEP_SECS}
   echo ">> Waking up.."
fi
}
######################################################################################
# Extract foreign key constraints from dba table (if any)
######################################################################################
pull_fromDBAtable ()
{
unset constr_array
echo "${DASHLINE}"
echo ">> Checking status ${status} on table:ALL_CONSTRAINTS..."
FKDSQL=$(sqlplus -s <<EOFKD
       ${PNET_SQLUSER}
       ${STD_SQL_HEADER};
       select distinct NVL(table_name,'UNKNOWN_TABLE'),
                       NVL(constraint_name,'UNKNOWN_CONSTR')
         from all_constraints
        where r_owner = '${PNET_TGT_SCHEMA}'
          and constraint_type = 'R'
          and status ${status}
          and table_name ${like};
       exit 0
EOFKD)

SQLRC=$(gsu_oraerror $? "${FKDSQL}")
if [[ ${SQLRC} -ne 0 ]] ; then
   echo;echo "${DASHLINE}";echo
   echo "+ Error in ${this_module} : SQL>while extracting constraints from table:ALL_CONSTRAINTS only"
   echo "+ Position=subr:pull_fromDBAtable () #1"
   echo "+ RC=${SQLRC}, SQLRETN:"
   echo "${FKDSQL}"|expand
   echo;echo "${DASHLINE}";echo
   finalise ${SQLRC}
fi

num_constr=$(echo "${FKDSQL}"|wc -w)
if [[ ${num_constr} -eq 0 ]]; then
   echo "+ Zero status ${status} constraints found for Tables ${like} on table:ALL_CONSTRAINTS.."
   echo "+ No work to do! run abandoned..RC=0"
   bannerize "Zero(0) constr."
   echo "${DASHLINE}\n"
   finalise 0
fi
echo "+ Ok, found $((num_constr/2)) relevant constraints on table:ALL_CONSTRAINTS..\n"
bannerize "$(echo "$((num_constr/2))"|gsu_commanum) constr."
echo "${DASHLINE}\n"
constr_array=(${FKDSQL})
}
######################################################################################
# Extract foreign key constraints from FRK_CONTROL table (if any)
######################################################################################
pull_fromFRKtable ()
{
unset constr_array
echo "\n>> Checking for relevant constraints on table:FRK_CONTROL..."
echo "${DASHLINE}"
FKFSQL=$(sqlplus -s <<EOFKF
       ${PNET_SQLUSER}
       ${STD_SQL_HEADER};
       select distinct NVL(table_name,'UNKNOWN_TABLE'),
                       NVL(constraint_name,'UNKNOWN_CONSTR')
         from ${PNET_TGT_SCHEMA}.FRK_CONTROL
        where caller_id = '${Shrt_caller}'
          and table_name ${like};
       exit 0
EOFKF)

SQLRC=$(gsu_oraerror $? "${FKFSQL}")
if [[ ${SQLRC} -ne 0 ]] ; then
   echo;echo "${DASHLINE}";echo
   echo "+ Error in ${this_module} : SQL>while extracting constraints from table:FRK_CONTROL only"
   echo "+ Position=subr:pull_fromFRKtable () #1"
   echo "+ RC=${SQLRC}, SQLRETN:"
   echo "${FKFSQL}"|expand
   echo;echo "${DASHLINE}";echo
   finalise ${SQLRC}
fi

num_constr=$(echo "${FKFSQL}"|wc -w)
if [[ ${num_constr} -eq 0 ]]; then
   echo "+ Zero relevant constraints found for Tables ${like} on table:FRK_CONTROL.."
   bannerize "Zero(0) constr."
   ## echo "+ Table ALL_CONSTRAINTS will be checked..."
else
   echo "+ Ok, found $((num_constr/2)) relevant constraints on table:FRK_CONTROL.."
   bannerize "$(echo "$((num_constr/2))"|gsu_commanum) constr."
   constr_array=(${FKFSQL})
fi
echo "${DASHLINE}\n"
}
######################################################################################
# Save extracted constraints to FRK_CONTROL (deduping if neccessary)
######################################################################################
save_constr ()
{
echo ">> Saving extracted constraints to table:FRK_CONTROL..."
echo "${DASHLINE}"
row_attemptcnt=0
ins_cnt=0
loopi=0
while [ ${loopi} -lt ${num_constr} ]
do
   INSSQL=$(sqlplus -s <<INFKD
          ${PNET_SQLUSER}
          ${STD_SQL_HEADER};
          set serveroutput on;
          begin
             insert
               into ${PNET_TGT_SCHEMA}.FRK_CONTROL
                    (caller_id,table_name,constraint_name)
                    (select '${Shrt_caller}',
                            '${constr_array[loopi]}',
                            '${constr_array[loopi+1]}'
                       from DUAL
                      where not exists (select 1
                                          from ${PNET_TGT_SCHEMA}.FRK_CONTROL dedupe
                                         where dedupe.caller_id       = '${Shrt_caller}'
                                           and dedupe.table_name      = '${constr_array[loopi]}'
                                           and dedupe.constraint_name = '${constr_array[loopi+1]}')
                    );
             dbms_output.put_line(SQL%ROWCOUNT);
          end;
          /
          exit 0
INFKD)

   SQLRC=$(gsu_oraerror $? "${INSSQL}")
   if [[ ${SQLRC} -ne 0 ]] ; then
      echo;echo "${DASHLINE}";echo
      echo "+ Error in ${this_module} : SQL>while inserting constraints into table:FRK_CONTROL"
      echo "+ Position=subr:save_constr () #1"
      echo "+ RC=${SQLRC}, SQLRETN:"
      echo "${INSSQL}"|expand
      echo;echo "${DASHLINE}";echo
      finalise ${SQLRC}
   fi

   ((ins_cnt+=$(expr ${INSSQL})))
   ((row_attemptcnt+=1))
   ((loopi+=2))
done

if [[ ${row_attemptcnt} -gt ${ins_cnt} ]]; then
   echo "+ Warning : $((row_attemptcnt-ins_cnt)) rows already existed on table:FRK_CONTROL.."
fi
echo "+ Inserted ${ins_cnt} of total ${row_attemptcnt} constraints into table:FRK_CONTROL.."
echo "${DASHLINE}\n"
}
######################################################################################
# Execute the array directives against the constraints (faster than using table,
# table is just for cross application storage).
######################################################################################
apply_array ()
{
echo ">> Applying constraint changes, setting constraints to ${Action}.."
echo "${DASHLINE}"
[ -z "${doretry}" ] && max=1 || ((max=MAX_SLEEP_TRY))
try=1
loopi=0
while [ ${loopi} -lt ${num_constr} ]
do
   ALTSQL=$(sqlplus -s <<EODALTER
          ${PNET_SQLUSER}
          ${STD_SQL_HEADER};
          alter table ${PNET_TGT_SCHEMA}.${constr_array[loopi]}
                      ${Action} constraint ${constr_array[loopi+1]};
          exit 0
EODALTER)

   SQLRC=$(gsu_oraerror $? "${ALTSQL}")
   if [[ ${SQLRC} -eq 0  ]]; then
      echo "+ OK:${Action} constraint:${constr_array[loopi+1]} for table:${constr_array[loopi]}..RC=${SQLRC}"
      [ "${Action}" = "ENABLE" ] && remove_FRKentry
   else ## SQLRC != 0, an error has occurred
      alterbusyfail=$(echo "${ALTSQL}" | grep -i "ORA-00054\|ORA-04020\|deadlock\|busy")
      if [[ ${max} -le 1 || -z "${alterbusyfail}" ]]; then ## max<=1, ie no retry or not a busy/deadlock error
         echo;echo "${DASHLINE}";echo
         echo "+ SQL Error on ${Action} of constraint;"
         echo "+ constraint name=${constr_array[loopi+1]}"
         echo "+ table name=${constr_array[loopi]}"
         echo "+ RC=${SQLRC} SQLRETN:"
         echo "${ALTSQL}"|expand
         echo;echo "${DASHLINE}";echo
         finalise ${SQLRC}
      fi

      ## retry possible (max>1 and busy/deadlock)
      if [[ ${try} -le ${max} ]]; then
         echo ">> Attempt #${try} of ${max}.."
         echo ">> Warning: System has returned a busy/deadlock msg, retry pending.."
         echo ">> table name     :${constr_array[loopi]}"
         echo ">> constraint name:${constr_array[loopi+1]}"
         echo "$(echo "${ALTSQL}"|sed 's/^/>> /g')"
         if [[ ${try} -lt ${max} ]]; then
            echo ">> Will retry in ${SLEEP_SECS} seconds.."
            echo ">> Sleeping..."
            sleep ${SLEEP_SECS}
            echo ">> Waking up.."
            echo "${DASHLINE}"
         fi
         ((try+=1))
         continue 1
      else
         finalise 8 "Too many attempts ($((try-1)) attempts) aborting job, please rerun ${Caller}\n+ after investigation & resolution\n${DASHLINE}"
      fi
   fi
   ((loopi+=2))
   try=1
done
echo "${DASHLINE}\n"
}
######################################################################################
# clear matching constraints from FRK_CONTROL
######################################################################################
remove_FRKentry ()
{
##echo ">> Removing ${Action}D constraint from table:FRK_CONTROL.."
DELSQL=$(sqlplus -s <<DELFRK
       ${PNET_SQLUSER}
       ${STD_SQL_HEADER};
       delete
         from ${PNET_TGT_SCHEMA}.FRK_CONTROL
        where caller_id = '${Shrt_caller}'
          and table_name = '${constr_array[loopi]}'
          and constraint_name = '${constr_array[loopi+1]}';
       exit 0
DELFRK)

SQLRC=$(gsu_oraerror $? "${DELSQL}")
if [[ ${SQLRC} -ne 0 ]] ; then
   echo;echo "${DASHLINE}";echo
   echo "+ Error in ${this_module} : SQL>while deleting constraints from table:FRK_CONTROL"
   echo "+ Position=subr:remove_FRKentry () #1"
   echo "+ RC=${SQLRC}, SQLRETN:"
   echo "${DELSQL}"|expand
   echo;echo "${DASHLINE}";echo
   finalise ${SQLRC}
fi

echo "+ Purged table_name:${constr_array[loopi]},constraint_name:${constr_array[loopi+1]} from table:FRK_CONTROL\n"
}
######################################################################################
#
# DO FINAL PRE-EXIT PROCESSING (CLEANUP)
#
######################################################################################
finalise ()
{
## $1=RC, defaults to 0 if not supplied
## $2=abort error message (optional - may have already been echoed out by caller)

[ ! -z "$1" ] && final_rc=$1 || final_rc=${RC}
[ ${final_rc} = 1 -a -z "${empty_file}" ] && { final_rc=8;xltmsg="(translated)"; } || unset xltmsg
[ ${final_rc} -ge 0 ] &&  unset noexit || { noexit="true";((final_rc*=-1)); }
[ ! -z "$2" ] && echo "\n${DASHLINE}\n\n+ Error in ${this_module} : $2\n\n${DASHLINE}"

echo ">>FINAL ${this_module} RC=${final_rc}${xltmsg}\n"

gsu_loaded >/dev/null 2>&1 &&
{
   ## put out final messages early (forced into subshell to stop actual exit happening yet)
   if [[ ${final_rc} -eq 0 ]]; then
      echo "$(gsu_cleanexit ${final_rc} "${this_module}")"
   elif [[ ${final_rc} -lt 8 ]]; then
      echo "$(gsu_warnexit ${final_rc} "${this_module}")"
   else
      echo "$(gsu_errorexit ${final_rc} "${this_module}")"
   fi
}

[ -z "${noexit}" ] && exit ${final_rc} || return ${final_rc}

}
##################################################
#                                                #
#        ## ##     #     #####   ##  #           #
#        # # #    # #      #     # # #           #
#        #   #   #####     #     # # #           #
#        #   #   #   #   #####   #  ##           #
#                                                #
##################################################
RC=0
noa=$#
typeset -R6 pid=$$
typeset -R6 ppid=${PPID}
export GSU_REPLCHAR=
which entering_module >/dev/null 2>&1 && . entering_module ||\
{
   : ${DASHLINE:="--------------------------------------------------------------------------------"}
   export DASHLINE
   : ${this_module:="$(basename $0)"}
   : ${Function:="${this_module%%.*}"}
}

: ${HOME:="/opt/nfsexports/OPER"}
export HOME
[ ! -d "${HOME}" ] && finalise 8 "Envvar dir \${HOME} (${HOME}) not found|not readable(check permissions)"
: ${MAIN_CTL_DIR:="${HOME}/CTL_MAIN"}
export MAIN_CTL_DIR
[ ! -d "${MAIN_CTL_DIR}" ] && finalise 8 "Reqd dir ${MAIN_CTL_DIR} not found|not readable(check permissions)"
[ -z "$(echo "${PATH} "|sed 's/:/ /g'|grep -w "${MAIN_CTL_DIR} ")" ] && export PATH=${MAIN_CTL_DIR}:${PATH}

aliaspfx="gsu"
. alias.conf
RC=$?
[ ${RC} -ne 0 ] && finalise ${RC}

Region="$(echo "$1"|gsu_stripwhitespc|gsu_uc)"
lc_region="$(echo "${Region}"|gsu_lc)"
System="$(echo "$2"|gsu_stripwhitespc|gsu_uc)"
lc_system="$(echo "${System}"|gsu_lc)"
Action="$(echo "$3"|gsu_stripwhitespc|gsu_uc)"
Qualifier="$(echo "$4"|gsu_stripwhitespc|gsu_uc)"
Table="$(echo "$5"|gsu_trimfrontback|gsu_uc)"
Caller="$(echo "$6"|gsu_stripwhitespc|gsu_uc)"
typeset -L6 Shrt_caller="${Caller:0:6}"
export TMESTP="$7"

. joblib.conf "${Region}"
RC=$?
[ ${RC} -ne 0 ] && finalise ${RC}

load_common
##pre-validation
if [[ ${noa} -lt 6 ]]; then
   gsu_notenoughargs "noexit:${this_module}" 6 ${noa}\
                     "Valid args=(region,system,action,qualifier,like_table,caller_id,TMESTP[0])"\
                     "$*"
   finalise 8
fi

validate_sentargs
do_action

finalise ${RC}
## -- EOF -- ##
