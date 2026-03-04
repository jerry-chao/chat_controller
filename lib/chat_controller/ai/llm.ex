defmodule ChatController.AI.LLM do
  @moduledoc """
  ReqLLM integration module for ChatController.
  Provides a thin wrapper around ReqLLM for LLM communication.
  Uses OpenAI-compatible API (e.g., Ollama, OpenAI, BigModel).
  """

  @default_model "gpt-3.5-turbo"
  @default_provider :openai
  @default_openai_base_url "http://localhost:11434/v1"

  @doc """
  Configures ReqLLM with API keys from application config.
  """
  def configure do
    api_key =
      Application.get_env(:chat_controller, :openai_api_key) ||
        System.get_env("OPENAI_API_KEY")

    if api_key do
      ReqLLM.put_key(:openai_api_key, api_key)
    end

    :ok
  end

  @doc """
  Gets the configured model, defaulting to #{@default_model}.
  """
  def model do
    Application.get_env(:chat_controller, :llm_model, @default_model)
  end

  @doc """
  Gets the configured ReqLLM provider, defaulting to #{@default_provider}.
  """
  def provider do
    Application.get_env(:chat_controller, :llm_provider, @default_provider)
  end

  @doc """
  Gets the OpenAI-compatible base URL from config.
  """
  def openai_base_url do
    Application.get_env(:chat_controller, :openai_base_url, @default_openai_base_url)
  end

  @doc """
  Generates text using ReqLLM.

  ## Options
  - `:temperature` - Sampling temperature (default: 0.7)
  - `:max_tokens` - Maximum tokens to generate (default: 1000)
  - `:base_url` - Custom base URL (for Ollama or custom endpoints)

  ## Examples

      iex> generate_text("gpt-3.5-turbo", "Hello!")
      {:ok, %{text: "Hello! How can I help you today?"}}

      iex> generate_text("gpt-4", "Write a haiku", temperature: 0.9)
      {:ok, %{text: "..."}}
  """
  def generate_text(model_name \\ nil, messages, opts \\ []) do
    with {:ok, model} <- build_model(model_name || model()) do
      ReqLLM.generate_text(model, build_context(messages), with_default_base_url(opts))
    end
  end

  @doc """
  Streams text using ReqLLM.

  ## Examples

      iex> {:ok, stream} = stream_text("gpt-3.5-turbo", "Write a story")
      iex> for chunk <- stream, do: IO.write(chunk.text || "")
  """
  def stream_text(model_name \\ nil, messages, opts \\ []) do
    with {:ok, model} <- build_model(model_name || model()) do
      ReqLLM.stream_text(model, build_context(messages), with_default_base_url(opts))
    end
  end

  @doc """
  Generates text with tool calling support.

  ## Options
  - `:tools` - List of ReqLLM.Tool structs
  - `:temperature` - Sampling temperature (default: 0.7)
  - `:max_tokens` - Maximum tokens to generate (default: 1000)
  - `:base_url` - Custom base URL (for Ollama or custom endpoints)
  """
  def generate_text_with_tools(model_name \\ nil, messages, tools, opts \\ []) do
    with {:ok, model} <- build_model(model_name || model()) do
      opts = opts |> with_default_base_url() |> Keyword.merge(tools: tools)
      ReqLLM.generate_text(model, build_context(messages), opts)
    end
  end

  defp build_context(messages) when is_list(messages) do
    ReqLLM.Context.new(messages)
  end

  defp build_context(message) when is_binary(message) do
    ReqLLM.Context.new([ReqLLM.Context.user(message)])
  end

  defp build_model(model_name) when is_binary(model_name) do
    if String.contains?(model_name, ":") do
      [provider_str, model_id] = String.split(model_name, ":", parts: 2)
      
      provider = 
        try do
          String.to_existing_atom(provider_str)
        rescue
          ArgumentError -> 
            # Fall back to trying ReqLLM.model for built-in providers
            case ReqLLM.model(model_name) do
              {:ok, model} -> 
                model.provider
              _ -> 
                nil
            end
        end
      
      cond do
        is_nil(provider) ->
          ReqLLM.model(model_name)
          
        provider_registered?(provider) ->
          model = LLMDB.Model.new!(%{id: model_id, provider: provider})
          {:ok, model}
          
        true ->
          ReqLLM.model(model_name)
      end
    else
      ReqLLM.model(%{id: model_name, provider: provider()})
    end
  rescue
    _ -> 
      ReqLLM.model(model_name)
  end

  defp provider_registered?(provider_id) do
    case ReqLLM.Provider.get!(provider_id) do
      _ -> true
    end
  rescue
    _ -> false
  end

  defp with_default_base_url(opts) do
    Keyword.put_new(opts, :base_url, openai_base_url())
  end
end