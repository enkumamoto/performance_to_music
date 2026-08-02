# SKILLS.md

Capacidades e heurísticas implementadas por `performance_to_music.ps1`.

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

## 9. Desativação de recursos de Inteligência Artificial do Windows (opcional)

- Pergunta específica e separada da remoção de navegadores/Office/HP: `Deseja tambem desativar os recursos de Inteligencia Artificial do Windows agora? (sim/nao)`. Também pode ser ativada direto com `-DisableWindowsAI` (funciona em modo `-NonInteractive`).
- `Get-RemoveWindowsAIScriptPath` localiza o `RemoveWindowsAi.ps1`: primeiro em `-RemoveWindowsAIScriptPath`, depois em pastas vizinhas (`.\RemoveWindowsAI\RemoveWindowsAi.ps1`, `..\RemoveWindowsAI\RemoveWindowsAi.ps1`), e por último baixa a versão oficial de `github.com/zoicware/RemoveWindowsAI` para uma pasta temporária.
- `Disable-WindowsAI` executa esse script com `-nonInteractive -AllOptions`, cobrindo: chaves de registro de IA, políticas do Copilot, pacotes AppX de IA, recurso opcional Recall, pacotes CBS de IA, arquivos de IA, componentes ocultos de IA, reescrita de texto (Rewrite) e tarefas agendadas de IA.
- Nunca roda em `-DryRun`. Falhas ao localizar/baixar/executar o script são registradas como erro (`error_log`), sem interromper o restante do processo.
- Essa etapa não interage com `$MusicKeywords` nem com as pastas de `-PreservePaths` — ela é escopada exclusivamente a componentes de IA do próprio Windows, não a software de terceiros.
