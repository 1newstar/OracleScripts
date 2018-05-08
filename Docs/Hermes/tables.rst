===========
Grid Tables
===========

The Fix/Solution
================

Pandoc, as yet, does not support row or column spans in tables. Bummer!


The Problem
===========

There seems to be a problem with ReStructuredText grid tables - I have not tried simple tables as they do not allow row or column spanning - whereby column spans don't span, but the text in the (hopefully) spanned columns is split into columns regardless.

Row spanning causes the text to be converted as a paragraph rather than a table.

Tables with both row and column spanning again convert as text.



..	code-block:: none

	C:\Users\hisg494> pandoc -v
	
	pandoc 2.1
	Compiled with pandoc-types 1.17.3, texmath 0.10.1, skylighting 0.5.1
	Default user data directory: C:\Users\hisg494\AppData\Roaming\pandoc
	Copyright (C) 2006-2018 John MacFarlane
	Web:  http://pandoc.org
	This is free software; see the source for copying conditions.
	There is no warranty, not even for merchantability or fitness
	for a particular purpose.

For all the following, the command line executed was:

..	code-block:: none

	C:\Users\hisg494> pandoc -f rst -t docx -o tables.docx tables.rst
	
Regardless of the output format, docx and/or html, the results are similar - no spanning and/or conversion to text rather than tables.
	


Column Span
===========

When converting to DOCX or HTML format, it seems that column spanning tables *sort of* work - they are converted to a table, but the span isn't converted - it's split into cells instead. Not good.

..	code-block:: none

	+------------+------------+-----------+ 
	| Header 1   | Header 2   | Header 3  | 
	+============+============+===========+ 
	| body row 1 | column 2   | column 3  | 
	+------------+------------+-----------+ 
	| body row 2 | Cells may span columns.| 
	+------------+------------+-----------+ 

Which produces the following table:
	
+------------+------------+-----------+ 
| Header 1   | Header 2   | Header 3  | 
+============+============+===========+ 
| body row 1 | column 2   | column 3  | 
+------------+------------+-----------+ 
| body row 2 | Cells may span columns.| 
+------------+------------+-----------+ 

Row Span
========

When converting to DOCX or HTML format, it seems that row spanning tables just don't work - they are converted to a paragraph instead. Not good. They are not even tables, just text. Sigh!

..	code-block:: none

	+------------+------------+-----------+ 
	| Header 1   | Header 2   | Header 3  | 
	+============+============+===========+ 
	| body row 3 | Cells may  | - Cells   | 
	+------------+ span rows. | - contain | 
	| body row 4 |            | - blocks. | 
	+------------+------------+-----------+

Which produces the following:

+------------+------------+-----------+ 
| Header 1   | Header 2   | Header 3  | 
+============+============+===========+ 
| body row 3 | Cells may  | - Cells   | 
+------------+ span rows. | - contain | 
| body row 4 |            | - blocks. | 
+------------+------------+-----------+
	
Both
====

When tables have both row and column, the row spanning problem takes effect. :-(

..	code-block:: none

	+------------+------------+-----------+ 
	| Header 1   | Header 2   | Header 3  | 
	+============+============+===========+ 
	| body row 1 | column 2   | column 3  | 
	+------------+------------+-----------+ 
	| body row 2 | Cells may span columns.| 
	+------------+------------+-----------+ 
	| body row 3 | Cells may  | - Cells   | 
	+------------+ span rows. | - contain | 
	| body row 4 |            | - blocks. | 
	+------------+------------+-----------+

Which gives a similar result to the above:

+------------+------------+-----------+ 
| Header 1   | Header 2   | Header 3  | 
+============+============+===========+ 
| body row 1 | column 2   | column 3  | 
+------------+------------+-----------+ 
| body row 2 | Cells may span columns.| 
+------------+------------+-----------+ 
| body row 3 | Cells may  | - Cells   | 
+------------+ span rows. | - contain | 
| body row 4 |            | - blocks. | 
+------------+------------+-----------+
