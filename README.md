Script em batch para padronização de sistemas Windows 11 e 10.

INSTRUÇÕES DE USO: 
1) Instale o Windows com o usuário padrão ("Beep Saude" ou outro) como administrador (único usuário do sistema) - esse deve ser o usuário 
2) Copie a pasta "padronizacao-windows" para o destino C:\
3) Execute o script setup.cmd
4) Caso o script esteja configurado para renomear o computador ele irá reiniciar e, se estiver ligado à tomada, se reexecutar automaticamente em 1 minuto após o login caso a máquina esteja ligada à tomada.
5) Caso ocorra falha na instalação de algum dos aplicativos via winget, um arquivo chamado fix-setup.cmd será criado, podendo ser usado para corrigir ou investigar o problema.
6) Ao terminar a execução do script, verifique se algum dos comandos retornou com erro e ajuste manualmente o restante que for necessário. Um registro de erros é feito no arquivo errorlog.txt

* Dica: para agilizar a instalação do Windows e criação do usuário, utilize o Rufus para a gravação do pendrive e configure as opções desejadas como nome do usuário e configurações de região e idioma.

CONFIGURAÇÃO DO SCRIPT:
- Arquivos de configuração estão localizados na pasta config

Pasta Files:
- Arquivos nessa pasta com extensão .exe ou .msi serão executados automaticamente, mas possivelmente ainda de forma interativa
- Arquivos de atalho com extensão .url são copiados para a área de trabalho e para o menu iniciar
- A imagem que se deseja usar como papel de parede e/ou tela de bloqueio também deve estar nessa pasta