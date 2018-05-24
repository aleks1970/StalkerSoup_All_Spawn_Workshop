@echo off
for %%i in ("%~dp0..") do SET "folder=%%~fi"
::echo. "%~dp0"

set acperl="%folder%\Prerequisite_files\ActivePerl_5_8_8_8\bin\perl.exe"
set acperlname=ActivePerl_5_8_8_8
set acperl64="%folder%\Prerequisite_files\ActivePerl_5_14_2_64-bit\bin\perl.exe"
set acperl64name=ActivePerl_5_16_2_64-bit
::set stperl="%folder%\Prerequisite_files\Strawberry_Perl_5_8_9_4_Portable\perl\bin\perl.exe"

SET Gpath="%~dp0g_graph"
SET path="%~dp0spawns\all.spawn"
SET new_spawn1="%~dp0New_All_Spawn_Test"

SET path="%~dp0spawns\all.spawn"
SET new_spawn64="%~dp0New_All_Spawn_Test"
SET idx_folder="%~dp0Idx_files"
SET compilef_1="%~dp0all_32"
SET compilef_64="%~dp0all_64"
SET Gpath="%~dp0g_graph"

echo. %path%
echo. %Gpath%
echo. %idx_folder%
echo. %new_spawn%
echo. %compilef_1%

pause
cls
::goto a
goto b

:a
echo. 
echo. Working with %acperlname% Perl version...
%acperl% universal_acdc.pl -compile %compilef_1% -out %new_spawn1%\all.spawn -Idx %idx_folder%\index_file_1  -g %Gpath% -scan "config" -log compile_log.txt
:: -log log.txt
:: -scan "config"
Exit /b

:b
del sections.ini
echo. 
echo. Working with %acperl64name% Perl version...
%acperl64% universal_acdc.pl -compile %compilef_64% -out %new_spawn1%\64all.spawn -Idx %idx_folder%\index_file_1  -g %Gpath% -scan "config" -log compile_log64.txt
Exit /b


::perl universal_acdc.pl -compile sources -out new.spawn -g ".." -log log.txt -scan "../config"
::pause