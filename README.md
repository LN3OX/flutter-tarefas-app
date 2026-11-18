# Minhas Tarefas — Flutter + SQLite

Aplicativo de **gerenciamento de tarefas (To-Do List)** desenvolvido em **Flutter/Dart**, com
**autenticação de usuários** (cadastro, login, logout e proteção de telas) e **CRUD completo**
de tarefas persistido em uma base de dados **SQLite**. Funciona em **Android, iOS e Web**.

Cada usuário vê e gerencia somente as próprias tarefas.

---

## Funcionalidades principais

**Autenticação**
- Cadastro de usuário (nome, e-mail, senha e confirmação de senha)
- Login com e-mail e senha
- Logout com confirmação
- Sessão persistente: ao reabrir o app o usuário continua logado até sair
- Proteção de telas: Home e formulário de tarefa só abrem com usuário autenticado
  (inclusive ao digitar a URL diretamente no navegador)
- Tratamento de erros: campos vazios, e-mail inválido, senha curta, senhas diferentes,
  **e-mail já cadastrado** e **login inválido**

**Tarefas (CRUD)**
- **Criar** tarefa com título, descrição, prioridade (Baixa/Média/Alta) e prazo opcional
- **Listar** tarefas do usuário, ordenadas (pendentes primeiro, depois por prioridade)
- **Atualizar** pelo formulário de edição ou marcando/desmarcando como concluída na lista
- **Excluir** pela lista ou pela tela de edição, sempre com confirmação
- Filtro por **Todas / Pendentes / Concluídas** (com contadores) e **busca** por texto
- Destaque de tarefas **atrasadas**
- Validação de formulário (título obrigatório, 3–80 caracteres; descrição até 500)

---

## Tecnologias utilizadas

