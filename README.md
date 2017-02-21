# OracleScripts
Some Oracle scripts I use from time to time. I'm fed up having to keep zipping and unzipping when I move between contracts. I'm not sure these will be of much use by anyone else though!

The `docs` folder has ReStructuredText source files for a number of documents that I've written which might be (partially) useful to someone? Maybe?

- 9iRestore - How to bring a database, upgraded from 9i to 11g, back from 11g to 9i. 
- DatabaseHandover - Documentation for me to supply to my replacements, colleagues when this project is finished.
- RMANRestore - Hosw to identify the files required, and the processes involved in restoring an RMAN (11g) database dump back to a test server to ensure that the backups are viable.
- There may be more .... wtach this space -> [ ]

## Scripts currently available:


### dbshut.cmd
A script, to be run as administrator, to stop any running Oracle Services on Windows. Only the database services are stopped. This  will shut down the databases too.


### oraenv.cmd
A useful script for Windows which doesn't have the oraenv command. Can be called from batch files, or interactively.


### OraRunning.cmd
A script to list any running Oracle Database services, on a Windows server.


### Clone-Refresh Scripts
Scripts in here refresh a database, using a pretty contrived method, using exp/imp in the case of dbrefresh.cmd, or, using an RMAN clone to clone an existing database from another. This messes up the backups etc for the database being refreshed. The script relies on the databases having all files on the same windows disc and is pretty much hard coded as to paths etc.

You can get help on these two scripts by running the following commands.


````
dbRefresh help
````

````
dbClone help
````

### Clone-Refresh Scripts
Some scripts that can be used to clone a database to another in order to refresh it. Uses RMAN to do the cloning. **Warning** Might be a tad out of date. Might also have some hard coding.

### ExportScripts
In this folder you will find a set of scripts that I used to generate a pile of separate parameter files for a 9i database export. These are pretty much hard coded in the table names etc. Unlikely to be of much use to anyone, perhaps!


### Toad Stuff
A pile of scripts, saved from Toad, that I've used for work, or for helping other people out on the Toad forums at ToadWorld.com. 


### RMAN_Scripts
A few scripts to make a cold backup, or a level 0 or 1 incremental backup of a database running on a Windows server. A separate script to backup the archived logs also exists here. Watch out for any hard coding!




