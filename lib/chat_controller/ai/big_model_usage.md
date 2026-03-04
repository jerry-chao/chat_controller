# BigModel Provider Usage Guide

This guide explains how to use the BigModel provider with ReqLLM in your ChatController application.

## Overview

BigModel is an OpenAI-compatible API provider. The implementation uses `ReqLLM.Provider.Defaults`, which means it inherits all OpenAI-compatible behavior including:

- Chat completions
- Streaming responses
- Tool/function calling
- Vision support (for glm-4v model)
- Automatic token usage tracking

## Configuration

The BigModel provider is already registered in `config/config.exs`:

```elixir
config :req_llm,
  custom_providers: [ChatController.AI.BigModel]
```

## Authentication

Set your BigModel API key as an environment variable:

```bash
export BIGMODEL_API_KEY="your-api-key-here"
```

Or configure it in your runtime config (`config/runtime.exs`):

```elixir
config :req_llm,
  bigmodel_api_key: System.get_env("BIGMODEL_API_KEY")
```

## Available Models

- **glm-4** - Standard chat model with tool support
- **glm-4-plus** - Enhanced version with better performance
- **glm-4v** - Vision model supporting text and image inputs
- **glm-3-turbo** - Fast, cost-effective model

## Basic Usage

### Simple Text Generation

```elixir
# Create a model instance
model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

# Generate text
{:ok, response} = ReqLLM.generate_text(model, "你好，请介绍一下你自己")

# Get the response text
text = ReqLLM.Response.text(response)
IO.puts(text)
```

### Streaming Responses

```elixir
model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

{:ok, stream_response} = ReqLLM.stream_text(model, "讲一个故事")

# Stream tokens as they arrive
stream_response
|> ReqLLM.StreamResponse.tokens()
|> Enum.each(fn token ->
  IO.write(token)
end)
```

### With Context and Options

```elixir
alias ReqLLM.Context
alias ReqLLM.Message.ContentPart

model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

# Build a conversation context
context = Context.new([
  Context.system([ContentPart.text("你是一个helpful的AI助手")]),
  Context.user([ContentPart.text("解释什么是机器学习")])
])

# Generate with options
{:ok, response} = ReqLLM.chat(model, context,
  temperature: 0.7,
  max_tokens: 500,
  top_p: 0.9
)

text = ReqLLM.Response.text(response)
```

### Using Vision Model (GLM-4V)

```elixir
model = LLMDB.Model.new!(%{id: "glm-4v", provider: :bigmodel})

# With image URL
context = Context.new([
  Context.user([
    ContentPart.text("这张图片里有什么？"),
    ContentPart.image_url("https://example.com/image.jpg")
  ])
])

{:ok, response} = ReqLLM.chat(model, context)

# With base64 encoded image
image_data = File.read!("path/to/image.jpg")

context = Context.new([
  Context.user([
    ContentPart.text("描述这张图片"),
    ContentPart.image(image_data, "image/jpeg")
  ])
])

{:ok, response} = ReqLLM.chat(model, context)
```

### Tool/Function Calling

```elixir
alias ReqLLM.Tool

model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

# Define a tool
weather_tool = Tool.new!(
  name: "get_weather",
  description: "Get current weather for a location",
  parameters: %{
    type: "object",
    properties: %{
      location: %{
        type: "string",
        description: "City name"
      },
      unit: %{
        type: "string",
        enum: ["celsius", "fahrenheit"]
      }
    },
    required: ["location"]
  }
)

context = Context.new([
  Context.user([ContentPart.text("北京现在天气怎么样？")])
])

# Request with tools
{:ok, response} = ReqLLM.chat(model, context, tools: [weather_tool])

# Check if model wants to call a tool
case ReqLLM.Response.tool_calls(response) do
  [] ->
    IO.puts("No tool calls")
    
  tool_calls ->
    Enum.each(tool_calls, fn call ->
      IO.inspect(call, label: "Tool Call")
      # Execute the tool and add result to context
    end)
end
```

## Advanced Usage

### Custom Base URL

If you need to use a different endpoint:

```elixir
model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

{:ok, response} = ReqLLM.generate_text(
  model,
  "Hello",
  base_url: "https://custom-endpoint.example.com/api/paas/v4"
)
```

### Per-Request API Key

```elixir
model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

{:ok, response} = ReqLLM.generate_text(
  model,
  "Hello",
  api_key: "custom-api-key"
)
```

### Usage and Cost Tracking

```elixir
{:ok, response} = ReqLLM.generate_text(model, "Hello")

# Get token usage
usage = response.usage
IO.inspect(usage)
# %{
#   input_tokens: 10,
#   output_tokens: 20,
#   total_tokens: 30
# }

# Cost is automatically calculated based on model pricing
# defined in priv/models_local/bigmodel.json
```

## Error Handling

```elixir
case ReqLLM.generate_text(model, "Hello") do
  {:ok, response} ->
    IO.puts(ReqLLM.Response.text(response))
    
  {:error, %ReqLLM.Error.Auth{}} ->
    IO.puts("Authentication failed - check your API key")
    
  {:error, %ReqLLM.Error.API.Response{status: 429}} ->
    IO.puts("Rate limit exceeded")
    
  {:error, %ReqLLM.Error.API.Response{status: status, response_body: body}} ->
    IO.puts("API error #{status}: #{inspect(body)}")
    
  {:error, error} ->
    IO.puts("Unexpected error: #{inspect(error)}")
end
```

## Integration with Jido AI

Since the project also uses Jido AI, you can create model aliases:

```elixir
# In config/config.exs
config :jido_ai,
  model_aliases: %{
    fast: "openai:gpt-3.5-turbo",
    capable: "openai:gpt-4",
    bigmodel_fast: "bigmodel:glm-3-turbo",
    bigmodel_capable: "bigmodel:glm-4-plus"
  }
```

Then use the aliases in your code:

```elixir
# Note: This requires Jido AI to support ReqLLM custom providers
{:ok, response} = JidoAI.chat(:bigmodel_fast, "你好")
```

## Testing

Run the provider tests:

```bash
mix test test/chat_controller/ai/big_model_test.exs
```

## Troubleshooting

### "Provider not found" error

Make sure the provider is registered in `config/config.exs`:

```elixir
config :req_llm, :custom_providers, [ChatController.AI.BigModel]
```

### Authentication errors

Verify your API key is set:

```bash
echo $BIGMODEL_API_KEY
```

### Network errors

The BigModel API endpoint is: `https://open.bigmodel.cn/api/paas/v4`

Ensure your network can reach this endpoint.

## API Compatibility

BigModel follows OpenAI's API structure, so all OpenAI-compatible features are supported:

- ✅ Chat completions
- ✅ Streaming (SSE)
- ✅ Function/tool calling
- ✅ Vision (glm-4v only)
- ✅ System messages
- ✅ Multi-turn conversations
- ✅ Temperature, top_p, max_tokens controls

## References

- BigModel API Documentation: https://open.bigmodel.cn/dev/api
- ReqLLM Documentation: https://hexdocs.pm/req_llm
- Provider Implementation: `lib/chat_controller/ai/big_model.ex`
- Model Metadata: `priv/models_local/bigmodel.json`
