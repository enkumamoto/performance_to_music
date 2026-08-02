# CLAUDE.md

Guia para o Claude Code ao trabalhar neste repositório.

## O que é este projeto

Um único script PowerShell (`performance_to_music.ps1`) que otimiza um PC Windows para gravação/produção musical, removendo softwares desnecessários (navegadores, Office, drivers/utilitários HP) e protegendo tudo que for relacionado a música e as pastas pessoais/de projetos do usuário (`-PreservePaths`). Opcionalmente, também aciona o [RemoveWindowsAI](https://github.com/zoicware/RemoveWindowsAI) (via `-DisableWindowsAI`) para desativar/remover recursos de Inteligência Artificial do Windows (Copilot, Recall, componentes de IA).

Não é um projeto multi-arquivo nem tem build/testes automatizados — é um script standalone pensado para rodar localmente no Windows do usuário (`netok`).

## Estrutura

- `performance_to_music.ps1` — script principal (único arquivo executável do projeto).
- `README.md` — documentação em português para o usuário final.
- `.claude/SKILLS.md` — lista das capacidades/heurísticas que o script implementa.
- Referências de estilo/estrutura usadas como base (fora deste repo):
  - `/Users/ronin/Documents/Coding/ZOICWARE`
  - `/Users/ronin/Documents/Coding/RemoveWindowsAI`

## Regras invioláveis ao editar o script

1. **Nunca remover ou colocar em risco software/arquivos de música.** A lista `$MusicKeywords` em `performance_to_music.ps1` é a lista de proteção — qualquer programa cujo nome case com essa lista deve ser classificado como protegido, mesmo que também case com uma palavra-chave de remoção (navegador/Office/HP). Em caso de dúvida, adicionar à lista de proteção, não remover.
2. **Nunca tocar em nenhuma das pastas de `-PreservePaths`** (padrão: `C:\Users\netok\Documentos`, `C:\Cakewalk Projects`, `C:\Cakewalk Content`, `C:\Arquivos de Programaa\Ableton`, `C:\Arquivos de Programaa\Cakewalk`). Qualquer varredura de arquivos deve excluir esses caminhos explicitamente via `Test-IsPreserved`.
3. **Sempre exigir confirmação explícita do usuário** antes de desinstalar qualquer coisa, a menos que `-NonInteractive` seja passado explicitamente. Não adicionar caminhos de código que removam programas sem passar pelo bloco de confirmação. Isso vale também para a etapa de IA: `Disable-WindowsAI` só deve ser chamada atrás de sua própria confirmação (pergunta separada) ou de `-DisableWindowsAI` explícito — nunca automaticamente junto do bloco de navegador/Office/HP.
4. **`-DryRun` nunca deve remover nada**, mesmo que o usuário confirme — é o modo seguro de conferência, incluindo a etapa de IA (`Disable-WindowsAI` não deve ser chamada quando `-DryRun` estiver ativo).
5. Manter mensagens de usuário (Write-Host/Write-Log) em português, consistente com o restante do script.
6. **A etapa de IA nunca deve tocar em `$MusicKeywords`/software de música.** O `RemoveWindowsAi.ps1` já é escopado a componentes de IA do Windows (Copilot, Recall, pacotes CBS de IA); não expandir essa integração para remover programas de terceiros sem antes checar contra as listas de proteção deste projeto.

## Convenções de código

- PowerShell 5.1 compatível (o script deve funcionar em `powershell.exe`, não depende de recursos exclusivos do PowerShell 7).
- Auto-elevação para Administrador segue o padrão usado em `RemoveWindowsAi.ps1` (relança o próprio script via `Start-Process -Verb RunAs`).
- Log de execução sempre separado em dois arquivos, além de exibido no console: `error_log\error_<timestamp>.log` (somente erros, via `Write-Log -Level Error`) e `success_log\success_<timestamp>.log` (mensagens informativas/sucesso, via `Write-Log -Level Success` ou o padrão `Info`). Ao adicionar novas mensagens de log, sempre classificar corretamente com `-Level` — falhas de remoção, exceções e "sem string de desinstalação" vão para `Error`; o restante vai para o log de sucesso.
- Evitar adicionar dependências externas (módulos, winget, chocolatey) — o script deve rodar em uma instalação padrão do Windows usando apenas cmdlets nativos.
- A integração com o RemoveWindowsAI é a única exceção deliberada: `Get-RemoveWindowsAIScriptPath` tenta um caminho local primeiro e só baixa de `raw.githubusercontent.com/zoicware/RemoveWindowsAI` como último recurso, sempre com `-ErrorAction Stop`/try-catch para falhar de forma silenciosa e logada (não travar o restante do script).

## Ao adicionar novas categorias de remoção

Se o usuário pedir para remover uma nova categoria de software (ex.: outro fabricante de driver, outro navegador), siga o padrão existente:
1. Adicionar um array de palavras-chave (ex. `$NovaCategoriaKeywords`).
2. Registrar em `$RemovalKeywordSets` com uma chave descritiva.
3. Confirmar que nenhuma palavra-chave nova colide com `$MusicKeywords` de forma perigosa (ex. não usar termos genéricos demais como `"Audio"` sozinho).

## Ao adicionar novas categorias de proteção

Basta adicionar termos a `$MusicKeywords` (para nomes de programas) e, se relevante, extensões a `$MusicFileExtensions` (para a varredura de arquivos com `-FullScan`).
