-- ============================================================
-- DESAFIO DE PROJETO — VIEWS, PERMISSÕES E TRIGGERS
-- Formação SQL Database Specialist | DIO
-- ============================================================
-- Parte 1: Views e permissões de acesso (cenário Company)
-- Parte 2: Triggers (cenário E-commerce)
-- ============================================================


-- ============================================================
-- PARTE 1 — VIEWS E PERMISSÕES (Cenário: company_constraints)
-- ============================================================

USE company_constraints;

-- ------------------------------------------------------------
-- VIEW 1: Número de empregados por departamento e localidade
-- ------------------------------------------------------------
-- Combina employee, departament e dept_locations para mostrar
-- quantos funcionários existem em cada (departamento, cidade).
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_emp_por_depto_localidade AS
SELECT
    d.Dname                AS Departamento,
    dl.Dlocation           AS Localidade,
    COUNT(e.Ssn)           AS Qtd_Empregados
FROM departament   d
JOIN dept_locations dl ON dl.Dnumber = d.Dnumber
LEFT JOIN employee  e  ON e.Dno      = d.Dnumber
GROUP BY d.Dname, dl.Dlocation
ORDER BY d.Dname, dl.Dlocation;

-- Consulta de verificação
SELECT * FROM vw_emp_por_depto_localidade;


-- ------------------------------------------------------------
-- VIEW 2: Lista de departamentos e seus gerentes
-- ------------------------------------------------------------
-- Traz nome do departamento, data de início do gerente e
-- o nome completo do funcionário que ocupa o cargo de gerente.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_depto_gerentes AS
SELECT
    d.Dnumber              AS Num_Departamento,
    d.Dname                AS Departamento,
    CONCAT(e.Fname, ' ', COALESCE(e.Minit, ''), '. ', e.Lname)
                           AS Gerente,
    e.Ssn                  AS SSN_Gerente,
    d.Mgr_start_date       AS Inicio_Gestao
FROM departament d
JOIN employee    e ON e.Ssn = d.Mgr_ssn
ORDER BY d.Dname;

-- Consulta de verificação
SELECT * FROM vw_depto_gerentes;


-- ------------------------------------------------------------
-- VIEW 3: Projetos com maior número de empregados (desc)
-- ------------------------------------------------------------
-- Conta quantos funcionários distintos estão alocados em cada
-- projeto e ordena do maior para o menor número de alocações.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_projetos_por_qtd_emp AS
SELECT
    p.Pnumber              AS Num_Projeto,
    p.Pname                AS Projeto,
    p.Plocation            AS Localidade,
    COUNT(DISTINCT wo.Essn) AS Qtd_Empregados,
    SUM(wo.Hours)           AS Total_Horas
FROM project  p
LEFT JOIN works_on wo ON wo.Pno = p.Pnumber
GROUP BY p.Pnumber, p.Pname, p.Plocation
ORDER BY Qtd_Empregados DESC, Total_Horas DESC;

-- Consulta de verificação
SELECT * FROM vw_projetos_por_qtd_emp;


-- ------------------------------------------------------------
-- VIEW 4: Lista de projetos, departamentos e gerentes
-- ------------------------------------------------------------
-- Apresenta cada projeto junto ao departamento responsável e
-- o nome do gerente daquele departamento.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_projetos_depto_gerente AS
SELECT
    p.Pnumber              AS Num_Projeto,
    p.Pname                AS Projeto,
    p.Plocation            AS Localidade_Projeto,
    d.Dnumber              AS Num_Departamento,
    d.Dname                AS Departamento,
    CONCAT(e.Fname, ' ', COALESCE(e.Minit, ''), '. ', e.Lname)
                           AS Gerente
FROM project     p
JOIN departament d  ON d.Dnumber = p.Dnum
JOIN employee    e  ON e.Ssn     = d.Mgr_ssn
ORDER BY d.Dname, p.Pname;

-- Consulta de verificação
SELECT * FROM vw_projetos_depto_gerente;


-- ------------------------------------------------------------
-- VIEW 5: Empregados com dependentes e se são gerentes
-- ------------------------------------------------------------
-- Lista os funcionários que têm pelo menos um dependente,
-- indicando quantos dependentes possuem e se exercem o papel
-- de gerente em algum departamento.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_emp_dependentes_gerente AS
SELECT
    e.Ssn                                    AS SSN,
    CONCAT(e.Fname, ' ', COALESCE(e.Minit, ''), '. ', e.Lname)
                                             AS Empregado,
    e.Dno                                    AS Num_Depto,
    COUNT(dep.Dependent_name)                AS Qtd_Dependentes,
    -- Verifica se o SSN aparece como gerente em algum departamento
    IF(EXISTS (
        SELECT 1 FROM departament d WHERE d.Mgr_ssn = e.Ssn
    ), 'Sim', 'Não')                         AS Eh_Gerente
