# BigModel 提供程序 - 快速开始指南

在 5 分钟内开始在您的 ChatController 应用程序中使用 BigModel AI（智谱AI）。

## 前置要求

- Elixir >= 1.15
- Phoenix >= 1.8
- 从 https://open.bigmodel.cn 获取 BigModel API 密钥

## 第 1 步：设置 API 密钥

```bash
export BIGMODEL_API_KEY="your-api-key-here"
```

或添加到 `.env` 文件：

```bash
BIGMODEL_API_KEY=your-api-key-here
```

## 第 2 步：验证安装

提供程序已在此项目中安装和配置。验证其工作：

```bash
mix test test/chat_controller/ai/big_model_test.exs
```

您应该看到：
```
6 tests, 0 failures
```

## 第 3 步：试用

### 方式 A：使用 IEx 控制台

```bash
iex -S mix
```

然后在控制台中：

```elixir
# 创建模型
model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

# 生成文本
{:ok, response} = ReqLLM.generate_text(model, "你好，请介绍一下你自己")

# 查看结果
IO.puts(ReqLLM.Response.text(response))
```

### 方式 B：运行示例脚本

```bash
mix run examples/bigmodel_example.exs
```

这将演示：
- 基本文本生成
- 流式响应
- 多轮对话
- 工具调用

## 第 4 步：在代码中使用

### 简单聊天

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

# 使用
{:ok, answer} = MyApp.Chat.ask("什么是Elixir?")
IO.puts(answer)
```

### 流式聊天

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

# 使用
MyApp.StreamChat.ask_stream("讲一个关于Elixir的故事")
```

### 带上下文的对话

```elixir
defmodule MyApp.Conversation do
  alias ReqLLM.Context
  alias ReqLLM.Message.ContentPart
  
  def chat_with_context do
    model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})
    
    # 开始对话
    context = Context.new([
      Context.system([ContentPart.text("你是一个helpful的AI助手")]),
      Context.user([ContentPart.text("你好")])
    ])
    
    {:ok, response1} = ReqLLM.chat(model, context)
    IO.puts("助手: #{ReqLLM.Response.text(response1)}")
    
    # 继续对话
    context = context
      |> Context.append(response1.message)
      |> Context.append_user([ContentPart.text("今天天气怎么样？")])
    
    {:ok, response2} = ReqLLM.chat(model, context)
    IO.puts("助手: #{ReqLLM.Response.text(response2)}")
  end
end

MyApp.Conversation.chat_with_context()
```

### 在 LiveView 中使用

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
    
    # 添加用户消息到上下文
    context = Context.append_user(socket.assigns.context, [ContentPart.text(message)])
    
    # 获取响应
    case ReqLLM.chat(socket.assigns.model, context) do
      {:ok, response} ->
        # 用助手响应更新上下文
        context = Context.append(context, response.message)
        
        # 更新消息用于显示
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
          <strong><%= if @msg.role == :user, do: "用户", else: "助手" %>:</strong> 
          <%= @msg.text %>
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

## 可用模型

| 模型 | 适用场景 | 成本 |
|-------|----------|------|
| `glm-3-turbo` | 快速响应、简单任务 | 最低 |
| `glm-4` | 通用目的、平衡性能 | 中等 |
| `glm-4-plus` | 复杂推理、更长上下文 | 较高 |
| `glm-4v` | 图像理解 | 较高 |

## 常用选项

```elixir
ReqLLM.chat(model, context,
  temperature: 0.7,      # 0.0 = 确定性, 2.0 = 创造性
  max_tokens: 1000,      # 最大响应长度
  top_p: 0.9,           # 核采样
  stream: true          # 启用流式传输
)
```

## 错误处理

```elixir
case ReqLLM.generate_text(model, question) do
  {:ok, response} ->
    # 成功
    text = ReqLLM.Response.text(response)
    {:ok, text}
    
  {:error, %ReqLLM.Error.Auth{}} ->
    # API 密钥问题
    {:error, "无效的 API 密钥"}
    
  {:error, %ReqLLM.Error.API.Response{status: 429}} ->
    # 速率限制
    {:error, "超出速率限制，请稍后重试"}
    
  {:error, %ReqLLM.Error.API.Response{status: status}} ->
    # 其他 API 错误
    {:error, "API 错误: #{status}"}
    
  {:error, error} ->
    # 其他错误
    {:error, inspect(error)}
end
```

## 高级功能示例

### 使用视觉模型（GLM-4V）

