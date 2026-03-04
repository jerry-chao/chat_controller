# ChatController

A Phoenix LiveView chat application with AI assistant capabilities powered by ReqLLM. Features include:

- Real-time chat interface with AI assistant
- Tool calling support (weather, user info, HTTP requests)
- PostgreSQL persistence for conversations and messages
- Beautiful gradient UI with smooth animations
- Support for multiple LLM providers (OpenAI, Ollama, BigModel, etc.)

## Features

### AI Tools

The AI assistant has access to three built-in tools:

1. **get_weather** - Retrieves mock weather data for any city
2. **get_user_info** - Fetches mock user information by ID
3. **fetch_remote_data** - Makes real HTTP requests to external APIs (currently whitelisted to jsonplaceholder.typicode.com)

### Architecture

This project uses a custom Jido-style orchestration pattern with ReqLLM:

- **ChatAgent** - GenServer managing chat sessions with message history
- **LLM Module** - Wrapper around ReqLLM for OpenAI-compatible APIs
- **Orchestration** - Multi-step flow (ModelStep → ToolStep → CompletionStep)
- **Database Layer** - Ecto schemas for conversations and messages

## Prerequisites

- Elixir 1.14+ and Erlang/OTP 25+
- PostgreSQL 14+
- Node.js 18+ (for asset compilation)
- OpenAI API key OR local Ollama installation OR BigModel API key

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

**For OpenAI:**
```bash
export OPENAI_API_KEY="sk-your-key-here"
export OPENAI_BASE_URL="https://api.openai.com/v1"
export LLM_MODEL="gpt-3.5-turbo"
```

**For Ollama (local):**
```bash
# Start Ollama first: ollama serve
# Pull a model: ollama pull llama2
export OPENAI_BASE_URL="http://localhost:11434/v1"
export LLM_MODEL="llama2"
# No API key needed for Ollama
```

**For BigModel (智谱AI):**
```bash
export BIGMODEL_API_KEY="your-bigmodel-api-key"
# Then use BigModel via ReqLLM
```

See [BigModel Quick Start Guide](BIGMODEL快速开始.md) for detailed usage.

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

### Using BigModel with ReqLLM

This project includes a custom BigModel provider for ReqLLM. To use it:

```elixir
# In IEx or your code
model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})
{:ok, response} = ReqLLM.generate_text(model, "你好，请介绍一下你自己")
text = ReqLLM.Response.text(response)
```

See the comprehensive guides:
- [Quick Start Guide (English)](BIGMODEL_QUICKSTART.md)
- [快速开始指南（中文）](BIGMODEL快速开始.md)
- [Implementation Details](BIGMODEL_IMPLEMENTATION.md)
- [Detailed Usage Guide](lib/chat_controller/ai/big_model_usage.md)

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

### LLM Settings (config/dev.exs)

```elixir
config :chat_controller,
  llm_model: System.get_env("LLM_MODEL") || "gpt-3.5-turbo",
  llm_provider: :openai,
  openai_base_url: System.get_env("OPENAI_BASE_URL") || "http://localhost:11434/v1",
  openai_api_key: System.get_env("OPENAI_API_KEY")
```

### Adding Custom Tools

Edit `lib/chat_controller/ai/tools.ex` to add new tools:

```elixir
defp build_tools do
  # Existing tools...
  
  # Add your custom tool
  {:ok, my_tool} = ReqLLM.Tool.new(
    name: "my_custom_tool",
    description: "What this tool does",
    parameter_schema: [
      param_name: [type: :string, required: true, doc: "Parameter description"]
    ],
    callback: &my_callback/1
  )
  
  [weather_tool, user_tool, fetch_tool, my_tool]
end

defp my_callback(%{"param_name" => value}) do
  # Your tool logic here
  {:ok, "Result: #{value}"}
end
```

## Project Structure

```
lib/chat_controller/
├── ai/
│   ├── big_model.ex           # Custom BigModel provider for ReqLLM
│   ├── chat_agent.ex          # GenServer for chat sessions
│   ├── llm.ex                 # ReqLLM wrapper
│   ├── llm_response.ex        # Response adapter
│   ├── tools.ex               # Tool definitions
│   └── jido/
│       ├── orchestration.ex   # Main orchestration loop
│       ├── model_step.ex      # LLM invocation
│       ├── tool_step.ex       # Tool execution
│       └── completion_step.ex # Final response extraction
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

**For OpenAI:**
- Verify your API key is correct
- Check your OpenAI account has credits
- Ensure OPENAI_BASE_URL is `https://api.openai.com/v1`

**For Ollama:**
```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Start Ollama if needed
ollama serve

# Pull a model if you haven't
ollama pull llama2
```

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

## BigModel Provider

This project includes a fully-featured custom provider for BigModel (智谱AI):

- ✅ Minimal implementation (14 lines of code)
- ✅ Full OpenAI compatibility via ReqLLM defaults
- ✅ Chat completions, streaming, tools, vision (glm-4v)
- ✅ Comprehensive documentation and examples
- ✅ Unit tested (6/6 tests passing)

**Available Models:**
- `glm-4` - Standard chat model
- `glm-4-plus` - Enhanced performance
- `glm-4v` - Vision model
- `glm-3-turbo` - Fast & cost-effective

For more information, see:
- [Quick Start (English)](BIGMODEL_QUICKSTART.md)
- [快速开始（中文）](BIGMODEL快速开始.md)
- [Implementation Guide](BIGMODEL_IMPLEMENTATION.md)

## Reference Project

This project is based on the AI/chat implementation from [excharge_umbrella](https://github.com/yourusername/excharge_umbrella).
