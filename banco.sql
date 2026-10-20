
CREATE TABLE usuarios (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nome NVARCHAR(100) NOT NULL,
    email NVARCHAR(150) NOT NULL UNIQUE,
    senha NVARCHAR(255) NOT NULL
);
GO

CREATE TABLE projetos (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nome NVARCHAR(150) NOT NULL,
    descricao NVARCHAR(MAX),
    prazo DATE,
    status NVARCHAR(30) NOT NULL DEFAULT 'Planejamento'
);
GO

CREATE TABLE projeto_membros (
    id INT IDENTITY(1,1) PRIMARY KEY,
    projeto_id INT NOT NULL,
    usuario_id INT NOT NULL,
    funcao NVARCHAR(30) NOT NULL DEFAULT 'Membro',

    CONSTRAINT FK_ProjetoMembros_Projeto
        FOREIGN KEY (projeto_id)
        REFERENCES projetos(id)
        ON DELETE CASCADE,

    CONSTRAINT FK_ProjetoMembros_Usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuarios(id)
        ON DELETE CASCADE,

    CONSTRAINT UQ_ProjetoMembros
        UNIQUE (projeto_id, usuario_id)
);
GO

CREATE TABLE tarefas (
    id INT IDENTITY(1,1) PRIMARY KEY,
    projeto_id INT NOT NULL,
    usuario_id INT NULL,
    titulo NVARCHAR(150) NOT NULL,
    descricao NVARCHAR(MAX),
    prioridade NVARCHAR(20) NOT NULL DEFAULT 'Media',
    status NVARCHAR(30) NOT NULL DEFAULT 'A Fazer',
    prazo DATE,

    CONSTRAINT FK_Tarefas_Projeto
        FOREIGN KEY (projeto_id)
        REFERENCES projetos(id)
        ON DELETE CASCADE,

    CONSTRAINT FK_Tarefas_Usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuarios(id)
        ON DELETE SET NULL
);
GO

CREATE TABLE comentarios (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tarefa_id INT NOT NULL,
    usuario_id INT NOT NULL,
    texto NVARCHAR(MAX) NOT NULL,
    data DATETIME2 NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Comentarios_Tarefa
        FOREIGN KEY (tarefa_id)
        REFERENCES tarefas(id)
        ON DELETE CASCADE,

    CONSTRAINT FK_Comentarios_Usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuarios(id)
        ON DELETE CASCADE
);
GO

CREATE TABLE notificacoes (
    id INT IDENTITY(1,1) PRIMARY KEY,
    usuario_id INT NOT NULL,
    mensagem NVARCHAR(255) NOT NULL,
    lida BIT NOT NULL DEFAULT 0,
    data DATETIME2 NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Notificacoes_Usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuarios(id)
        ON DELETE CASCADE
);
GO

INSERT INTO usuarios (nome, email, senha)
VALUES
('Garcia', 'garcia@email.com', 'senha_teste'),
('Joao', 'joao@email.com', 'senha_teste'),
('Maria', 'maria@email.com', 'senha_teste');
GO

INSERT INTO projetos (nome, descricao, prazo, status)
VALUES
(
    'TaskFlow',
    'Aplicativo de gerenciamento de equipes e projetos',
    '2026-12-01',
    'Em andamento'
);
GO

INSERT INTO projeto_membros (projeto_id, usuario_id, funcao)
VALUES
(1, 1, 'Lider'),
(1, 2, 'Membro'),
(1, 3, 'Membro');
GO

INSERT INTO tarefas
(projeto_id, usuario_id, titulo, descricao, prioridade, status, prazo)
VALUES
(
    1,
    1,
    'Criar tela de login',
    'Desenvolver a tela de login do aplicativo',
    'Alta',
    'Em andamento',
    '2026-09-10'
),
(
    1,
    2,
    'Criar banco de dados',
    'Desenvolver estrutura inicial do banco SQL Server',
    'Alta',
    'Concluido',
    '2026-09-05'
),
(
    1,
    3,
    'Criar Dashboard',
    'Desenvolver a tela principal do sistema',
    'Media',
    'A Fazer',
    '2026-09-20'
);
GO

INSERT INTO comentarios
(tarefa_id, usuario_id, texto)
VALUES
(
    1,
    2,
    'A tela de login precisa ser revisada.'
),
(
    1,
    1,
    'Vou realizar os ajustes.'
);
GO

INSERT INTO notificacoes
(usuario_id, mensagem)
VALUES
(
    1,
    'Você recebeu uma nova tarefa.'
),
(
    1,
    'Joao comentou na tarefa Criar tela de login.'
);
GO

SELECT * FROM usuarios;
SELECT * FROM projetos;
SELECT * FROM projeto_membros;
SELECT * FROM tarefas;
SELECT * FROM comentarios;
SELECT * FROM notificacoes;
GO