CREATE TABLE jogadores (
    id_jogador SERIAL PRIMARY KEY,
    nickname VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    senha TEXT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK
    (status IN ('Ativo', 'Inativo', 'Banido'))
);


CREATE TABLE modalidades (
    id_modalidade SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    categoria VARCHAR(50) NOT NULL,
    descricao TEXT
);


CREATE TABLE partidas (
    id_partida SERIAL PRIMARY KEY,
    titulo_confronto VARCHAR(100) NOT NULL,
    id_jogador INTEGER NOT NULL,
    id_modalidade INTEGER NOT NULL,
    data_agendada TIMESTAMP NOT NULL,
    status_partida VARCHAR(30) NOT NULL
    CHECK (status_partida IN
    ('Agendada', 'Em andamento', 'Finalizada', 'Cancelada')),
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_jogador)
    REFERENCES jogadores(id_jogador),

    FOREIGN KEY (id_modalidade)
    REFERENCES modalidades(id_modalidade)
);


CREATE TABLE historico_partidas (
    id_historico SERIAL PRIMARY KEY,
    id_partida INTEGER NOT NULL,
    acao VARCHAR(50) NOT NULL,
    descricao TEXT,
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_partida)
    REFERENCES partidas(id_partida)
);


INSERT INTO jogadores (nickname, email, senha, status) VALUES
('NinjaBR', 'ninja@email.com', '123456', 'Ativo'),
('LobaGamer', 'loba@email.com', '123456', 'Ativo'),
('PlayerX', 'player@email.com', '123456', 'Ativo');


INSERT INTO modalidades (nome, categoria, descricao) VALUES
('Valorant', 'FPS', 'Jogo de tiro'),
('League of Legends', 'MOBA', 'Jogo de estrategia'),
('Rocket League', 'Esporte', 'Futebol com carros');


CREATE OR REPLACE FUNCTION validar_partida()
RETURNS TRIGGER AS $$
DECLARE
    situacao VARCHAR(20);
BEGIN

    SELECT status INTO situacao
    FROM jogadores
    WHERE id_jogador = NEW.id_jogador;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Jogador nao encontrado';
    END IF;

    IF situacao <> 'Ativo' THEN
        RAISE EXCEPTION 'Jogador nao esta ativo';
    END IF;

    NEW.data_criacao = CURRENT_TIMESTAMP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_validar_partida
BEFORE INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION validar_partida();


CREATE OR REPLACE FUNCTION registrar_historico()
RETURNS TRIGGER AS $$
BEGIN

    INSERT INTO historico_partidas
    (id_partida, acao, descricao)
    VALUES
    (NEW.id_partida, 'Cadastro',
    'Nova partida cadastrada');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_historico
AFTER INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION registrar_historico();


INSERT INTO partidas
(titulo_confronto, id_jogador, id_modalidade,
data_agendada, status_partida)
VALUES
('NinjaBR x Alpha', 1, 1, CURRENT_TIMESTAMP + INTERVAL '2 days', 'Agendada'),
('LobaGamer x Beta', 2, 2, CURRENT_TIMESTAMP + INTERVAL '5 days', 'Agendada'),
('PlayerX x Gamma', 3, 3, CURRENT_TIMESTAMP + INTERVAL '8 days', 'Agendada');


CREATE OR REPLACE FUNCTION fn_buscar_jogadores(termo TEXT)
RETURNS TABLE (
    id INTEGER,
    nickname VARCHAR(50),
    email VARCHAR(100),
    status VARCHAR(20)
)
AS $$
BEGIN

    RETURN QUERY
    SELECT j.id_jogador, j.nickname, j.email, j.status
    FROM jogadores j
    WHERE j.nickname ILIKE '%' || termo || '%'
    OR j.email ILIKE '%' || termo || '%';

END;
$$ LANGUAGE plpgsql;


CREATE VIEW vw_painel_principal AS
SELECT
    j.nickname,
    p.titulo_confronto,
    m.categoria,
    p.data_agendada,
    p.status_partida
FROM partidas p
INNER JOIN jogadores j
ON p.id_jogador = j.id_jogador
INNER JOIN modalidades m
ON p.id_modalidade = m.id_modalidade;



CREATE VIEW vw_cronograma_partidas AS
SELECT
    p.id_partida,
    p.titulo_confronto,
    p.data_agendada,
    p.status_partida,
    p.data_agendada::DATE - CURRENT_DATE AS dias_restantes,
    j.nickname
FROM partidas p
INNER JOIN jogadores j
ON p.id_jogador = j.id_jogador
ORDER BY p.data_agendada ASC;


SELECT * FROM jogadores;

SELECT * FROM modalidades;

SELECT * FROM partidas;

SELECT * FROM historico_partidas;

SELECT * FROM vw_painel_principal;

SELECT * FROM vw_cronograma_partidas;

SELECT * FROM fn_buscar_jogadores('Ninja');
