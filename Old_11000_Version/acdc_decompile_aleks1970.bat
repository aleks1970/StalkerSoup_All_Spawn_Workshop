@echo off
for %%i in ("%~dp0..") do SET "folder=%%~fi"
::echo. "%~dp0"

set acperl="%folder%\Prerequisite_files\ActivePerl_5_8_8_8\bin\perl.exe"
set acperlname=ActivePerl_5_8_8_8
set acperl64="%folder%\Prerequisite_files\ActivePerl_5_14_2_64-bit\bin\perl.exe"
set acperl64name=ActivePerl_5_16_2_64-bit
::set stperl="%folder%\Prerequisite_files\Strawberry_Perl_5_8_9_4_Portable\perl\bin\perl.exe"

SET path="%~dp0spawns\all.spawn"
SET idx_folder="%~dp0Idx_files"
SET Gpath="%~dp0g_graph"
SET path="%~dp0spawns\all.spawn"
SET new_spawn1="%~dp0new_spawns_1"

SET Gpath="%~dp0g_graph"
echo. %path%
echo. %Gpath%
echo. %acperlname% is default Perl version for unpack/pack!...
pause
cls
goto a
::goto b

:a
del sections.ini
echo. 
echo. Working with %acperlname% Perl version...
%acperl% universal_acdc.pl -decompile %path% -out all_32 -scan config -nofatal sources  -g %Gpath% -log log.txt
::%acperl% universal_acdc.pl -decompile %path% -out all_32_simple -sort simple -scan config -nofatal sources  -g %Gpath% -log sort_log.txt
::%acperl% universal_acdc.pl -decompile %path% -out all_32_complex -sort complex -scan config -nofatal sources  -g %Gpath% -log sort_complex_log.txt
log.txt
pause
Exit /b

:b
del sections.ini
echo. 
echo. Working with %acperl64name% Perl version...
%acperl64% universal_acdc.pl -decompile %path% -out all_64 -scan config/ -nofatal sources -g %Gpath% -log log64.txt
log64.txt
pause
Exit /b




::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::del sections.ini
::echo. Unpacking with: %stperl%
::%stperl% universal_acdc.pl -decompile %path% -out all_3 -scan config/ -nofatal sources -g %Gpath% -log log.txt
::log.txt
::pause


:: -sort complex
:: -Sort simple
