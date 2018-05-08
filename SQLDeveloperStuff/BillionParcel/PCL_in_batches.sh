export TZ='Europe/London'
export LANG=en_GB

sqlplus /nolog <<EOD | tee -a pcl.log

conn / as sysdba
set pages 3000 lines 500 time on
set timing on echo on feed on linesize 1000 trimspool on trimout on
set serverout on size unlimited
set define off


-- IN THIS SCRIPT
-- 1. Set sleepyTime to the number of seconds to pause between batches. Minimum is one.
-- 2. Set rowLimit to the number of rows to be deleted per batch.
-- 3. Change, in two places, the table name and partition name to be deleted from.

-- ON THE DATABASE SERVER:
-- 4. Set the oracle environment.
-- 5. nohup ./this_file &

-- It will run on the server, as a batch job, and when your network drops out,
-- as it will, it will keep running.

declare
    kount number;
    inLoop number := 1;
    sleepyTime constant number := 30;
    rowLimit constant number := 250000;

begin
    -- Report initial progress.
    dbms_application_info.set_module('BillionParcels', 'First batch deletion.');

    loop
        -- Delete one batch.
        -- *** CHANGE ME AS NECESSARY ***
        delete /*+ full(t) parallel(t,12) */ 
        from pnet.pcl partition(PNET_PCL_PART_201702) t 
        where rownum < rowLimit + 1;
        commit;

        -- More to do?
        -- *** CHANGE ME AS NECESSARY ***
        select count(*)
        into kount
        from pnet.pcl partition(PNET_PCL_PART_201702);

        -- Done, bale out.
        if (kount = 0) then
            exit;
        end if;

        -- Not complete, report progress so far.
        dbms_application_info.set_action(to_char(inLoop * rowLimit, '9,999,999,999') || ' deletions.');

        inLoop := inLoop + 1;

        -- Delay a while to allow processing to get a look in, if necessary.
        dbms_lock.sleep(sleepyTime);

    end loop;

    -- Sign off.
    dbms_application_info.set_module(null, null);

end;
/


quit;
EOD