FROM employee  e
JOIN dependent dep ON dep.Essn = e.Ssn
GROUP BY e.Ssn, e.Fname, e.Minit, e.Lname, e.Dno
ORDER BY Eh_Gerente DESC, Empregado;

-- Consulta de verificação
SELECT * FROM vw_emp_dependentes_gerente;


-- ============================================================
-- PARTE 1 — GERENCIAMENTO DE USUÁRIOS E PERMISSÕES
-- ============================================================
-- Cria dois perfis de acesso:
--   • gerente_usr  → acesso às views de employee + departamento
--   • employee_usr → acesso apenas às views de projetos/alocação
--                    (sem informações de gerência ou salários)
-- ============================================================

-- Remove usuários anteriores (evita erros em re-execução)
DROP USER IF EXISTS 'gerente_usr'@'localhost';
DROP USER IF EXISTS 'employee_usr'@'localhost';

-- Cria o usuário gerente
CREATE USER 'gerente_usr'@'localhost'
    IDENTIFIED BY 'Gerente@2024!';

-- Cria o usuário funcionário
CREATE USER 'employee_usr'@'localhost'
    IDENTIFIED BY 'Employee@2024!';

-- -------------------------------------------------------
-- Permissões do GERENTE
-- Pode consultar todas as views do cenário company
-- -------------------------------------------------------
GRANT SELECT ON company_constraints.vw_emp_por_depto_localidade  TO 'gerente_usr'@'localhost';
GRANT SELECT ON company_constraints.vw_depto_gerentes             TO 'gerente_usr'@'localhost';
GRANT SELECT ON company_constraints.vw_projetos_por_qtd_emp       TO 'gerente_usr'@'localhost';
GRANT SELECT ON company_constraints.vw_projetos_depto_gerente     TO 'gerente_usr'@'localhost';
GRANT SELECT ON company_constraints.vw_emp_dependentes_gerente    TO 'gerente_usr'@'localhost';

-- -------------------------------------------------------
-- Permissões do EMPLOYEE
-- Pode ver apenas projetos e alocações (sem dados gerenciais
-- nem informações salariais / de dependentes)
-- -------------------------------------------------------
GRANT SELECT ON company_constraints.vw_projetos_por_qtd_emp   TO 'employee_usr'@'localhost';
GRANT SELECT ON company_constraints.vw_projetos_depto_gerente TO 'employee_usr'@'localhost';

-- Aplica as permissões imediatamente
FLUSH PRIVILEGES;

/*
  Resumo de acesso:
  ┌──────────────────────────────────────────────┬──────────────┬──────────────┐
  │ View                                         │ gerente_usr  │ employee_usr │
  ├──────────────────────────────────────────────┼──────────────┼──────────────┤
  │ vw_emp_por_depto_localidade                  │     ✔        │      ✘       │
  │ vw_depto_gerentes                            │     ✔        │      ✘       │
  │ vw_projetos_por_qtd_emp                      │     ✔        │      ✔       │
  │ vw_projetos_depto_gerente                    │     ✔        │      ✔       │
  │ vw_emp_dependentes_gerente                   │     ✔        │      ✘       │
  └──────────────────────────────────────────────┴──────────────┴──────────────┘
*/


-- ============================================================
-- PARTE 2 — TRIGGERS (Cenário: e-commerce)
-- ============================================================
-- Recriamos o banco e-commerce com as tabelas necessárias para
-- demonstrar os gatilhos solicitados.
-- ============================================================

DROP DATABASE IF EXISTS ecommerce;
CREATE DATABASE ecommerce;
USE ecommerce;

-- ------------------------------------------------------------
-- Tabela de clientes (usuários da plataforma)
-- ------------------------------------------------------------
CREATE TABLE cliente (
    idCliente        INT          NOT NULL AUTO_INCREMENT,
    Pnome            VARCHAR(10)  NOT NULL,
    NomeMeio         VARCHAR(3),
    Sobrenome        VARCHAR(20)  NOT NULL,
    CPF              CHAR(11)     NOT NULL,
    endereco         VARCHAR(45),
    dataNascimento   DATE,
    PRIMARY KEY (idCliente),
    UNIQUE (CPF)
);

