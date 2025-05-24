@echo off

rem Stop and delete the legacy SunshineSvc service
net stop sunshinesvc
sc delete sunshinesvc

rem Stop and delete the new AquaHostService service
net stop AquaHostService
sc delete AquaHostService
