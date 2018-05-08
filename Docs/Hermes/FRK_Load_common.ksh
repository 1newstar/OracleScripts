Sourced utility pack;

#!/bin/ksh
#debug:
#set -x
#set -e
########################################################################################################
## See usage below:
## Note: some of the code is long winded, this is done deliberately so that we can successfully source 
##       from shells other than ksh (eg havent used some of the more powerfull ksh cmds/structs).
########################################################################################################
gsu_usage ()
{
echo " "
echo "###########################################################################################################"
echo " general_sourced_utils.conf usage:"
echo " Note: This code MUST be sourced to be usable in current shell"
echo "     : Export envvar GSU_DEBUG as none blank before calling these to get extra output (for debug)."
echo " "                    
echo " Function(func): Purpose                             Args|o=optional,    Calls:"
echo " --------------- -------                             ----|m=mandatory    ------"
echo " gsu_loaded      See if this file sourced or not.    none"                
echo " gsu_istype      Test if string is data type.        type[m],string[o]" 
echo " gsu_epoch       Return current epoch time(secs).    unique[o]"                 
echo " gsu_datetime    Return current date/time formats.   format[m]           func:gsu_epoch"
echo " gsu_tempstore   Make or generate unique file/dir.   type[m]"
echo " gsu_fileinfo    Return various file info.           info[m],file[m]"
echo " gsu_randomnum   Return random number.               lower#[o],upper#[o] func:gsu_istype"
echo " gsu_thread      Return next thread/delete current.  action[m],          func:gsu_istype"
echo "                                                     currthreadno#[o]" 
echo " gsu_dnslookup   Returns dname+ip given dname|ip.    ip-or-dnsname [o]   func:gsu_trimchar"
echo " gsu_trimchar    Trims char(s) from string/file.     trimposn[m],        func:gsu_tempstore"
echo "                                                     stringorfile[m]"
echo "                 Set envvar GSU_REPLCHAR to change"
echo "                 the char(s) to trim(default=' ')." 
echo " gsu_strip       Shortcut to gsu_trimchar.           stringorfile[m]     func:gsu_trimchar"
echo " gsu_searchcache Return found offset of row for      searchvalue[m]      func:gsu_istype"
echo "                 given search value.                 arrayname[m]"
echo "                 See subr:gsu_cachefile." 
echo " gsu_seprarray   seperate single named array by      seperatorchar(s)[m] func:gsu_istype" 
echo "                 char(s) specified(not destructive)  arrayname[m]"
echo " gsu_pathsearch  search \$PATH dirs for existence    filename[o]"
echo "                 of a file name [which only does -x]"
echo " gsu_oraerror    Scan oracle string for error.       oraRC#[o],string[o] func:gsu_istype"
echo " gsu_sqlavail    Check if sqlplus is callable and    orauidpasswrd[m],"
echo "                 reqd envvar \$PNET_TGT_SCHEMA set.  callingfunc[o]"
echo "                 Mainly called internally."   
echo " gsu_oraobjexist Check if an oracle object exists.   orauidpasswrd[m],   func:gsu_sqlavail,gsu_oraerror"
echo "                 Requires envvars \$PNET_TGT_SCHEMA, objtype[m],"
echo "                 and possibly \$TWO_TASK to be set.  [objname1 ... n][m]"
echo " gsu_oratrunctab Truncate passed table(s)            orauidpasswrd[m],   func:gsu_sqlavail,gsu_oraerror"
echo "                 Requires envvars \$PNET_TGT_SCHEMA, [objname1 ... n][m]"
echo "                 and possibly \$TWO_TASK to be set."  
echo " " 
echo " On error return:"
echo " error message will be in function variable(assignee)"
echo " \$?=returned RC (0 ok|3-7 warning|>=8 error)"
echo " "                    
echo " Subroutine(subr): Purpose                           Args|o=optional,    Calls:"
echo " ----------------- -------                           ----|m=mandatory    ------"
echo " gsu_checktty      Sets \${PNET_TTY} if screen avail. none"    
echo " gsu_mytee         Tees string to both screen-       string[o],file[o],"
echo "                   (if available) & file.            echoparms[o]"
echo " gsu_startendmsg   Echo start/end program msgs.      action[o],caller[o]"
echo " gsu_errorexit     Force error exit(+msgs).          RC#[o],caller[o],   subr:gsu_allexits"
echo "                                                     logfile[o]"
echo " gsu_warnexit      Force warn exit (+msgs).          as gsu_errorexit   subr:gsu_allexits"
echo " gsu_cleanexit     Force clean exit (+msgs).         as gsu_errorexit   subr:gsu_allexits"
echo " gsu_allexits      General exit routine for          RC#[o],caller[o],   subr:gsu_mytee"
echo "                   gsu_errorexit,gsu_warnexit        exitmessage[o],"
echo "                   & gsu_cleanexit                   logfile[o]"
echo " gsu_archivefile   Archive passed file(s).           filename(s)[m],     func:gsu_makemoddir"
echo "                                                     tofilename(s)[o]"
echo " gsu_handletrailer Add/Remove envvar trailer record. action[m],trec[m],  func:gsu_tempstore"
echo "                                                     filename(s)[m]"
echo " gsu_makemoddir    Make dir(s) & chmod it/them       modvl#[o],dir(s)[o] func:gsu_istype"
echo " gsu_srcfile       Source a specified file           caller[o],          func:gsu_tempstore,gsu_thread"
echo "                                                     module[m],arg(s)[o]"
echo " gsu_notenoughargs Produce 'not enough args' error   caller[m],minarg#[m],"
echo "                                                     rcdargs#[m],usage[o],"
echo "                                                     rcdargs[o]"
echo " gsu_sshutils      Gateway to various SSH related    (uid@)server[m],    func:gsu_strip,subr:gsu_sshaction,"
echo "                   sub functions (see below)         subfunc[m],         gsu_scpaction,gsu_sftpaction"
echo "                                                     subfunc-arg(s)[m|o] see below"
echo " gsu_sshaction     Perform SSH actions: and/or       (uid@)server[m],    func:gsu_randomnum,gsu_tempstore,gsu_strip," 
echo "                   a) execute remote commands        file-or-cmds[o=(:|\"\")] gsu_istype"
echo "                   b) pull remote envvars to local   remote-envvar(s)[o]"
echo " gsu_scpaction     Perform SCP actions:              (uid@)server[m],    func:gsu_strip" 
echo "                                                     cpydirection[m],"
echo "                                                     localfile[m],"
echo "                                                     remotefile[m]" 
echo "                                                     remote-envvar(s)[o]"
echo " gsu_sftpaction    Perform SFTP actions:             (uid@)server[m],    func:gsu_strip" 
echo "                                                     file-or-cmds[m]"
echo " gsu_cachefile     Cache flat file fields-->arrays   filename[m]         func:gsu_strip"
echo "                                                     filefieldseperator[m]"
echo "                                                     arrayname(s)[m]" 
echo " gsu_procstat      Return process run state info     pidofprocess[m],    func:gsu_istype,gsu_strip"
echo "                   envvars are set on return which   processname[m]"
echo "                   describe the run state"   
echo " " 
echo " On error return:"
echo " Error message is echoed to screen/log" 
echo " \$?=returned RC (0 ok|3-7 warning|>=8 error)"
echo " " 
echo "###########################################################################################################"
echo " "
}
########################################################################################################
#############
# FUNCTIONS #
#############
#######################################################################################################
function gsu_loaded
{
## no args
## returns true & RC=0, intended to be used to see if this file sourced yet or not
GSU_RC=0
echo true
return ${GSU_RC}
}
#######################################################################################################
function gsu_istype
{
## $1=a*|n* [alpha|numeric]
## $2=string to test
## returns null if $2 not type $1 or "true" if it is 
GSU_RC=0
set - "$(echo "$1"|gsu_lc)" "$2"
case "$1" in
a*) [ -z "$(echo "$2"|egrep ^[[:alpha:]]+$)" ] && echo || echo true
    ;;
n*) set - $1 ${2#*-}
    set - $1 ${2#*+}
    [ -z "$(echo "$2"|egrep ^[[:digit:]]+$)" ] && echo || echo true
    ;;
*)  echo "\n+ Error : Function=gsu_istype, arg \$1=$1 not recognised [a*|n*]\n "
    GSU_RC=8
    ;; 
esac
return ${GSU_RC}
}
########################################################################################################
function gsu_epoch 
{
## $1=u*|* [unique|*]
## returns current epoch now
GSU_RC=0
set - "$(echo "$1"|gsu_lc)"
case $1 in
u*) sleep 1 ## put 1 sec on clock to make gsu_epoch unique from any other
    ;;
*)  :
    ;;
esac
echo $(date +%s)
return ${GSU_RC}
}
########################################################################################################
function gsu_datetime
{
## $1=d*|e*|y*|mo*|day|time|h*|mi*|s*|n*|(times*|ts)|(timestampf*|tsf)|* 
##   [date|gsu_epoch|year|month|day|time|hour|min|second|nanosec|timestamp|timestampfull]
## returns requested date/time combo
GSU_RC=0
set - "$(echo "$1"|gsu_lc)"
case $1 in
day)         echo $(date +%d)             ## day of month eg 12
             ;;
d*)          echo $(date +%F)             ## date eg 2011-05-12
             ;;
e*)          gsu_epoch                    ## current gsu_epoch eg 1305315822
             ;; 
mo*)         echo $(date +%m)             ## month eg 05
             ;;
y*)          echo $(date +%Y)             ## year eg 2011
             ;;
time)        echo $(date +%H.%M:%S)       ## time eg 23.01:23
             ;;
h*)          echo $(date +%H)             ## houreg 23
             ;;  
mi*)         echo $(date +%M)             ## minute eg 01
             ;;
s*)          echo $(date +%S)             ## second eg 23
             ;;
n*)          echo $(date +%N)             ## nanosecond eg 487390004
             ;;                 
timestampf*|tsf)
             echo $(date +%F-%H.%M.%S.%N) ## full timestamp eg 2011-05-12-23.01.23.487390004
             ;;             
times*|ts)   echo $(date +%F-%H.%M:%S)    ## timestamp eg 2011-05-12-23.01:23
             ;;
*)           echo "\n+ Error : Function=gsu_datetime, arg \$1=$1 not recognised\n+ [d*|e*|y*|mo*|day|time|h*|mi*|s*|n*|(times*|ts)|(timestampf*|tsf)]\n "
             GSU_RC=8 
             ;;             
esac  
return ${GSU_RC} 
}
########################################################################################################
function gsu_fileinfo
{
## $1=function=c*|l*|w*|s* [characters|linecount|words|size(in bytes)]
## $2=filename (+path)
## returns stats about a file
GSU_RC=0
set - "$(echo "$1"|gsu_lc)" $2
if [[ ! -f "$2" ]]; then
   echo "\n+ Error : Function=gsu_fileinfo, arg \$2=$2 file not found\n "
   GSU_RC=8
else
   case $1 in
   c*) echo $(expr "$(wc -m "$2"|cut -d' ' -f1)")
       ;;   
   l*) echo $(expr "$(wc -l "$2"|cut -d' ' -f1)")
       ;;
   w*) echo $(expr "$(wc -w "$2"|cut -d' ' -f1)")
       ;; 
   s*) typeset cmdstat lenstr filesize goodsize 
       if [[ ! -z "$(uname -a|grep -i "AIX")" ]]; then
          filesize=$(istat $2|sed '/^.*Length */!d; s///;q'|cut -d' ' -f1)
       else
          filesize=$(stat -c %s $2)
       fi 
       goodsize=$(echo ${filesize}|gsu_allnum)
       if [[ ! -z "${goodsize}" ]]; then ## the extracted filesize is numeric
          echo ${filesize}
       else ## something went wrong, file size not all numeric
          echo "\n+ Error : Function=gsu_fileinfo, sizing file, cmd ${cmdstat} returned : ${filesize}"
          GSU_RC=8
       fi
       ;;       
   *)  echo "\n+ Error : Function=gsu_fileinfo, arg \$1=$1 not recognised [c*|l*|w*]\n "
       GSU_RC=8
       ;; 
   esac
fi

return ${GSU_RC}
}
########################################################################################################
function gsu_tempstore
{
## $1=d*|f*|g* [directory|file|generate(no make)]
## makes(or generates) and returns name of a unique temporary directory or file.
## Note: have not used mktemp here because of usual AIX problems(ie not installed)
GSU_RC=0
set - "$(echo "$1"|gsu_lc)"
case $1 in
d*|f*|g*) :
    while true 
    do
       gsu_node1="$(gsu_randomnum)" || { GSU_RC=$?;echo "${gsu_node1}";return ${GSU_RC}; }
       gsu_node2="$(gsu_epoch)" || { GSU_RC=$?;echo "${gsu_node2}";return ${GSU_RC}; }
       gsu_genobj="/tmp/${gsu_node1}.${gsu_node2}"
       [ -d "${gsu_genobj}" -o -f "${gsu_genobj}" ] && continue 1 ## already exists, try again
       if [[ "$1" == d* ]]; then
          mkdir -p "${gsu_genobj}" 
       elif [[ "$1" == f* ]]; then
          touch "${gsu_genobj}"
       fi
       break 1
    done
    echo "${gsu_genobj}"
    ;;
