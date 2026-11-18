# MCP do vault do Obsidian (vault.dessa.casa)

Tutorial para usar o vault compartilhado do Obsidian no seu computador:

1. **MCP:** a sua IA (Claude, ChatGPT ou Antigravity) lê e atualiza as notas do vault de qualquer rede.
2. **Obsidian:** uma cópia do vault no seu PC, sempre sincronizada com o servidor (Syncthing), instalada por um instalador de dois cliques.

Este repositório é só um tutorial: os passos e o instalador da pasta `instalador/`.

Se você recebeu este link, diga à sua IA:

> Siga https://github.com/rafaelcruzmartins/mcp-obsidian-servidor e implemente.

---

## Para a IA: leia tudo antes de começar

Você foi chamada para configurar, no computador desta pessoa, o MCP remoto do vault e, se ela quiser, a cópia do vault para o Obsidian. Siga as seções na ordem. Não invente passos que não estão aqui.

Faça as duas partes, a menos que a pessoa diga que quer só uma: primeiro o MCP (passos 1 a 4), depois o [Obsidian no computador](#obsidian-no-computador).

### O que é o servidor

| Item | Valor |
|---|---|
| Nome a usar na configuração | `vault` |
| URL do servidor MCP | `https://vault.dessa.casa` |
| Transporte | Streamable HTTP (MCP remoto) |
| Autenticação | OAuth pelo navegador (Cloudflare Access, com registro dinâmico de cliente). Não há chave, token nem senha para configurar |
| Login | A pessoa digita o e-mail dela numa página da Cloudflare e digita ali o código de 6 dígitos que chega por e-mail. Só e-mails liberados por quem administra o vault recebem o código |
| Duração do login | Não expira na prática. É feito uma vez |
| Ferramentas | Arquivos do vault: listar, ler, buscar, criar, editar e mover notas e pastas. Não há ferramenta de apagar |

Use a URL exatamente como está: `https://vault.dessa.casa`, sem barra e sem `/mcp` no fim. É o endereço que o servidor de login anuncia, e alguns clientes recusam a conexão se a URL for diferente.

### Regras

1. **Nunca peça, leia ou guarde o código de login.** A pessoa digita o código só na página da Cloudflare, no navegador. Se ela colar o código no chat, diga para não fazer isso e siga em frente.
2. **Não crie tokens, chaves nem contas.** Não existe etapa assim neste tutorial.
3. **Antes de editar qualquer arquivo de configuração, faça uma cópia** no mesmo lugar, com `.bak` no fim do nome.
4. **Não apague nem altere outros servidores MCP** que já estejam na configuração. A única exceção é o MCP antigo do vault (passo 2).
5. **Confira o JSON depois de editar** (abrir com um parser, por exemplo `ConvertFrom-Json` no PowerShell). Um JSON quebrado desliga todos os MCPs do aplicativo.
6. **Grave os arquivos em UTF-8 sem BOM.** No Windows PowerShell 5.1, não use `Set-Content`, `Out-File` nem `>`, porque eles gravam com BOM. Use `[System.IO.File]::WriteAllText($caminho, $texto, (New-Object System.Text.UTF8Encoding $false))`, o Bloco de Notas ou o VS Code.
7. **Diga à pessoa o que só ela pode fazer** (clicar em botões do aplicativo, fazer o login no navegador) e espere ela confirmar antes de seguir.
8. **Nunca execute o instalador (`instalar-vault.cmd` ou `instalar-vault.ps1`) você mesma**, nem por PowerShell, nem por qualquer outro meio. Só a pessoa roda, com dois cliques, depois de você explicar o que ele faz e ela concordar. Se ela não pediu a parte do Obsidian, nem baixe.
9. Os passos estão escritos para Windows. Em macOS ou Linux, veja [Outros sistemas](#outros-sistemas) para os caminhos e comandos equivalentes.

### Passo 1. Perguntar em qual aplicativo a pessoa quer o vault

**Sempre pergunte antes de configurar qualquer coisa.** Não conclua pelo aplicativo em que você está rodando: o aplicativo que está seguindo este tutorial (por exemplo, o Claude Code ou um agente de IDE) muitas vezes não é o que a pessoa usa no dia a dia.

Pergunte assim, com as opções:

> Em qual aplicativo você quer usar o vault? Pode ser mais de um.
> 1. Chat do Claude (Claude Desktop ou claude.ai)
> 2. Claude Code (terminal)
> 3. ChatGPT
> 4. Antigravity

Se a pessoa não souber, recomende a opção 1 (chat do Claude) ou o aplicativo de IA que ela mais usa. Configure só o que ela escolher, um de cada vez, e teste cada um (passo 4). Cada aplicativo tem a sua seção:

- Chat do Claude (Desktop ou claude.ai): [Claude Desktop e claude.ai](#claude-desktop-e-claudeai-conector-personalizado)
- Claude Code: [Claude Code](#claude-code)
- ChatGPT: [ChatGPT](#chatgpt)
- Antigravity: [Antigravity](#antigravity)

### Passo 2. Remover o MCP antigo do vault

Antes, o vault era lido por um MCP local, normalmente chamado `obsidian`, que roda `@modelcontextprotocol/server-filesystem` apontando para uma pasta de rede (um caminho que começa com `\\`, terminando em `Obsidian`). Ele não funciona fora do escritório e deve sair.

- Procure nos arquivos de configuração do cliente (os caminhos estão na seção de cada um) uma entrada com `server-filesystem` e um caminho `\\...\Obsidian`.
- Se encontrar: faça o `.bak`, remova só essa entrada e confira o JSON.
- Se não encontrar, siga em frente.
- Se houver uma entrada parecida mas você não tiver certeza de que é o vault antigo, pergunte à pessoa antes de remover.

### Passo 3. Configurar o cliente

Vá para a seção do cliente abaixo.

### Passo 4. Testar

Peça à IA configurada (em uma conversa nova, se for outro aplicativo): **"Usando o MCP vault, liste a pasta raiz do vault."**

- Funcionou se aparecer a lista de pastas e notas do vault.
- Não precisa testar escrita. Não crie notas de teste no vault: ele é compartilhado com outras pessoas.
- Se falhar, veja [Problemas comuns](#problemas-comuns).

Depois, siga para [Obsidian no computador](#obsidian-no-computador), se a pessoa quiser a cópia do vault.

No fim de tudo, diga à pessoa, em poucas linhas, o que foi configurado, onde fica o `.bak` e se o teste passou.

---

## Claude

O Claude tem três lugares possíveis. Os conectores do claude.ai e do Claude Desktop são da conta: adicionar em um aparece no outro.

### Claude Desktop e claude.ai (conector personalizado)

Este é o caminho preferido. A pessoa faz pela interface; você só orienta.

1. Peça à pessoa para abrir **Configurações > Conectores** (Settings > Connectors) e clicar em **Adicionar conector personalizado** (Add custom connector).
2. Nome: `Vault`. URL: `https://vault.dessa.casa`. Não preencha Client ID nem Client Secret (opções avançadas): o registro é automático.
3. Clicar em **Adicionar** e depois em **Conectar** (Connect). Abre o navegador na página da Cloudflare: e-mail, depois o código que chegar por e-mail.
4. Voltar ao Claude. Em uma conversa nova, conferir se o conector `Vault` está ligado no menu de ferramentas da conversa.
5. Testar (passo 4).

Se der erro no **Conectar** (por exemplo "Authorization with the MCP server failed"), use o plano B abaixo, no Claude Desktop.

### Claude Desktop, plano B (ponte mcp-remote)

Use só se o conector personalizado falhar. Aqui você pode fazer quase tudo.

1. Conferir o Node.js: `npx -v`. Se não existir, instalar o Node.js LTS:
   ```powershell
   winget install --id OpenJS.NodeJS.LTS --exact --source winget
   ```
   Depois, abrir um PowerShell novo e conferir de novo com `npx -v`.
2. Pedir à pessoa para fechar o Claude Desktop **pela bandeja do Windows** (clicar com o botão direito no ícone > Sair). Com ele aberto, o arquivo é sobrescrito.
3. Achar o arquivo `claude_desktop_config.json`:
   - instalação normal: `%APPDATA%\Claude\claude_desktop_config.json`;
   - versão da Microsoft Store: procure em `%LOCALAPPDATA%\Packages\` uma pasta que comece com `Claude`, e dentro dela `LocalCache\Roaming\Claude\claude_desktop_config.json`;
   - se não achar, peça à pessoa: no Claude Desktop, **Settings > Developer > Edit Config** abre a pasta certa.
4. Fazer o `.bak`. Se o arquivo não existir, criar com `{ "mcpServers": {} }`.
5. Dentro de `"mcpServers"`, acrescentar (sem mexer nos outros):
   ```json
   "vault": {
     "command": "cmd",
     "args": ["/c", "npx", "-y", "mcp-remote@0.16.6", "https://vault.dessa.casa"]
   }
   ```
   O `cmd /c` é necessário no Windows, porque o `npx` é um `npx.cmd`.
6. Conferir o JSON e gravar em UTF-8 sem BOM.
7. Pedir à pessoa para abrir o Claude Desktop. Na primeira vez abre o navegador para o login (e-mail e código).
8. Testar (passo 4). Se aparecer erro no servidor `vault`, o log fica em `%APPDATA%\Claude\logs\mcp-server-vault.log` (ou na pasta `logs` ao lado do arquivo de configuração).

### Claude Code

1. Rodar no terminal (vale para todos os projetos do usuário):
   ```powershell
   claude mcp add --transport http --scope user vault https://vault.dessa.casa
   ```
   Se já existir um `vault`, conferir com `claude mcp get vault` se a URL é essa. Se não for, remover com `claude mcp remove vault --scope user` e adicionar de novo.
2. O MCP antigo do passo 2, se existir no Claude Code, sai com `claude mcp remove obsidian` (conferir antes com `claude mcp list` e `claude mcp get obsidian` que é o `server-filesystem` da pasta de rede).
3. Pedir à pessoa para abrir uma sessão nova do Claude Code, digitar `/mcp`, escolher `vault` e **Authenticate**. Abre o navegador para o login.
4. Testar (passo 4) na sessão nova.

---

## ChatGPT

O ChatGPT só aceita MCP próprio pelo site (chatgpt.com), não pelo aplicativo de desktop, e só no **modo de desenvolvedor**, disponível em planos pagos (Plus, Pro, Business, Enterprise, Edu). Em contas de empresa, o administrador pode ter desligado essa opção.

Aqui você não tem como fazer nada pela pessoa: oriente o passo a passo. Os nomes dos menus mudam com frequência; se algum não bater, procure o equivalente.

1. Em chatgpt.com: **Configurações > Apps e conectores** (Apps & Connectors) **> Configurações avançadas** e ligar o **Modo de desenvolvedor** (Developer mode).
2. Em **Apps e conectores**, clicar em **Criar** (Create).
3. Preencher:
   - Nome: `Vault`
   - Descrição: `Vault compartilhado do Obsidian`
   - URL do servidor MCP: `https://vault.dessa.casa`
   - Autenticação: **OAuth**. Não preencher Client ID nem Secret.
   - Marcar que confia no aplicativo, se for pedido.
4. Clicar em **Criar**. Abre a página da Cloudflare: e-mail e o código que chegar por e-mail.
5. Em uma conversa nova, ligar o conector `Vault` pelo menu **+** da conversa (em modo de desenvolvedor) e testar (passo 4). O ChatGPT pede confirmação antes de cada escrita: é normal.

Se o modo de desenvolvedor não aparecer, o plano da pessoa não permite ou o administrador desligou. Avise a pessoa; não há outro caminho no ChatGPT.

---

## Antigravity

No Antigravity, use a ponte mcp-remote: é o caminho testado. A conexão direta (`serverUrl`) não foi validada.

1. Conferir o Node.js: `npx -v`. Se não existir, instalar o Node.js LTS (`winget install --id OpenJS.NodeJS.LTS --exact --source winget`) e abrir um PowerShell novo.
2. Achar o arquivo de configuração de MCP, `mcp_config.json`. Ele costuma ficar em `%USERPROFILE%\.gemini\antigravity\mcp_config.json` ou `%USERPROFILE%\.gemini\config\mcp_config.json`. Procure nos dois; se existirem os dois, pergunte à pessoa qual o Antigravity dela usa. Não descreva menus do Antigravity que você não consegue ver.
3. Fazer o `.bak`. Se o arquivo não existir, criar com `{ "mcpServers": {} }`.
4. Dentro de `"mcpServers"`, acrescentar (sem mexer nos outros):
   ```json
   "vault": {
     "command": "cmd",
     "args": ["/c", "npx", "-y", "mcp-remote@0.16.6", "https://vault.dessa.casa"]
   }
   ```
5. Conferir o JSON e gravar em **UTF-8 sem BOM** (com BOM o Antigravity deixa de ler o arquivo inteiro).
6. Ao salvar o arquivo, o Antigravity carrega o `vault` sozinho e o mcp-remote abre o navegador para o login (e-mail e código). Avise a pessoa que essa página vai aparecer. Se não aparecer em cerca de um minuto, peça para ela fechar o Antigravity por completo e abrir de novo.
7. Testar (passo 4).

---

## Obsidian no computador

O instalador baixa o Syncthing oficial (com conferência da soma SHA-256), coloca para abrir com o Windows, desliga o UPnP, cadastra o servidor do vault e cria a pasta do vault já compartilhada com ele. Não pede administrador e pode ser rodado de novo sem problema. Só Windows.

Antes:
- Pergunte se a pessoa quer a cópia do vault no Obsidian deste computador. Só siga se ela disser que sim.
- Se a pessoa já tiver o **vault original** (a pasta de onde o vault foi copiado para o servidor), não use este passo: ela fala com quem mandou o link, porque o caso dela é migração.
- Se ela já tiver o Obsidian aberto em outra cópia do vault (por exemplo, por um caminho de rede `\\...`), ela deve parar de usar essa cópia depois desta parte.

1. Baixe os dois arquivos direto na pasta **Downloads** da pessoa, com o PowerShell (assim o Windows não bloqueia o arquivo baixado). O comando acha a pasta Downloads mesmo se ela tiver sido movida para outro disco:
   ```powershell
   $d = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
   if (-not $d) { $d = Join-Path $env:USERPROFILE 'Downloads' }
   $base = 'https://raw.githubusercontent.com/rafaelcruzmartins/mcp-obsidian-servidor/main/instalador'
   foreach ($f in 'instalar-vault.cmd','instalar-vault.ps1') { Invoke-WebRequest "$base/$f" -OutFile (Join-Path $d $f) -UseBasicParsing }
   Get-ChildItem $d -Filter 'instalar-vault.*'
   ```
   Confira que os dois arquivos existem e não estão vazios. Se já existirem versões antigas deles em Downloads, o comando as substitui (o que é o certo). Não altere o conteúdo deles.
2. Não rode o instalador (regra 8). Diga à pessoa: **"Baixei os dois arquivos na sua pasta Downloads. Dê dois cliques em `instalar-vault.cmd`"** (não no `.ps1`; os dois precisam ficar juntos na mesma pasta). Se quiser, abra a pasta para ela com `explorer.exe $d`. Se o Windows mostrar um aviso de segurança, ela clica em **Executar** (ou **Mais informações > Executar assim mesmo**).
3. Explique o que vai acontecer na janela:
   - os passos de 1 a 5 aparecem em azul e verde;
   - no fim aparece um código amarelo (o código deste PC), que já fica copiado. A pessoa **manda esse código para quem enviou o link do tutorial**, que aceita o PC no servidor;
   - a janela fica esperando a primeira sincronização. Pode fechar: a sincronização continua sozinha.
4. A pasta do vault fica em `Documentos\Vault` (ou em `%USERPROFILE%\Vault`, se Documentos estiver no OneDrive). O caminho aparece no fim da janela.
5. Depois que o PC for aceito e os arquivos chegarem: no Obsidian, **Open folder as vault** (Abrir pasta como cofre) e escolher essa pasta.

Não rode o instalador com parâmetros. As opções `-UsarPastaExistente` e `-SomenteEnviar` são só para a migração do vault original.

Se der erro:
- "a pasta ... já existe e não está vazia": já há uma pasta `Vault` com conteúdo. Pergunte à pessoa o que é; não apague. Ela pode renomear a pasta antiga e rodar de novo.
- "não pode ficar dentro de OneDrive/Dropbox/Google Drive": rodar de novo resolve só se a pasta escolhida for outra; fale com quem mandou o link.
- "o Syncthing não respondeu em 60 segundos": reiniciar o PC e dar dois cliques de novo.

## Outros sistemas

Os passos são os mesmos; mudam só os caminhos e a ponte mcp-remote.

| Item | macOS | Linux |
|---|---|---|
| `claude_desktop_config.json` | `~/Library/Application Support/Claude/claude_desktop_config.json` | (Claude Desktop não tem versão oficial; use claude.ai ou Claude Code) |
| Log do Claude Desktop | `~/Library/Logs/Claude/mcp-server-vault.log` | |
| `mcp_config.json` do Antigravity | `~/.gemini/antigravity/mcp_config.json` ou `~/.gemini/config/mcp_config.json` | o mesmo |
| Login guardado do mcp-remote | `~/.mcp-auth` | `~/.mcp-auth` |
| Instalar Node.js LTS | `brew install node` ou o instalador de https://nodejs.org | o gerenciador de pacotes da distribuição ou https://nodejs.org |

Fora do Windows, a ponte mcp-remote não usa `cmd /c`:

```json
"vault": {
  "command": "npx",
  "args": ["-y", "mcp-remote@0.16.6", "https://vault.dessa.casa"]
}
```

O comando do Claude Code é o mesmo em todos os sistemas. Fora do Windows, a regra do BOM (regra 6) não se aplica, mas grave em UTF-8.

## Problemas comuns

| Sintoma | O que fazer |
|---|---|
| O código não chega no e-mail | O e-mail não está liberado ou foi digitado errado. Conferir a caixa de spam. Se persistir, falar com quem mandou o link deste tutorial |
| Página "Verifying you are human" que não termina | Abrir o login num navegador comum (Chrome, Edge) e tentar de novo. Se persistir, avisar quem mandou o link |
| `401` ou "Authorization failed" no Claude Desktop | Usar o plano B (mcp-remote) |
| `403 forbidden` depois do login | O login passou, mas o servidor recusou. Avisar quem mandou o link (é configuração do servidor, não do computador) |
| Servidor `vault` some ou nenhum MCP carrega | JSON quebrado ou gravado com BOM. Restaurar o `.bak` e refazer com cuidado |
| `npx` não encontrado | Instalar o Node.js LTS e abrir um terminal novo. No Claude Desktop, reiniciar o aplicativo pela bandeja |
| mcp-remote pede login toda hora ou trava | Apagar a pasta `%USERPROFILE%\.mcp-auth` (só guarda o login do mcp-remote) e reabrir o aplicativo |
| Conflito de notas (`Nota.sync-conflict-....md`) | Não é problema do MCP: duas edições na mesma nota ao mesmo tempo. Juntar o conteúdo na nota original e apagar o arquivo de conflito |

Qualquer outra falha: pare, mostre à pessoa a mensagem de erro exata e peça para ela falar com quem mandou o link deste tutorial. Não tente contornar a autenticação.

---

## O que este tutorial não faz

- Não dá acesso a nada além das notas do vault.
- O MCP não sincroniza o Obsidian do computador: isso é a parte [Obsidian no computador](#obsidian-no-computador), pelo Syncthing.
