# SKILLS.md

Capacidades e heurísticas implementadas pelos scripts deste repositório: `performance_to_music.ps1` (limpeza/otimização) e `removeAI.ps1` (desativação de IA do Windows, seções 9-11).

## 1. Descoberta de programas instalados

- Lê o registro do Windows nas três chaves de desinstalação padrão (`HKLM` 64-bit, `HKLM` WOW6432Node 32-bit e `HKCU`).
- Lê também pacotes AppX instalados (`Get-AppxPackage -AllUsers`), cobrindo casos como Office/HP Smart/Edge distribuídos via Microsoft Store.

## 2. Proteção de software musical

- Compara o nome de cada programa/pacote contra `$MusicKeywords`, uma lista com marcas e termos: VST/VST2/VST3/AAX/AU, IK Multimedia, iZotope, LANDR, Native Instruments, Neural DSP / Neural Amp Modeler, Steinberg/Cubase, Ableton, FL Studio, Studio One, Reaper, Pro Tools, Waves, Melodyne, Arturia, Universal Audio, Focusrite, ASIO, Slate Digital, Toontrack, Spitfire Audio, FabFilter, entre outros.
- Qualquer item que case com essa lista é marcado como **protegido** e excluído de qualquer remoção, mesmo que também case com uma palavra-chave de remoção.

## 3. Proteção de arquivos e projetos musicais (varredura completa, `-FullScan`)

- Ao usar `-FullScan`, varre todas as unidades de disco fixas em busca de extensões associadas a projetos e plugins de áudio: `.als`, `.flp`, `.cpr`, `.rpp`, `.ptx`, `.vst`, `.vst3`, `.nki`, `.fxp`, etc.
- Esses arquivos entram apenas no relatório informativo — o script não deleta arquivos soltos, só reporta a presença deles como contexto de proteção.

## 4. Preservação de pastas pessoais e de projetos

- As pastas listadas em `-PreservePaths` são tratadas como zona segura: qualquer caminho de arquivo dentro delas é ignorado em varreduras e nunca é candidato a remoção.
- Padrão:
  - `C:\Users\netok\Documentos`
  - `C:\Cakewalk Projects`
  - `C:\Cakewalk Content`
  - `C:\Arquivos de Programaa\Ableton`
  - `C:\Arquivos de Programaa\Cakewalk`

## 5. Identificação de itens a remover

- **Navegadores**: Microsoft Edge, Google Chrome, Mozilla Firefox, Opera/Opera GX, Brave, Vivaldi, Internet Explorer.
- **Office**: Microsoft Office, Microsoft 365, Outlook, Access, Publisher, OneNote.
- **Impressoras HP**: HP Smart, HP Support Assistant, drivers e utilitários HP Officejet/LaserJet/DeskJet/ENVY, HP Print/Scan.

## 6. Confirmação explícita antes de remover

- Antes de qualquer desinstalação, o script imprime um relatório dividido em `[PROTEGIDO]` e `[REMOVER]` e pergunta ao usuário se ele concorda com a lista completa.
- Sem confirmação (`sim`), nada é removido. `-DryRun` nunca remove, mesmo com confirmação. `-NonInteractive` pula a pergunta (uso avançado).

## 7. Remoção

- Programas comuns: usa `QuietUninstallString`/`UninstallString` do registro, tentando primeiro `msiexec /x <ProductCode> /qn` quando aplicável, senão flags silenciosas comuns (`/S /silent /quiet /norestart`).
- Microsoft Edge: tratado como caso especial, usando `setup.exe --uninstall --system-level --force-uninstall`, já que o Edge normalmente bloqueia desinstalação padrão.
- Pacotes AppX: removidos via `Remove-AppxPackage -AllUsers`.

## 8. Logging separado por tipo

- Toda ação (candidatos encontrados, confirmação, sucesso/erro de cada remoção) é exibida no console com cores (verde = protegido/sucesso, vermelho = remoção/erro, amarelo = avisos) e também gravada em arquivo, em duas pastas criadas automaticamente na pasta do script:
  - `error_log\error_<timestamp>.log` — exclusivamente mensagens de erro/falha (`Write-Log -Level Error`).
  - `success_log\success_<timestamp>.log` — mensagens informativas e de sucesso (`Write-Log -Level Success`/`Info`, padrão).

