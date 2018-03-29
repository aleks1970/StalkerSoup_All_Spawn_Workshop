@echo off
for %%i in ("%~dp0..") do SET "folder=%%~fi"
::for %%j in ("%~dp0") do SET "foldergraph=%%~fj"
::echo. "%~dp0"


set acperl="%folder%\Prerequisite_files\ActivePerl_5_8_8_8\bin\perl.exe"
set acperlname=ActivePerl_5_8_8_8
set acperl64="%folder%\Prerequisite_files\ActivePerl_5_14_2_64-bit\bin\perl.exe"
set acperl64name=ActivePerl_5_16_2_64-bit
::set stperl="%folder%\Prerequisite_files\Strawberry_Perl_5_8_9_4_Portable\perl\bin\perl.exe"

SET path="%~dp0spawns\all.spawn"
SET idx_folder="%~dp0Idx_files"
SET Gpath="%~dp0g_graph"
::SET Gpath="%foldergraph%g_graph\game.graph"
echo. %path%
echo. %folder%
echo. %acperl%
echo. %acperl64%

pause
cls
goto a
::goto b

:a
echo. 
echo. Working with %acperlname% Perl version...
%acperl% universal_acdc.pl -split %path% -Use_graph %Gpath%\game.graph -out splited_levels -use -way -nofatal -log Log_split.txt
Exit /b

:b
echo. 
echo. Working with %acperl64name% Perl version...
%acperl64% universal_acdc.pl -split %path% -Use_graph %Gpath%\game.graph -out splited_levels64 -use -way -nofatal -log Log_split64.txt
Exit /b


::%stperl% universal_acdc.pl -split %path% -Use_graph %Gpath%\game.graph -out splited_levels -use -way -nofatal -log Log_split.txt
::pause