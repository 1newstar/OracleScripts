create or replace function interpret_time_values(

    piString in varchar2, 
    piErrorString varchar2 default '00:00 AM')
     
return varchar2
as
    --=================================================================
    -- Takes a randomly formatted time string and converts it to
    -- hh:mi AM format.
    -- NULL is returned in the input string itself was NULL or
    -- if the input string was the '--:--' value.
    --=================================================================


    --lString varchar2(11); -- Should use table_name.column_name%type
    lString norman.a_time%type;


    --=================================================================
    -- Helper Function.                                 Convert_Time().
    --=================================================================
    function Convert_Time(
    
        piTime in varchar2, 
        piAmPm in varchar2)
        
    return varchar2
    as
        --=============================================================
        -- Convert a time string to hh:mi AM/PM.
        --
        -- PiTime is never NULL and always is upper case.
        -- PiAmPm is always AM or PM.
        --
        -- Any errors will return a result of NULL.
        --=============================================================
        lHours varchar2(10);
        lMinutes varchar2(10);
        lColon binary_integer;
        lTime norman.a_time%type;
        lAmPm varchar2(2);
        lSize binary_integer;
        lNumber number;
        
    begin
        -- Parameters to local variables.
        lTime := piTime;
        lAmPm := piAmPm;
        
        -- If there is a colon, split there.
        if (lTime like '%:%') then
            lColon := instr(lTime, ':');
            lHours := substr(lTime, 1, lColon - 1);
            lMinutes := substr(lTime, lColon + 1);
            
            -- Is there another colon? Split if so.
            if (lMinutes like '%:%') then
                lColon := instr(lMinutes, ':');
                lMinutes := substr(lMinutes, 1, lColon - 1);
            end if;
            
        else
            -- No colon. The time portion should be either HMM or HHMM
            lSize := length(lTime);
            
            if ((lSize < 3) or (lSize > 4)) then
                -- Yuk!
                return null;
            end if;   
            
            -- If the length is 3, assume HMI, otherwise HHMI.
            -- it COULD be HHM of course, but ....
            if  (lSize = 3) then
                lHours := substr(lTime, 1, 1);
                lMinutes := substr(lTime, 2, 2);
            else
                lHours := substr(lTime, 1, 2);
                lMinutes := substr(lTime, 3, 2);
            end if;
                            
        end if;

        -- Hours must be 1-12.
        begin
            lNumber := to_number(lHours);
            if (lNumber > 23) then
                -- barf!
                raise invalid_number;
            end if;
            
            if (lNumber > 12) then
                lNumber := lNumber - 12;
                lAmPm := 'PM';
            end if;
            
            lHours := trim(to_char(lNumber, '00'));
 
        exception
            when others then
                return null;
        end;
            
        -- Minutes must be 0-59, otherwise barf.
        begin
            lNumber := to_number(lMinutes);
            if (lNumber > 59) then
                -- barf!
                raise invalid_number;
            else
                -- Convert to 2 digits. Should always be thus, but ...
                lMinutes := trim(to_char(lNumber, '00'));
            end if;
            
        exception
            when others then
                return null;
        end;

            
        -- Return 'HH:MI AM'
        return lHours || ':' || lMinutes || ' ' || lAmPm;
        
    end;
    
    

    --=================================================================
    -- Helper Function.                              Strip_AMPM_Time().
    --=================================================================
    function Strip_AMPM_Time (
    
        piTime varchar2)
         
    return varchar2
    as
        --=============================================================
        -- Convert a time string with AM or PM to hh:mi AM/PM.
        --
        -- PiTime is never NULL and always is upper case. It always
        -- has AM or PM in it and no leading or trailing spaces.
        --
        -- Any errors will return a result of NULL.
        --=============================================================
        lAmPm varchar2(10);
        lTime norman.a_time%type;
        -- lTime varchar2(11); -- Should use table_name.column_name%type here.
        
    begin
        -- Parameters to local variables.
        lTime := piTime;
        
        -- AM or PM? Save and then lose it from lTime.
        if (lTime like '%AM%') then
            lAmPm := 'AM';
            lTime := trim(replace(lTime, 'AM', null));
        else
            lAmPm := 'PM';
            lTime := trim(replace(lTime, 'PM', null));
        end if;

        -- Convert the hours and minutes part to HH:MI
        return convert_time(lTime, lAmPm);
        
    end;
    

--=================================================================
-- Main Code Starts Here.
--=================================================================
begin
    -- Parameter to local variables.
    lString := trim(upper(piString));
    
    -- Parameter Validation.
    -- Raising no_data_found activates the exception handler below.
    if (lString is null) then
        raise no_data_found;
    end if;
    
    -- Whatever this one is for, I know not! ;-) 
    -- Return a NULL if we find it.
    if (lString = '--:--') then
        raise no_data_found;
    end if;
    
    
    -- AM or PM already there, at the end?
    if (lString like '%AM') or (lString like '%PM')then
        lString := strip_AMPM_Time(lString);
    else
        -- Ok, AM or PM is not present. Deal with it.
        -- We must assume AM in this case. At least to start with!
        -- But the Convert_Time function will correct that.
        lString := Convert_time(lString, 'AM');   
    end if; 
    
    -- Were there conversion errors?
    -- Return the desired error string if so.
    if (lString is null) then
        return piErrorString;
    end if;
    
    -- Return a correctly converted value.
    return lString;
    
    
exception
    -- NULL is a special error case. Change this if necessary.
    when no_data_found then
        return null;
        
    -- Other exceptions return our desired error string.    
    when others then
        return piErrorString;
end;
/    