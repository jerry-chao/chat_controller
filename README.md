# ChatController

A Phoenix LiveView chat application with AI assistant capabilities powered by LangChain. Features include:

- Real-time chat interface with AI assistant
- Tool calling support (weather, user info, HTTP requests)
- PostgreSQL persistence for conversations and messages
- Beautiful gradient UI with smooth animations
- Support for multiple LLM providers (OpenAI, BigModel, etc.)

## Features

### AI Tools

The AI assistant has access to three built-in tools:

1. **get_weather** - Retrieves mock weather data for any city
2. **get_user_info** - Fetches mock user information by ID
3. **fetch_remote_data** - Makes real HTTP requests to external APIs (currently whitelisted to jsonplaceholder.typicode.com)

### Architecture

This project uses LangChain for AI orchestration:

- **ChatAgent** - GenServer managing chat sessions with message history
- **LangChain Agent** - AI agent with tool calling capabilities
- **Database Layer** - Ecto schemas for conversations and messages

## Prerequisites

- Elixir 1.14+ and Erlang/OTP 25+
- PostgreSQL 14+
- Node.js 18+ (for asset compilation)
- BigModel API key (智谱AI) or OpenAI API key

## Setup

### 1. Install Dependencies

```bash
cd chat_controller
mix deps.get
npm install --prefix assets
```

### 2. Configure Environment

Copy the example environment file and edit it:

```bash
cp .env.example .env
# Edit .env with your settings
```

**For BigModel (智谱AI):**
```bash
export BIGMODEL_API_KEY="your-bigmodel-api-key"
export LLM_MODEL="GLM-4"
```

**For OpenAI:**
```bash
export OPENAI_API_KEY="sk-your-key-here"
export LLM_MODEL="gpt-3.5-turbo"
```

### 3. Setup Database

```bash
mix ecto.create
mix ecto.migrate
```

### 4. Start the Server

```bash
mix phx.server
```

Or start inside IEx:

```bash
iex -S mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) from your browser.

## Usage

### Quick Test

The chat interface includes three example prompt buttons:

1. **"What's the weather in Tokyo?"** - Tests the weather tool
2. **"Get user info for ID 123"** - Tests the user info tool
3. **"Fetch data from jsonplaceholder"** - Tests HTTP request tool

### Using the Chat

Simply type your message and the AI will:
- Respond directly for general questions
- Call appropriate tools when needed (e.g., weather queries, data fetching)
- Explain the results from tool calls

All conversations are persisted to PostgreSQL and restored on page refresh.

## Configuration

### LangChain Settings (config/config.exs)

```elixir
config :langchain,
  openai_key: System.get_env("BIGMODEL_API_KEY"),
  openai_endpoint: "https://open.bigmodel.cn/api/paas/v4"
```

## Project Structure

```
lib/chat_controller/
├── ai/
│   ├── langchain/
│   │   ├── agent.ex          # LangChain agent implementation
│   │   └── tools/
│   │       ├── weather.ex     # Weather tool
│   │       ├── user_info.ex   # User info tool
│   │       └── http_fetch.ex  # HTTP fetch tool
│   └── chat_agent.ex          # GenServer for chat sessions
├── chat/
│   ├── conversation.ex        # Conversation schema
│   ├── message.ex             # Message schema
│   └── chat.ex                # Context module (CRUD)
└── repo.ex                    # Ecto repository

lib/chat_controller_web/
└── live/
    └── chat_live/
        └── index.ex           # Chat LiveView UI
```

## Troubleshooting

### Database Connection Error

Make sure PostgreSQL is running:
```bash
# macOS with Homebrew
brew services start postgresql

# Linux
sudo systemctl start postgresql
```

### LLM Connection Error

**For BigModel:**
- Verify your API key is correct
- Check your BigModel account has credits
- Ensure BIGMODEL_API_KEY is set correctly

### Asset Compilation Issues

```bash
# Clean and reinstall
cd assets
rm -rf node_modules package-lock.json
npm install
cd ..
mix phx.server
```

## Development

### Running Tests

```bash
mix test
```

### Code Quality

```bash
# Run all quality checks
mix precommit
```

## Deployment
Ready to run in production? Please [check the Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Reference Project

This project is based on the AI/chat implementation from [excharge_umbrella](https://github.com/yourusername/excharge_umbrella).