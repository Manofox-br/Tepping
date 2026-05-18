@echo off
echo =======================================
echo     Instalador Tepping (Windows)
echo =======================================
echo.
echo [1/3] Preparando a pasta do sistema...

:: Define a pasta de instalacao dentro da pasta do usuario (ex: C:\Users\Joao\.tepping_lang)
set "INSTALL_DIR=%USERPROFILE%\.tepping_lang"

:: Cria a pasta de instalacao se ela nao existir
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo [2/3] Copiando o codigo-fonte...
:: Copia as pastas bin e src (ignora arquivos como .gitignore, readme, etc)
xcopy "%~dp0bin" "%INSTALL_DIR%\bin" /E /I /Y /Q > nul
xcopy "%~dp0src" "%INSTALL_DIR%\src" /E /I /Y /Q > nul

echo [3/3] Criando comando global e configurando o PATH...
:: Cria o comando tepping.cmd que o Windows consegue executar
echo @echo off > "%INSTALL_DIR%\bin\tepping.cmd"
echo ruby "%INSTALL_DIR%\bin\tepping.rb" %%* >> "%INSTALL_DIR%\bin\tepping.cmd"

:: Adiciona a pasta oculta ao PATH do Windows para o comando funcionar em qualquer lugar
setx PATH "%PATH%;%INSTALL_DIR%\bin" > nul

echo.
echo =======================================
echo [OK] Tepping instalada com sucesso!
echo =======================================
echo A linguagem foi copiada para o sistema do seu Windows.
echo Se quiser, voce ja pode apagar a pasta que baixou do GitHub.
echo.
echo [!] IMPORTANTE: Reinicie o seu terminal (CMD/PowerShell) 
echo     para que o comando 'tepping' comece a funcionar.
pause
