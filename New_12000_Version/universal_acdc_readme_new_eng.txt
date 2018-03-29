-------------------------------------------------- -
----- S. T.A.L.K.E.R. *. Spawn compiler/decompiler-----
-------------------------------------------------- -

Version: 1.34
Date of the latest revisions: 08/09/2013

Summary: This acdc designed to extract and zapakovki all.spawn / level.spawn from
any build, starting from 1265.

The main modes of operation:
-Unpacking original spawn PM, CHN, PZ and builds PM xrCore build since 1265.
-Unpacking spawn of mods (required config folder of fashion)
-Conversion spawn in any other version.
-Massive replacement of game-vertex unpacked spawn.
-Breakdown all.spawn on level.spawn 's and level.game' s
-Comparison unwrapped spawn
-Update vertex coordinates of the objects according to

What you need to run:
-Actually, spawn (all.spawn, level.spawn)
-Game.graph (only if you unpack all.spawn).
If all.spawn from build 3120, ERs or RFP - game.graph not needed (it is sutured to spawn).
-Directory config / configs (if you unpack the mod and universal_acdc complains unknown section)

For correct operation, use a folder stkutils strictly latest version (stkutils_07_08_2013).

Usage:
Put all.spawn (or level.spawn) and game.graph in the program folder, make a batch file (command below)
run a batch file, you rejoice life.

Explanation for the further text: in angle brackets (<>) is set to an option. It is a way to spawn,
folder to unpack, etc., that is what you need to enter. The numbers in square brackets ([])
are optional options. All Options skobochek - are required.

-------------------------------------------------- -
---------------- [Unpacking spawn] -----------------
-------------------------------------------------- -
This mode is designed to unzip the files and all.spawn level.spawn

Team: universal_acdc.pl-d <spawn_file> [common_options]

-D <spawn_file> - the way to spawn.
common_options - general options. Read about them below.

When you unpack the spawn of the mods may receive an error "unknown section".
This means that use non-standard fashion section items / mobs.
To unpack this spawn to use the key-scan, pointing to it as a parameter
the path to the folder config / configs. See an example of a batch file acdc_decompile_scan.

-------------------------------------------------- -
---------------- [Wrapping spawn] ------------------
-------------------------------------------------- -
This mode is designed to pack unwrapped text files spawn in all.spawn or level.spawn

Team: universal_acdc.pl-compile <dir> [-idx <index_file>] [-f <flag1,flag2,...>] [common_options]

-Compile <dir> - folder, which contains the uncompressed spawn. If you work in the current folder, <dir> not necessary.
common_options - general options. Read about them below.
-Idx <index_file> - this script will form a key ltx config with sections of the form:

[13_box_wood_01_0021]; format - "indeks_lokatsii" _ "object_name"
id = 2907; id object
story_id = -1; story_id object

Such records will be created for all objects of the spawn.
If you specify a key-idx without a path to the config, it will appear in the folder universal_acdc (spawn_ids).
Why do it? In the game you will be able to open the file from a script and find the object you want.
If earlier to find the desired object id named obety needed to sort out all of the game,
now it can be done simply by reading the id of the desired section of the config.

Also, there are some additional features:
- When compiling for the correct operation of all sections necessarily affix to spawn
parameters and version script_version. Enough to put them in a section of the reactor, atsdts will continue to use them.
Useful when the spawn "assembly."
- Compile the uniqueness of parameters monitored story_id, so as not to suffer then with departures game.

-------------------------------------------------- -
------------ [Convert spawn] ----------------
-------------------------------------------------- -
Mode allows you to convert spawns PM, CHN, PO together.

Team: universal_acdc.pl-convert <file>-version <new_version> [-ini <file>] [common_options]

-Convert <file> - file you want to convert. You can specify both packed (*. Spawn) spawn
and unpacked (alife_ ***. ltx). Attention! Since the graph and cross-table in the ERs and RFP sewn into the spawn
to convert packed with spawn of PM in these formats you will need to put in a folder with universal_acdc
folder levels of the game. Optionally, copy all the files in the folder is enough to leave with each location
file level.gct.

-Version <new_version> - new version spawn. To pick up the version you will be able to browsing a file spawn_versions.txt

-Ini - file conversion fine-tuning (convert.ini). If not specified, the convert.ini, lying
in the current folder.
common_options - general options. Read about them below.

Also supported by fine-tuning the conversion of a file convert.ini.
The file has two sections: [exclude] and [change]. In the section can be assigned to exclude those sections
to be removed during the conversion of synthetic surfactants. Example:

[Exclude]
sections = m_trader, m_car, flesh_weak

