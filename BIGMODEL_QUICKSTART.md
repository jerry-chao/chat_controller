# BigModel Provider - Quick Start Guide

Get started with BigModel AI in your ChatController application in 5 minutes.

## Prerequisites

- Elixir >= 1.15
- Phoenix >= 1.8
- BigModel API key from https://open.bigmodel.cn

## Step 1: Set Your API Key

```bash
export BIGMODEL_API_KEY="your-api-key-here"
```

Or add to `.env` file:

```bash
BIGMODEL_API_KEY=your-api-key-here
```

## Step 2: Verify Installation

The provider is already installed and configured in this project. Verify it works:

```bash
mix test test/chat_controller/ai/big_model_test.exs
```

You should see:
```
6 tests, 0 failures
```

## Step 3: Try It Out

### Option A: Using IEx Console

```bash
iex -S mix
```

Then in the console:

```elixir
# Create a model
model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

# Generate text
{:ok, response} = ReqLLM.generate_text(model, "你好，请介绍一下你自己")

# See the result
IO.puts(ReqLLM.Response.text(response))
```

### Option B: Run the Example Script

```bash
mix run examples/bigmodel_example.exs
```

This will demonstrate:
- Basic text generation
- Streaming responses
- Multi-turn conversations
- Tool calling

## Step 4: Use in Your Code

### Simple Chat

```elixir
defmodule MyApp.Chat do
  def ask(question) do
    model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})
    
    case ReqLLM.generate_text(model, question) do
      {:ok, response} -> 
        {:ok, ReqLLM.Response.text(response)}
      {:error, error} -> 
        {:error, error}
    end
  end
end

# Usage
{:ok, answer} = MyApp.Chat.ask("什么是Elixir?")
IO.puts(answer)
```

### Streaming Chat

```elixir
defmodule MyApp.StreamChat do
  def ask_stream(question) do
    model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})
    
    case ReqLLM.stream_text(model, question) do
      {:ok, stream_response} ->
        stream_response
        |> ReqLLM.StreamResponse.tokens()
        |> Enum.each(&IO.write/1)
        
        IO.puts("\n")
        :ok
        
      {:error, error} ->
        {:error, error}
    end
  end
end

# Usage
MyApp.StreamChat.ask_stream("讲一个关于Elixir的故事")
```

### Conversation with Context

```elixir
defmodule MyApp.Conversation do
  alias ReqLLM.Context
  alias ReqLLM.Message.ContentPart
  
  def chat_with_context do
    model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})
    
    # Start conversation
    context = Context.new([
      Context.system([ContentPart.text("你是一个helpful的AI助手")]),
      Context.user([ContentPart.text("你好")])
    ])
    
    {:ok, response1} = ReqLLM.chat(model, context)
    IO.puts("Assistant: #{ReqLLM.Response.text(response1)}")
    
    # Continue conversation
    context = context
      |> Context.append(response1.message)
      |> Context.append_user([ContentPart.text("今天天气怎么样？")])
    
    {:ok, response2} = ReqLLM.chat(model, context)
    IO.puts("Assistant: #{ReqLLM.Response.text(response2)}")
  end
end

MyApp.Conversation.chat_with_context()
```

### In a LiveView

```elixir
defmodule MyAppWeb.ChatLive do
  use MyAppWeb, :live_view
  
  alias ReqLLM.Context
  alias ReqLLM.Message.ContentPart
  
  def mount(_params, _session, socket) do
    model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})
    context = Context.new([])
    
    socket = socket
      |> assign(:model, model)
      |> assign(:context, context)
      |> assign(:messages, [])
      |> assign(:loading, false)
    
    {:ok, socket}
  end
  
  def handle_event("send_message", %{"message" => message}, socket) do
    socket = assign(socket, :loading, true)
    
    # Add user message to context
    context = Context.append_user(socket.assigns.context, [ContentPart.text(message)])
    
    # Get response
    case ReqLLM.chat(socket.assigns.model, context) do
      {:ok, response} ->
        # Update context with assistant response
        context = Context.append(context, response.message)
        
        # Update messages for display
        messages = [
          %{role: :user, text: message},
          %{role: :assistant, text: ReqLLM.Response.text(response)}
          | socket.assigns.messages
        ]
        
        socket = socket
          |> assign(:context, context)
          |> assign(:messages, messages)
          |> assign(:loading, false)
        
        {:noreply, socket}
        
      {:error, _error} ->
        {:noreply, assign(socket, :loading, false)}
    end
  end
  
  def render(assigns) do
    ~H"""
    <div>
      <div :for={msg <- @messages} class="mb-4">
        <div class={[
          "p-4 rounded",
          if(@msg.role == :user, do: "bg-blue-100", else: "bg-gray-100")
        ]}>
          <strong><%= @msg.role %>:</strong> <%= @msg.text %>
        </div>
      </div>
      
      <form phx-submit="send_message" id="chat-form">
        <.input 
          field={@form[:message]} 
          type="text" 
          placeholder="输入消息..." 
          disabled={@loading}
        />
        <button type="submit" disabled={@loading}>
          <%= if @loading, do: "发送中...", else: "发送" %>
        </button>
      </form>
    </div>
    """
  end
end
```

