set nls_date_format=
start "NOFCS import" /d . /high imp sys/ForConfig2lock compile=n parfile=parfiles\imp_rows_nofcs.par
start "FCS1  import" /d . /high imp sys/ForConfig2lock compile=n parfile=parfiles\imp_rows_fcs1.par
start "FCS2D import" /d . /high imp sys/ForConfig2lock compile=n parfile=parfiles\imp_rows_fcs2d.par
start "FCS3  import" /d . /high imp sys/ForConfig2lock compile=n parfile=parfiles\imp_rows_fcs3.par
start "FCS4  import" /d . /high imp sys/ForConfig2lock compile=n parfile=parfiles\imp_rows_fcs4.par
start "FCS5  import" /d . /high imp sys/ForConfig2lock compile=n parfile=parfiles\imp_rows_fcs5.par
start "FCS6  import" /d . /high imp sys/ForConfig2lock compile=n parfile=parfiles\imp_rows_fcs6.par
start "FCS7  import" /d . /high imp sys/ForConfig2lock compile=n parfile=parfiles\imp_rows_fcs7.par
start "FCS8  import" /d . /high imp sys/ForConfig2lock compile=n parfile=parfiles\imp_rows_fcs8.par
rem start "FCS9  import" /d . /high imp sys/ForConfig2lock compile=n parfile=parfiles\imp_rows_fcs9.par