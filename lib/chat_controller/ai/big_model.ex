defmodule ChatController.AI.BigModel do
  @moduledoc """
  BigModel provider for ReqLLM.

  BigModel is fully OpenAI-compatible, so this implementation uses the default
  OpenAI-style encoding/decoding behavior provided by ReqLLM.

  ## Configuration

  Set your BigModel API key as an environment variable:

      export BIGMODEL_API_KEY="your-api-key-here"

  Or configure it in your application config:

      config :req_llm,
        bigmodel_api_key: System.get_env("BIGMODEL_API_KEY")

  ## Available Models

  - glm-4 - Standard chat model with tool support
  - glm-4-plus - Enhanced version with better performance
  - glm-4v - Vision model supporting text and image inputs
  - glm-3-turbo - Fast, cost-effective model

  ## Usage

      # Create a model instance
      model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

      # Generate text
      {:ok, response} = ReqLLM.generate_text(model, "你好，请介绍一下你自己")

      # Get the response text
      text = ReqLLM.Response.text(response)

  ## Streaming

      model = LLMDB.Model.new!(%{id: "glm-4", provider: :bigmodel})

      {:ok, stream_response} = ReqLLM.stream_text(model, "讲一个故事")

      stream_response
      |> ReqLLM.StreamResponse.tokens()
      |> Enum.each(fn token -> IO.write(token) end)
  """

  use ReqLLM.Provider,
    id: :bigmodel,
    default_base_url: "https://open.bigmodel.cn/api/paas/v4",
    default_env_key: "BIGMODEL_API_KEY"

  use ReqLLM.Provider.Defaults
end