# CLAUDE.md

Guia para o Claude Code ao trabalhar neste repositório.

## O que é este projeto

Dois scripts PowerShell independentes que otimizam um PC Windows para gravação/produção musical:

- `performance_to_music.ps1` — remove softwares desnecessários (navegadores, Office, drivers/utilitários HP) e protege tudo que for relacionado a música e as pastas pessoais/de projetos do usuário (`-PreservePaths`). Opcionalmente aciona `removeAI.ps1` (via `-DisableWindowsAI`) como etapa final.
- `removeAI.ps1` — script **exclusivo** para desativar/remover recursos de Inteligência Artificial do Windows (Copilot, Recall, componentes de IA, pacotes CBS de IA), usando o [RemoveWindowsAI](https://github.com/zoicware/RemoveWindowsAI) como motor. Pode ser chamado pelo `performance_to_music.ps1` ou executado sozinho.

Não é um projeto com build/testes automatizados — são scripts standalone pensados para rodar localmente no Windows do usuário (`netok`).

## Estrutura

- `performance_to_music.ps1` — script principal de limpeza/otimização (navegadores, Office, HP, proteção de software de música).
- `removeAI.ps1` — script dedicado exclusivamente à desativação/remoção de recursos de IA do Windows.
- `README.md` — documentação em português para o usuário final.
- `.claude/SKILLS.md` — lista das capacidades/heurísticas que os scripts implementam.
- Referências de estilo/estrutura usadas como base (fora deste repo):
  - `/Users/ronin/Documents/Coding/ZOICWARE`
  - `/Users/ronin/Documents/Coding/RemoveWindowsAI`

## Regras invioláveis ao editar o script

1. **Nunca remover ou colocar em risco software/arquivos de música.** A lista `$MusicKeywords` em `performance_to_music.ps1` é a lista de proteção — qualquer programa cujo nome case com essa lista deve ser classificado como protegido, mesmo que também case com uma palavra-chave de remoção (navegador/Office/HP). Em caso de dúvida, adicionar à lista de proteção, não remover.
2. **Nunca tocar em nenhuma das pastas de `-PreservePaths`** (padrão: `C:\Users\netok\Documentos`, `C:\Cakewalk Projects`, `C:\Cakewalk Content`, `C:\Arquivos de Programaa\Ableton`, `C:\Arquivos de Programaa\Cakewalk`). Qualquer varredura de arquivos deve excluir esses caminhos explicitamente via `Test-IsPreserved`.
3. **Sempre exigir confirmação explícita do usuário** antes de desinstalar/desativar qualquer coisa, a menos que `-NonInteractive` seja passado explicitamente — em ambos os scripts. `performance_to_music.ps1` só invoca `removeAI.ps1` atrás de sua própria pergunta (ou de `-DisableWindowsAI` explícito); e `removeAI.ps1`, por sua vez, tem sua própria confirmação antes de chamar o `RemoveWindowsAi.ps1` de fato — não remover essa dupla confirmação.
4. **`-DryRun` nunca deve alterar nada**, mesmo que o usuário confirme — é o modo seguro de conferência, em `performance_to_music.ps1` e em `removeAI.ps1` (nenhum dos dois deve chamar o `RemoveWindowsAi.ps1` real quando `-DryRun` estiver ativo).
5. Manter mensagens de usuário (Write-Host/Write-Log) em português, consistente com o restante dos scripts.
6. **`removeAI.ps1` nunca deve tocar em `$MusicKeywords`/software de música.** Ele é escopado exclusivamente a componentes de IA do Windows (Copilot, Recall, pacotes CBS de IA) via `RemoveWindowsAi.ps1`; não expandir esse script para remover programas de terceiros, nem misturar sua lógica de volta em `performance_to_music.ps1`.

## Convenções de código

- PowerShell 5.1 compatível (os scripts devem funcionar em `powershell.exe`, sem depender de recursos exclusivos do PowerShell 7).
- Auto-elevação para Administrador segue o padrão usado em `RemoveWindowsAi.ps1` (relança o próprio script via `Start-Process -Verb RunAs`) — implementada de forma independente em `performance_to_music.ps1` e em `removeAI.ps1`, já que `removeAI.ps1` também pode ser executado sozinho.
- Log de execução sempre separado em dois arquivos por script, além de exibido no console: `error_log\error_<timestamp>.log` / `error_log\error_removeAI_<timestamp>.log` (somente erros, via `Write-Log -Level Error`) e `success_log\success_<timestamp>.log` / `success_log\success_removeAI_<timestamp>.log` (mensagens informativas/sucesso, via `Write-Log -Level Success` ou o padrão `Info`). Ao adicionar novas mensagens de log, sempre classificar corretamente com `-Level` — falhas e exceções vão para `Error`; o restante vai para o log de sucesso.
- Evitar adicionar dependências externas (módulos, winget, chocolatey) — os scripts devem rodar em uma instalação padrão do Windows usando apenas cmdlets nativos.
- A integração com o RemoveWindowsAI (dentro de `removeAI.ps1`) é a única exceção deliberada: `Get-RemoveWindowsAIScriptPath` tenta um caminho local primeiro (`-RemoveWindowsAIScriptPath` ou pastas vizinhas) e só baixa de `raw.githubusercontent.com/zoicware/RemoveWindowsAI` como último recurso, sempre com `-ErrorAction Stop`/try-catch para falhar de forma silenciosa e logada (não travar o restante do script).
- `performance_to_music.ps1` chama `removeAI.ps1` como script externo (operador `&`, mesma pasta via `$PSScriptRoot`), repassando `-NonInteractive`/`-RemoveWindowsAIScriptPath` — nunca duplicar a lógica de IA de volta em `performance_to_music.ps1`.

## Ao adicionar novas categorias de remoção

Se o usuário pedir para remover uma nova categoria de software (ex.: outro fabricante de driver, outro navegador), siga o padrão existente:
1. Adicionar um array de palavras-chave (ex. `$NovaCategoriaKeywords`).
2. Registrar em `$RemovalKeywordSets` com uma chave descritiva.
3. Confirmar que nenhuma palavra-chave nova colide com `$MusicKeywords` de forma perigosa (ex. não usar termos genéricos demais como `"Audio"` sozinho).

## Ao adicionar novas categorias de proteção

Basta adicionar termos a `$MusicKeywords` (para nomes de programas) e, se relevante, extensões a `$MusicFileExtensions` (para a varredura de arquivos com `-FullScan`).
