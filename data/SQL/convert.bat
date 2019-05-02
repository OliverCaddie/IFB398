@echo off

for %%f in (".\*") do (
if "%%~nf" NEQ "convert" (
in2csv --date-format "%%d.%%m.%%Y" -e cp1252 "%%~nxf" > "../out/%%~nf.csv"
))
PAUSE