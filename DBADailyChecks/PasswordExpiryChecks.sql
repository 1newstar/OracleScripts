spool logs\PasswordExpiryChecks.lst

-- List all users with a profile which limits password life times
-- and who are going to have to change their password in the next 
-- fortnight.
--
-- Norman Dunbar.
--

with password_life_time as (
    select profile, limit
    from dba_profiles
    where resource_name = 'PASSWORD_LIFE_TIME'
    and limit <> 'UNLIMITED' 
    and limit <> 'DEFAULT'   
),
--
user_stuff as (
    select username, expiry_date, profile as profile_name, trunc(expiry_date) - trunc(sysdate) as days_remaining
    from dba_users
    where account_status = 'OPEN'
    and profile <> 'APP_USER'
)
--
select username, expiry_date, days_remaining, profile, limit
from password_life_time, user_stuff
where profile = profile_name
and days_remaining <= 14
order by days_remaining, username;


spool off