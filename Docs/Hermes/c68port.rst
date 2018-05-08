=======
C68Port
=======

Initial Thoughts
================

*   The program_name will be the sav file with the _sav extension removed and _c added. It will include any required system headers plus its own ``program_name_h`` file.
*   Possible to have a ``program_name_h`` containing nothing more than:

    ..  code-block:: c
    
        #include <globals.h>
        #include <functions.h>
        
*   Scan the sav file from top to bottom.
*   Make a note of where various sections start as offsets in the file. Needed later.
*   For each def proc/def fn found, write a ``functions_h`` line defining how it will look in when converted to c.
*   For any non-LOCal variables, write them out to the ``globals_h`` file.
*   Any statements not in any DEF PROC/FN sections should be written out to ``program_name_c``  in the ``main()`` function.
*   All Def Proc/FN code will be written out to the ``functions_c`` file.
*   Debugging information will be written to a separate debugging file, if the command line parameter(s) includes '--debug=file_name' in upper or lower case.


Foibles
=======

FOR Statements
--------------

*   FOR statements can have a range. If the statement is a "normal" one ``for x = start to finish step x`` then it is fine and converts to equivalent c code:

    ..  code-block:: c
    
        int x;
        for (x = start; x <= finish; x++) {
            ...
        }

*   If it is along  the lines of ``for x = 1,3,8,17,64``  then it could be converted to something like:

    ..  code-block:: c

        int xArray[] = {1,3,8,17,64};
        int x;
        for (xArrayTmp = 0; xArrayTmp < sizeof(xArray/sizeof(short)); xArrayTmp++) {
            x = xArray[xArrayTmp];
            ...
        }

    Problem is, what happens if there are two for x loops in the same function/proc/free standing.
        
*   If the format is a mixture of the above, we can't cope!

    
Nested EXITs
------------

These are going to cause problems. ``break`` exits one level in C and there's no way (other than a goto?) to exit from a nested loop *cleanly*.    