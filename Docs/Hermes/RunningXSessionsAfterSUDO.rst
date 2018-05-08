===================================
Running X Applications on MobaXterm
===================================

Introduction
============

MobaXterm starts an X server automatically on connecting to a server. However, only the logged in user can access the ``$DISPLAY`` set up. 

The Solution
============

In order to use a X application from a different user, the following is required:

*   Login as yourself.
*   Execute:

    ..  code-block:: bash
    
        xauth list | tail -1
        screen
        
*   Copy the ``xauth -list`` output to the clipboard.
*   ..  code-block:: bash

        sudo -iu oracle
        # Set Oracle Environment here
        
        xauth add <paste clipboard here>
        
Your desired X application, Oracle installer etc, will now run.        