## Available Models

| Model | Best For | Cost |
|-------|----------|------|
| `glm-3-turbo` | Fast responses, simple tasks | Lowest |
| `glm-4` | General purpose, balanced | Medium |
| `glm-4-plus` | Complex reasoning, longer context | Higher |
| `glm-4v` | Image understanding | Higher |

## Common Options

```elixir
ReqLLM.chat(model, context,
  temperature: 0.7,      # 0.0 = deterministic, 2.0 = creative
  max_tokens: 1000,      # Maximum response length
  top_p: 0.9,           # Nucleus sampling
  stream: true          # Enable streaming
)
```

## Error Handling

```elixir
case ReqLLM.generate_text(model, question) do
  {:ok, response} ->
    # Success
    text = ReqLLM.Response.text(response)
    {:ok, text}
    
  {:error, %ReqLLM.Error.Auth{}} ->
    # API key issue
    {:error, "Invalid API key"}
    
  {:error, %ReqLLM.Error.API.Response{status: 429}} ->
    # Rate limited
    {:error, "Rate limit exceeded, try again later"}
    
  {:error, %ReqLLM.Error.API.Response{status: status}} ->
    # Other API error
    {:error, "API error: #{status}"}
    
  {:error, error} ->
    # Other error
    {:error, inspect(error)}
end
```

## Next Steps

1. **Read the full documentation:**
   - `lib/chat_controller/ai/README.md` - Complete provider docs
   - `lib/chat_controller/ai/big_model_usage.md` - Detailed usage guide

2. **Try advanced features:**
   - Vision with `glm-4v`
   - Tool/function calling
   - Streaming responses

3. **Check the examples:**
   - `examples/bigmodel_example.exs` - Working examples

4. **View the tests:**
   - `test/chat_controller/ai/big_model_test.exs` - Test examples

## Troubleshooting

### "Provider not found"
Ensure provider is registered in `config/config.exs`:
```elixir
config :req_llm, :custom_providers, [ChatController.AI.BigModel]
```

### "Authentication failed"
Check your API key:
```bash
echo $BIGMODEL_API_KEY
```

### "Connection refused"
Check network access to `https://open.bigmodel.cn`

## Getting Help

- BigModel API Docs: https://open.bigmodel.cn/dev/api
- ReqLLM Docs: https://hexdocs.pm/req_llm
- Project README: `BIGMODEL_IMPLEMENTATION.md`

## Cost Estimation

Approximate costs (CNY per 1M tokens):

- **glm-3-turbo**: ¥50 (input) / ¥50 (output)
- **glm-4**: ¥100 (input) / ¥100 (output)
- **glm-4-plus**: ¥500 (input) / ¥500 (output)
- **glm-4v**: ¥500 (input) / ¥500 (output)

Example: A typical conversation (1000 tokens in + 500 out) costs:
- glm-3-turbo: ~¥0.075 (≈ $0.01 USD)
- glm-4: ~¥0.15 (≈ $0.02 USD)
- glm-4-plus: ~¥0.75 (≈ $0.10 USD)

## Quick Reference

```elixir
# Create model
model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

# Simple text
{:ok, response} = ReqLLM.generate_text(model, "Hello")
text = ReqLLM.Response.text(response)

# Streaming
{:ok, stream} = ReqLLM.stream_text(model, "Hello")
stream |> ReqLLM.StreamResponse.tokens() |> Enum.each(&IO.write/1)

# With context
context = Context.new([Context.user([ContentPart.text("Hello")])])
{:ok, response} = ReqLLM.chat(model, context, temperature: 0.7)

# Check usage
usage = response.usage
# %{input_tokens: 10, output_tokens: 20, total_tokens: 30}
```

---

**You're all set!** Start building amazing AI-powered features with BigModel. 🚀