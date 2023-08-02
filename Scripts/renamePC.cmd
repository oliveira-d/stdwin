set /p patrimonio="Digite o patrimonio: "
wmic computersystem where name='%computername%' call rename name='%1-%patrimonio%'
