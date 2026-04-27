# 🗄️ Desafio de Projeto — Views, Permissões e Triggers

## 📋 Descrição

Este projeto implementa **views com controle de acesso** (cenário *Company*) e **triggers de auditoria** (cenário *E-commerce*), como parte da formação **SQL Database Specialist** da DIO.

---

## 🗂 Arquivos

```
├── desafio_views_triggers.sql   # Script principal: DDL + Views + Users + Triggers + Testes
├── company.sql                  # Schema e dados do cenário Company (base para Parte 1)
└── README.md
```

---

## 🏗 Parte 1 — Views e Permissões (Cenário: `company_constraints`)

### Esquema lógico base

O banco `company_constraints` representa uma empresa com departamentos, funcionários, projetos e dependentes.

```
departament ──┬── dept_locations
              └── employee ──┬── works_on ── project
                             └── dependent
```

### Views criadas

| View | Descrição | Recursos SQL |
|---|---|---|
| `vw_emp_por_depto_localidade` | Número de empregados agrupados por departamento e localidade | `JOIN`, `COUNT`, `GROUP BY` |
| `vw_depto_gerentes` | Departamentos com o nome completo do gerente responsável | `JOIN`, `CONCAT`, `COALESCE` |
| `vw_projetos_por_qtd_emp` | Projetos ordenados pelo maior número de empregados alocados | `COUNT DISTINCT`, `SUM`, `ORDER BY DESC` |
| `vw_projetos_depto_gerente` | Projetos com departamento responsável e gerente do departamento | Multi-`JOIN` |
| `vw_emp_dependentes_gerente` | Funcionários com dependentes, indicando se são gerentes | `EXISTS`, `IF`, `COUNT`, `GROUP BY` |

### Controle de acesso por perfil

As views ficam armazenadas no banco como objetos de banco de dados, permitindo conceder `SELECT` de forma granular — sem expor as tabelas base.

```
┌──────────────────────────────────────────────┬──────────────┬──────────────┐
│ View                                         │ gerente_usr  │ employee_usr │
├──────────────────────────────────────────────┼──────────────┼──────────────┤
│ vw_emp_por_depto_localidade                  │     ✔        │      ✘       │
│ vw_depto_gerentes                            │     ✔        │      ✘       │
│ vw_projetos_por_qtd_emp                      │     ✔        │      ✔       │
│ vw_projetos_depto_gerente                    │     ✔        │      ✔       │
│ vw_emp_dependentes_gerente                   │     ✔        │      ✘       │
└──────────────────────────────────────────────┴──────────────┴──────────────┘
```

- **`gerente_usr`** — acesso completo a todas as views, incluindo dados de gerência, dependentes e localidades.
- **`employee_usr`** — acesso restrito às views de projetos. Não visualiza informações salariais, de gerência nem de dependentes.

---

## ⚡ Parte 2 — Triggers (Cenário: `ecommerce`)

### Esquema lógico base

```
cliente ──── pedido ──── produto
colaborador
```

Tabelas auxiliares de auditoria:

```
cliente_removido    ← alimentada por trigger de remoção
historico_salario   ← alimentada por trigger de atualização
```

### Triggers implementadas

#### 🔴 `tg_before_delete_cliente` — BEFORE DELETE

**Contexto:** usuários podem solicitar a exclusão de suas contas. Para não perder informações cadastrais (conformidade, auditoria, LGPD), a trigger copia todos os dados do cliente para a tabela `cliente_removido` **antes** de o registro ser apagado.

```sql
BEFORE DELETE ON cliente
→ INSERT INTO cliente_removido (todos os campos + timestamp)
```

**Campos preservados:** `idCliente`, `Pnome`, `NomeMeio`, `Sobrenome`, `CPF`, `endereco`, `dataNascimento`, `removido_em`.

---

#### 🟡 `tg_before_update_salario_colaborador` — BEFORE UPDATE

**Contexto:** a empresa precisa rastrear todos os reajustes salariais dos colaboradores para fins de RH e auditoria interna. A trigger registra o salário anterior e o novo valor **antes** da atualização ser aplicada, mas **somente quando o salário de fato muda** (evita registros desnecessários em atualizações de outros campos).

```sql
BEFORE UPDATE ON colaborador
IF OLD.salario_base <> NEW.salario_base THEN
  → INSERT INTO historico_salario (idColaborador, salario_anterior, salario_novo, alterado_em, motivo)
```

**Campos registrados:** `idColaborador`, `salario_anterior`, `salario_novo`, `alterado_em`, `motivo` (gerado automaticamente com data/hora).

---

## 🔍 Casos de Teste

### Trigger de remoção

```sql
DELETE FROM cliente WHERE CPF = '98765432100';
-- Bruno Oliveira é removido de `cliente`
-- e preservado automaticamente em `cliente_removido`
```

### Trigger de atualização de salário

```sql
UPDATE colaborador SET salario_base = 5200.00 WHERE idColaborador = 1;
-- Gera 1 linha em historico_salario (4500 → 5200)

UPDATE colaborador SET cargo = 'Gerente Comercial' WHERE idColaborador = 2;
-- Não gera linha (salário não alterado)
```

---

## 🚀 Como Executar

**Pré-requisito:** MySQL 8.0+

```bash
mysql -u root -p < company.sql
mysql -u root -p < desafio_views_triggers.sql
```

Ou dentro do cliente MySQL:

```sql
source company.sql;
source desafio_views_triggers.sql;
```

---

## 🧩 Tecnologias

- **MySQL 8.0** — SGBD relacional
- **SQL** — DDL (`CREATE VIEW`, `CREATE TRIGGER`, `CREATE USER`, `GRANT`), DML (`INSERT`, `UPDATE`, `DELETE`), DQL (`SELECT`, `JOIN`, `GROUP BY`, `HAVING`)

---

## 👤 Autor

### **[Sailanth](https://github.com/Sailanth)**

Desafio de Projeto — Formação SQL Database Specialist | DIO
