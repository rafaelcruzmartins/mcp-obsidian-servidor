# MCP do vault do Obsidian (vault.dessa.casa)

Tutorial para conectar a IA do seu computador (Claude, ChatGPT ou Antigravity) ao vault compartilhado do Obsidian. Depois disso, a IA lê e atualiza as notas do vault de qualquer rede.

Este repositório é só um tutorial: não tem código para instalar, só os passos.

Se você recebeu este link, diga à sua IA:

> Siga https://github.com/rafaelcruzmartins/mcp-obsidian-servidor e implemente.

---

## Para a IA: leia tudo antes de começar

Você foi chamada para configurar um servidor MCP remoto no computador desta pessoa. Siga as seções na ordem. Não invente passos que não estão aqui.

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
8. Os passos estão escritos para Windows. Em macOS ou Linux, veja [Outros sistemas](#outros-sistemas) para os caminhos e comandos equivalentes.

### Passo 1. Descobrir o cliente

Descubra qual aplicativo vai usar o MCP. Se você está rodando dentro dele, já sabe. Se houver dúvida, pergunte à pessoa. Cada cliente tem a sua seção:

- Claude (claude.ai, Claude Desktop ou Claude Code): [Claude](#claude)
- ChatGPT: [ChatGPT](#chatgpt)
- Antigravity: [Antigravity](#antigravity)

Se a pessoa usa mais de um, configure um de cada vez e teste cada um (passo 4).

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

No fim, diga à pessoa, em poucas linhas, o que foi configurado, onde fica o `.bak` e se o teste passou.

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

1. Achar o arquivo de configuração de MCP:
   - pelo agente: menu **…** > **MCP Servers** > **Manage MCP Servers** > **View raw config**;
   - o arquivo global costuma ser `%USERPROFILE%\.gemini\antigravity\mcp_config.json` ou `%USERPROFILE%\.gemini\config\mcp_config.json`. Use o que o aplicativo abrir.
2. Fazer o `.bak`. Se o arquivo não existir, criar com `{ "mcpServers": {} }`.
3. Dentro de `"mcpServers"`, acrescentar (sem mexer nos outros):
   ```json
   "vault": {
     "serverUrl": "https://vault.dessa.casa"
   }
   ```
4. Conferir o JSON e gravar em **UTF-8 sem BOM** (com BOM o Antigravity deixa de ler o arquivo inteiro).
5. Pedir à pessoa para atualizar a lista de MCP Servers e clicar em **Authenticate** ao lado de `vault`. Abre o navegador para o login. Se no fim a página mostrar um código de autorização, a pessoa cola em **Enter authorization code** no Antigravity e clica em **Submit**.
6. Testar (passo 4).

Se o login do Antigravity não funcionar, use a ponte mcp-remote (precisa do Node.js LTS, ver o plano B do Claude Desktop) trocando o bloco por:

```json
"vault": {
  "command": "cmd",
  "args": ["/c", "npx", "-y", "mcp-remote@0.16.6", "https://vault.dessa.casa"]
}
```

---

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

## O que este MCP não faz

- Não dá acesso a nada além das notas do vault.
- Não sincroniza o Obsidian do computador. A cópia local do vault para o Obsidian é configurada à parte (Syncthing), com quem administra o vault.
