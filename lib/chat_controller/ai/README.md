# ChatController AI Integration

This directory contains AI provider integrations for the ChatController application.

## BigModel Provider

The BigModel provider is a custom ReqLLM provider that integrates BigModel's OpenAI-compatible API.

### Overview

BigModel (智谱AI) is fully OpenAI-compatible, so this implementation uses `ReqLLM.Provider.Defaults` to inherit all standard OpenAI behavior:

- ✅ Chat completions
- ✅ Streaming responses (SSE)
- ✅ Tool/function calling
- ✅ Vision support (glm-4v model)
- ✅ Multi-turn conversations
- ✅ Token usage tracking

### Configuration

The provider is registered in `config/config.exs`:

```elixir
config :req_llm,
  custom_providers: [ChatController.AI.BigModel]
```

### Authentication

Set your BigModel API key:

```bash
export BIGMODEL_API_KEY="your-api-key-here"
```

Or in `config/runtime.exs`:

```elixir
config :req_llm,
  bigmodel_api_key: System.get_env("BIGMODEL_API_KEY")
```

### Available Models

| Model ID | Description | Features | Cost (per 1K tokens) |
|----------|-------------|----------|---------------------|
| `glm-4` | Standard chat model | Chat, Tools | ¥0.0001 in/out |
| `glm-4-plus` | Enhanced performance | Chat, Tools | ¥0.0005 in/out |
| `glm-4v` | Vision model | Chat, Tools, Vision | ¥0.0005 in/out |
| `glm-3-turbo` | Fast & cost-effective | Chat, Tools | ¥0.00005 in/out |

Model metadata is defined in `priv/models_local/bigmodel.json`.

### Usage Examples

#### Basic Text Generation

```elixir
# Create model
model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

# Generate text
{:ok, response} = ReqLLM.generate_text(model, "你好，请介绍一下你自己")

# Get response
text = ReqLLM.Response.text(response)
IO.puts(text)
```

#### Streaming

```elixir
model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

{:ok, stream} = ReqLLM.stream_text(model, "讲一个故事")

stream
|> ReqLLM.StreamResponse.tokens()
|> Enum.each(&IO.write/1)
```

#### Conversations with Context

```elixir
alias ReqLLM.Context
alias ReqLLM.Message.ContentPart

model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

context = Context.new([
  Context.system([ContentPart.text("你是一个helpful的AI助手")]),
  Context.user([ContentPart.text("解释什么是机器学习")])
])

{:ok, response} = ReqLLM.chat(model, context,
  temperature: 0.7,
  max_tokens: 500
)
```

#### Vision (GLM-4V)

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

# With base64 image
image_data = File.read!("path/to/image.jpg")
context = Context.new([
  Context.user([
    ContentPart.text("描述这张图片"),
    ContentPart.image(image_data, "image/jpeg")
  ])
])

{:ok, response} = ReqLLM.chat(model, context)
```

#### Tool/Function Calling

```elixir
alias ReqLLM.Tool

model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

weather_tool = Tool.new!(
  name: "get_weather",
  description: "获取指定城市的天气信息",
  parameters: %{
    type: "object",
    properties: %{
      city: %{type: "string", description: "城市名称"},
      unit: %{type: "string", enum: ["celsius", "fahrenheit"]}
    },
    required: ["city"]
  }
)

context = Context.new([
  Context.user([ContentPart.text("北京今天天气怎么样？")])
])

{:ok, response} = ReqLLM.chat(model, context, tools: [weather_tool])

# Check for tool calls
case ReqLLM.Response.tool_calls(response) do
  [] -> 
    IO.puts("No tools called")
  tool_calls -> 
    Enum.each(tool_calls, fn call ->
      IO.inspect(call.name)
      IO.inspect(call.arguments)
    end)
