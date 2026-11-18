# Guia de estudo do OrbittTask

Este guia explica como as partes do OrbittTask se conectam e sugere uma ordem para estudar o código. A ideia é ajudar você a entender o funcionamento do projeto, não apenas copiar os comandos para executá-lo.

## 1. O que o projeto faz

O OrbittTask é um sistema de gerenciamento de projetos para pequenas equipes. Usuários podem criar uma conta, organizar projetos e atividades, convidar membros por código e conversar em canais do projeto.

As tecnologias principais são:

- **HTML e CSS** para as páginas e o visual.
- **JavaScript no navegador** para interações e chamadas à API.
- **Node.js e Express** para o servidor e a API HTTP.
- **Microsoft SQL Server** para guardar contas, sessões e dados dos projetos.
- **bcryptjs** para armazenar senhas como hashes, em vez de texto puro.

## 2. Como as partes conversam

```text
Navegador
  ├─ HTML e CSS: mostra as páginas
  └─ JavaScript: envia e recebe JSON
             │ HTTP
             ▼
Servidor Node.js / Express
  ├─ valida dados e permissões
  ├─ aplica autenticação e regras de negócio
  └─ consulta ou altera dados
             │ driver mssql
             ▼
Microsoft SQL Server
```

Por exemplo, ao criar uma atividade, o JavaScript da página envia os campos para uma rota da API. O Express valida os dados e a participação do usuário no projeto, grava a atividade no SQL Server e devolve uma resposta JSON. A página usa essa resposta para atualizar a lista.

## 3. Mapa dos arquivos

| Caminho | Responsabilidade |
|---|---|
| `server/index.js` | Carrega variáveis de ambiente, verifica a conexão SQL e inicia o servidor. |
| `server/app.js` | Configura o Express, segurança HTTP, autenticação, páginas e rotas da API. |
| `server/db.js` | Valida as configurações SQL e compartilha o pool de conexões. |
| `server/validation.js` | Valida e normaliza entradas, como e-mails, datas, IDs e atividades. |
| `server/migrate.js` | Lê e aplica a migração do banco em lotes. |
| `server/seed.js` | Insere dados de demonstração de forma repetível. |
| `server/*.test.js` | Testes automatizados de validação, páginas e proteção da API. |
| `sql/schema.sql` | Define e atualiza as tabelas, relações, índices e dados legados do schema. |
| `html/` | Uma página HTML para cada área do sistema. |
| `css/` | Estilos específicos das páginas e tema compartilhado. |
| `js/api.js` | Cliente comum para chamadas HTTP JSON à API. |
| `js/app.js` | Comportamentos compartilhados, como sessão, tema e mensagens de feedback. |
| `js/login.js`, `js/cadastro.js` | Lógica dos formulários de entrada e cadastro. |
| `js/dashboard.js` | Seleção de projetos, membros e resumo de atividades. |
| `js/atividade.js` | Criação, edição, filtros e atualização de atividades. |
| `js/canais.js` | Canais e mensagens, atualizados por polling. |
| `js/conta.js` | Dados da conta, tema, código de convite e logout. |
| `.env.example` | Modelo das configurações locais; não deve conter segredos reais. |
| `.gitignore` | Impede que `.env` e `node_modules/` sejam enviados ao Git. |

As páginas carregam `js/api.js` e `js/app.js` antes do script específico da página. Assim, funções comuns não precisam ser repetidas em cada tela.

## 4. Executar o projeto

Requisitos: Node.js 20 ou mais recente e uma instância do SQL Server acessível.

No PowerShell, na pasta do projeto:

```powershell
npm.cmd install
Copy-Item .env.example .env
```

Edite o `.env` local com as configurações da instância:

```env
DB_SERVER=localhost
DB_PORT=1433
DB_DATABASE=OrbittTask
DB_USER=seu_login_sql
DB_PASSWORD=sua_senha
```

`DB_SERVER` é o host e `DB_PORT` é a porta TCP da instância escolhida. Como o código configura a porta separadamente, não acrescente `\NOME_DA_INSTANCIA` ao valor de `DB_SERVER`. Use a porta real configurada no SQL Server; ela pode ser diferente de `1433`.

Prepare o banco e inicie a aplicação:

```powershell
npm.cmd run db:migrate
npm.cmd run db:seed
npm.cmd start
```