-- ------------------------------------------------------------
-- Tabela de histórico de clientes removidos
-- Utilizada pela trigger de remoção (before delete)
-- ------------------------------------------------------------
CREATE TABLE cliente_removido (
    idRegistro       INT          NOT NULL AUTO_INCREMENT,
    idCliente_orig   INT          NOT NULL,
    Pnome            VARCHAR(10)  NOT NULL,
    NomeMeio         VARCHAR(3),
    Sobrenome        VARCHAR(20)  NOT NULL,
    CPF              CHAR(11)     NOT NULL,
    endereco         VARCHAR(45),
    dataNascimento   DATE,
    removido_em      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (idRegistro)
);

-- ------------------------------------------------------------
-- Tabela de colaboradores (funcionários internos da empresa)
-- ------------------------------------------------------------
CREATE TABLE colaborador (
    idColaborador    INT            NOT NULL AUTO_INCREMENT,
    nome             VARCHAR(45)    NOT NULL,
    cargo            VARCHAR(30)    NOT NULL,
    salario_base     DECIMAL(10,2)  NOT NULL,
    data_admissao    DATE           NOT NULL,
    ativo            TINYINT(1)     NOT NULL DEFAULT 1,
    PRIMARY KEY (idColaborador)
);

-- ------------------------------------------------------------
-- Tabela de histórico de salários dos colaboradores
-- Utilizada pela trigger de atualização (before update)
-- ------------------------------------------------------------
CREATE TABLE historico_salario (
    idHistorico      INT            NOT NULL AUTO_INCREMENT,
    idColaborador    INT            NOT NULL,
    salario_anterior DECIMAL(10,2)  NOT NULL,
    salario_novo     DECIMAL(10,2)  NOT NULL,
    alterado_em      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo           VARCHAR(100),
    PRIMARY KEY (idHistorico)
);

-- ------------------------------------------------------------
-- Tabela de produtos
-- ------------------------------------------------------------
CREATE TABLE produto (
    idProduto    INT            NOT NULL AUTO_INCREMENT,
    categoria    VARCHAR(45)    NOT NULL,
    descricao    VARCHAR(45)    NOT NULL,
    valor        DECIMAL(10,2)  NOT NULL,
    PRIMARY KEY (idProduto)
);

-- ------------------------------------------------------------
-- Tabela de pedidos
-- ------------------------------------------------------------
CREATE TABLE pedido (
    idPedido         INT            NOT NULL AUTO_INCREMENT,
    status_pedido    ENUM('Em processamento','Confirmado','Em transporte',
                          'Entregue','Cancelado')
                                   NOT NULL DEFAULT 'Em processamento',
    descricao        VARCHAR(45),
    Cliente_idCliente INT           NOT NULL,
    frete            FLOAT          NOT NULL DEFAULT 0,
    PRIMARY KEY (idPedido),
    CONSTRAINT fk_pedido_cliente
        FOREIGN KEY (Cliente_idCliente) REFERENCES cliente(idCliente)
        ON UPDATE CASCADE ON DELETE RESTRICT
);


-- ============================================================
-- TRIGGER 1 — REMOÇÃO (BEFORE DELETE) em cliente
-- ============================================================
-- Objetivo: antes de excluir um registro de cliente, salvar
-- todos os seus dados na tabela cliente_removido, garantindo
-- rastreabilidade e conformidade com auditorias.
-- ============================================================
DELIMITER $$

CREATE TRIGGER tg_before_delete_cliente
BEFORE DELETE ON cliente
FOR EACH ROW
BEGIN
    INSERT INTO cliente_removido (
        idCliente_orig,
        Pnome,
        NomeMeio,
        Sobrenome,
        CPF,
        endereco,
        dataNascimento,
        removido_em
    ) VALUES (
        OLD.idCliente,
        OLD.Pnome,
        OLD.NomeMeio,
        OLD.Sobrenome,
        OLD.CPF,
        OLD.endereco,
        OLD.dataNascimento,
        NOW()
    );
END$$

DELIMITER ;


-- ============================================================
-- TRIGGER 2 — ATUALIZAÇÃO (BEFORE UPDATE) em colaborador
-- ============================================================
-- Objetivo: sempre que o salário_base de um colaborador for
-- alterado, registrar na tabela historico_salario o valor
-- anterior, o novo valor e o momento da alteração, antes que
-- o UPDATE seja de fato aplicado.
-- ============================================================
DELIMITER $$