## 9. Acionamento opcional do removeAI.ps1 (a partir de performance_to_music.ps1)

- Pergunta específica e separada da remoção de navegadores/Office/HP: `Deseja rodar agora a etapa de desativacao de IA do Windows (removeAI.ps1)? (sim/nao)`. Também pode ser ativada direto com `-DisableWindowsAI` (funciona em modo `-NonInteractive`).
- Se confirmado, `performance_to_music.ps1` localiza `removeAI.ps1` na mesma pasta (`$PSScriptRoot`) e o executa via operador `&`, repassando `-NonInteractive` e `-RemoveWindowsAIScriptPath` quando aplicável.
- Nunca aciona `removeAI.ps1` em `-DryRun`. Se `removeAI.ps1` não for encontrado na pasta, registra erro (`error_log`) e segue sem interromper o restante do processo.

## 10. removeAI.ps1 — script dedicado à desativação de IA do Windows

- Script **independente**: tem seu próprio bloco de elevação para Administrador, seus próprios logs (`error_log\error_removeAI_<timestamp>.log`, `success_log\success_removeAI_<timestamp>.log`) e sua própria confirmação — pode ser executado sozinho (`.\removeAI.ps1`) ou chamado pelo `performance_to_music.ps1`.
- `-Options` permite escolher um subconjunto das categorias do `RemoveWindowsAi.ps1` (`DisableRegKeys`, `PreventAIPackageReinstall`, `DisableCopilotPolicies`, `RemoveAppxPackages`, `RemoveRecallFeature`, `RemoveCBSPackages`, `RemoveAIFiles`, `HideAIComponents`, `DisableRewrite`, `RemoveWindowsAITasks`, `UpdateCleanupCheck`); sem o parâmetro, aplica todas.
- Antes de executar, imprime a lista de categorias com descrição e pergunta `Confirma a desativacao/remocao de TODOS os itens de IA listados acima? (sim/nao)`. `-DryRun` nunca executa; `-NonInteractive` pula a pergunta.
- `Get-RemoveWindowsAIScriptPath` localiza o `RemoveWindowsAi.ps1`: primeiro em `-RemoveWindowsAIScriptPath`, depois em pastas vizinhas (`.\RemoveWindowsAI\RemoveWindowsAi.ps1`, `..\RemoveWindowsAI\RemoveWindowsAi.ps1`), e por último baixa a versão oficial de `github.com/zoicware/RemoveWindowsAI` para uma pasta temporária.
- Executa esse script com `-nonInteractive -Options <categorias escolhidas>`, cobrindo: chaves de registro de IA, políticas do Copilot, pacotes AppX de IA, recurso opcional Recall, pacotes CBS de IA, arquivos de IA, componentes ocultos de IA, reescrita de texto (Rewrite) e tarefas agendadas de IA.

## 11. Escopo isolado do removeAI.ps1

- `removeAI.ps1` não interage com `$MusicKeywords` nem com as pastas de `-PreservePaths` — ele é escopado exclusivamente a componentes de IA do próprio Windows, não a software de terceiros, e não tem conhecimento das listas de proteção de `performance_to_music.ps1`.

## 12. Lançadores .cmd (contorno da política de execução do PowerShell)

- `performance_to_music.cmd` e `removeAI.cmd` resolvem o erro comum `... não pode ser carregado porque a execução de scripts foi desabilitada neste sistema` sem exigir que o usuário rode comandos manualmente.
- Cada `.cmd` tenta primeiro `powershell -ExecutionPolicy Bypass -File <script>.ps1`; se o `errorlevel` indicar falha, aplica `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force` e tenta novamente sem o bypass.
- Essa lógica só pode existir fora do `.ps1`, porque a política de execução bloqueia o carregamento do arquivo antes de qualquer linha dele rodar.