*)  echo "\n+ Error : Function=gsu_tempstore, arg \$1=$1 not recognised [d*|f*|g*]\n "
    GSU_RC=8
    ;;
esac
return ${GSU_RC}
}
########################################################################################################
function gsu_randomnum
{
## $1=min number [0-9*], default=0
## $2=max number [0-9*], default=32767
## generates a random number between $1 & $2
GSU_RC=0
if [[ ! -z "$1" ]]; then
   gsu_mintest="$(gsu_istype "numeric" "$1")" || unset gsu_mintest
   [ -z "${gsu_mintest}" ] && set - 0 "$2"
else
   set - 0 "$2"
fi
if [[ ! -z "$2" ]]; then
   gsu_maxtest="$(gsu_istype "numeric" "$2")" || unset gsu_maxtest
   [ -z "${gsu_maxtest}" ] && set - "$1" 32767
else
   set - "$1" 32767
fi
[ $2 -lt $1 ] && set - "$2" "$1"
[ $1 -eq $2 ] && echo $1 || echo $(( RANDOM % ($2 - $1) + $1 ))
return ${GSU_RC}
}
########################################################################################################
function gsu_thread
{
## $1=a*|d* [add|delete]
## $2=gsu_thread number
## add or delete gsu_thread
GSU_RC=0
set - "$(echo "$1"|gsu_lc)" $2
case $1 in 
a*) gsu_addtest="$(gsu_istype "numeric" "$2")" || { GSU_RC=$?;echo "${gsu_addtest}";return ${GSU_RC}; }
    [ ! -z "${gsu_addtest}" ] && echo $(expr $2 + 1) || echo 0
    ;;
d*) gsu_deltest="$(gsu_istype "numeric" "$2")" || { GSU_RC=$?;echo "${gsu_deltest}";return ${GSU_RC}; }
    if [[ ! -z "${gsu_deltest}" ]]; then
       [ $2 -eq 0 ] && echo || echo $(expr $2 - 1) 
    else
       echo
    fi
    ;;
*)  echo "\n+ Error : Function=gsu_thread, arg \$1=$1 not recognised [a*|d*]\n "
    GSU_RC=8
    ;;       
