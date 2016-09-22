@echo off

REM ref. http://mattn.kaoriya.net/software/why-i-use-cmd-on-windows.htm

doskey ls=ls --color=auto --show-control-chars -N $*
doskey grep=grep --color=auto $*
doskey rm=rm -i $*
doskey cp=cp -i $*
doskey mv=mv -i $*
doskey vi=vim $*
doskey find=c:/msys64/usr/bin/find.exe $*
doskey ag=ag --nocolor $*

if "%CMD_INIT_SCRIPT_LOADED%" neq "" goto :eof
set CMD_INIT_SCRIPT_LOADED=1

cls