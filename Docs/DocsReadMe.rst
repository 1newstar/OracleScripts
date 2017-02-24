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

00 Using DBCA to Build Initial Databases
    Using Oracle's DBCA to build an initial blank database ready to be upgraded to a full sized UV database.

01 Building UV Databases
    Upgrading a blank DBCA created database with various scripts, to resemble a full sized UV database, ready for importing of the data.
    
9iRestore
    A document that details how to revert an 11g database in the Azure cloud (aka The *Fog*), running on Windows, back to a 9i database running on Solaris, and not in the cloud.
    
BrokenLatex
    Some wise words on making stuff work when converting RST to Latex/pdf.
    
DatabaseHandover
    Handover document for when my contract expires and some other victim has to take on my work.
    
GeneratingEXPParameterFiles
    How to install and use the 9i package that generates the desired ``exp`` parameter files to assist in parallelising the exports from Solaris 9i, and the imports on Azure 11g.
    
MigrationChecklist
    Checklist of the steps required to migrate from Solaris to 11g Windows (in the Fog), or, to refresh an Azure database from a Solaris 9i export.

MigrationPlan
    Detailed description of how to run the 9i Solaris to 11g Windows (in the Fog) migration. Step, by, step!

RMANCloning
    How to use RMAN to create a new database, or, refresh an existing one, from a staging database.

RMANCreateStandby
    How to create a standby database from a running primary, without having to shutdown the primary.

RMANRestore
    How to restore an RMAN backup, taken on one server, to a new database on another server (or a compatible kind) using 11g RMAN. Also details how to identify the files required - given RMAN's interesting naming style! Basically, this is a &how to determine if your backups can be restored* document for DBAs.

SOP_DataGuardFailover
    How to use Data Guard to fail, or switch, over between a currently running primary to a standby database.
    
SOP_ServerPatching
    How to patch the various servers running in a Data Guard "cluster" - with minimal down time.
    
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

**Note**: If you want to use the above named colours, you cannot use the ``--listings`` command line option. You have a choice, one or the other! But, all you have to do is go to <http://latexcolor.com/>, find the colours you need, and add something like the following to the listings_setup.tex file:

..  code-block:: latex

    \definecolor{Cool Grey}{rgb}{0.55,0.57,0.67}
    \definecolor{Blue}{rgb}{0,0,1}
    \definecolor{Lava}{rgb}{0.81,0.06,0.13}
    \definecolor{Ao}{rgb}{0,0.5,0}
    \definecolor{Cobalt}{rgb}{0,0.28,0.67}

Now, you can use any of the above named colours in the listings_setup.tex file, or, on the command line to set link colours etc. Easy!    

It is accepted standard, that the colour of links, table of contents and URLs should be Gr\ **a**\ y. Or, as people who *can* speak proper English would say, Gr\ **e**\ y - but that gets rejected by the US-centric software. Pah! ;-)

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

PDF output requires something like ``pdflatex`` to be installed, and on Windows that's done using ``MikTeX`` while on Linux, just install ``texlive`` (the full option).


Other Outputs
-------------

Pandoc does other formats for the output files, Epub, HTML etc etc.