It also supports masking. Instead similar pile sections (stalker_zombied, stalker_sakharov etc.)
You can set the mask using the * symbol. Example: stalker *. Such a record would eliminate all
sections, the title of which is the word stalker.

In the section change the names of the prescribed sections in which you need to change something or add to it.
Example:

[Change]
sections = inventory_box

Next, fill out the file entries for those sections that you have written to change. Example:

[Inventory_box] / / section_name desired section
add: custom_data = PREVED / / add the prefix used for the settings you wish to add
add: game_vertex_id = 10000 / / desired value (if the number - the sum if the string - added to the end)
rep: level_vertex_id = 0 / / rep prefix is ??used for parameters that need to be replaced by something

A common example. The following configuration will cause that all stalkers 500 will be added to the game-and the Vertices
visual changes to the visual warriors in a gas mask:

[Exclude]

[Change]
sections = stalker

[Stalker]
add: game_vertex_id = 500
rep: visual_name = actors / soldier / soldier_antigas.ogf

-------------------------------------------------- -
---------- [Mass replacement vertex] ---------------
-------------------------------------------------- -
When connecting the new locations without having to recompile the graph at the same time there is a need
shift of all game-vertex spawn new locations for a specific value.
This can be done in this mode.

Team: universal_acdc-parse <file>-old <old_gvid0>-new <new_gvid0> [-way] [common_options]

-Parse <file> - name ltx, in which the spawn.
-Old <old_gvid0> - old game_vertex_id initial location.
-New <new_gvid0> - game_vertex_id new starting location.
-Way - handles atkzhe file way_ ***. Ltx to the same location.

Example: universal_acdc-parse alife_l01_escape.ltx-old-new 934 0

-------------------------------------------------- -
------- [Breakdown all.spawn on level.spawn] ----------
-------------------------------------------------- -
Breakdown all.spawn on level.spawn can be useful when editing at the same time
spawn in the sdk and with the help atsdts.

Team: universal_acdc-split <file> [-use_graph] [-way] [common_options]

-Split <file> - spawn-broken. To restore the graph points are needed level.spawn for all locations
are in the graph. They should be placed in a folder levels according to their position in geymdate stalker - by folder,
appropriate locations. Folder levels should be in the folder with universal_acdc (or the path to it, you can specify the - read on).
-Use_graph - game.graph use to restore the graph points. Plus - no need level.spawn, minus -
not restored the names of graph-points (except the graph points transitions).
-Way - also from the spawn generated level.game

-------------------------------------------------- -
----- [Compare files unpacked spawn] -------
-------------------------------------------------- -
In this mode, we compare two text files spawn. The resulting file is generated based on the first file.
All sections that are not in the second file, but there is in the first, removed, and those sections that are in the second,
but not in the first, are transferred to the output file. Parameters sections do not change. Mode allows you to
save time in case it is necessary to combine the two files, and there are sections of sync.
 
Team: universal_acdc-compare <file1,file2> [common_options]

-Compare <file1,file2> - files to compare

-------------------------------------------------- -
------- [Update vertex coordinates] --------
-------------------------------------------------- -
Why do you need if you change au-mesh objects have changed and game_vertex_id level_vertex_id.
This entails the need for repeated removal of these parameters in the game. This mode
automatically update the vertices of all sections spawn.

Team: universal_acdc-update <spawn_name> [common_options]

-Update <spawn_name> - all.spawn, for which it is necessary to update the vertices.

Update mode requires additional configuration. In the folder there is a file with acdc fs_vertex.ltx
In this file, you must include the path to the locations with the updated au-netting. Necessarily
files must be present level.ai, level.gct for all locations of the spawn.
WARNING! For normal working off mode geymgraf must be old, used
before recompiling. After normal working off a spawn mode you can extract with a new
geymgrafom.

-------------------------------------------------- -
------------------ [General Options] ---------------------
-------------------------------------------------- -

-Out <file> - path to the file / folder with the result. Has different meanings for different options:
to decompile, parse - folder with the result
to compile, convert - rezultruyuschy file.
for the split - folder levels, where to save level.spawn.

-Scan <scan_dir> - the path to the folder with configs. Used in the case of the spawn mods.
-G <graph_dir> - the path to the folder with game.graph. No use to compile and parse, and
if you are working with a spawn CHN, RFP, build 3120.
-Level - how to handle spawn level.spawn.
-Af - also unpacked \ spawn places are packed artifacts in anomalies (section2.bin).
-Nofatal - disables crash when a fatal error, replacing it with a warning.
-Sort <type> - includes alife-sorting facilities. Has two states: simple - sorting by name in alphabetical order,
complex - sort first by section_name, then alphabetically by name.

