#!/usr/bin/env elixir

# BigModel Provider Usage Example
# 
# This script demonstrates how to use the BigModel provider with ReqLLM
# 
# Setup:
#   1. Set your API key: export BIGMODEL_API_KEY="your-api-key"
#   2. Run: mix run examples/bigmodel_example.exs

Mix.install([
  {:req_llm, "~> 1.6"},
  {:jason, "~> 1.4"}
])

# Ensure the custom provider is loaded
# In a real Phoenix app, this would be configured in config.exs
Application.put_env(:req_llm, :custom_providers, [ChatController.AI.BigModel])

defmodule BigModelExample do
  @moduledoc """
  Examples of using BigModel with ReqLLM
  """

  def run_all do
    IO.puts("\n=== BigModel Provider Examples ===\n")

    check_api_key()
    basic_text_generation()
    streaming_example()
    conversation_example()
    tool_calling_example()
  end

  defp check_api_key do
    case System.get_env("BIGMODEL_API_KEY") do
      nil ->
        IO.puts("⚠️  Warning: BIGMODEL_API_KEY not set")
        IO.puts("   Please set it with: export BIGMODEL_API_KEY=\"your-key\"\n")
        System.halt(1)

      key ->
        IO.puts("✓ API key found: #{String.slice(key, 0..8)}...\n")
    end
  end

  defp basic_text_generation do
    IO.puts("--- Example 1: Basic Text Generation ---")

    model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

    case ReqLLM.generate_text(model, "请用一句话介绍你自己") do
      {:ok, response} ->
        text = ReqLLM.Response.text(response)
        IO.puts("Response: #{text}")
        IO.puts("Usage: #{inspect(response.usage)}\n")

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}\n")
    end
  end

  defp streaming_example do
    IO.puts("--- Example 2: Streaming Response ---")

    model = LLMDB.Model.new!(%{id: "glm-3-turbo", provider: :bigmodel})

    case ReqLLM.stream_text(model, "数到10") do
      {:ok, stream_response} ->
        IO.write("Response: ")

        stream_response
        |> ReqLLM.StreamResponse.tokens()
        |> Enum.each(fn token ->
          IO.write(token)
          Process.sleep(50)
        end)

        IO.puts("\n")

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}\n")
    end
  end

  defp conversation_example do
    IO.puts("--- Example 3: Multi-turn Conversation ---")

    alias ReqLLM.Context
    alias ReqLLM.Message.ContentPart

    model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

    context =
      Context.new([
        Context.system([ContentPart.text("你是一个友好的AI助手，回答要简洁")]),
        Context.user([ContentPart.text("北京的天气怎么样？")])
      ])

    case ReqLLM.chat(model, context, temperature: 0.7, max_tokens: 100) do
      {:ok, response} ->
        IO.puts("Assistant: #{ReqLLM.Response.text(response)}")

        updated_context =
          context
          |> Context.append_message(response.message)
          |> Context.append_user([ContentPart.text("那上海呢？")])

        case ReqLLM.chat(model, updated_context, temperature: 0.7, max_tokens: 100) do
          {:ok, response2} ->
            IO.puts("Assistant: #{ReqLLM.Response.text(response2)}\n")

          {:error, error} ->
            IO.puts("Error: #{inspect(error)}\n")
        end

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}\n")
    end
  end

  defp tool_calling_example do
    IO.puts("--- Example 4: Tool/Function Calling ---")

    alias ReqLLM.Tool
    alias ReqLLM.Context
    alias ReqLLM.Message.ContentPart

    model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

    weather_tool =
      Tool.new!(
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

    context = Context.new([Context.user([ContentPart.text("北京今天天气怎么样？")])])

    case ReqLLM.chat(model, context, tools: [weather_tool]) do
      {:ok, response} ->
        case ReqLLM.Response.tool_calls(response) do
          [] ->
            IO.puts("No tool calls. Response: #{ReqLLM.Response.text(response)}\n")

          tool_calls ->
            IO.puts("Tool calls requested:")

            Enum.each(tool_calls, fn call ->
              IO.puts("  - Function: #{call.name}")
              IO.puts("    Arguments: #{inspect(call.arguments)}")
            end)

            IO.puts("")
        end

      {:error, error} ->
        IO.puts("Error: #{inspect(error)}\n")
    end
  end
end

BigModelExample.run_all()