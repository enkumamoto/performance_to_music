# 🎵 Performance to Music

> Script PowerShell para preparar um PC Windows para **gravação e produção musical**, liberando recursos do sistema ao remover softwares que não são necessários para essa finalidade (navegadores, Office, utilitários de impressora HP) — enquanto **protege** todo o software e arquivos de áudio/música e as pastas pessoais e de projetos do usuário.

<p align="left">
  <img alt="PowerShell" src="https://img.shields.io/badge/PowerShell-5391FE?style=flat&logo=powershell&logoColor=white">
  <img alt="Windows" src="https://img.shields.io/badge/Windows-0078D6?style=flat&logo=windows&logoColor=white">
  <img alt="Requer Administrador" src="https://img.shields.io/badge/Requer-Administrador-critical?style=flat">
</p>

---

## 📑 Sumário

- [O que o script faz](#-o-que-o-script-faz)
- [Como usar](#-como-usar)
  - [Opções](#opções)
  - [Exemplos](#exemplos)
- [Estrutura interna do script](#-estrutura-interna-do-script)
- [removeAI.ps1 — Desativação de IA do Windows](#-removeaips1--desativação-de-ia-do-windows)
- [Referências / inspiração](#-referências--inspiração)
- [Aviso](#-aviso)

---

## ⚙️ O que o script faz

1. **Lê todos os programas instalados** (registro do Windows + pacotes AppX).

2. **Classifica** cada programa em:

   - 🟢 **Protegido** — qualquer software relacionado a música (VST, VST2, VST3, IK Multimedia, iZotope, LANDR, Native Instruments, Neural DSP / Neural Amp Modeler, Steinberg, Ableton, FL Studio, Waves, etc.). Esses itens **nunca** são removidos.
   - 🔴 **Remover** — navegadores (incluindo Microsoft Edge), pacotes do Microsoft Office e software de impressoras HP.

3. **Preserva integralmente** as pastas abaixo — nada dentro delas é tocado, independente do que for encontrado:

   ```text
   C:\Users\<user_name>\Documentos
   C:\Cakewalk Projects
   C:\Cakewalk Content
   C:\Arquivos de Programas\Ableton
   C:\Arquivos de Programas\Cakewalk
   ```

   > 💡 **Observação:** caso outras pastas precisem ser preservadas, deve-se adicioná-las ao código.

4. **Mostra um relatório completo** de tudo que será removido e **pede confirmação explícita** antes de desinstalar qualquer coisa.

5. **Pergunta separadamente** se o usuário também quer rodar a etapa de desativação de Inteligência Artificial do Windows, delegada ao script dedicado [`removeAI.ps1`](#-removeaips1--desativação-de-ia-do-windows) (ver seção própria abaixo). Essa etapa é **opcional** e só roda com confirmação própria (ou com a flag `-DisableWindowsAI`).

6. **Registra tudo em dois arquivos de log** separados, na pasta do script:

   | Arquivo | Conteúdo |
   | ------- | -------- |
   | `error_log\error_AAAAMMDD_HHmmss.log`     | Exclusivamente erros/falhas. |
   | `success_log\success_AAAAMMDD_HHmmss.log` | Mensagens informativas e de sucesso. |

---

## 🚀 Como usar

Abra o PowerShell **como Administrador** (o script se eleva sozinho se necessário) e execute:

```powershell
.\performance_to_music.ps1
```

O script vai:

1. Escanear programas instalados.
2. Mostrar a lista do que será protegido e do que será removido.
3. Perguntar `Confirma a remoção de TODOS os itens listados acima em [REMOVER]? (sim/nao)`.
4. Só remover algo se a resposta for `sim`.
5. Depois, perguntar separadamente se deseja também desativar os recursos de Inteligência Artificial do Windows.

### Opções

| Parâmetro | Descrição |
| --------- | --------- |
| `-DryRun` | Mostra o relatório completo, mas **nunca remove nada** — útil para conferir antes de rodar de verdade. |
| `-FullScan` | Além dos programas instalados, varre todo o disco procurando arquivos de projeto/plugins de música (`.als`, `.flp`, `.rpp`, `.vst3`, etc.) para incluir no relatório de itens protegidos. Pode demorar bastante em discos grandes. |
| `-PreservePaths` | Lista de caminhos a serem preservados integralmente. Padrão: `C:\Users\netok\Documentos`, `C:\Cakewalk Projects`, `C:\Cakewalk Content`, `C:\Arquivos de Programas\Ableton`, `C:\Arquivos de Programas\Cakewalk`. |
| `-NonInteractive` | Pula as perguntas de confirmação e remove direto (uso avançado, ex.: automações). **Use com cuidado.** |
| `-DisableWindowsAI` | Aciona o script dedicado `removeAI.ps1` para desativar/remover os recursos de IA do Windows. Em modo interativo, `removeAI.ps1` confirma antes de executar; em `-NonInteractive`, executa direto se esta flag estiver presente. |
| `-RemoveWindowsAIScriptPath` | Repassado para `removeAI.ps1`: caminho local para `RemoveWindowsAi.ps1`, caso já tenha o repositório [RemoveWindowsAI](https://github.com/zoicware/RemoveWindowsAI) clonado. Se omitido, `removeAI.ps1` procura em pastas vizinhas e, não encontrando, baixa a versão oficial do GitHub para uma pasta temporária. |

### Exemplos

```powershell
# Só ver o que seria removido, sem remover nada
.\performance_to_music.ps1 -DryRun

# Varredura completa do disco incluída no relatório
.\performance_to_music.ps1 -FullScan

# Preservar pastas diferentes das padrão
.\performance_to_music.ps1 -PreservePaths "D:\Projetos","D:\Samples"

# Também rodar a etapa de IA do Windows (removeAI.ps1), sem perguntar de novo
.\performance_to_music.ps1 -NonInteractive -DisableWindowsAI

# Usar uma cópia local do RemoveWindowsAI em vez de baixar do GitHub
.\performance_to_music.ps1 -DisableWindowsAI -RemoveWindowsAIScriptPath "C:\Coding\RemoveWindowsAI\RemoveWindowsAi.ps1"
```

---

## 🧩 Estrutura interna do script

O código não contém comentários explicativos — toda a documentação de cada bloco fica aqui.

1. **Parâmetros** (`param(...)`) — `-PreservePaths`, `-FullScan`, `-DryRun`, `-NonInteractive`, `-ScanRoots`, `-DisableWindowsAI`, `-RemoveWindowsAIScriptPath`.

2. **Elevação** — verifica se está rodando como Administrador; se não, relança o próprio script via `Start-Process -Verb RunAs` repassando os mesmos parâmetros.

3. **Log** — `Write-Log` grava cada mensagem no console (colorida) e, conforme o parâmetro `-Level`, em um dos dois arquivos: `error_log\error_<timestamp>.log` (Level `Error`) ou `success_log\success_<timestamp>.log` (Level `Info`/`Success`, o padrão). As pastas `error_log` e `success_log` são criadas automaticamente dentro do diretório onde o script está.

4. **Listas de referência:**

   - `$MusicKeywords` — termos que classificam um programa como software de música e o protegem de remoção, mesmo que também case com uma palavra-chave de remoção.
   - `$MusicFileExtensions` — extensões de projeto/plugin usadas apenas na varredura de arquivos (`-FullScan`), para relatório informativo.
   - `$BrowserKeywords`, `$OfficeKeywords`, `$HPKeywords` — reunidos em `$RemovalKeywordSets`, definem o que é candidato a remoção (navegadores incluindo Edge, Office, software de impressoras HP).

5. **Helpers** — `Test-MatchesAny` (compara um nome contra uma lista de palavras-chave) e `Test-IsPreserved` (verifica se um caminho está dentro de qualquer pasta listada em `-PreservePaths`, usado para nunca varrer/remover nada dentro delas).

6. **Levantamento de programas instalados** — `Get-InstalledPrograms` lê as três chaves de desinstalação do registro (`HKLM` 64-bit, `HKLM\WOW6432Node`, `HKCU`).

7. **Classificação** — cada programa e cada pacote AppX (`Get-AppxPackage -AllUsers`, cobre casos como Office/HP Smart/Edge distribuídos via Store) é testado primeiro contra `$MusicKeywords` (se casar, vai para `$protectedPrograms` e nunca é tocado); senão, testado contra `$RemovalKeywordSets` (se casar, vai para `$removalCandidates`/`$removalAppx`).

8. **Varredura de arquivos** (`-FullScan`) — percorre todas as unidades de disco fixas procurando `$MusicFileExtensions`, excluindo pastas de sistema (`Windows`, `$Recycle.Bin`, etc.) e qualquer caminho dentro de `-PreservePaths`; resultado é apenas informativo no relatório.

9. **Relatório** — imprime no console as seções `[PROTEGIDO]` (pastas preservadas, programas de música, arquivos encontrados) e `[REMOVER]` (programas e pacotes AppX candidatos), e grava cada candidato no log.

10. **Confirmação** — se `-DryRun`, nunca remove; se `-NonInteractive`, remove sem perguntar; caso contrário, pergunta `sim/nao` e só prossegue com `sim`.

11. **Remoção** — `Uninstall-Program` trata o Microsoft Edge como caso especial (uninstall padrão costuma estar bloqueado, por isso usa `setup.exe --uninstall --system-level --force-uninstall`); para os demais, usa `QuietUninstallString`/`UninstallString`, preferindo `msiexec /x <ProductCode> /qn` quando detecta um GUID, senão anexa flags silenciosas comuns (`/S /silent /quiet /norestart`). Pacotes AppX são removidos via `Remove-AppxPackage -AllUsers`. Cada resultado (sucesso ou falha) é gravado no log correspondente via `Write-Log -Level Success` / `Write-Log -Level Error`.

12. **Etapa de IA do Windows** (opcional) — se confirmada (ou com `-DisableWindowsAI`), chama `removeAI.ps1` (na mesma pasta) como script externo, repassando `-NonInteractive` e `-RemoveWindowsAIScriptPath` quando aplicável. Ver seção dedicada abaixo.

---

## 🤖 removeAI.ps1 — Desativação de IA do Windows

Script **independente**, dedicado exclusivamente a desativar/remover recursos de Inteligência Artificial do Windows (Copilot, Recall, componentes de IA, pacotes CBS de IA, políticas relacionadas), usando como motor o projeto [RemoveWindowsAI](https://github.com/zoicware/RemoveWindowsAI).

Pode ser chamado automaticamente pelo `performance_to_music.ps1` (via `-DisableWindowsAI`) ou executado sozinho:

```powershell
.\removeAI.ps1
```

O script vai:
1. Mostrar a lista de recursos de IA que serão desativados/removidos, com descrição de cada categoria.
2. Perguntar `Confirma a desativacao/remocao de TODOS os itens de IA listados acima? (sim/nao)`.
3. Só executar se a resposta for `sim`.
4. Localizar (ou baixar) `RemoveWindowsAi.ps1` e executá-lo com as categorias escolhidas.

### Opções

| Parâmetro | Descrição |
| --------- | --------- |
| `-Options` | Lista de categorias a aplicar (mesmos valores aceitos pelo `RemoveWindowsAi.ps1`: `DisableRegKeys`, `PreventAIPackageReinstall`, `DisableCopilotPolicies`, `RemoveAppxPackages`, `RemoveRecallFeature`, `RemoveCBSPackages`, `RemoveAIFiles`, `HideAIComponents`, `DisableRewrite`, `RemoveWindowsAITasks`, `UpdateCleanupCheck`). Se omitido, aplica **todas**. |
| `-DryRun` | Mostra a lista de recursos que seriam desativados, mas **nunca altera nada**. |
| `-NonInteractive` | Pula a pergunta de confirmação e executa direto (uso avançado). |
| `-RemoveWindowsAIScriptPath` | Caminho local para `RemoveWindowsAi.ps1`, caso já tenha o repositório [RemoveWindowsAI](https://github.com/zoicware/RemoveWindowsAI) clonado. Se omitido, o script procura em `.\RemoveWindowsAI\RemoveWindowsAi.ps1` e `..\RemoveWindowsAI\RemoveWindowsAi.ps1` e, não encontrando, baixa a versão oficial do GitHub para uma pasta temporária. |

### Exemplos

```powershell
# Ver o que seria desativado, sem alterar nada
.\removeAI.ps1 -DryRun

# Aplicar apenas a remoção do Recall e dos pacotes AppX de IA
.\removeAI.ps1 -Options RemoveRecallFeature,RemoveAppxPackages

# Rodar tudo sem perguntar, usando uma cópia local do RemoveWindowsAI
.\removeAI.ps1 -NonInteractive -RemoveWindowsAIScriptPath "C:\Coding\RemoveWindowsAI\RemoveWindowsAi.ps1"
```

Assim como `performance_to_music.ps1`, gera seus próprios logs em `error_log\error_removeAI_<timestamp>.log` e `success_log\success_removeAI_<timestamp>.log`.

---

## 📚 Referências / inspiração

Este script segue convenções de estrutura e estilo dos projetos:

- [ZOICWARE](https://github.com/zoicware/ZOICWARE)
- [RemoveWindowsAI](https://github.com/zoicware/RemoveWindowsAI)

---

## ⚠️ Aviso

> Desinstalar programas é uma ação com **efeito real no sistema**. Revise sempre o relatório antes de confirmar.
>
> Recomenda-se rodar primeiro com `-DryRun` para conferir a lista de remoção antes de executar de verdade.