| Tecnologia | Uso |
|---|---|
| [Flutter](https://flutter.dev) 3.50 / Dart 3.14 | Framework e linguagem |
| [`material_ui`](https://pub.dev/packages/material_ui) | Componentes Material Design |
| [`sqflite`](https://pub.dev/packages/sqflite) | SQLite no Android e iOS |
| [`sqflite_common_ffi_web`](https://pub.dev/packages/sqflite_common_ffi_web) | SQLite (WebAssembly) no navegador, persistido em IndexedDB |
| [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi) | SQLite nos testes automatizados |
| [`provider`](https://pub.dev/packages/provider) | Gerenciamento de estado / injeção de dependência |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Guardar a sessão do usuário logado |
| [`crypto`](https://pub.dev/packages/crypto) | Hash SHA-256 das senhas |
| [`intl`](https://pub.dev/packages/intl) | Formatação de datas (dd/MM/aaaa) |
| Navigator 1.0 com rotas nomeadas | Navegação e proteção de telas |

---

## Estrutura do projeto

```
lib/
├── main.dart                     # Inicialização, providers, tema e rotas
├── routes.dart                   # Nomes das rotas + proteção de telas
├── models/
│   ├── app_user.dart             # Modelo de usuário
│   └── task.dart                 # Modelo de tarefa + enum de prioridade
├── screens/
│   ├── login_screen.dart         # Login
│   ├── register_screen.dart      # Cadastro
│   ├── home_screen.dart          # Lista, filtro, busca, concluir e excluir
│   └── task_form_screen.dart     # Criar / editar tarefa
├── services/
│   ├── auth_service.dart         # Cadastro, login, logout e sessão
│   ├── database_service.dart     # Conexão SQLite, tabelas e CRUD
│   └── task_service.dart         # Estado da lista de tarefas para a UI
├── utils/
│   └── validators.dart           # Validações dos formulários
└── widgets/                      # Componentes reutilizáveis
    ├── auth_layout.dart
    ├── confirm_dialog.dart
    ├── empty_state.dart
    ├── error_banner.dart
    ├── password_field.dart
    └── task_tile.dart
test/                             # Testes unitários e de interface
web/sqlite3.wasm                  # Motor SQLite usado na versão Web
```

A lógica está separada em camadas: as **telas** (`screens/`, `widgets/`) só exibem dados e
chamam os **serviços** (`services/`), que por sua vez usam os **modelos** (`models/`) e o banco.

---

## Como executar

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.50 ou superior (canal stable)
- Para Web: Google Chrome ou Microsoft Edge
- Para Android: Android Studio com um emulador ou um celular com depuração USB

Confira o ambiente com:

```bash
flutter doctor
```

### Passos

```bash
git clone https://github.com/LN3OX/flutter-tarefas-app.git
cd flutter-tarefas-app
flutter pub get
```

Executar no navegador:

```bash
flutter run -d chrome
```

(Use `-d edge` se tiver apenas o Microsoft Edge.)

Executar no Android (com emulador aberto ou celular conectado):

```bash
flutter run -d android
```

Rodar os testes automatizados:

```bash
flutter test
```

Gerar a versão Web de produção (saída em `build/web`):

```bash
flutter build web --release
```

> **Dica (Windows):** para compilar para Android, prefira uma pasta **sem acentos nem espaços**
> no caminho (ex.: `C:\projetos\flutter-tarefas-app`), pois o Gradle pode falhar com esses caracteres.

### Primeiro uso
1. Na tela de login, toque em **"Não tem conta? Cadastre-se"**.
2. Preencha nome, e-mail e senha (mínimo 6 caracteres) e toque em **Cadastrar**.
3. Você é levado à tela inicial. Toque em **Nova tarefa** para criar a primeira.
4. Toque em uma tarefa para editar; use a caixa de seleção para concluir e a lixeira para excluir.
5. Use o ícone de saída no topo para fazer logout.

---

## Autenticação

A autenticação é **local**, feita pelo `AuthService` sobre a própria base SQLite, sem depender
de serviços externos:

- **Cadastro:** o e-mail é normalizado (minúsculas, sem espaços) e verificado na tabela `users`.
  Se já existir, o app mostra *"Este e-mail já está cadastrado"*. A senha **nunca é salva em
  texto puro**: é gerado um *salt* aleatório (16 bytes) e salvo apenas o hash SHA-256
  (1000 iterações) de `salt + senha`.
- **Login:** busca o usuário pelo e-mail e compara o hash da senha digitada com o salvo.
  Para e-mail inexistente ou senha errada a mensagem é a mesma — *"E-mail ou senha inválidos"* —
  para não revelar quais e-mails existem.
- **Sessão:** o `id` do usuário logado fica no `SharedPreferences`; ao abrir o app a sessão é
  restaurada. O **logout** apaga esse registro e volta para o login.
- **Proteção de telas:** em `routes.dart`, toda navegação passa por `generateRoute`. Se a rota é
  protegida (`/home`, `/task-form`) e não há usuário logado, o app redireciona para `/login`;
  se o usuário já está logado e tenta abrir login/cadastro, vai para `/home`.

## Base de dados

O app usa **SQLite** através do `DatabaseService`:

- **Android/iOS:** plugin nativo `sqflite` (arquivo `tarefas_app.db` no armazenamento do app).
- **Web:** `sqflite_common_ffi_web`, que roda o SQLite compilado para WebAssembly
  (`web/sqlite3.wasm`) e salva os dados no **IndexedDB** do navegador.

Tabelas:

```sql
CREATE TABLE users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  salt          TEXT NOT NULL,
  created_at    TEXT NOT NULL
);

CREATE TABLE tasks (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  priority    INTEGER NOT NULL DEFAULT 1,   -- 0 baixa, 1 média, 2 alta
  due_date    TEXT,                          -- ISO 8601, opcional
  is_done     INTEGER NOT NULL DEFAULT 0,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);
```

Todas as consultas de tarefas filtram por `user_id`, inclusive `UPDATE` e `DELETE`, garantindo
que um usuário não acesse nem altere tarefas de outro.

---

## Testes

O projeto possui **13 testes automatizados** (`flutter test`), usando um SQLite real em memória:

- `validators_test.dart` — regras de validação dos formulários
- `services_test.dart` — cadastro, e-mail duplicado, login válido/inválido, sessão,
  CRUD completo, filtro/busca e isolamento entre usuários
- `app_flow_test.dart` — fluxo pela interface: validação de campos vazios, login inválido,
  cadastro → criar → editar → concluir → excluir → logout → bloqueio da Home sem login