CREATE TRIGGER tg_before_update_salario_colaborador
BEFORE UPDATE ON colaborador
FOR EACH ROW
BEGIN
    -- Dispara apenas quando o salário efetivamente muda
    IF OLD.salario_base <> NEW.salario_base THEN
        INSERT INTO historico_salario (
            idColaborador,
            salario_anterior,
            salario_novo,
            alterado_em,
            motivo
        ) VALUES (
            OLD.idColaborador,
            OLD.salario_base,
            NEW.salario_base,
            NOW(),
            CONCAT(
                'Atualização via sistema em ',
                DATE_FORMAT(NOW(), '%d/%m/%Y %H:%i:%s')
            )
        );
    END IF;
END$$

DELIMITER ;


-- ============================================================
-- BLOCO DE TESTES — validação das triggers
-- ============================================================

-- Dados de teste: clientes
INSERT INTO cliente (Pnome, NomeMeio, Sobrenome, CPF, endereco, dataNascimento) VALUES
    ('Ana',    'M',  'Silva',    '12345678901', 'Rua A, 10 - SP', '1990-03-15'),
    ('Bruno',  'C',  'Oliveira', '98765432100', 'Rua B, 20 - RJ', '1985-07-22'),
    ('Carla',  NULL, 'Santos',   '11122233344', 'Rua C, 30 - BH', '1995-11-05');

-- Dados de teste: colaboradores
INSERT INTO colaborador (nome, cargo, salario_base, data_admissao) VALUES
    ('Diego Mendes',   'Analista de TI',    4500.00, '2020-01-10'),
    ('Fernanda Lima',  'Gerente de Vendas', 7800.00, '2018-05-20'),
    ('Gabriel Costa',  'Suporte N1',        2800.00, '2022-09-01');

-- -----------------------------------------------------------
-- TESTE TRIGGER 1: remoção de cliente
-- Esperado: linha deletada de `cliente`; linha salva em
--           `cliente_removido` com os mesmos dados + timestamp
-- -----------------------------------------------------------
DELETE FROM cliente WHERE CPF = '98765432100';

-- Verificar resultado:
SELECT * FROM cliente;           -- Bruno não deve aparecer
SELECT * FROM cliente_removido;  -- Bruno deve constar aqui


-- -----------------------------------------------------------
-- TESTE TRIGGER 2: atualização de salário
-- Esperado: `historico_salario` registra salário antigo/novo
-- -----------------------------------------------------------

-- Reajuste normal
UPDATE colaborador
SET    salario_base = 5200.00
WHERE  idColaborador = 1;   -- Diego: 4500 → 5200

-- Promoção com cargo + salário (gatilho filtra apenas alterações de salário)
UPDATE colaborador
SET    cargo        = 'Analista Sênior de TI',
       salario_base = 6000.00
WHERE  idColaborador = 1;   -- Diego: 5200 → 6000

-- Alteração sem mudança de salário (NÃO deve gerar linha no histórico)
UPDATE colaborador
SET    cargo = 'Gerente Comercial'
WHERE  idColaborador = 2;   -- Fernanda: cargo muda, salário não

-- Verificar resultado:
SELECT * FROM colaborador;
SELECT * FROM historico_salario;  -- Deve conter 2 linhas de Diego


-- ============================================================
-- RESUMO DOS OBJETOS CRIADOS
-- ============================================================
/*
  BANCO: company_constraints
  ┌─ VIEWS ──────────────────────────────────────────────────┐
  │ vw_emp_por_depto_localidade   → emp count por depto/local │
  │ vw_depto_gerentes             → lista de gerentes          │
  │ vw_projetos_por_qtd_emp       → projetos ordenados desc    │
  │ vw_projetos_depto_gerente     → projeto + depto + gerente  │
  │ vw_emp_dependentes_gerente    → emp c/ dep + flag gerente  │
  └──────────────────────────────────────────────────────────┘
  ┌─ USUÁRIOS ───────────────────────────────────────────────┐
  │ gerente_usr  → SELECT em todas as 5 views                 │
  │ employee_usr → SELECT apenas em views de projetos (2)     │
  └──────────────────────────────────────────────────────────┘

  BANCO: ecommerce
  ┌─ TRIGGERS ───────────────────────────────────────────────┐
  │ tg_before_delete_cliente          → BEFORE DELETE         │
  │   Preserva dados do cliente em cliente_removido           │
  │                                                           │
  │ tg_before_update_salario_colaborador → BEFORE UPDATE      │
  │   Registra variação salarial em historico_salario         │
  └──────────────────────────────────────────────────────────┘
*/
