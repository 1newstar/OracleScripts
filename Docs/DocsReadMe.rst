ReadMe
======

Version History
---------------

+---------+------------+-------------+----------------------------------+
| Version | Date       | Author      | Description                      |
+=========+============+=============+==================================+
| 0.1     | 2016/10/21 | N Dunbar    | Initial version                  | 
+---------+------------+-------------+----------------------------------+
| 0.2     | 2017/02/21 | N Dunbar    | Updated to add ``docs`` details. | 
+---------+------------+-------------+----------------------------------+

Introduction
------------

The files in this folder are in ReStructuredText format. (Yes, apparently, it must be spelt that way!) and can be used to create numerous different output formats, using:

- Pandoc
- Sphinx-doc

There is a pandoc_reference document which defines my (current) favoured styles when converting to a docx file. Things might change however, and some of the styles used in the document are not actually applied by Word when the document is opened. Sigh.

Why RST? Well, it was that or Markdown, and I'm more used to RST but also, these are text files and can be easily checked in to a version control system! Binary files are a tad more difficult.


Documents Included
------------------

9iRestore
    A document that details how to revert an 11g database in the Azure cloud (aka The *Fog*), running on Windows, back to a 9i database running on Solaris, and not in the cloud.
    
DatabaseHandover
    Handover document for when my contract expires and some other victim has to take on my work.
    
00 Using DBCA to Build Initial Databases
    Using Oracle's DBCA to build an initial blank database ready to be upgraded to a full sized UV database.

01 Building UV Databases
    Upgrading a blank DBCA created database with various scripts, to resemble a full sized UV database, ready for importing of the data.
    
RMANRestore
    How to restore an RMAN backup, taken on one server, to a new database on another server (or a compatible kind) using 11g RMAN. Also details how to identify the files required - given RMAN's interesting naming style! Basically, this is a &how to determine if your backups can be restored* document for DBAs.

RMANCloning
    How to use RMAN to create a new database, or, refresh an existing one, from a staging database.

SOP_DataGuardFailover
    How to use Data Guard to fail, or switch, over between a currently running primary to a standby database.
    
SOP_ServerPatching
    How to patch the various servers running in a Data Guard "cluster" - with minimal down time.
    
RMANCreateStandby
    How to create a standby database from a running primary, without having to shutdown the primary.

Readme
    This document, you are reading it now.
    
Pandoc_reference.docx
    A reference docx file used by pandoc to build Microsoft docx files, with my chosen styles. Mostly! While pandoc does output the correct style information, Word ignores some of it - in-line code and tables, for example.

Listings_setup.tex
    A file of options for the LaTeX listings package. If you use ``--listings`` on the command line to create a PDF file, you should also include the ``-H ..\listings_setup.tex`` to ensure that the required options are used.

Output - Docx
-------------

The pandoc_reference doc contains examples of the styles you wish to use. The following code is *all on one line* ...

..  code-block:: batch

    cd Docs\sources
    
    pandoc --from rst 
           --to docx 
           --output Readme.docx 
           --reference-docx=..\pandoc_reference.docx 
           --table-of-contents 
           --toc-depth=3 
           DocsReadMe.rst

If you don't want to set up a style document, then don't and just leave it off the command line - the defaults are a tad boring though! 

Pandoc can generate a default for you which can be amended to suit your style and subsequently used.


Output - PDF
------------

Colour names are case sensitive! 

See <https://en.wikibooks.org/wiki/LaTeX/Colors#Predefined_colors> for details and note that the colours demonstrated in the nice colourful table are the ones that you can use. Make sure that the colour names are specified in the exact letter case shown in the table. ``Apricot`` will work, ``apricot`` will not. Some colours, ``blue``, ``black`` seem ok, but stick with the table's defined names to avoid problems.

It is accepted standard, that the colour of links, table of contents and URLs should be Gr\ *a*\ y. Or, as people who *can* speak proper English would say, Gr\ *e*\ y - but that gets rejected by the US-centric software. Pah! ;-)

Personally, I prefer Blue. Yah, boo sucks! I also prefer the output when using the *Utopia* font family over the default "Latin Modern". I also use the ``listings`` package when generating PDF files, so there needs to be a setup file used - otherwise I get all the wrong options.

The following code is *all on one line* ...

..  code-block:: batch

    cd Docs\sources
    
    pandoc --from rst 
           --to latex 
           --output Readme.pdf 
           --table-of-contents 
           --toc-depth=3 
           --listings
           --H ..\listings_setup.tex
           --variable fontfamily="Utopia"
           --variable toccolor=Blue 
           --variable linkcolor=Blue 
           --variable urlcolor=Blue 
           --variable margin-top=3cm
           --variable margin-left=3cm
           --variable margin-right=3cm
           --variable margin-bottom=4cm
           DocsReadMe.rst

I *think* PDF output required something like ``pdflatex`` to be installed, and on Windows that's done using MikTeX while on Linux, just install texlive (the full option).


Other Outputs
-------------

Pandoc does other formats for the output files, Epub, HTML etc etc.