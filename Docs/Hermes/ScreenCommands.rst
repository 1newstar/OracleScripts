====================
Screen Utility Guide
====================

Introduction to Screen
======================

Given that whenever we forget to type something into a session on a server, we get disconnected from the network, the ``screen`` command is very useful.

It allows a session to fork a new session, and that session will remain running even after the network disconnect has occurred. When you login again "later", you can simply find out which sessions are running and reconnect, picking up from where you left off.

The ``screen`` command works fine on the MISA01P1, RTT and MyHermes, servers, so is extremely useful for the daily stats running, for example. It may also exist on other servers that I rarely login to.

Best Practice?
--------------

The best practice, if such a thing can be said to actually exist, is to do the following:

*   Login as yourself, hisgnnn
*   Run the ``screen -list`` command to see your existing sessions. 

If you have no existing sessions, start a new one by running the ``screen`` command. You should now:

*   ``sudo -iu oracle``
*   Set the Oracle environment
*   Do your work.

If you do have existing session(s) then reconnect using the command ``screen -R``, which if it fails, can be forced by ``screen -RR`` and you will be able to pick up from where you left off.

A summary of the most useful commands are given below.

It is best to start a screen session in your own account because when you list the existing screen sessions, it is based on the account that started the session, not the account you are currently running in. If we all did it after changing to the oracle user, we would have difficulty determining our own session from every one else's! By staring in our own account, no problem exists.    
    


Starting Screen etc
===================

+-------------------------+--------------------------------------------------------+
| screen -list            | List all available screens, plus connection status.    |
+-------------------------+--------------------------------------------------------+
| screen -r [pid.session] | Reattach to session. pid.session optional.             |
+-------------------------+--------------------------------------------------------+
| screen -R               | Connect to first available session.                    |
+-------------------------+--------------------------------------------------------+
| screen -RR              | Connect to anything!                                   |
+-------------------------+--------------------------------------------------------+
| screen -d [pid.session] | Detach session from whoever, and connect to it 'here'. |
+-------------------------+--------------------------------------------------------+
| screen -S session_name  | Set name of new screen session to given name.          |
+-------------------------+--------------------------------------------------------+


Commands Within a Screen
========================

+------------------+----------------------------------------------------+
| CTRL-a "         | List available windows, pick one, and activate it. |
+------------------+----------------------------------------------------+
| CTRL-a 0-9       | Activate window 'n'.                               |
+------------------+----------------------------------------------------+
| CTRL-a backspace | Previous window.                                   |
+------------------+----------------------------------------------------+
| CTRL-a n         | Next window.                                       |
+------------------+----------------------------------------------------+
| CTRL-a CTRL-c    | Create new window.                                 |
+------------------+----------------------------------------------------+
| CTRL-a d         | Detach from this screen, can reattach later.       |
+------------------+----------------------------------------------------+
| CTRL-a C         | Clear screen of current window.                    |
+------------------+----------------------------------------------------+


Regions
=======

Screen windows can be split into regions. A region is basically half of the window/region you were in when you split it. It allows you to have multiple windows open on the same physical screen - similar to having two separate sessions on the server, but all done from within one session! Try it!

+---------------+----------------------------------------------------+
| CTRL-a S      | Split current window. Adds a blank region.         |
+---------------+----------------------------------------------------+
| CTRL-a tab    | Activate next region.                              |
+---------------+----------------------------------------------------+
| CTRL-a X      | Kill current region.                               |
+---------------+----------------------------------------------------+


Once you create a new region, it is initially blank. You need to the switch to it and start or choose a window to display in the new region. As described below.

Running Multiple Windows, Simultaneously
----------------------------------------

*   *CTRL-a S* to split the current window into two regions. One will be blank.
*   *CTRL-a tab* to activate the blank region.
*   Either:
    *   *CTRL-a "* and choose an existing window.
    *   *CTRL-a CTRL-c* and create a new window.

Now you have a screen with two active windows. Use *CTRL-a tab* to focus between them. This will allow you to see more than one open session on the same window - so you can easily switch between them.

When you are done with having two (or more) sessions on screen, *CTRL-a X* will kill the *region* but not the *window* that was displayed in it. That can still be switched to with *C-a "* etc.

You can split these regions again, if necessary.