Depois, abra [http://localhost:3000](http://localhost:3000). Para desenvolvimento com reinício automático, use `npm.cmd run dev`. Para parar o servidor no terminal, pressione `Ctrl+C`.

**Segredos:** nunca coloque a senha real em `.env.example`, documentação, código ou commits. O `.env` está ignorado pelo Git neste projeto. Se uma senha real tiver sido publicada ou compartilhada, troque-a e atualize o arquivo local.

## 5. Conexão e permissões do SQL Server

`server/db.js` lê as variáveis `DB_*`, cria um pool de conexões e o reutiliza. O pool evita abrir uma conexão nova para cada solicitação. `server/index.js` faz uma consulta `SELECT 1` antes de começar a aceitar requisições.

O login SQL precisa:

- Conseguir conectar à instância e ao banco configurados.
- Durante migração e carga inicial, ter permissão para criar/alterar o schema e ler/escrever os dados.
- Durante o uso normal, ter apenas as permissões de leitura e gravação necessárias.

Uma role de DDL, como `db_ddladmin`, pode ser concedida temporariamente para a migração e removida depois. As permissões de leitura e gravação usadas pela aplicação devem continuar atribuídas. Não use uma conta administradora do SQL Server como credencial permanente do app.

### Erros comuns de conexão

- **`ELOGIN` / falha de logon:** confira usuário, senha, autenticação SQL habilitada, host, porta e instância. O fato de uma conta funcionar no SSMS não significa que o login SQL do `.env` esteja correto.
- **`CREATE TABLE permission denied`:** o login conectou, mas não tem as permissões de DDL necessárias para a migração.
- **Erro de conexão/timeout:** confira se TCP/IP está ativo, se a porta corresponde à instância e se o serviço do SQL Server está iniciado.

O endpoint `GET /health` também testa a conexão e responde `{ "status": "ok" }` quando consegue consultar o banco.

## 6. Banco de dados

As tabelas principais do schema são:

| Tabela | Uso |
|---|---|
| `usuarios` | Conta, senha com hash, e-mail, código de convite e tema. |
| `sessoes` | Hash do token da sessão e sua data de expiração. |
| `projetos` | Nome, descrição, prazo e pessoa criadora. |
| `projeto_membros` | Relação entre usuários e projetos, incluindo a função no projeto. |
| `tarefas` | Atividades, responsável, prioridade, status e datas. |
| `atividade_eventos` | Registro de eventos de criação, atualização e exclusão de atividades. |
| `canais` | Canais de conversa pertencentes a projetos. |
| `mensagens` | Mensagens dos canais e seus autores. |
| `comentarios`, `notificacoes` | Estruturas previstas no schema; não correspondem a funcionalidades completas na interface atual. |

Chaves estrangeiras mantêm relações entre as tabelas. Por exemplo, uma atividade pertence a um projeto, e uma participação relaciona um usuário a um projeto.

`sql/schema.sql` é uma migração repetível: verifica se tabelas, colunas e índices existem antes de criá-los ou ajustá-los. `server/migrate.js` divide o arquivo nos lotes separados por `GO`, pois `GO` é um separador usado por ferramentas SQL e não um comando enviado diretamente ao SQL Server pelo driver.

A migração também converte senhas antigas em texto puro da tabela `usuarios` para hashes bcrypt. Antes de aplicar alterações em um banco com dados importantes, mantenha um backup.

`server/seed.js` cria contas e dados de demonstração sem duplicar os mesmos registros a cada execução. As contas de demonstração estão descritas no README; troque ou remova essas senhas antes de disponibilizar o sistema publicamente.

## 7. Login, sessão e segurança

### Fluxo de autenticação

1. No cadastro, os dados são validados e a senha é transformada em hash bcrypt.
2. No login, o servidor compara a senha enviada com o hash guardado.
3. Após autenticar, o servidor gera um token aleatório para a sessão.
4. O banco guarda o **hash** do token; o navegador recebe o token em um cookie `HttpOnly`.
5. Nas próximas chamadas, o servidor valida o cookie e recupera a conta associada.
6. No logout, a sessão é removida do banco e o cookie é apagado.

Isso evita guardar a senha em texto puro e evita armazenar o token de sessão sem hash no banco.

### Outras proteções presentes

- Helmet configura cabeçalhos de segurança e uma política de conteúdo.
- Há limite de tentativas nas rotas de cadastro e login.
- Operações que alteram dados exigem JSON e verificam a origem da solicitação.
- Entradas são validadas no servidor; valores SQL são passados por parâmetros do driver.
- Páginas e rotas da API protegidas exigem uma sessão válida.
- As permissões de membro e liderança são verificadas no servidor, não apenas escondendo botões na interface.
- O cookie é `Secure` em produção, quando `NODE_ENV=production`.

Essas medidas não substituem HTTPS, senhas fortes, atualização das dependências, backups e configuração cuidadosa antes de uma implantação pública.

## 8. Regras principais do produto

- Cada usuário pode participar de vários projetos.
- Quem cria um projeto entra nele como líder.
- A liderança pode convidar alguém usando o código da conta e adicionar membros.
- Membros do projeto podem consultar suas atividades e participar dos canais.
- Liderança e pessoa criadora podem editar ou excluir atividades.
- A pessoa responsável por uma atividade pode atualizar seu status.
- A liderança pode escolher o responsável; a pessoa escolhida precisa ser membro do projeto.
- Apenas a liderança cria canais; membros do projeto podem ler e enviar mensagens.
- Mensagens são persistidas no banco. A tela consulta novas mensagens a cada quatro segundos; isso é chamado de **polling**, não é uma conexão WebSocket.

## 9. Rotas da API

Todas as rotas de `/api` abaixo, exceto cadastro e login, exigem uma sessão válida.

| Grupo | Rotas principais | O que fazem |
|---|---|---|
| Autenticação | `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/auth/me`, `POST /api/auth/logout` | Criar conta, entrar, consultar sessão e sair. |
| Conta | `GET /api/account`, `PATCH /api/account`, `PATCH /api/account/theme` | Consultar e atualizar dados e tema. |
| Projetos e membros | `GET/POST /api/projects`, `GET /api/projects/:projectId/members`, `POST /api/projects/:projectId/members/lookup`, `POST /api/projects/:projectId/members` | Listar/criar projetos, consultar membros e convidar por código. |
| Atividades | `GET/POST /api/projects/:projectId/tasks`, `PATCH/DELETE /api/tasks/:taskId` | Consultar, filtrar, criar, editar e excluir atividades. |
| Histórico | `GET /api/projects/:projectId/activity` | Consultar eventos do projeto. |
| Canais | `GET/POST /api/projects/:projectId/channels` | Consultar canais e criar canal. |
| Mensagens | `GET/POST /api/channels/:channelId/messages` | Buscar mensagens novas ou enviar uma mensagem. |
| Saúde | `GET /health` | Verificar se o servidor consegue consultar o banco. |

`GET` consulta dados; `POST` normalmente cria ou executa uma ação; `PATCH` altera parcialmente um recurso; `DELETE` remove. Os dados enviados e respostas da API são JSON.

## 10. Como entender uma funcionalidade seguindo o código

Use a criação de atividade como exemplo:

1. Abra `html/atividade.html` e veja os campos do formulário.
2. Em `js/atividade.js`, procure o listener de `submit`; ele coleta os valores e chama `OrbittTask.api.post(...)`.
3. Em `js/api.js`, veja como o objeto é convertido para JSON e enviado com `fetch`.
4. Em `server/app.js`, procure `POST /api/projects/:projectId/tasks`.
5. A rota valida a participação no projeto e os campos usando `server/validation.js`.
6. A consulta SQL usa parâmetros e grava a atividade em `dbo.tarefas`.
7. Uma transação também registra o evento em `dbo.atividade_eventos`.
8. A resposta JSON retorna à página, que recarrega a lista.

Esse caminho — HTML → JavaScript da página → cliente de API → rota Express → validação/regra → SQL → resposta — serve para estudar as demais funcionalidades.

## 11. Testes e comandos úteis

```powershell
npm.cmd test
npm.cmd run dev
npm.cmd run db:migrate
npm.cmd run db:seed
npm.cmd start
```

Os testes existentes cobrem validação de dados, acesso a páginas, proteção de rotas e exigência de JSON em operações de alteração. Eles não executam a migração nem substituem um teste manual com um SQL Server configurado.

Para entender os testes, comece por `server/validation.test.js` e `server/app.test.js`. Os testes são executados com o test runner integrado do Node.js (`node --test`).

## 12. O que ainda pode ser desenvolvido

- Testes automatizados de integração com SQL Server.
- Recuperação de senha e verificação de e-mail.
- Interface/API de comentários e notificações, cujas tabelas já existem no schema.
- Atualização de mensagens por WebSocket, em vez de polling.
- Mais recursos de administração de projetos e membros.
- Configuração de implantação com HTTPS, logs, backups e credenciais próprias para produção.

Uma boa ordem para estudar é: `html/` e `js/` para a interface, `server/validation.js` para validação, `server/app.js` para as rotas e permissões, depois `sql/schema.sql` para relacionar o código ao banco.
