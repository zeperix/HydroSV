@echo off

set RULE_NAME=AquaHost

rem Delete the rule
netsh advfirewall firewall delete rule name=%RULE_NAME%