```elixir
model = LLMDB.Model.new!(%{id: "glm-4v", provider: :bigmodel})

# 使用图片 URL
context = Context.new([
  Context.user([
    ContentPart.text("这张图片里有什么？"),
    ContentPart.image_url("https://example.com/image.jpg")
  ])
])

{:ok, response} = ReqLLM.chat(model, context)

# 使用 Base64 编码的图片
image_data = File.read!("path/to/image.jpg")
context = Context.new([
  Context.user([
    ContentPart.text("描述这张图片"),
    ContentPart.image(image_data, "image/jpeg")
  ])
])

{:ok, response} = ReqLLM.chat(model, context)
```

### 工具/函数调用

```elixir
alias ReqLLM.Tool

model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

# 定义工具
weather_tool = Tool.new!(
  name: "get_weather",
  description: "获取指定城市的天气信息",
  parameters: %{
    type: "object",
    properties: %{
      city: %{
        type: "string",
        description: "城市名称，如：北京、上海"
      },
      unit: %{
        type: "string",
        enum: ["celsius", "fahrenheit"],
        description: "温度单位"
      }
    },
    required: ["city"]
  }
)

context = Context.new([
  Context.user([ContentPart.text("北京今天天气怎么样？")])
])

{:ok, response} = ReqLLM.chat(model, context, tools: [weather_tool])

# 检查工具调用
case ReqLLM.Response.tool_calls(response) do
  [] ->
    IO.puts("没有调用工具")
    
  tool_calls ->
    Enum.each(tool_calls, fn call ->
      IO.puts("函数: #{call.name}")
      IO.puts("参数: #{inspect(call.arguments)}")
      
      # 执行实际的函数调用
      result = execute_tool(call.name, call.arguments)
      
      # 将结果添加回上下文继续对话
      # ...
    end)
end
```

## 下一步

1. **阅读完整文档：**
   - `lib/chat_controller/ai/README.md` - 完整提供程序文档
   - `lib/chat_controller/ai/big_model_usage.md` - 详细使用指南

2. **尝试高级功能：**
   - 使用 `glm-4v` 进行视觉理解
   - 工具/函数调用
   - 流式响应

3. **查看示例：**
   - `examples/bigmodel_example.exs` - 工作示例

4. **查看测试：**
   - `test/chat_controller/ai/big_model_test.exs` - 测试示例

## 故障排除

### "未找到提供程序"
确保提供程序已在 `config/config.exs` 中注册：
```elixir
config :req_llm, :custom_providers, [ChatController.AI.BigModel]
```

### "身份验证失败"
检查您的 API 密钥：
```bash
echo $BIGMODEL_API_KEY
```

### "连接被拒绝"
检查对 `https://open.bigmodel.cn` 的网络访问

## 获取帮助

- BigModel API 文档: https://open.bigmodel.cn/dev/api
- ReqLLM 文档: https://hexdocs.pm/req_llm
- 项目 README: `BIGMODEL_IMPLEMENTATION.md`

## 成本估算

近似成本（人民币/百万tokens）：

- **glm-3-turbo**: ¥50（输入）/ ¥50（输出）
- **glm-4**: ¥100（输入）/ ¥100（输出）
- **glm-4-plus**: ¥500（输入）/ ¥500（输出）
- **glm-4v**: ¥500（输入）/ ¥500（输出）

示例：一次典型对话（1000 tokens 输入 + 500 输出）的成本：
- glm-3-turbo: ~¥0.075
- glm-4: ~¥0.15
- glm-4-plus: ~¥0.75

## 快速参考

```elixir
# 创建模型
model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

# 简单文本
{:ok, response} = ReqLLM.generate_text(model, "你好")
text = ReqLLM.Response.text(response)

# 流式
{:ok, stream} = ReqLLM.stream_text(model, "你好")
stream |> ReqLLM.StreamResponse.tokens() |> Enum.each(&IO.write/1)

# 带上下文
context = Context.new([Context.user([ContentPart.text("你好")])])
{:ok, response} = ReqLLM.chat(model, context, temperature: 0.7)

# 检查使用情况
usage = response.usage
# %{input_tokens: 10, output_tokens: 20, total_tokens: 30}
```

## 最佳实践

1. **使用适当的模型**
   - 简单任务使用 `glm-3-turbo`（更快、更便宜）
   - 复杂推理使用 `glm-4-plus`
   - 图片理解使用 `glm-4v`

2. **优化 token 使用**
   - 保持提示简洁明了
   - 使用 `max_tokens` 限制响应长度
   - 定期清理对话上下文

3. **处理错误**
   - 始终使用 `case` 模式匹配处理结果
   - 实现重试逻辑处理速率限制
   - 记录错误以进行调试

4. **安全性**
   - 不要在代码中硬编码 API 密钥
   - 使用环境变量或配置
   - 在生产环境中使用 `runtime.exs`

5. **性能**
   - 对实时交互使用流式响应
   - 考虑缓存常见查询
   - 监控 token 使用和成本

---

**一切就绪！** 开始使用 BigModel 构建出色的 AI 驱动功能。🚀