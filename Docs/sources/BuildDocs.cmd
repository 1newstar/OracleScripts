rem =================================================================
rem Build some docs. Translates an RST into DOCX and PDF.
rem =================================================================
rem pass the root of the document on the command line.
rem
rem     buildDocs fred
rem
rem Takes 'fred.rst' and creates 'fred.docx' as well as 'fred.pdf'.
rem
rem Norman Dunbar
rem 23 March 2017.
rem =================================================================

set document=%1
if "%document%" equ "" (
    echo No document name supplied.
    exit/b 1
)

rem Build a docx file.
pandoc -f rst -t docx -o %document%.docx --reference-docx=..\pandoc_reference.docx --toc --toc-depth=3 %document%.rst 
 
rem Build a pdf file. 
pandoc -f rst -t latex -o %document%.pdf --toc --toc-depth=3 %document%.rst --variable fontfamily="utopia" --listings -H ..\listings_setup.tex --variable toccolor="Cobalt" --variable linkcolor="Cobalt" --variable urlcolor="Cobalt" --variable margin-top=2.5cm --variable margin-left=2.5cm --variable margin-right=2.5cm --variable margin-bottom=3.5cm
 
