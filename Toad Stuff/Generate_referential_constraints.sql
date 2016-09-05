-- 1.2. addcons: This SQL will create an
-- "add constraint" script to recreate all
-- constraints that depend on <WHATEVER> table
select  'alter table ' || t1_table_name
     || ' add constraint ' || t1_constraint_name
     || ' foreign key (' || t1_column_names || ')'
     || ' references ' || t2_table_name
     || '(' || t2_column_names || ');' FK_script
  from
    (select a.table_name t1_table_name
      , a.constraint_name t1_constraint_name
      , b.r_constraint_name t2_constraint_name
      -- Concatenate columns to handle composite
      -- foreign keys [handles up to 10 columns]
      , max(decode(a.position, 1,
           a.column_name,NULL)) ||
        max(decode(a.position, 2,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 3,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 4,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 5,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 6,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 7,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 8,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 9,', '||
           a.column_name,NULL)) ||          
           max(decode(a.position, 10,', '||
           a.column_name,NULL))
          t1_column_names
    from dba_cons_columns a
       , dba_constraints b
    where a.constraint_name = b.constraint_name
    and b.constraint_type = 'R'
    and a.owner = 'FCS'
    group by a.table_name
           , a.constraint_name
           , b.r_constraint_name
    ) t1,
    (select a.constraint_name t2_constraint_name
      , a.table_name t2_table_name
      -- Concatenate columns for PK/UK referenced
      -- from a composite foreign key
      , max(decode(a.position, 1,
           a.column_name,NULL)) ||
        max(decode(a.position, 2,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 3,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 4,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 5,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 6,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 7,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 8,', '||
           a.column_name,NULL)) ||
        max(decode(a.position, 9,', '||
           a.column_name,NULL)) ||          
        max(decode(a.position, 10,', '||
           a.column_name,NULL))
          t2_column_names
    from dba_cons_columns a, dba_constraints b
    where a.constraint_name = b.constraint_name
    and b.constraint_type in ( 'P', 'U' )
    and a.owner = 'FCS'
    group by a.table_name
           , a.constraint_name ) t2
where t1.t2_constraint_name = t2.t2_constraint_name
  and t2.t2_table_name = 'ORDTRAN';