end
```

### Options

All standard OpenAI parameters are supported:

- `temperature` (0.0-2.0) - Controls randomness
- `max_tokens` - Maximum tokens to generate
- `top_p` (0.0-1.0) - Nucleus sampling
- `frequency_penalty` (-2.0-2.0) - Reduce repetition
- `presence_penalty` (-2.0-2.0) - Encourage new topics
- `stop` - Stop sequences
- `stream` - Enable streaming (automatic with `stream_text`)

```elixir
{:ok, response} = ReqLLM.chat(model, context,
  temperature: 0.7,
  max_tokens: 1000,
  top_p: 0.9,
  frequency_penalty: 0.5
)
```

### Error Handling

```elixir
case ReqLLM.generate_text(model, "Hello") do
  {:ok, response} ->
    IO.puts(ReqLLM.Response.text(response))
    
  {:error, %ReqLLM.Error.Auth{}} ->
    IO.puts("Authentication failed - check API key")
    
  {:error, %ReqLLM.Error.API.Response{status: 429}} ->
    IO.puts("Rate limit exceeded")
    
  {:error, %ReqLLM.Error.API.Response{status: status, response_body: body}} ->
    IO.puts("API error #{status}: #{inspect(body)}")
    
  {:error, error} ->
    IO.puts("Error: #{inspect(error)}")
end
```

### Testing

Run the provider tests:

```bash
mix test test/chat_controller/ai/big_model_test.exs
```

Run the example script:

```bash
export BIGMODEL_API_KEY="your-key"
mix run examples/bigmodel_example.exs
```

### Implementation Details

The implementation is minimal because BigModel is fully OpenAI-compatible:

```elixir
defmodule ChatController.AI.BigModel do
  use ReqLLM.Provider,
    id: :bigmodel,
    default_base_url: "https://open.bigmodel.cn/api/paas/v4",
    default_env_key: "BIGMODEL_API_KEY"

  use ReqLLM.Provider.Defaults
end
```

This leverages:
- `ReqLLM.Provider` - Provider behavior and DSL
- `ReqLLM.Provider.Defaults` - OpenAI-compatible defaults for:
  - Request preparation (`prepare_request/4`)
  - Authentication and headers (`attach/3`)
  - Request body encoding (`encode_body/1`)
  - Response decoding (`decode_response/1`)
  - Streaming setup (`attach_stream/4`)
  - SSE event decoding (`decode_stream_event/2`)
  - Usage extraction (`extract_usage/2`)

No custom callbacks are needed because the API is fully compatible.

### Files

- `lib/chat_controller/ai/big_model.ex` - Provider implementation
- `lib/chat_controller/ai/big_model_usage.md` - Detailed usage guide
- `priv/models_local/bigmodel.json` - Model metadata
- `test/chat_controller/ai/big_model_test.exs` - Unit tests
- `examples/bigmodel_example.exs` - Usage examples

### References

- BigModel API Docs: https://open.bigmodel.cn/dev/api
- ReqLLM Docs: https://hexdocs.pm/req_llm
- Adding Providers: https://hexdocs.pm/req_llm/adding_a_provider.html
- Provider source: [big_model.ex](big_model.ex)

### Troubleshooting

#### Provider not found

Ensure it's registered in `config/config.exs`:

```elixir
config :req_llm, :custom_providers, [ChatController.AI.BigModel]
```

#### Authentication errors

Check your API key:

```bash
echo $BIGMODEL_API_KEY
```

#### Network connectivity

BigModel API endpoint: `https://open.bigmodel.cn/api/paas/v4`

Test connectivity:

```bash
curl -H "Authorization: Bearer $BIGMODEL_API_KEY" \
  https://open.bigmodel.cn/api/paas/v4/chat/completions
```

### Future Enhancements

Potential improvements:

1. **Custom provider options** - Add BigModel-specific parameters
2. **Embeddings support** - Add embedding model support
3. **Batch API** - Implement batch processing
4. **Fine-tuning** - Support for fine-tuned models
5. **Model sync** - Run `mix req_llm.model_sync` to update registry

### Contributing

When adding new features:

1. Update `big_model.ex` implementation
2. Add tests to `big_model_test.exs`
3. Update model metadata in `priv/models_local/bigmodel.json`
4. Document in this README and usage guide

---

**Note**: This is a custom provider implementation for the ChatController application. It demonstrates best practices for integrating OpenAI-compatible APIs with ReqLLM.