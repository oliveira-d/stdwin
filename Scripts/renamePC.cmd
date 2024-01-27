set /p asset="Enter the asset number: "
wmic computersystem where name='%computername%' call rename name='%1-%asset%'