esac
return ${GSU_RC}
}
########################################################################################################
function gsu_dnslookup
{
# $1=ip-address or dnsname
# purpose - to output "GSU_DNAME=dname GSU_IP=ip" given dname or ip in $1
GSU_RC=0
export GSU_REPLCHAR=
while [ ! -z "$1" ]
do
   dig -v >/dev/null 2>/dev/null
   GSU_RC=$?
   if [[ ${GSU_RC} -ne 0 ]]; then
      echo "\n+ Error : Function=gsu_dnslookup, 'dig' command not callable(RC=${GSU_RC})\n "
      break 1     
   fi
   gsu_server="$(echo "$1"|cut -d'@' -f2)"                                     ## remove uid if included
   gsu_dname2ip="$(dig "${gsu_server}" +search +short)"                                ## try dname->ip
   [ -z "${gsu_dname2ip}" ] && gsu_ip2dname="$(dig -x "${gsu_server}" +search +short)" ## try ip->dname
   if [[ ! -z "${gsu_dname2ip}" || ! -z "${gsu_ip2dname}" ]]; then
      [ -z  "${gsu_ip2dname}" ] && gsu_digout="GSU_DNAME=${gsu_server}" || gsu_digout="GSU_DNAME=${gsu_ip2dname}"
      gsu_digout="$(echo "${gsu_digout}"|sed -e 's/\.$//')"
      [ -z  "${gsu_dname2ip}" ] && gsu_digout="${gsu_digout} GSU_IP=${gsu_server}" || gsu_digout="${gsu_digout} GSU_IP=${gsu_dname2ip}"
      echo "${gsu_digout}"|sed -e 's/\.$//'   
   else
      echo "\n+ Error : Function=gsu_dnslookup, arg host \$1=$1 not found\n "
      GSU_RC=8
   fi
   break 1
done
return ${GSU_RC} 
}
########################################################################################################
function gsu_strip
{
# $1..$n(or "$1" for all)=string or file(+path) to trim envvar ${GSU_REPLCHAR} character from
# purpose - shortcut to gsu_trimchar with hardcoded 'all' trim posn
GSU_RC=0
gsu_strip="$(gsu_trimchar "all" "$*")"
GSU_RC=$?
echo "${gsu_strip}"
return ${GSU_RC}
}
########################################################################################################
function gsu_trimchar
{
# $1=trim posn, where to trim char(s) from [l*|t*|b*|a*] [leading|trailing|both|all]
# $2..$n(or "$2" for all)=string or file(+path) to trim chars from
# For file processing, prefix $2(file+path) with 'file:', otherwise it will be treated as a string
# envvar; set GSU_REPLCHAR to character you wish to trim (default=' '(1xspace))
# purpose - remove chars from sepcified posn 
GSU_RC=0
while true
do
   gsu_trimposn="$(echo "$1"|gsu_lc)"  
   [ -z "${GSU_REPLCHAR}" ] && GSU_REPLCHAR="[ \t]"
   case ${gsu_trimposn} in
   l*) gsu_sedstr="s/^${GSU_REPLCHAR}*//"                        ## Leading
       ;;
   t*) gsu_sedstr="s/${GSU_REPLCHAR}*$//"                        ## Trailing
       ;;
   b*) gsu_sedstr="s/^${GSU_REPLCHAR}*//;s/${GSU_REPLCHAR}*$//g" ## Both
       ;;
   a*) gsu_sedstr="s/${GSU_REPLCHAR}//g"                         ## All
       ;;
   *)  echo "\n+ Error : Function=gsu_trimchar, arg \$1=$1 not recognised [l*|t*|b*|a*]\n "
       GSU_RC=8
       break 1
       ;;      
   esac

   shift 1
   if [[ $# -eq 0 ]]; then
      echo "\n+ Error : Function=gsu_trimchar, arg \$2 (file/string) is blank\n "
      GSU_RC=8
      break 1
   fi
   
   gsu_stringorfile="$*" 
   if [[ "echo ${gsu_stringorfile:0:5}|gsu_lc}" = "file:" ]]; then            ## string contains a 'file:'
      gsu_stringorfile="$(echo ${gsu_stringorfile:5:${#gsu_stringorfile}-5})" ## remove 'file:'
      if [[ -f "${gsu_stringorfile}" ]]; then
         gsu_tempfile="$(gsu_tempstore "file")" || { GSU_RC=$?;echo "${gsu_tempfile}";return ${GSU_RC}; }
         sed -e "${gsu_sedstr}" "${gsu_stringorfile}" >${gsu_tempfile} 2>&1
         GSU_RC=$?
         if [[ ${GSU_RC} -ne 0 ]]; then
            echo "\n+ Error : Function=gsu_trimchar, sed returned RC=${GSU_RC} sed out=$(cat ${gsu_tempfile})\n "
            GSU_RC=8
            rm -f ${gsu_tempfile}
            break 1         
         fi
         mv ${gsu_tempfile} ${gsu_stringorfile}
         echo "file=${gsu_stringorfile}"                ## return "file=$filename" on file trimchar
      else   
         echo "\n+ Error : Function=gsu_trimchar, arg \$2 file trim requested but file not found (${gsu_stringorfile})\n "
         GSU_RC=8
         break 1         
      fi
   else
      echo "${gsu_stringorfile}"|sed -e "${gsu_sedstr}" ## return trimmed string on string trimchar
   fi
   break 1
done

return ${GSU_RC} 
}
########################################################################################################
function gsu_searchcache
{
## $1=value to search cache array for 
## $2=cache array field to scour down
## Return an array subscript(vertical) if a passed value was found in the cached 
## column field(array) from gsu_cachefile, that subscript can then be used to access the other
## fields(horizontal) of that row - search is case insensitive, and stops on 1st hit.
## Return values=0 to array max if found or -1 if not found 
GSU_RC=0
while true
do
   if [[ $# -lt 2 ]]; then
      echo "\n+ Error : Function=gsu_searchcache, expected at least 2 args, detected $# ($*)\n "
      GSU_RC=8
      break 1 
   elif [[ -z "$1" ]]; then
      echo "\n+ Error : Function=gsu_searchcache, arg \$1 search for value passed is blank\n "
      GSU_RC=8
      break 1     
   elif [[ -z "$2" ]]; then
      echo "\n+ Error : Function=gsu_searchcache, arg \$2 cached column field passed is blank\n "
      GSU_RC=8
      break 1
   fi

   gsu_columnwrk="echo \${$2[*]}"
   gsu_columnxpnd="$(eval ${gsu_columnwrk})"
   if [[ ${#gsu_columnxpnd} -eq 0 ]]; then 
      echo "\n+ Error : Function=gsu_searchcache, arg \$2=$2 cached column field contains no data\n "
      GSU_RC=8
      break 1 
   fi
   gsu_fndoffset=$(echo "${gsu_columnxpnd}"|sed 's/ /\n/g'|grep -m 1 -inw "$1"|cut -d':' -f1)
   if [[ -z "${gsu_fndoffset}" ]]; then ## not found in array
      echo -1
      break
   fi
   
   gsu_idxnumeric="$(gsu_istype "numeric" "${gsu_fndoffset}")" || { GSU_RC=$?;echo "${gsu_idxnumeric}";return ${GSU_RC}; }
   
   if [[ -z "${gsu_idxnumeric}" ]]; then ## got something back, but wasnt numeric
      echo -1
      break
   elif [[ ${gsu_fndoffset} -le 0 ]]; then ## was numeric, is it in range?
      echo -1
      break  
   fi
   
   ## grep -n gives us an offset starting at 1, but the array will start at 0, so have to reduce by 1
   ((gsu_fndoffset-=1))
   echo ${gsu_fndoffset}
   break 1

done
return ${GSU_RC} 
}
########################################################################################################
function gsu_seprarray
{
## $1=seperator value (char(s)) 
## $2=arrayname
## Echo back the single whole array named in $2,elements seperated by $1 
GSU_RC=0
gsu_rebuild=
while true
do
   if [[ $# -lt 2 ]]; then 
      echo "\n+ Error : Function=gsu_seprarray, expected at least 2 args, detected $# ($*)\n "
      GSU_RC=8
      break 1
   elif [[ -z "$2" ]]; then 
      echo "\n+ Error : Function=gsu_seprarray, arg \$2 arrayname is blank\n "
      GSU_RC=8
      break 1
   elif [[ -z "$(echo $1|sed 's/ //g')" ]]; then
      eval 'gsu_rebuild=${'${2}'[*]}'
      break 1      
   fi

   set - "$1" "$(echo $2|sed 's/\$//g')" ## remove escaped '$'s from arrayname
   eval 'gsu_numinarr=${#'${2}'[*]}' 
   if [[ $? -ne 0 ]]; then ## eval failed
      echo "\n+ Error : Function=gsu_seprarray, arg \$2=$2 arrayname caused eval error.eval=(gsu_numinarr="'${#'${2}'[*]}'"\n "
      GSU_RC=8
      break 1
   fi 
   [ ! -z "${GSU_DEBUG}" ] && echo "gsu_seprarray debug:gsu_numinarr="'${#'${2}'[*]}' 
   gsu_isnum="$(gsu_istype "numeric" "${gsu_numinarr}")" || { GSU_RC=$?;echo "${gsu_isnum}";return ${GSU_RC}; }
   if [[ ! -z "${gsu_isnum}" ]]; then 
      if [[ ${gsu_numinarr} -eq 0 ]]; then
         echo "\n+ Error : Function=gsu_seprarray, arg \$2=$2 arrayname contains zero elements\n "
         GSU_RC=8
         break 1
      fi
      gsu_x=0
      gsu_seprcopy="$1"
      ((gsu_penult=gsu_numinarr - 1))
      while [ ${gsu_x} -lt ${gsu_numinarr} ]
      do
         eval 'gsu_arrextr=${'${2}'['${gsu_x}']}'
         if [[ $? -ne 0 ]]; then ## eval failed
            echo "\n+ Error : Function=gsu_seprarray, arg \$2=$2 arrayname caused eval error.eval=(gsu_arrextr="'${'${2}'['${gsu_x}']}'"\n "
            GSU_RC=8
            break 1
         fi 
         [ ! -z "${GSU_DEBUG}" ] && echo "gsu_seprarray debug:gsu_arrextr="'${'${2}'['${gsu_x}']}'
         [ ${gsu_x} -eq ${gsu_penult} ] && unset gsu_seprcopy     
         gsu_rebuild="${gsu_rebuild}${gsu_arrextr}${gsu_seprcopy}"
         ((gsu_x+=1))
      done
   else
      echo "\n+ Error : Function=gsu_seprarray, arg \$2=$2 contains unknown number of elements (may not be an array)\n "
      GSU_RC=8
      break 1    
   fi    
   break 1
done
[ ${GSU_RC} -eq 0 ] && echo "${gsu_rebuild}"
return ${GSU_RC}
}
########################################################################################################
function gsu_pathsearch
{
## $1(..$n)=file(s) to search in path for
## returns 'ls -l' lines of file(s) found in $PATH dir concat
unset gsu_infile gsu_fstack gsu_pathbreak gsu_lslines gsu_filelist gsulist
for gsu_infile in $(echo "$*"|sed 's/,/ /g;s/\;/ /g'|gsu_sqspc)
do
   gsu_pathbreak="$(echo "${PATH}:"|sed "s/:/\/${gsu_infile} /g"|gsu_sqspc)"
   gsu_lslines="$(echo "$(ls -l ${gsu_pathbreak} 2>/dev/null)"|grep '^_*.')" 
   gsu_fstack="${gsu_fstack}${gsu_lslines}\n "
done
gsu_filelist="$(echo "${gsu_fstack}"|sed '/^$/d'|awk '{print $NF}'|awk ' !x[$0]++')"
gsu_list="$(echo "${gsu_filelist}"|gsu_file2list)"
echo "${gsu_list}"   
return
}
########################################################################################################
#
# Oracle Functions
#
########################################################################################################
function gsu_oraerror
{
# $1=incoming RC (from sqlplus command) -  dont do anything if $1 > 1(1=sql[plus/ldr] call error), return $1
# $2=string/file to scan (output from sqlplus command)
# $3="file" if $2 is a file(incl path), file not fnd/readable, return=0. null/other $3 means $2 is a string
# purpose - on sqlplus returning a zero|1 return code (not neccessarily what really happened if 
#           the sql command o/p is put into a variable/array, then scan sqlplus output ($2) 
#           for 'PLS-'|'ORA-'|SP2- & return 16 if it contains any or all. 
GSU_RC=0
gsu_rctest="$(gsu_istype "numeric" "$1")" || unset gsu_rctest
[ -z "$1" -o -z "${gsu_rctest}" ] && set - 0 "$2" "$3"
if [[ $1 -gt 1 ]]; then ## RC already an error RC, return it
   echo $1
elif [[ "$(echo "$3"|gsu_lc)" = "file" ]]; then ## sql o/p is a file,
   if [[ -f "$2" && -r "$2" ]]; then            ## it exists & can be read.
                                                ## check it for sql errors.                 
      echo $(expr $(grep -ic -m1 'ORA-[0-9].*\|PLS-[0-9].*\|SP2-[0-9].*' "$2") \* 16) 
   else ## file missing/cant be read, return 'no error' in that case
      echo 0
   fi      
else ## sql o/p sent as a string, check the string for sql errors.
   echo $(expr $(echo "$2"|grep -ic -m1 'ORA-[0-9].*\|PLS-[0-9].*\|SP2-[0-9].*') \* 16)
fi
return ${GSU_RC}
}
########################################################################################################
function gsu_sqlavail
{
# $1=sql uid/password
# $2=calling function (for error messages)
GSU_RC=0
unset GSU_EMSG
while true
do
   if [[ -z "$1" ]]; then 
      GSU_EMSG="arg \$1 oracle_uid/password is blank\n"
      GSU_RC=8
      break 1
   fi     

   if [[ -z "$(which sqlplus 2>/dev/null)" ]]; then
      GSU_EMSG="sqlplus is either not installed or not defined in \$PATH\n"
      GSU_RC=8
      break 1
   fi
   
   gsu_sqlpretn=$(sqlplus /nolog "exit" 2>&1)
   gsu_sqlprc=$?
   if [[ ${gsu_sqlprc} -ne 0 ]]; then
      GSU_EMSG="sqlplus nologin call returns RC=${gsu_sqlprc}, msg:\n\n ${gsu_sqlpretn}"
      GSU_RC=8
      break 1
   fi

   if [[ -z "${PNET_TGT_SCHEMA}" ]]; then
      GSU_EMSG="required envvar \$PNET_TGT_SCHEMA is blank\n"
      GSU_RC=8
   fi
   break 1
done
   
[ ${GSU_RC} -ne 0 ] && GSU_EMSG="\n+ Error : $2, ${GSU_EMSG}"
echo "${GSU_EMSG}" 
exit ${GSU_RC}
}
########################################################################################################
function gsu_oraobjexist
{
# $1=sql uid/password
# $2=object type (table|column)
# if $2="column" then $3=tablename to check for. $4..$n (or "$4" for all)=column list
# if $2="table" then $3..$n (or "$3" for all)=table list
# purpose - check if an oracle object exists or not, in an instant client environment, assumes envvar
#           $TWO_TASK is set to the correct database name(from tnsnames.ora), or that $1(uid/password) is
#           defined with database name within it (@...).
#           Also, envvar $PNET_TGT_SCHEMA  must be set to correct schema & sqlplus must be executable.
#           Currently can test for existence of 1 or more tables or existence of a number of columns
#           within 1 table. Note; column check does an implicit 1 table check before columns checked.
# RC=0 ; all table(s) and/or columns exist
# RC=4 ; warning; 1 or more tables dont exist in schema
# RC=6 ; warning; 1 or more columns dont exist on table
# RC=8 ; error; other specified error
GSU_RC=0
while true
do
   if [[ $# -lt 3 ]]; then 
      echo "\n+ Error : Function=gsu_oraobjexist, expected at least 3 args, detected $# ($*)\n"
      GSU_RC=8
      break 1
   fi     

   GSU_EMSG=$(gsu_sqlavail "$1" "Function=gsu_oraobjexist") 
   if [[ $? -ne 0 ]]; then
      echo "${GSU_EMSG}"
      GSU_RC=8
      break 1
   elif [[ -z "$2" ]]; then 
      echo "\n+ Error : Function=gsu_oraobjexist, arg \$2 object_type is blank\n"
      GSU_RC=8
      break 1    
   fi

   gsu_oracreds="$1"
   shift 1
   gsu_objtype="$(echo "$1"|gsu_uc)"
   shift 1

   case ${gsu_objtype} in
   TABLE) :  
          gsu_table="$*"   ## all args leftover in list
          unset gsu_column
          ;;
   COLUMN) :
          if [[ $# -lt 2 ]]; then
             echo "\n+ Error : Function=gsu_oraobjexist, no columns [\$4..\$n (or '\$4' for all)] entered for object_type=${gsu_objtype}\n"
             GSU_RC=8
             break 1
          fi
          gsu_table="$1"   ## used to be $3 before 1st & 2nd shifts
          if [[ ! -z "$(echo "${gsu_table}"|grep ",\|;\| ")" ]]; then
             echo "\n+ Error : Function=gsu_oraobjexist, \$3 tablename looks like a list of tables (not allowed for column lookup)"
             echo "+ \$3=${gsu_table}"
             GSU_RC=8
             break 1
          fi 
          shift 1
          gsu_column="$*"  ## all args leftover in list
          ;;
   *)     :
          echo "\n+ Error : Function=gsu_oraobjexist, arg \$2=${gsu_objtype} object_type not recognised. Valid=(table|column)\n"
          GSU_RC=8
          break 1
         ;;
   esac        

   ## check table(s) exist
   if [[ ! -z "${gsu_table}" ]]; then
      gsu_table="$(echo "${gsu_table}"|sed 's/,/ /g;s/;/ /g'|gsu_uc|gsu_sqspc)"
      unset gsu_tablelist
      gsu_numtables=$(echo "${gsu_table}"|wc -w)
      for gsu_tablen in ${gsu_table}  
      do
         gsu_quotedword="$(echo "'${gsu_tablen}'")"
         gsu_tablelist="${gsu_tablelist}${gsu_quotedword},"
      done
      gsu_tablelist="${gsu_tablelist%?}" ## remove last ','
      
      
      GSU_SQLCNTTAB=$(sqlplus -s <<CNT0
                ${gsu_oracreds}
                whenever sqlerror exit 16
                whenever oserror  exit 16
                set serveroutput off newpage 0 space 0 pagesize 0 echo off feedback off;
                set heading off termout off veri off trimspool off timing off markup html off;
                select count(*)
                  from all_tables
                 where table_name in (${gsu_tablelist}) 
                   and owner='${PNET_TGT_SCHEMA}'
                   and status = 'VALID';
                exit 0
CNT0)
      
      GSU_SQLRC=$(gsu_oraerror $? "${GSU_SQLCNTTAB}")
      if [[ ${GSU_SQLRC} -ne 0 ]]; then
         echo "\n+ Error : Function=gsu_oraobjexist\n+ SQLERROR>position=GSU_SQLCNTTAB, caught sql error\n+ RC=${GSU_SQLRC}, SQLRETN:\n${GSU_SQLCNTTAB}\n"
         GSU_RC=8
         break 1         
      else
         gsu_chkcnt=$(expr ${GSU_SQLCNTTAB})
         if [[ -z "$(echo "${gsu_chkcnt}"|gsu_allnum)" ]]; then
            echo "\n+ Error : Function=gsu_oraobjexist\n+ SQLERROR>position=GSU_SQLCNTTAB sql returned non numeric\n+ RC=${GSU_SQLRC}, SQLRETN:\n${GSU_SQLCNTTAB}\n"
            GSU_RC=8
            break 1
         fi
         if [[ ${gsu_chkcnt} -eq ${gsu_numtables} ]]; then
            if [[ "${gsu_objtype}" = T* ]]; then
               echo "true" 
               GSU_RC=0
               break 1
            fi   
         else
            echo "\n+ Warning : Function=gsu_oraobjexist\n+ One or more tables does not exist or is not valid in schema ${PNET_TGT_SCHEMA}\n+ (tablelist=${gsu_tablelist})\n"
            GSU_RC=4
            break 1
         fi
      fi      
   fi

   ## check column(s) exist
   if [[ ! -z "${gsu_column}" ]]; then
      gsu_column="$(echo "${gsu_column}"|sed 's/,/ /g;s/;/ /g'|gsu_uc|gsu_sqspc)"
      unset gsu_columnlist
      gsu_numcolumns=$(echo "${gsu_column}"|wc -w)
      for gsu_columnn in ${gsu_column}  
      do
         gsu_quotedword="$(echo "'${gsu_columnn}'")"
         gsu_columnlist="${gsu_columnlist}${gsu_quotedword},"
      done
      gsu_columnlist="${gsu_columnlist%?}" ## remove last ','
      
      GSU_SQLCNTCOL=$(sqlplus -s <<CNT1
                    ${gsu_oracreds} 
                    whenever sqlerror exit 16
                    whenever oserror  exit 16
                    set serveroutput off newpage 0 space 0 pagesize 0 echo off feedback off;
                    set heading off termout off veri off trimspool off timing off markup html off;
                    select count(*)
                      from ALL_TAB_COLS
                     where table_name=${gsu_tablelist} and owner='${PNET_TGT_SCHEMA}' and column_name in (${gsu_columnlist});
                    exit 0 
CNT1)

      GSU_SQLRC=$(gsu_oraerror $? "${GSU_SQLCNTCOL}")
     if [[ ${GSU_SQLRC} -ne 0 ]]; then
         echo "\n+ Error : Function=gsu_oraobjexist\n+ SQLERROR>position=GSU_SQLCNTCOL\n+ RC=${GSU_SQLRC}, SQLRETN:\n${GSU_SQLCNTCOL}\n"
         GSU_RC=8
         break 1         
     else
         gsu_chkcnt=$(expr ${GSU_SQLCNTCOL})
         if [[ -z "$(echo "${gsu_chkcnt}"|gsu_allnum)" ]]; then
            echo "\n+ Error : Function=gsu_oraobjexist\n+ SQLERROR>position=GSU_SQLCNTCOL sql returned non numeric\n+ RC=${GSU_SQLRC}, SQLRETN:\n${GSU_SQLCNTCOL}\n"
            GSU_RC=8
            break 1
         fi
         if [[ ${gsu_chkcnt} -eq ${gsu_numcolumns} ]]; then
            echo "true" 
            GSU_RC=0
            break 1
         else
            echo "\n+ Warning : Function=gsu_oraobjexist\n+ One or more columns does not exist in table ${gsu_tablelist} in schema ${PNET_TGT_SCHEMA}\n+ (columnlist=${gsu_columnlist})\n"
            GSU_RC=6
            break 1
         fi
      fi      
   fi   
   break 1
done

return ${GSU_RC} 
}
########################################################################################################
function gsu_oratrunctab
{
# $1=sql uid/password
# $2..$n (or "$2" for all)=table list
# purpose - truncate oracle table, assumes envvar $TWO_TASK is set to the correct database 
#           name(from tnsnames.ora), or that $1(uid/password) is defined with database name 
#           within it (@...).
#           Also, envvar $PNET_TGT_SCHEMA  must be set to correct schema & sqlplus must be executable.
#           Currently can truncate 1 or more tables.
# RC=0 ; run successful
GSU_RC=0
while true
do
   if [[ $# -lt 2 ]]; then 
      echo "\n+ Error : Function=gsu_oratrunctab, expected at least 2 args, detected $# ($*)\n"
      GSU_RC=8
      break 1
   fi     

   GSU_EMSG=$(gsu_sqlavail "$1" "Function=gsu_oratrunctab") 
   if [[ $? -ne 0 ]]; then
      echo "${GSU_EMSG}"
      GSU_RC=8
      break 1
   fi
   
   gsu_oracreds="$1"
   shift 1
   gsu_tables="$(echo "$*"|sed 's/,/ /g;s/;/ /g;s/|/ /g'|gsu_uc|gsu_sqspc|gsu_dedupelist)"
   if [[ -z "$(gsu_strip "${gsu_tables}")" ]]; then 
      echo "\n+ Error : Function=gsu_oratrunctab, arg \$2..\$n (or '\$2' for all) object_name(s) is/are blank\n"
      GSU_RC=8
      break 1    
   fi

   unset gsu_sqlpack
   for gsu_table in ${gsu_tables}
   do
       gsu_sqlpack="${gsu_sqlpack}truncate table ${PNET_TGT_SCHEMA}.${gsu_table};#"
   done
   [ ! -z "${gsu_sqlpack}" ] && gsu_sqlpack="${gsu_sqlpack%?}"
   gsu_sqlpack="$(echo "${gsu_sqlpack}"|sed 's/#/\n/g')"
      

   GSU_SQLTRN=$(sqlplus -s ${PNET_SQLUSER} <<EOTR
              whenever sqlerror exit 16
              whenever oserror  exit 16
              set serveroutput off newpage 0 space 0 pagesize 0 echo off feedback off;
              set heading off termout off veri off trimspool off timing off markup html off;
              ${gsu_sqlpack}
              commit;
              exit 0
EOTR)

   GSU_SQLRC=$(gsu_oraerror $? "${GSU_SQLTRN}")
   if [[ ${GSU_SQLRC} -ne 0 ]]; then
      echo "\n+ Error : Function=gsu_oratrunctab\n+ SQLERROR>position=GSU_SQLTRN\n+ RC=${GSU_SQLRC}, SQLRETN:\n${GSU_SQLTRN}\n"
      GSU_RC=8
   fi      
   
   break 1
done
[ ${GSU_RC} -eq 0 ] && echo "true"
return ${GSU_RC}   
}
########################################################################################################
###############
# SUBROUTINES #
###############
########################################################################################################
gsu_checktty ()
{
## No args, sets envvar PNET_TTY to true if screen available, else null. (eg cron/background)
## note this check is faulty if in a file fed loop, even though screen is actually available there
GSU_RC=0
tty -s
GSU_RC=$?
[ ${GSU_RC} -eq 0 ] && PNET_TTY="true" || unset PNET_TTY
export PNET_TTY
export PNET_MACHINE="$(uname -a)"
[ ! -z "${GSU_DEBUG}" ] && 
{
   echo "gsu_checktty debug:PNET_TTY=${PNET_TTY}"
   echo "gsu_checktty debug:PNET_MACHINE=${PNET_MACHINE}"
   echo "gsu_checktty debug:RC=${GSU_RC}"
}
return ${GSU_RC}
}
#######################################################################################################
gsu_mytee ()
{
## $1=string to tee (""/'' surround)
## $2=file to tee string ($1) to
## $3=if null, normal echo (file/screen), otherwise echo directive $3
## tees a passed string to screen (if available) & file
GSU_RC=0
if [[ ! -z "$1" ]]; then
   ## fix echo line depending on machine
   [ -z "$(alias echo 2>/dev/null)" ] && unset gsu_echosw || gsu_echosw="$3"
   [ ! -z "${PNET_TTY}" -o ! -z "${CTL_RUN}" ] && echo ${gsu_echosw} "$1"
   [ ! -z "$2" ]          && echo ${gsu_echosw} "$1" >>$2
   [ -z "$2" -a ! -z "${GSU_DEBUG}" ] && echo "gsu_mytee debug:\$2 tee filename blank(ignored)" 
else
   [ ! -z "${GSU_DEBUG}" ] && echo "gsu_mytee debug:\$1 string  blank(ignored)"   
fi
[ ! -z "${GSU_DEBUG}" ] && echo "gsu_mytee debug:RC=${GSU_RC}"
return ${GSU_RC}
}
#######################################################################################################
gsu_startendmsg ()
{
## $1=e*|* [end|start]
## $2=calling script
## display start/end message
GSU_RC=0
gsu_msgtype="$(echo "$1"|gsu_lc)"
set - "$1" "$(echo "$2"|cut -d' ' -f1)"
case ${gsu_msgtype} in
s*) echo " "
    echo "--- Starting $2(pid=$$,ppid=${PPID}) ---"
    echo "$2 Started on : $(gsu_datetime d) at: $(gsu_datetime time)" 
    ;;
e*) echo "$2   Ended on : $(gsu_datetime d) at: $(gsu_datetime time)"
    echo "---  Ending $2(pid=$$,ppid=${PPID})  ---"
    echo " "
    ;;
*)  echo "--- Starting/Ending(pid=$$,ppid=${PPID}) parms=$* ---"
    ;;  
esac
[ ! -z "${GSU_DEBUG}" ] && echo "gsu_startendmsg debug:RC=${GSU_RC}"
return ${GSU_RC}
}
########################################################################################################
## $1=RC(incoming)
## $2=calling script
## $3=log file (optional - only useful if gsu_mytee is wanted)
## various exit type wrappers
gsu_cleanexit () { gsu_allexits $1 $2 "successfully" $3; exit $1; }
gsu_warnexit  () { gsu_allexits $1 $2 "with warnings" $3; exit $1; }
gsu_errorexit () { gsu_allexits $1 $2 "with errors" $3; exit $1; }
########################################################################################################
gsu_allexits ()
{
## $1=RC(incoming)
## $2=calling script
## $3=exit type message
## $4=log file (for gsu_mytee use - optional)
## detail for various exit type wrappers
GSU_RC=0
gsu_xfile="$(gsu_tempstore "file")" || { GSU_RC=$?;echo "${gsu_xfile}";return ${GSU_RC}; }
gsu_omsg=
gsu_omsg="Run "
[ ! -z "$2" ] && gsu_omsg="${gsu_omsg}of $2"
gsu_omsg="${gsu_omsg} completed $3 RC="
[ ! -z "$1" ] && gsu_omsg="${gsu_omsg}$1" || gsu_omsg="${gsu_omsg}unknown"
echo "${gsu_omsg}" >${gsu_xfile}

if [[ ! -z "$4" && -f "$4" ]]; then
   gsu_mytee "$(cat ${gsu_xfile})" "$4"
   gsu_mytee "$(gsu_startendmsg "end" "$2")" "$4"
else
   cat ${gsu_xfile}
   gsu_startendmsg "end" "$2"
fi   
rm -f "${gsu_xfile}" "${SQL_DUMP}" "${SQL_TCMD}"
[ ! -z "${GSU_DEBUG}" ] && echo "gsu_allexits debug:RC=${GSU_RC}"
return ${GSU_RC}
}
########################################################################################################
gsu_archivefile ()
{
## $1=filename(s)(+path) to archive
## $2=filename(s) to archive to [generated as "tsf+$(basename $1)" if null]
## archives flat file(s) (always to "$(dirname $1)/arch") as long as envvar ${PNET_ARCH_SWITCH} != "false"
GSU_RC=0
gsu_doarchive="$(echo "${PNET_ARCH_SWITCH}"|gsu_lc)"
if [[ "${gsu_doarchive}" != "false" ]]; then
   if [[ -z "$1" ]]; then
      echo "\n+ Error : arg \$1 blank filename(s)"
      echo "+ (procedure=gsu_archivefile)\n "
      GSU_RC=8   
   else
      gsu_allfromfiles="$(echo "$1"|sed "s/,/ /g")"
      gsu_alltofiles="$(echo "$2"|sed "s/,/ /g") " ## append extra space on
      gsu_index=1
      for gsu_archfile in ${gsu_allfromfiles}
      do   
         if [[ ! -f "${gsu_archfile}" ]]; then
            echo  " "
            echo "+ Warning while attempting archive of ${gsu_archfile}"
            echo "+ File not found ! (procedure=gsu_archivefile)"
            echo " " 
            GSU_RC=3
         else
            gsu_element="$(echo "${gsu_alltofiles}"|cut -d' ' -f"${gsu_index}")"
            gsu_topath="$(dirname "${gsu_archfile}")/arch"       ## generate directory
            [ ! -d "${gsu_topath}" ] && gsu_makemoddir "${gsu_topath}"
            if [[ -z "${gsu_element}" ]]; then                   ## nothing supplied
               gsu_tofile="$(gsu_datetime tsf)" || { GSU_RC=$?;echo "${gsu_tofile}";return ${GSU_RC}; }   
               gsu_tofile="${gsu_tofile}.$(basename ${gsu_archfile})" ## generate archiveto filename
            else                                                 ## just archiveto filename supplied     
               gsu_tofile="${gsu_element}"
            fi   
            while [ -f "${gsu_topath}/${gsu_tofile}" ]           ## archiveto filename already exists?
            do
               gsu_uepoch="$(gsu_epoch unique)" || { GSU_RC=$?;echo "${gsu_uepoch}";return ${GSU_RC}; } ## yes, then make a new unique one 
               gsu_tofile="${gsu_tofile}.${gsu_uepoch}"
            done                                                 ## until it is a none existant name      
            mv ${gsu_archfile} ${gsu_topath}/${gsu_tofile}
            GSU_RC=$?
            if [[ ${GSU_RC} -ne 0 ]] ; then
               echo " "
               echo "+ Warning while attempting archive of"
               echo "+   ${gsu_archfile}"
               echo "+ to"
               echo "+   ${gsu_topath}/${gsu_tofile}"
               echo "+"         
               echo "+ Command Returned RC=${GSU_RC}"
               [ -f "${gsu_archfile}" ] && { echo " ";echo "+ *** Archive not performed ! *** (procedure=gsu_archivefile)";echo " "; }
               GSU_RC=3
            else
               echo " "
               echo "** Archived ${gsu_archfile}" 
               echo "**       to ${gsu_topath}/${gsu_tofile}" 
            fi
         fi
         ((gsu_index+=1)) 
      done   
   fi     
else
   echo " "
   echo "+ Warning *** Archiving not performed ! *** [ envvar \${PNET_ARCH_SWITCH}=${PNET_ARCH_SWITCH} ] (procedure=gsu_archivefile)"
   GSU_RC=3   
fi
echo "\n---------------------------------------------------------------"
[ ! -z "${GSU_DEBUG}" ] && echo "gsu_archivefile debug:RC=${GSU_RC}"
return ${GSU_RC}
}
########################################################################################################
gsu_handletrailer ()
{
## $1=Action [a*|d*] [add|delete]
## $2=Trailer record to be added/deleted (actual text)
## $3=filename(s)(+path) to add/delete trailer from
## add/delete trailer record to specified file(s)
GSU_RC=0
unset gsu_action gsu_trlrec

while true
do
   gsu_action="$(echo "$1"|gsu_lc)"
   case $1 in
   a*) gsu_action="add"
       ;;
   d*) gsu_action="delete"
       ;;
   *)  echo "\n+ Error : arg \$1 not recognised/blank (=$1) [a*|d*]"
       echo "+ (procedure=gsu_handletrailer)\n "
       GSU_RC=8
       break 1     
       ;;
   esac

   if [[ -z "$2" ]]; then
      echo "\n+ Error : arg \$2 trailer record text is blank"
      echo "+ (procedure=gsu_handletrailer)\n "
      GSU_RC=8
      break 1
   else
      gsu_trlrec="$2"   
   fi
   
   [ $# -ge 2 ] && shift 2 || set -
   gsu_trlfiles="$(echo "$*"|sed "s/,/ /g")" 
   if [[ -z "${gsu_trlfiles}" ]]; then
      echo "\n+ Error : arg \$3-\$n filename(s) is blank"
      echo "+ (procedure=gsu_handletrailer)\n "
      GSU_RC=8
      break 1
   fi
   
   gsu_index=1
   for gsu_htfname in ${gsu_trlfiles}
   do
      if [[ ! -f "${gsu_htfname}" ]]; then
         [ "${gsu_action}" = "delete" ] &&  gsu_oemsg="Error" || gsu_oemsg="Warning"
         echo " "
         echo "+${gsu_oemsg}: file arg \$$((gsu_index+2))=${gsu_htfname}"
         echo "+file not found ! (procedure=gsu_handletrailer)"
         echo " "  
         if [[ "${gsu_action}" = "delete" ]]; then
            GSU_RC=8
            break 2             
         else
            GSU_RC=3
         fi 
      else
         gsu_lastrec="$(tail -n1 "${gsu_htfname}")"
         gsu_match="$(echo "${gsu_lastrec}"|egrep -i "^${gsu_trlrec}$")"
         if [[ "${gsu_action}" = "add" ]]; then ## we can multipass add because we
                                                ## check if it already has a trailer.
            if [[ ! -z "${gsu_match}" ]]; then  ## do nothing, trailer found already there.
               echo "+ Info : OK - Trailer record already exists in file: arg \$$((gsu_index+2))=${gsu_htfname}"
            else                                ## else add trailer.
               echo "${gsu_trlrec}" >>${gsu_htfname}
               echo "+ Info : OK - Trailer record added to file: arg \$$((gsu_index+2))=${gsu_htfname}"
            fi             
         else                                   ## we cant multipass delete yet because
                                                ## any without a trailer should be an error
                                                ## and rerunning would cause all to be errors.
            if [[ -z "${gsu_match}" ]]; then    ## no trailer found, cause error
               echo "\n+ Error : file arg \$$((gsu_index+2))=${gsu_htfname}"
               echo "+ Does not contain an expected trailer record"
               echo "+ Expected Trailer record    : '"${gsu_trlrec}"'"
               echo "+ Actual last record(full)   : '"${gsu_lastrec}"'"
               echo "+ (procedure=gsu_handletrailer)\n "
               GSU_RC=8
               break 2
            else
               echo "+ Info : OK - Trailer record found in file: arg \$$((gsu_index+2))=${gsu_htfname}"
            fi             
         fi
      fi
      ((gsu_index+=1))
   done
   
   if [[ "${gsu_action}" = "delete" ]]; then ## delete all found trailers
      ## reaching here means that RC=0|3 (clean\warnings), execute delete trailer(s)
      gsu_tfile=$(gsu_tempstore "file") || { GSU_RC=$?;echo "${gsu_tfile}";break 1; }   
      for gsu_htfname in ${gsu_trlfiles}
      do
         sed '$d' "${gsu_htfname}" >${gsu_tfile} ## havent used insitu (AIX compatibility)
         mv ${gsu_tfile} ${gsu_htfname}
         echo "+ Info : OK - Trailer record existed and was removed from file: arg \$$((gsu_index+2))=${gsu_htfname}"
      done
      rm -f ${gsu_tfile} ## incase it was left over.
   fi
   break 1
done   
[ ! -z "${GSU_DEBUG}" ] && echo "gsu_handletrailer debug:RC=${GSU_RC}"
return ${GSU_RC}

}
########################################################################################################
gsu_makemoddir ()
{
## $1=value to chmod $2 directory(s) to, default=775
## $2=directory(s) to create
## creates requested directory(s) (if neccessary) & chmods it/them
GSU_RC=0
if [[ $# -eq 0 ]]; then
   GSU_RC=3
else
   gsu_modtest="$(gsu_istype "numeric" "$1")" || { GSU_RC=$?;echo "${gsu_modtest}";return ${GSU_RC}; }
   
   if [[ -z "${gsu_modtest}" ]]; then
      gsu_mod=775 ## assuming 1st arg was null or a dir
   else
      gsu_mod=$1
      [ $# -gt 0 ] && shift 1
   fi     
   
   if [[ $# -eq 0 ]]; then
      GSU_RC=3
   else
      gsu_alldirs="$(echo "$*"|sed "s/,/ /g")"   
      for gsu_dir in ${gsu_alldirs}
      do
         if [[ ! -d "${gsu_dir}" ]]; then
            mkdir -p "${gsu_dir}"
            GSU_RC=$?
         fi
         if [[ ${GSU_RC} -eq 0 ]]; then
            chmod -R ${gsu_mod} "${gsu_dir}"
            GSU_RC=$?
         fi     
      done   
   fi
fi

if [[ ${GSU_RC} -eq 3 ]]; then
   echo "+ Warning while attempting to make dir"
   echo "+ Directory to make is blank (procedure=gsu_makemoddir)"
elif [[ ${GSU_RC} -ne 0 ]]; then
   echo "+ Warning while attempting to make dir"
   echo "+ mkdir and/or chmod problem occurred (procedure=gsu_makemoddir)"   
fi
[ ! -z "${GSU_DEBUG}" ] && echo "gsu_makemoddir debug:RC=${GSU_RC}"   
return ${GSU_RC}
}
########################################################################################################
gsu_srcfile ()
{
## $1=caller (sourcing module) 
##    specify as noexit:module to avoid exiting if an error is hit in the sourced module(or while trying to source it) 
## $2=module to source (incl. path)
##    specify as switch:module if you want the switch to control if it is called or not (null switch=yes,do call)
## $3-$n(or "$3" to contain all)=values to pass as args to sourced module $2
## Sources a requested module & passes it arguments as specified. gsu_threaded, so recursive calls are ok.
GSU_RC=0
if [[ -z "$2" ]]; then
   echo "+ Error while attempting to source a file"
   echo "+ Filename (\$2) is blank"
   RC=8
   gsu_errorexit ${GSU_RC} "$1" ## cant really noexit this error
fi

gsu_su_sf_threadno=$(gsu_thread "add" ${gsu_su_sf_threadno}) || { GSU_RC=$?;echo "${gsu_su_sf_threadno}";return ${GSU_RC}; }
gsu_caller[gsu_su_sf_threadno]=$1 
gsu_srcfile[gsu_su_sf_threadno]=$2 
gsu_stderr[gsu_su_sf_threadno]=$(gsu_tempstore "file") || { GSU_RC=$?;echo "${gsu_stderr[gsu_su_sf_threadno]}";return ${GSU_RC}; } 
gsu_onoffswitch[gsu_su_sf_threadno]="$(echo "${gsu_srcfile[gsu_su_sf_threadno]}"|cut -d':' -f1)"
if [[ "${gsu_onoffswitch[gsu_su_sf_threadno]}" != "${gsu_srcfile[gsu_su_sf_threadno]}" ]]; then  ## string contains a ':'
   gsu_srcfile[gsu_su_sf_threadno]="$(echo "${gsu_srcfile[gsu_su_sf_threadno]}"|cut -d':' -f2-)" ## remove '*:'
else                                                                                             ## no ':'
   unset gsu_onoffswitch[gsu_su_sf_threadno]
fi

while true
do
   ## Establish (via exported switch) if this module already called, note this assumes that the sourced module
   ## is merely and exported environment variable setter which can carry to subshells invoked.
   ## Any functions etc would have to be re-sourced on entering a subshell since they wont travel.
   if [[ ! -z "${gsu_onoffswitch[gsu_su_sf_threadno]}" ]]; then
      echo "## Current process(pid=$$,ppid=${PPID}) : $(basename ${gsu_srcfile[gsu_su_sf_threadno]}) exported values still avialable from a previous process"
      break 1
   fi

   gsu_noexit[gsu_su_sf_threadno]="$(echo ${gsu_caller[gsu_su_sf_threadno]:0:7}|gsu_lc)" 
   gsu_oemsg[gsu_su_sf_threadno]="Error"
   if [[ "${gsu_noexit[gsu_su_sf_threadno]}" = "noexit:" ]]; then                                 ## string contains a 'noexit:'
      gsu_caller[gsu_su_sf_threadno]="$(echo "${gsu_caller[gsu_su_sf_threadno]}"|cut -d':' -f2-)" ## remove 'noexit:'
      gsu_oemsg[gsu_su_sf_threadno]="Warning"
   else                                                                                           ## no 'noexit:' found
      unset gsu_noexit[gsu_su_sf_threadno]
   fi
   
   if [[ "$(dirname "${gsu_srcfile[gsu_su_sf_threadno]}")" = "." ]]; then
      [ -z "$(gsu_pathsearch "${gsu_srcfile[gsu_su_sf_threadno]}")" ] &&
      {
         echo "+ ${gsu_oemsg[gsu_su_sf_threadno]}: while attempting to source a file"
         echo "+ (\$2) ${gsu_srcfile[gsu_su_sf_threadno]} does not exist in \$PATH (procedure=gsu_srcfile)"
         echo "+ PATH=${PATH}"
         GSU_RC=8
         break 1
      }   
   else   
      if [[ ! -f "${gsu_srcfile[gsu_su_sf_threadno]}" ]]; then
         echo "+ ${gsu_oemsg[gsu_su_sf_threadno]}: while attempting to source a file"
         echo "+ (\$2) ${gsu_srcfile[gsu_su_sf_threadno]} does not exist (procedure=gsu_srcfile)"
         GSU_RC=8
         break 1
      fi
   fi      
   
   [ $# -ge 2 ] && shift 2 || set -
   . ${gsu_srcfile[gsu_su_sf_threadno]} $* 2>${gsu_stderr[gsu_su_sf_threadno]}
   
   GSU_RC=$?
   if [[ ${GSU_RC} -ne 0 ]]; then
      echo "+ ${gsu_oemsg[gsu_su_sf_threadno]}:sourcing $(basename ${gsu_srcfile[gsu_su_sf_threadno]}) from ${gsu_caller[gsu_su_sf_threadno]}"
      echo "+ Returned GSU_RC=${GSU_RC} (procedure=gsu_srcfile)"
      echo "+ stderr caught:"
      cat ${gsu_stderr[gsu_su_sf_threadno]}
      echo " "
      GSU_RC=8
   else
      gsu_stderrwc=$(gsu_fileinfo linecnt "${gsu_stderr[gsu_su_sf_threadno]}") || { GSU_RC=$?;echo "${gsu_stderrwc}";return ${GSU_RC}; } 
      if [[ ${gsu_stderrwc} -ne 0 ]]; then
         echo "+ Warning sourcing $(basename ${gsu_srcfile[gsu_su_sf_threadno]})"
         echo "+ Returned RC was 0(zero) (procedure=gsu_srcfile),"
         echo "+ but stderr caught:"
         cat ${gsu_stderr[gsu_su_sf_threadno]}
         echo " "
      fi
   fi
   
   break 1 
done

rm -f "${gsu_stderr[gsu_su_sf_threadno]}"
if [[ ${GSU_RC} -ne 0 ]]; then
   if [[ -z "${gsu_noexit[gsu_su_sf_threadno]}" ]]; then
      gsu_exit_caller="${gsu_caller[gsu_su_sf_threadno]}"
      gsu_su_sf_threadno=$(gsu_thread "delete" ${gsu_su_sf_threadno}) || { GSU_RC=$?; echo "${gsu_su_sf_threadno}";return ${GSU_RC}; }
      gsu_errorexit ${GSU_RC} "${gsu_exit_caller}"
   fi
fi   
gsu_su_sf_threadno=$(gsu_thread "delete" ${gsu_su_sf_threadno})  || { GSU_RC=$?; echo "${gsu_su_sf_threadno}";return ${GSU_RC}; } 
[ ! -z "${GSU_DEBUG}" ] && echo "gsu_srcfile debug:RC=${GSU_RC}"
return ${GSU_RC}  
}
########################################################################################################
gsu_notenoughargs ()
{
## $1=calling module, preceed name with 'noexit:' to stop exit happening 
## $2=least args expected
## $3=number received
## $4=valid args(usage text, optional)
## $5=args received(optional)
## dumps msg for < min args specified for a called script
GSU_RC=8 ## automatically 8 because an error has occurred.
gsu_caller="$1" 
unset gsu_noexit gsu_oemsg gsu_omsg  
gsu_oemsg="Error  "
if [[ "$(echo ${gsu_caller:0:7}|gsu_lc)" = "noexit:" ]]; then ## string contains a 'noexit:'
   gsu_noexit="true"
   gsu_caller="$(echo ${gsu_caller:7:${#gsu_caller}-7})"       ## remove 'noexit:'
   gsu_oemsg="Warning"
else                                                          ## no 'noexit:' found
   unset gsu_noexit
fi
echo "\n+ ${gsu_oemsg}: ${gsu_caller} module expects at least $2 arguments"
gsu_omsg="+ but received $3 arguments"
if [[ ! -z "$(gsu_istype "numeric" "$3")" ]]; then
   [ $3 -eq 0 ] && gsu_omsg="${gsu_omsg}(zero)"
   [ $3 -gt 0 -a ! -z "$5" ] && gsu_omsg="${gsu_omsg}($5)" || gsu_omsg="${gsu_omsg}."
fi
echo "${gsu_omsg}"
[ ! -z "$4" ] && echo "+ $4"
[ -z "${gsu_noexit}" ] && gsu_errorexit ${GSU_RC} $1

[ ! -z "${GSU_DEBUG}" ] && echo "gsu_notenoughargs debug:RC=${GSU_RC}"
return 0
}
########################################################################################################
gsu_sshutils ()
{
## $1=uid@server(or just server if same uid) to pull envvar(s) from.
## $2=SSH subcommand to execute: [ss*|sc*|sf*] [ssh|scp|sftp]
##   : $2=ss* - perform SSH actions, following args control actions;
##     : $3=remote commands or file containing remote commands, use :|"" for nop or to "-test" to just test ssh.
##     : $4-$n(or "$4" to contain all)=remote envvar(s) to pull(local name will be same)
##     : Note - to just execute commands leave $4-$n blank, to just pull envvars, set $3 to :|"". 
##   : $2=sc* - perform scp actions - just 1 file handled/call, following args control actions;
##     : $3=copy direction -  relates to $4 & $5 files below [i*|o*|-test] [in|out|-test],use "-test" to just test scp.
##     : $4=local filename(+path)
##     : $5=remote filename(+path)
##   : $2=sf* - perform sftp actions
##     : $3=file(+path) or containing sftp directives (can be hardcoded to arg instead) to execute,use "-test" to just test sftp.
GSU_RC=0
export GSU_REPLCHAR=
while true
do
   if [[ -z "$(gsu_strip "$1")" ]]; then
      echo "\n+ Error : arg \$1 remote (uid@)server is blank"
      echo "+ (procedure=gsu_sshutils)\n "
      GSU_RC=8
      break 1
   else
      gsu_target="$1" 
      gsu_dnsextract="$(gsu_dnslookup "$(hostname)")" || { GSU_RC=$?; echo "${gsu_dnsextract}";return ${GSU_RC}; } 
      eval ${gsu_dnsextract}
      gsu_localip="${GSU_IP}" 
      gsu_localdname="${GSU_DNAME}"
      gsu_dnsextract="$(gsu_dnslookup "${gsu_target}")" || { GSU_RC=$?; echo "${gsu_dnsextract}";return ${GSU_RC}; } 
      eval ${gsu_dnsextract}
      gsu_remoteip="${GSU_IP}" 
      gsu_remotedname="${GSU_DNAME}"
      [ ! -z "${GSU_DEBUG}" ] && 
      {
         echo "gsu_sshutils debug:[localhost  : ${gsu_localdname}(${gsu_localip})]"
         echo "gsu_sshutils debug:[remotehost : ${gsu_remotedname}(${gsu_remoteip})]"
      }
      if [[ "${gsu_localip}" = "${gsu_remoteip}" ]]; then
         echo " "
         echo "+ Warning : arg \$1=$1 remote host is equal to the local host ssh actions may fail (procedure=gsu_sshutils)"
         echo " "
      fi
      shift 1     
   fi

   gsu_sshaction="$(echo "$1"|gsu_uc)"
   [ $# -gt 0 ] && shift 1
   gsu_savedcmd="$1"
   [ $# -gt 0 ] && shift 1
   gsu_rhs=$*
   gsu_sshactiontest="$(echo "${gsu_savedcmd}"|gsu_uc)"
   [ "${gsu_sshactiontest}" = "-TEST" ] && { gsu_savedcmd="-TEST";unset gsu_rhs; }

   case ${gsu_sshaction} in
   SS*) gsu_sshaction "${gsu_target}" "${gsu_savedcmd}" ${gsu_rhs}
        ;;
   SC*) gsu_scpaction "${gsu_target}" "${gsu_savedcmd}" ${gsu_rhs}
        ;;
   SF*) gsu_sftpaction "${gsu_target}" "${gsu_savedcmd}" ${gsu_rhs}
        ;;
   *)   echo "\n+ Error : arg \$2 ssh action (${gsu_sshaction}) is not recognised"
        echo "+ valid arg values are; [ss*|sc*|sf*] [ssh|scp|sftp]"
        echo "+ (procedure=gsu_sshutils)\n "
        GSU_RC=8
        break 1
        ;;
   esac
   GSU_RC=$?
   break 1   
done
[ ! -z "${GSU_DEBUG}" ] && echo "gsu_sshutils debug:RC=${GSU_RC}"
return ${GSU_RC}
}
########################################################################################################
gsu_sshaction ()
{
## $1=uid@server(or just server if same uid) to pull envvar(s) from.
## $2=remote command or file of commands to run (; seperate) use :|"" for nop or "-test" to just test ssh.
##    specify 'file:<filename>' for a file of commands. 
## $3-$n(or "$3" to contain all)=remote envvar(s) to pull(local name will be same)
## Set envvar GSU_SSHMAXRC to maximum return code allowed (to NOT report as error) from $2 remote cmd(s),
## default=0 when GSU_SSHMAXRC unset|<0|not numeric.
## Run remote cmd(s) and/or extract given environment variables from remote server.
## Note: Assume auto ssh(no password/passphrase) already set up. This is none terminal(tty) ssh.
##       The remote command is executed before the remote envvar pull, so if the source script to setup
##       the pulled envvars is not fired automatically via .profile on signin then it should be run in
##       the remote command $2 argument first, for example to extract SEQFILES envvar from ukprodapp under
##       unikix user; gsu_sshutils ". ./pulseapp.setup" SEQFILES
##       In this case remote script pulseapp.setup is sourced before ${SEQFILES} is pulled back to local
##       server - as it turns out pulseapp.setup is sourced by auto fired .profile on that server so the 
##       actual command can be reduced to; gsu_sshutils : SEQFILES, after this ${SEQFILES} locally will 
##       contain the remote value of ${SEQFILES} remote envvar.
GSU_RC=0
export GSU_REPLCHAR=
while true
do
   gsu_unique="_$(gsu_randomnum)_$(gsu_randomnum)_"
   gsu_target="$1"
   unset gsu_remcmd gsu_sshtest
   gsu_remcmd=":"
   
   case $2 in
   -TEST)  gsu_sshtest="true" ## gsu_remcmd is left as ":" default for -test run
           ;;    
   *)      gsu_remcmd="$2"
           ;;
   esac    
   [ $# -ge 2 ] && shift 2 || set -
   unset gsu_sshincmd
   gsu_envvarlist="$*" 
   
   if [[ -z "$(gsu_strip "${gsu_remcmd}")" || "${gsu_remcmd}" = ":" ]]; then
      gsu_sshincmd=":;"
   else
      if [[ "$(echo ${gsu_remcmd:0:5}|gsu_lc)" = "file:" ]]; then
         gsu_remcmd="$(echo ${gsu_remcmd}|cut -d':' -f2-)"
         eval "gsu_remcmd=${gsu_remcmd}" ## expand vars etc
         if [[ ! -f "${gsu_remcmd}" || ! -r "${gsu_remcmd}" ]]; then
            echo "\n+ Error : arg \$2[\$3 from gsu_sshutils] ssh remote commands(file/cmds) is"
            echo "+ specified as a file, but file cannot be found or is not readable (check permissions)"
            echo "+ file=${gsu_remcmd}"             
            echo "+ (procedure=gsu_sshaction)\n "
            GSU_RC=8
            break 1
         fi         
         gsu_sshincmd="$(cat "${gsu_remcmd}");" 
      else
         gsu_sshincmd="${gsu_remcmd};"
      fi   
      gsu_pseudosshmaxrc=
      [ -z "$(gsu_istype "numeric" "${GSU_SSHMAXRC}")" ] && gsu_pseudosshmaxrc=0 ||\
      {
         [ ${GSU_SSHMAXRC} -lt 0 ] && export GSU_SSHMAXRC=0
         gsu_pseudosshmaxrc=${GSU_SSHMAXRC}         
      }
      gsu_sshincmd="${gsu_sshincmd}GSU_SSHRC=\$?;exit \${GSU_SSHRC};"
   fi
    
   gsu_sshoutcmdfile="$(gsu_tempstore "file")" || { GSU_RC=$?; echo "${gsu_sshoutcmdfile}";return ${GSU_RC}; }
   gsu_sshoutcmdfilestripped="$(gsu_tempstore "file")"  || { GSU_RC=$?;echo "${gsu_sshoutcmdfilestripped}";return ${GSU_RC}; }
   
   for gsu_line in ${gsu_envvarlist}
   do
       gsu_sshincmd="${gsu_sshincmd}echo ${gsu_line}${gsu_unique}=\${${gsu_line}};"
   done

   ssh -v -o BatchMode=yes ${gsu_target} <<GSU_HEREDOC >${gsu_sshoutcmdfile} 2>&1
   ${gsu_sshincmd}
GSU_HEREDOC

   GSU_RC=$?
   if [[ ${GSU_RC} -ne 0 ]]; then
      echo "=================================================================="
      echo "+ Error : SSH returned RC=${GSU_RC} (procedure=gsu_sshaction)"
      echo "+ Command(s) sent to remote_server ${gsu_target};"
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      echo "${gsu_sshincmd}"
      echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      echo "+ SSH returned message;"
      echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
      if [[ ${GSU_RC} -eq 255 ]]; then
         cat ${gsu_sshoutcmdfile}
      else
         grep -iv "^debug1:" ${gsu_sshoutcmdfile}
      fi         
      echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
      break 1
   else
      if [[ ! -z "${gsu_sshtest}" || ! -z "${GSU_DEBUG}" ]]; then
         [ ! -z "${GSU_DEBUG}" ] && echo "gsu_sshaction debug:"
         [ ! -z "${gsu_sshtest}" ] && echo ">> ssh test : verbose output;"
         cat ${gsu_sshoutcmdfile}
         [ ! -z "${gsu_sshtest}" ] && echo ">> ssh test : connection+nop to ${gsu_target} successful, RC=${GSU_RC}"
      else
         echo "-----------------------------------------------------------"
         echo "--- SSH Command(s) sent to remote_server ${gsu_target};"
         echo " "
         echo "${gsu_sshincmd}"
         echo "-----------------------------------------------------------"      
         echo "--- SSH returned message;"
         echo " "
         grep -iv "^debug1:" ${gsu_sshoutcmdfile}
         echo "-----------------------------------------------------------"
      fi     
   fi
   
   cat "${gsu_sshoutcmdfile}"|grep ".${gsu_unique}="|sed "s/${gsu_unique}=/=/g" >${gsu_sshoutcmdfilestripped} 2>&1
   gsu_sshoutwc=$(gsu_fileinfo l "${gsu_sshoutcmdfilestripped}") || { GSU_RC=$?;echo "${gsu_sshoutwc}";return ${GSU_RC}; } 
   [ ${gsu_sshoutwc} -gt 0 ] && export $(<${gsu_sshoutcmdfilestripped})
   break 1   
done   

rm -f ${gsu_sshoutcmdfile} ${gsu_sshoutcmdfilestripped}
[ ! -z "${GSU_DEBUG}" ] && echo "gsu_sshaction debug:RC=${GSU_RC}"
return ${GSU_RC}
}
########################################################################################################
gsu_scpaction ()
{
## $1=uid@server(or just server if same uid) to pull envvar(s) from.
## $2=copy direction -  relates to $3 & $4 files below [i*|o*|-test] [in|out|-test],use "-test" to just test scp.
## $3=local filename(+path)
## $4=remote filename(+path)
## Secure copy named file to/from remote system.
## Note: Assume auto ssh(no password/passphrase) already set up. This is none terminal(tty) scp.
GSU_RC=0
export GSU_REPLCHAR=
while true
do
   gsu_target="$1" 
   gsu_scpdirection="$2" 
   unset gsu_scptest
   
   case ${gsu_scpdirection} in
   -TEST)  gsu_scptest="true"
           gsu_scpdirection="IN"
           set - "dummy" "dummy" "/dev/null" "\${HOME}/.ssh/id_rsa.pub"
           ;;    
   i*|I*)  gsu_scpdirection="IN"
           ;;
   o*|O*)  gsu_scpdirection="OUT"
           ;;
   *)      echo "\n+ Error : arg \$2[\$3 from gsu_sshutils] scp direction (${gsu_scpdirection}) is not recognised"
           echo "+ valid arg values are; [i*|o*|-test] [in|out|-test]"
           echo "+ (procedure=gsu_scpaction)\n "
           GSU_RC=8
           break 1
           ;;
   esac
   [ $# -ge 2 ] && shift 2 || set -
   
   gsu_localfile="$1"
   gsu_remotefile="$2"
   if [[ -z "${gsu_scptest}" ]]; then
      unset gsu_oemsg 
      gsu_localtemp="$(gsu_strip "${gsu_localfile}")" || { GSU_RC=$?;echo "${gsu_localtemp}";return ${GSU_RC}; }
      gsu_remotetemp="$(gsu_strip "${gsu_remotefile}")" || { GSU_RC=$?;echo "${gsu_remotetemp}";return ${GSU_RC}; }
      
      if [[ -z "${gsu_localtemp}" && -z "${gsu_remotetemp}" ]]; then
         gsu_oemsg="arg \$3+\$4[\$4+$\5 from gsu_sshutils] scp local+remote files(resp.) are both blank"
      elif [[ -z "${gsu_localtemp}" ]]; then
         echo "Info : blank localfile, inheriting localfile(+path)=remotefile(+path)"
         gsu_localfile="${gsu_remotefile}"
      elif [[ -z "${gsu_remotetemp}" ]]; then
         echo "Info : blank remotefile, inheriting remotefile(+path)=localfile(+path)"   
         gsu_remotefile="${gsu_localfile}"
      fi         

      if [[ "${gsu_scpdirection}" = "OUT" && -z "${gsu_oemsg}" ]]; then
         if [[ ! -f "${gsu_localfile}" ]]; then
            gsu_oemsg="arg \$3[\$4 from gsu_sshutils] scp local file (${gsu_localfile}) not found" 
         elif [[ ! -r "${gsu_localfile}" ]]; then
            gsu_oemsg="arg \$3[\$4 from gsu_sshutils] scp local file (${gsu_localfile}) found but not readable - check permissions"
         fi
      fi
      
      if [[ ! -z "${gsu_oemsg}" ]]; then
         echo "\n+ Error : ${gsu_oemsg}"
         echo "+ (procedure=gsu_scpaction)\n "
         GSU_RC=8
         break 1
      fi
   fi
    
   unset gsu_scpfilespec 
   gsu_scpoutcmdfile="$(gsu_tempstore "file")" || { GSU_RC=$?;echo "${gsu_scpfilespec}";return ${GSU_RC}; }

   [ "${gsu_scpdirection}" = "IN" ] && gsu_scpfilespec="${gsu_target}:${gsu_remotefile} ${gsu_localfile}"\
                                    || gsu_scpfilespec="${gsu_localfile} ${gsu_target}:${gsu_remotefile}"
                               
   scp -qv -o BatchMode=yes ${gsu_scpfilespec} >${gsu_scpoutcmdfile} 2>&1
   
   GSU_RC=$?
   if [[ ${GSU_RC} -ne 0 ]]; then
      echo "=================================================================="
      echo "+ Error : scp returned RC=${GSU_RC} (procedure=gsu_scpaction)"
      echo "+ remote server=${gsu_target}"
      echo "+ scp returned message;"
      echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
      cat ${gsu_scpoutcmdfile}
      echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
      break 1
   else
      if [[ ! -z "${gsu_scptest}" || ! -z "${GSU_DEBUG}" ]]; then
         [ ! -z "${GSU_DEBUG}" ] && echo "gsu_scpaction debug:"
         [ ! -z "${gsu_scptest}" ] && echo ">> scp test : verbose output;"
         cat ${gsu_scpoutcmdfile}
         [ ! -z "${gsu_scptest}" ] && echo ">> scp test : connection+null copy back from ${gsu_target} successful, RC=${GSU_RC}"
      else       
         echo "-----------------------------------------------------------"
         echo "--- SCP Command(s) sent to remote_server ${gsu_target};"
         echo " "
         echo "scp -qv -o BatchMode=yes\\"
         echo "\t${gsu_scpfilespec}"|sed 's/ /\\\n\t/g'
         echo "-----------------------------------------------------------"      
         echo "--- SCP returned message;"
         echo " "
         grep -iv "^debug1:" ${gsu_scpoutcmdfile}
         echo "-----------------------------------------------------------"  
      fi     
   fi                                   
   break 1   
done

rm -f ${gsu_scpoutcmdfile}
[ ! -z "${GSU_DEBUG}" ] && echo "gsu_scpaction debug:RC=${GSU_RC}"
return ${GSU_RC}
}
########################################################################################################
gsu_sftpaction ()
{
## $1=uid@server(or just server if same uid) to pull envvar(s) from.
## $2=file(+path) containing sftp directives (directives can be hardcoded to arg instead if reqd) to execute,use "-test" to just test sftp.
##    specify 'file:<filename>' for a file of directives. 
## SFTP to remote server & execute $2 commands [can be file/hardcoded contents], note hardcoded contents will have to be 
##                                              properly escaped & LF'd to execute successfully].
## Note: Assume auto ssh(no password/passphrase) already set up. This is none terminal(tty) sftp.
GSU_RC=0
export GSU_REPLCHAR=
while true
do
  gsu_target="$1" 
  gsu_sftpdirectives="$2" 
  unset gsu_sftptest
  
  if [[ -z "$(gsu_strip "${gsu_sftpdirectives}")" ]]; then
     echo "\n+ Error : arg \$2[\$3 from gsu_sshutils] sftp directives(file/cmds) is blank"
     echo "+ (procedure=gsu_sftpaction)\n "
     GSU_RC=8
     break 1
  elif [[ "${gsu_sftpdirectives}" = "-TEST" ]]; then
       gsu_sftpdirectives="ls"
       gsu_sftptest="true"
  fi
    
  unset gsu_sftpprepipe 
  gsu_sftpoutcmdfile="$(gsu_tempstore "file")" || { GSU_RC=$?;echo "${gsu_sftpprepipe}";return ${GSU_RC}; }
  
  if [[ "$(echo ${gsu_sftpdirectives:0:5}|gsu_lc)" = "file:" ]]; then
     gsu_sftpdirectives="$(echo ${gsu_sftpdirectives}|cut -d':' -f2-)"
     eval "gsu_sftpdirectives=${gsu_sftpdirectives}" ## expand vars etc
     if [[ ! -f "${gsu_sftpdirectives}" || ! -r "${gsu_sftpdirectives}" ]]; then
        echo "\n+ Error : arg \$2[\$3 from gsu_sshutils] sftp directives(file/cmds) is"
        echo "+ specified as a file, but file cannot be found or is not readable (check permissions)"
        echo "+ file=${gsu_sftpdirectives}"             
        echo "+ (procedure=gsu_sftpaction)\n "
        GSU_RC=8
        break 1
     fi         
     gsu_sftpprepipe="cat ${gsu_sftpdirectives}" 
  else
     gsu_sftpprepipe="echo "${gsu_sftpdirectives}""
  fi   
  
  ${gsu_sftpprepipe} | sftp -vo BatchMode=yes ${gsu_target} >${gsu_sftpoutcmdfile} 2>&1
  
  GSU_RC=$?
  if [[ ${GSU_RC} -ne 0 ]]; then
     echo "=================================================================="
     echo "+ Error : sftp returned RC=${GSU_RC} (procedure=gsu_sftpaction)"
     echo "+ remote server=${gsu_target}"
     echo "+ sftp returned message;"
     echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"    
     cat ${gsu_sftpoutcmdfile}
     echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
     break 1
  else
     if [[ ! -z "${gsu_sftptest}" ||  ! -z "${GSU_DEBUG}" ]]; then
        [ ! -z "${GSU_DEBUG}" ] && "gsu_sftpaction debug:"
        [ ! -z "${gsu_sftptest}" ] && echo ">> sftp test : verbose output;"
        cat ${gsu_sftpoutcmdfile}
        [ ! -z "${gsu_sftptest}" ] && echo ">> sftp test : connection+ls from ${gsu_target} successful, RC=${GSU_RC}"
     else        
         echo "-----------------------------------------------------------"
         echo "--- SFTP Command(s) sent to remote_server ${gsu_target};"
         echo " "
         echo "${gsu_sftpprepipe}"
         echo "-----------------------------------------------------------"      
         echo "--- SFTP returned message;"
         echo " "
         grep -iv "^debug1:" ${gsu_sftpoutcmdfile}
         echo "-----------------------------------------------------------"  
     fi  
  fi                                   
  break 1    
done

rm -f ${gsu_sftpoutcmdfile}
[ ! -z "${GSU_DEBUG}" ] && echo "gsu_sftpaction debug:RC=${GSU_RC}"
return ${GSU_RC}
}
########################################################################################################
gsu_cachefile ()
{
## $1=file to cache to named variables
## $2=parse field seperator in file, what char(s) fields are seperated by
## $3..$n(or "$3" for all) variables(arrays) to instantiate file fields into (horizontally)
## Cache flat file fields into passed variables(arrays), ignores blank & '#' records
GSU_RC=0
while true
do
   if [[ $# -lt 3 ]]; then
      gsu_notenoughargs "noexit:gsu_cachefile" 3 $# "Valid args=filename field-seperator field-column-arrayname(s)" "$*"
      GSU_RC=8
      break 1
   fi

   gsu_pathload=
   if [[ "$(dirname "$1")" = "." ]]; then
      gsu_pathload="[\$PATH lookup] "
      gsu_pathlookup="$(gsu_pathsearch "$1")"
      if [[ ! -z "${gsu_pathlookup}" ]]; then
         gsu_occ1="$(echo "${gsu_pathlookup}"|cut -d' ' -f1)" ## grab 1st occurence
         shift 1
         gsu_saveargs="$*"
         set - "${gsu_occ1}" ${gsu_saveargs}
     fi
   fi
  
   if [[ ! -f "$1" ]]; then
      echo "\n+ Error : arg \$1=$1 file not found ${gsu_pathload}(procedure=gsu_cachefile)\n "   
      GSU_RC=8
      break 1
   elif [[ ! -r "$1" ]]; then
      echo "\n+ Error : arg \$1=$1 file ${gsu_pathload}found but not readable - check permissions (procedure=gsu_cachefile)\n "     
      GSU_RC=8
      break 1
   fi
   
   ## check for a shared memory version that is newer than(or =) the original 
   gsu_dir="$(dirname "$1")"
   gsu_file="$(basename "$1")"
   while [ -d "/dev/shm" ] ## shared memory available
   do
       gsu_filerefresh=
       if [[ ! -f "/dev/shm/${gsu_file}" ]]; then       ## doesnt exist    
          gsu_filerefresh="true"
       elif [[ "$1" -nt "/dev/shm/${gsu_file}" ]]; then ## orig newer(changed?)
          gsu_filerefresh="true"  
       fi
       if [[ ! -z "${gsu_filerefresh}" ]]; then
                                                        ## despace, de remark(=speed)
          sed '/^[ \t]$/d;/^ *$/d;/^[ \t]*\#/d' "$1" >"/dev/shm/${gsu_file}" 2>/dev/null
          if [[ $? -ne 0 ]]; then                       ## some problem=default to orig 
             rm -f "/dev/shm/${gsu_file}"
             break 1
          fi
       fi      
       gsu_dir="/dev/shm" 
       break 1     
   done
   
   gsu_fullfilename="${gsu_dir}/${gsu_file}"
   gsu_sepr="$2"
   [ -z "${gsu_sepr}" ] && gsu_sepr=" "
      
   shift 2
   GSU_SIFS="${IFS}" 
   gsu_y=0
   gsu_instvars="$(echo $*|sed "s/ /${gsu_sepr}/g")"
   gsu_instvars="$(echo "${gsu_instvars}"|sed 's/\$//g')" ## remove '$'s   
   export GSU_REPLCHAR=
   
   [ ! -z "${BASH_VERSION}" ] && gsu_rarrsw="-a" || gsu_rarrsw="-A" 
   IFS="${gsu_sepr}"
   while read ${gsu_rarrsw} gsu_field
   do
      if [[ "${gsu_dir}" != "/dev/shm" ]]; then
         gsu_tline="$(gsu_strip "${gsu_field[*]}")" || { GSU_RC=$?;echo "${gsu_tline}";return ${GSU_RC}; }
         [ -z "${gsu_tline}" -o "${gsu_tline:0:1}" = "#" ] && continue 1 ## empty or remark line
      fi
      
      gsu_x=0
      for gsu_arrayvar in ${gsu_instvars}
      do 
         gsu_field[gsu_x]="$(gsu_trimchar "both" "${gsu_field[gsu_x]}")" || { GSU_RC=$?;echo "${gsu_filed[gsu_x]}";return ${GSU_RC}; }
         eval "${gsu_arrayvar}[gsu_y]='${gsu_field[gsu_x]}'"
         if [[ $? -ne 0 ]]; then ## eval failed
            echo "\n+ Error : arg \$1=$1 file eval of field failed (procedure=gsu_cachefile)"
            echo "+ eval line; ${gsu_arrayvar}[${gsu_y}]=${gsu_field[gsu_x]}\n "
            GSU_RC=8
            break 1
         fi  
         [ ! -z "${GSU_DEBUG}" ] && echo "gsu_cachefile debug:${gsu_arrayvar}[${gsu_y}]=${gsu_field[gsu_x]}"
         ((gsu_x+=1))
      done
      ((gsu_y+=1))
   done < ${gsu_fullfilename}
   IFS="${GSU_SIFS}"
   
   if [[ ${gsu_y} -eq 0 ]]; then
      echo " "
      echo "+ Warning : arg \$1=$1 file contains no valid usable config (procedure=gsu_cachefile)"     
      GSU_RC=3
   fi     
   break 1   
done
[ ! -z "${GSU_DEBUG}" ] && echo "gsu_cachefile debug:RC=${GSU_RC}"
return ${GSU_RC} 
}
########################################################################################################
gsu_procstat ()
{
## $1=pid of process to check(if sourced/executed)
## $2=process(script) to check(ifsourced/executed) - add args and/or final space if require unique match
## Checks a passed process to see if it is executed or sourced.
## returns envvars PNET_PROCESS="sourced|notfnd" / "executed"
## If 'executed' envvars PNET_THISSCRIPT/PNET_THISSCRIPT_PATH will contain the $2 basename/dirname resp.
## If 'sourced|notfnd' envvars PNET_THISSCRIPT/PNET_THISSCRIPT_PATH will contain the $2 parent basename/dirname resp.

GSU_RC=0
unset PNET_PS_LINE PNET_PROCESS PNET_THISSCRIPT PNET_THISSCRIPT_PATH
while true
do
   if [[ $# -lt 2 ]]; then
      gsu_notenoughargs "noexit:gsu_procstat" 2 $# "Valid args=pid process-name" "$*"
      GSU_RC=8
      break 1
   fi

   gsu_pidnumeric="$(gsu_istype "numeric" "$1")" || { GSU_RC=$?;echo "${gsu_pidnumeric}";return ${GSU_RC}; }
   
   if [[ -z "${gsu_pidnumeric}" || $1 -eq 0 ]]; then
      echo "\n+ Error : arg \$1=$1 pid is not numeric or out of range (procedure=gsu_procstat)\n "   
      GSU_RC=8
      break 1
   fi
  
   gsu_scriptstripped="$(gsu_strip "$2")"
   GSU_RC=$?
   if [[ ${GSU_RC} -ne 0 ]]; then
      echo "${gsu_scriptstripped}"
      break 1
   elif [[ -z "${gsu_scriptstripped}" ]]; then
      echo "\n+ Error : arg \$2 process(script) to check is blank (procedure=gsu_procstat)\n "   
      GSU_RC=8
      break 1
   fi
   set - $1 "${gsu_scriptstripped}" 

   PNET_PS_LINE="$(ps -o args= -p $1)"
   
   if [[ -z "${PNET_PS_LINE}" ]]; then
      echo "\n+ Error : arg \$1=$1 pid returned null process, pid may be incorrect (procedure=gsu_procstat)\n "     
      GSU_RC=8
      break 1
   fi

   gsu_simplecmd="$(ps -o comm= -p $1)"
   gsu_pslhs="$(echo "${PNET_PS_LINE%%${gsu_simplecmd}*}"|awk -F' ' '{print $(NF)}')"
   gsu_psrhs="$(echo "${PNET_PS_LINE#*${gsu_simplecmd}*}")"
   PNET_THISSCRIPT="${gsu_simplecmd}${gsu_psrhs}"
   gsu_dirbreak="$(dirname "${gsu_pslhs}/${PNET_THISSCRIPT}" 2>/dev/null)"
   [ -z "${gsu_dirbreak}" -o "${gsu_dirbreak}" = "." ] && PNET_THISSCRIPT_PATH="$(pwd)" || PNET_THISSCRIPT_PATH="${gsu_pslhs}"
   if [[ "${PNET_THISSCRIPT:0:${#2}}" = "$2" ]]; then
      PNET_PROCESS="executed"
   else
      PNET_PROCESS="sourced|notfnd"
   fi
   break 1

done
export PNET_PS_LINE PNET_PROCESS PNET_THISSCRIPT PNET_THISSCRIPT_PATH
[  ! -z "${GSU_DEBUG}" ] && 
{ 
   echo "gsu_procstat debug:PNET_PS_LINE=${PNET_PS_LINE}"
   echo "gsu_procstat debug:PNET_PROCESS=${PNET_PROCESS}"
   echo "gsu_procstat debug:PNET_THISSCRIPT=${PNET_THISSCRIPT}"
   echo "gsu_procstat debug:PNET_THISSCRIPT_PATH=${PNET_THISSCRIPT_PATH}"
   echo "gsu_procstat debug:RC=${GSU_RC}"   
}   
return ${GSU_RC}
}
########################################################################################################
gsu_trighandle ()
{
## $1=action to perform on trigger [a*|d*] [add|delete]
## $2=trigger status to set [y*|n*] [yes|no] - can be [a*|all] for $1=delete
## $3=trigger to fire(set) or delete (should incl. path if not pwd)
## $4=intertrigger refresh wait time in seconds 
## adds/deletes a specified trigger to envvar directory $PNET_TRIGGER_DIR
GSU_RC=0
while true
do
   ## validate no. of args+reqd envvar
   if [[ $# -lt 4 ]]; then
      gsu_notenoughargs "noexit:gsu_trighandle" 3 $# "Valid args=action[a|d] trigstat [y|n|a] triggername(+path) refreshwaitsecs" "$*"
      GSU_RC=8
      break 1
   fi

   ## validate action ($1)
   set - "$(echo $1|gsu_lc)" "$(echo $2|gsu_lc)" "$3" "$4"
   gsu_action=
   case $1 in 
   a*) gsu_action="add"
       ;;
   d*) gsu_action="delete" 
       ;;
   *)  echo "\n+ Error : Arg \$1=$1 action is invalid, valid=[add|delete] (procedure=gsu_trighandle)\n "   
       GSU_RC=8
       break 1
       ;; 
   esac
   
   ## validate set status ($2)
   gsu_trigswitch=
   case $2 in
   y*) gsu_trigswitch="Y"
       ;;
   n*) gsu_trigswitch="N"
       ;;
   a*) if [[ "${gsu_action}" != "delete" ]]; then
          echo "\n+ Error : Arg \$2=$2 trigger status is invalid for \$1=$1 action, valid=[yes|no] only (procedure=gsu_trighandle)\n "   
          GSU_RC=8
          break 1
       else
          gsu_trigswitch="*"
       fi
       ;;      
   *)  echo "\n+ Error : Arg \$2=$2 trigger status is invalid, valid=[yes|no|all{for \$1=delete only}] (procedure=gsu_trighandle)\n "   
       GSU_RC=8
       break 1
       ;; 
   esac        

   ## validate trigger dir/file ($3)
   gsu_trigdir="$(dirname $3)" 
   gsu_trigname="$(echo $(basename $3)|gsu_uc)"
   
   if [[ -z "${gsu_trigname}" ]]; then
      echo "\n+ Error : Arg \$3 trigger name is blank\n "   
      GSU_RC=8
      break 1
   elif [[ ! -d "${gsu_trigdir}" ]]; then   
      echo "\n+ Error : Arg \$3=$3 directory (${gsu_trigdir}) does not exist (procedure=gsu_trighandle)\n "   
      GSU_RC=8
      break 1
    elif [[ ! -r "${gsu_trigdir}" || ! -w "${gsu_trigdir}" ]]; then 
      echo "\n+ Error : Arg \$3=$3 directory (${gsu_trigdir}) exists, but is not readable/writable (check permissions) (procedure=gsu_trighandle)\n "   
      GSU_RC=8
      break 1     
   fi

   ## validate intertrigger refresh wait time
   if [[ -z "$4" ]]; then
      echo "\n+ Error : Arg \$4 refresh wait time is blank (procedure=gsu_trighandle)\n "   
      GSU_RC=8
      break 1          
   fi     
   gsu_wait="$(gsu_istype "numeric" "$4")" || { GSU_RC=$?;echo "${gsu_wait}";return ${GSU_RC}; } 
   if [[ -z "${gsu_wait}" ]]; then
      echo "\n+ Error : Arg \$4=$4 refresh wait time is not numeric (procedure=gsu_trighandle)\n "   
      GSU_RC=8
      break 1          
   fi
   
   ## all args validated perform actions required now.
   gsu_trigfile="${gsu_trigdir}/${gsu_trigname}_AVAIL_${gsu_trigswitch}"
   gsu_trigexist="$(ls ${gsu_trigfile} 2>/dev/null)" ## (ls rather than -f because of potential '*')
      
   echo "\n+ Info : ${gsu_action} trigger ${gsu_trigfile}, refresh delay=$4 secs"
   [ -z "${gsu_trigexist}" ] && gsu_fndmsg="not " || unset gsu_fndmsg
   echo "+ Info : existing trigger(s) ${gsu_fndmsg}found"
   for gsu_fndtrig in ${gsu_trigexist}
   do
      echo "+ Info : $(basename ${gsu_fndtrig})"
   done
   
   [ "${gsu_action}" = "delete" -a -z "${gsu_trigexist}" ] && break 1 ## no work to do
   ## otherwise its add(new/refresh)/delete(old) trigger file(s)
   gsu_tmpcmd=$(gsu_tempstore "file") || { GSU_RC=$?;echo "${gsu_tmpcmd}";return ${GSU_RC}; }
   chmod 700 ${gsu_tmpcmd} 
   
   case ${gsu_action} in
   a*) if [[ ! -z "${gsu_trigexist}" ]]; then ## add, trigger already exists;
          [ $4 -gt 0 ] && echo "sleep $4" >>${gsu_tmpcmd}
          echo "rm -f ${gsu_trigfile}"    >>${gsu_tmpcmd}
          [ $4 -gt 0 ] && echo "sleep $4" >>${gsu_tmpcmd}         
          echo "+ Info : trigger(s) will be removed in $4 seconds & refreshed after a further $4 seconds have elapsed"
       else                                   ## trigger doesnt exist
          echo "+ Info : trigger will be written immediately"
       fi
       echo "touch ${gsu_trigfile}"       >>${gsu_tmpcmd}
       ;;
   *)  if [[ $4 -gt 0 ]]; then ## must be delete, trigger(s) definately exist
          echo "sleep $4"                 >>${gsu_tmpcmd}
          echo "+ Info : trigger(s) will be removed in $4 seconds"
       else
          echo "+ Info : trigger(s) will be removed immediately"           
       fi 
       echo "rm -f ${gsu_trigfile}"       >>${gsu_tmpcmd}
       ;;
   esac        
   echo "rm -f ${gsu_tmpcmd}" >>${gsu_tmpcmd} ## finally remove command store file
   
   [  ! -z "${GSU_DEBUG}" ] &&
   {
         echo "gsu_trighanlde debug:dump temp command file start;"
         cat ${gsu_tmpcmd}
         echo "gsu_trighanlde debug:dump temp command file end;"
   }   
   
   if [[ ! -z "${gsu_trigexist}" && $4 -gt 0 ]]; then
      echo "+ Info : Delayed job will be completed in background."
      nohup ${gsu_tmpcmd} >/dev/null 2>&1 &
   else
      ${gsu_tmpcmd}
      echo "+ Info : Immediate job completed in foreground."
   fi
      
   break 1
done
[ ${GSU_RC} -eq 0 ] && echo " "
return ${GSU_RC}
}
##################################################
#                                                #
#        ## ##     #     #####   ##  #           #
#        # # #    # #      #     # # #           #
#        #   #   #####     #     # # #           #
#        #   #   #   #   #####   #  ##           #
#                                                #
##################################################
########################################################################################################
## Always executed, these vars not exported since should be local only
## These lines are concerned with checking the calling (ie sourcing) module, since this module, 
## to be of any use should always be sourced and not called, if this module is found to have its
## own pid, then the above functions and procedures wont be callable since they will have 
## been instantiated in a sub shell and not the calling shell.
GSU_RC=0
gsu_thisscript="general_sourced_utils.conf"

alias gsu_lc="tr '[:upper:]' '[:lower:]'"
alias gsu_uc="tr '[:lower:]' '[:upper:]'"
alias gsu_allnum="egrep ^[[:digit:]]+$"
alias gsu_file2list="tr '\n' ' '"
alias gsu_list2file="tr ' ' '\n'"
alias gsu_sqspc="tr -s '[ ]'"
alias gsu_commanum="sed -e :a -e 's/\(.*[0-9]\)\([0-9]\{3\}\)/\1,\2/;ta'"
alias gsu_dedupelist="gsu_list2file|sort|uniq|gsu_file2list"
[ "$(alias echo 2>/dev/null)" != "alias echo='echo -e'" -a -z "$(echo -e)" ] && alias echo='echo -e'

gsu_checktty

unset gsu_silent
gsu_args="$(echo "$*"|gsu_lc)"

while true
do
   case ${gsu_args} in
   *\?*|-h*|-i*|-u*|h*|i*|u*|--*)
           gsu_usage ## usage output run
           break 1;;
   -s*|s*) gsu_silent=true;;
   *)      :;;    
   esac

   [ -z "${gsu_silent}" ] && gsu_startendmsg "start" "${gsu_thisscript}"
   
   gsu_procstat $$ "${gsu_thisscript}" || gsu_errorexit 8 "${gsu_thisscript}"

   ## check to see that this script is being sourced,no use if it isnt.
   if [[ "$(echo ${PNET_PROCESS}|gsu_lc)" != sourced* ]]; then
      echo " "
      echo "+ERROR : ${gsu_thisscript} MUST be sourced to instantiate utilities into current shell."
      echo "+      : This run was executed rather than sourced,ie in a subshell & not callers shell,"
      echo "+      : as a result none of the functions/procedures will be callable."
      echo "+      : ${gsu_thisscript} -?*|-h*|-i*|-u*|--*|h*|i*|u* for usage."
      echo " "
      gsu_errorexit 8 "${gsu_thisscript}"
   fi

   if [[ -z "${gsu_silent}" ]]; then   
      echo " "
      echo "## Functions & Routines sourced successfully..."
      echo "## Current user    : $(id)"
      gsu_omsg="## Machine         : "
      [ -z "${PNET_MACHINE}" ] && echo "${gsu_omsg}Unknown" || echo "${gsu_omsg}${PNET_MACHINE}"
      gsu_omsg="## Sourcing script : "
      [ -z "${PNET_THISSCRIPT}" ] && echo "${gsu_omsg}Unknown(caller=shell|a sourced script itself)" || echo "${gsu_omsg}${PNET_THISSCRIPT}"
      gsu_omsg="## Sourcing pwd    : "
      [ -z "${PNET_THISSCRIPT_PATH}" ] && echo "${gsu_omsg}Unknown" || echo "${gsu_omsg}${PNET_THISSCRIPT_PATH}"
      gsu_omsg="## Terminal run    : "
      [ -z "${PNET_TTY}" ] && echo "${gsu_omsg}false" || echo "${gsu_omsg}${PNET_TTY}"
      echo " " 
   fi   
   break 1
done

[ -z "${gsu_silent}" ] && gsu_allexits 0 "${gsu_thisscript}" "successfully"
return 0
########################################################################################################