======================================

If universal_acdc generates an error 'unknown clsid ... for section ... ', this means
that in this mode adds new pair of client / server class in class_registrator.script.
In order not to complicate the work with universal_acdc, such couples are not detected automatically.
It is best to report it to me (http://www.amk-team.ru/forum/index.php?showuser=11696),
However, if you know what is inside class_registrator.script, can add
New sets in clsids.ini themselves. Sets are added in this format:

clsid = соответствующий_серверный_класс

Example:
ZS_ELECT = se_zone_anom

======================================

Any option names can be abbreviated. For example, it is not necessary to use-use_graph, the script will understand also-use, and-u.
However, a number of options for reducing their behalf may conflict with each other. -Compile can not be reduced to a-c, as
in this case, the script is not clear what is meant:-compile or-convert. In this case, the shortest name for the compile
be so:-com

======================================

IMPORTANT! When working with SPAWN 25xx builds before each new unpacking MUST be removed
sections.ini configs and scan again.

======================================
History of edits:
1.34:
[!] Fixed update vertices
[+] Add update the distance parameter when updating the vertices
[+] Added control when compiling the uniqueness story_id
1.33:
[!] Fixed spawns unpacking nektoroyh builds
[+] Added update mode vertices
[+] Added "smart" way-analysis of objects on the locations for the mode split
1,322:
[+] Added compare the unpacked files
1,321:
[!] Fixed spawns unpacking RFP
1.32:
[!] Guids.ltx no longer needed without the-idx
[+] Imple-way-sort objects alphabetically
[+] Implemented to determine exact way-section on gvid and prefix
[+] Imple alife-sorting facilities
1.31:
[!] Changed the algorithm scans the config
[!] Changed the priority of requests from clsids.ini, now the data from it override internal tables
[!] Script adapted under the new system debug messages
[I] corrected logic of Service actor in ERs
[+] Added the possibility of making a log file
[+] Added the possibility of making sets in a separate config file
1.30:
[I] is now a new version of the error handler is still processing the spawn of the People's thistle
[I] Fixed problems unpacking level.spawn some builds
1.29:
[I] bug unpacking level.spawn builds
[I] bug unpacking spawn CHN
[I] any minor edits
1.28:
[I] Fixed parser to ignore the key-way in the mode split.
[I] fixed error when compiling scan configs.
[I] Fixed bug in reading some sections of the se-classes.
[I] fix spawn breakdown because of which were generated shifted to the Left spawns the wrong size.
[+] Added control duplicate actor at compile time.

1.27:
[I] parser bug, in some cases, lead to deterioration of logic.
[I] Fixed creation of folders when saving result.
[+] Added reinitializing the parameters section after class change during the conversion. This extends the range
Versions are available for conversion.
[+] Added support for converting masks.
[+] Added the-ini mode conversion

1.26:
[I] corrected unpacking spawn ERs.
[+] Added auto-complete version of the spawn of the first section (if there is no actor in the spawn).
[+] Something else on the little things, I do not remember.

1.25:
[I] not to display an empty parameter spawned_obj unpacking.
[+] Implemented auto-complete version of parameters and script_version at zapakovke spawn with sections of
different versions of the game. Version is taken from the config actor.

1.24:
[I] Fixed unpacking / wrapping spawn build 2571.
[I] Fixed record guids.ltx
[I] minor edits

1.23b:
[+] Removed warning "state data left" when unpacking spawn GFA, packed
previously using acdccop.
[I] fixes split, which could be obtained from the curves level.spawn
[I] altered the logic of packet read / write se_stalker / se_monster
[I] minor changes

1.22b:
[+] Added the key-nofatal

1.21b:
[I] Fixed some typos in the code.
[I] parser now correctly reads the values ??of the comments.

1.2b:
[+] Minor edits to convert.
[+] Added in the modes of compliance clsid -> server class now be edited
in a separate config file (clsids.ini).
[+] Error when meeting a stranger clsid now issued under section unpacking
spawn with clsid, rather than scanning the config as before.

1.1b:
[+] Tested unpacking build-spawn, spawn solved the problem of reverse engineering
 builds 25hh.
[+] Added control of the availability of the version parameter in the sections unpacked spawn.
[I] Fixed an exception file with spawn_id objects when scanning config.

1.0b:
[+] Thoroughly reworked the code of the script is made in separate modules.
[I] fixed all the features do not work.
[+] Increased the speed of the code, reduced memory requirements.
================================================== ==============
Copyrights: acdc for PM - bardak, for RFP - bardak, Kolmogor. Everything else - K.D.
Use the / lay out where and how you want, with the indication of the author.