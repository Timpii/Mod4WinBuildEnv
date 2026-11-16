@echo off
rem Delete editor backup files in the current directory - recreated
if exist *.bak del *.bak
if exist *.~* del *.~*
