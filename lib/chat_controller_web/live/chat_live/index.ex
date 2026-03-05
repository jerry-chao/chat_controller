defmodule ChatControllerWeb.ChatLive.Index do
  use ChatControllerWeb, :live_view

  require Logger

  alias ChatController.AI.ChatAgent

  @impl true
  def mount(_params, _session, socket) do
    {chat_agent_pid, error} = start_chat_agent()

    {:ok,
     socket
     |> assign(:messages, [])
     |> assign(:loading, false)
     |> assign(:error, error)
     |> assign(:input_value, "")
     |> assign(:chat_agent_pid, chat_agent_pid)}
  end

  @impl true
  def handle_event("send_message", %{"message" => message}, socket) do
    if String.trim(message) == "" do
      {:noreply, socket}
    else
      user_message = %{
        role: :user,
        content: message,
        timestamp: DateTime.utc_now()
      }

      socket =
        socket
        |> assign(:messages, socket.assigns.messages ++ [user_message])
        |> assign(:loading, true)
        |> assign(:input_value, "")
        |> assign(:error, nil)

      send(self(), {:send_to_ai, message})

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_input", %{"message" => message}, socket) do
    {:noreply, assign(socket, :input_value, message)}
  end

  @impl true
  def handle_event("clear_error", _, socket) do
    {:noreply, assign(socket, :error, nil)}
  end

  @impl true
  def handle_info({:send_to_ai, message}, socket) do
    case chat_agent_response(socket.assigns.chat_agent_pid, message) do
      {:ok, response} ->
        ai_message = %{
          role: :assistant,
          content: extract_text_from_response(response),
          timestamp: DateTime.utc_now()
        }

        {:noreply,
         socket
         |> assign(:messages, socket.assigns.messages ++ [ai_message])
         |> assign(:loading, false)}

      {:error, reason} ->
        Logger.error("AI request failed: #{inspect(reason)}")

        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:error, format_error(reason))}
    end
  end

  @impl true
  def terminate(_reason, socket) do
    stop_chat_agent(socket.assigns[:chat_agent_pid])
    :ok
  end

  defp chat_agent_response(nil, _message), do: {:error, :chat_agent_unavailable}

  defp chat_agent_response(chat_agent_pid, message) do
    ChatAgent.ask_sync(chat_agent_pid, message, timeout: 45_000, tool_context: %{})
  end

  defp extract_text_from_response(response) when is_binary(response), do: response
  defp extract_text_from_response(%{text: text}) when is_binary(text), do: text
  defp extract_text_from_response(%{content: content}) when is_binary(content), do: content
  defp extract_text_from_response(%{message: message}) when is_binary(message), do: message
  defp extract_text_from_response({:ok, response}), do: extract_text_from_response(response)

  defp extract_text_from_response(response) when is_map(response) do
    cond do
      Map.has_key?(response, :text) -> Map.get(response, :text)
      Map.has_key?(response, :content) -> Map.get(response, :content)
      Map.has_key?(response, :message) -> Map.get(response, :message)
      true -> inspect(response)
    end
  end

  defp extract_text_from_response(response), do: inspect(response)

  defp stop_chat_agent(nil), do: :ok

  defp stop_chat_agent(pid) when is_pid(pid) do
    if Process.alive?(pid) do
      GenServer.stop(pid, :normal)
    end

    :ok
  rescue
    _ -> :ok
  end

  defp format_error(:chat_agent_unavailable), do: "AI service is not available right now."

  defp format_error({:chat_agent_start_failed, reason}),
    do: "AI service start failed: #{inspect(reason)}"

  defp format_error(_), do: "An error occurred. Please try again."

  defp start_chat_agent do
    case safe_start_agent() do
      {:ok, pid} ->
        {pid, nil}

      {:error, reason} ->
        Logger.error("Failed to start chat agent: #{inspect(reason)}")
        {nil, format_error({:chat_agent_start_failed, reason})}
    end
  end

  defp safe_start_agent do
    try do
      ChatAgent.start_link()
    catch
      :exit, reason -> {:error, reason}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-6">
      <div class="max-w-5xl mx-auto">
        <div class="mb-8 text-center animate-in fade-in duration-700">
          <h1 class="text-5xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-indigo-600 mb-3">
            ChatController AI
          </h1>
          <p class="text-lg text-gray-600">
            Powered by LangChain with HTTP Tools
          </p>
        </div>

        <div class="h-[calc(100vh-280px)] flex flex-col gap-6 bg-white/80 backdrop-blur-lg p-6 rounded-3xl shadow-2xl">
          <div class="flex-1 flex flex-col rounded-3xl bg-gradient-to-br from-white to-gray-50 overflow-hidden border border-gray-200 shadow-inner">
            <div
              class="flex-1 overflow-y-auto p-6 md:p-8 space-y-6"
              id="messages-container"
              phx-hook="ScrollToBottom"
            >
              <%= if Enum.empty?(@messages) do %>
                <div class="flex h-full flex-col items-center justify-center text-center animate-in fade-in zoom-in duration-500">
                  <div class="mb-8 flex h-28 w-28 items-center justify-center rounded-[2rem] bg-gradient-to-br from-blue-500/10 to-indigo-500/10 shadow-inner group transition-all duration-500 hover:scale-105">
                    <.icon name="hero-sparkles" class="h-14 w-14 text-blue-600 animate-pulse" />
                  </div>
                  <h2 class="mb-4 text-3xl font-extrabold text-blue-600 tracking-tight">
                    Welcome to ChatController AI
                  </h2>
                  <p class="mb-8 max-w-lg text-gray-600 text-lg leading-relaxed px-4">
                    Ask me about weather, user information, or fetch data from remote services.
                  </p>
                  <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 w-full max-w-2xl px-4">
                    <button
                      class="text-sm p-4 rounded-2xl bg-white hover:bg-white hover:shadow-lg hover:shadow-blue-500/10 transition-all text-left border border-blue-500/10 hover:border-blue-500/30"
                      phx-click="send_message"
                      phx-value-message="What's the weather in Tokyo?"
                    >
                      <span class="block font-bold text-blue-600 mb-1">Check Weather</span>
                      <span class="text-xs text-gray-500">"What's the weather in Tokyo?"</span>
                    </button>
                    <button
                      class="text-sm p-4 rounded-2xl bg-white hover:bg-white hover:shadow-lg hover:shadow-indigo-500/10 transition-all text-left border border-indigo-500/10 hover:border-indigo-500/30"
                      phx-click="send_message"
                      phx-value-message="Get user info for ID 42"
                    >
                      <span class="block font-bold text-indigo-600 mb-1">User Info</span>
                      <span class="text-xs text-gray-500">"Get user info for ID 42"</span>
                    </button>
                    <button
                      class="text-sm p-4 rounded-2xl bg-white hover:bg-white hover:shadow-lg hover:shadow-purple-500/10 transition-all text-left border border-purple-500/10 hover:border-purple-500/30"
                      phx-click="send_message"
                      phx-value-message="Fetch data from https://jsonplaceholder.typicode.com/posts/1"
                    >
                      <span class="block font-bold text-purple-600 mb-1">Fetch Data</span>
                      <span class="text-xs text-gray-500">"Fetch remote data"</span>
                    </button>
                  </div>
                </div>
              <% else %>
                <div class="space-y-8 pb-4">
                  <%= for message <- @messages do %>
                    <div class={[
                      "flex w-full group animate-in slide-in-from-bottom-4 duration-300",
                      if(message.role == :user, do: "justify-end", else: "justify-start")
                    ]}>
                      <div class={[
                        "flex flex-col gap-2 max-w-[85%] md:max-w-[70%]",
                        if(message.role == :user, do: "items-end", else: "items-start")
                      ]}>
                        <div class={[
                          "rounded-[2rem] px-6 py-4 transition-all duration-200",
                          if(message.role == :user,
                            do:
                              "bg-gradient-to-br from-blue-500 to-indigo-600 text-white shadow-lg rounded-tr-none",
                            else:
                              "bg-white border border-gray-200 shadow-md rounded-tl-none hover:border-blue-300"
                          )
                        ]}>
                          <div class="whitespace-pre-wrap text-[15px] leading-relaxed font-medium">
                            {message.content}
                          </div>
                        </div>
                        <span class="text-[10px] font-bold uppercase tracking-widest text-gray-400 px-2">
                          {if(message.role == :user, do: "You", else: "AI Assistant")} • {Calendar.strftime(
                            message.timestamp,
                            "%H:%M"
                          )}
                        </span>
                      </div>
                    </div>
                  <% end %>

                  <%= if @loading do %>
                    <div class="flex justify-start animate-in fade-in duration-300">
                      <div class="flex flex-col gap-2">
                        <div class="rounded-[2rem] rounded-tl-none bg-white px-6 py-5 border border-gray-200">
                          <div class="flex flex-col gap-3">
                            <div class="flex space-x-1.5 items-center">
                              <div
                                class="h-1.5 w-1.5 animate-bounce rounded-full bg-blue-500/40"
                                style="animation-delay: 0ms"
                              >
                              </div>
                              <div
                                class="h-1.5 w-1.5 animate-bounce rounded-full bg-blue-500/60"
                                style="animation-delay: 150ms"
                              >
                              </div>
                              <div
                                class="h-1.5 w-1.5 animate-bounce rounded-full bg-blue-500/80"
                                style="animation-delay: 300ms"
                              >
                              </div>
                            </div>
                            <p class="text-sm font-medium text-gray-600">Thinking...</p>
                          </div>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>

              <%= if @error do %>
                <div class="mx-auto max-w-md rounded-2xl border-2 border-red-200 bg-red-50 p-4 animate-in shake duration-500">
                  <div class="flex items-center gap-3">
                    <div class="flex-shrink-0 size-10 rounded-xl bg-red-100 flex items-center justify-center">
                      <.icon name="hero-exclamation-triangle" class="h-5 w-5 text-red-600" />
                    </div>
                    <div class="flex-1">
                      <p class="text-sm font-bold text-red-600 leading-tight">{@error}</p>
                    </div>
                    <button
                      phx-click="clear_error"
                      class="p-2 hover:bg-red-100 rounded-lg transition-colors text-red-600"
                    >
                      <.icon name="hero-x-mark" class="h-5 w-5" />
                    </button>
                  </div>
                </div>
              <% end %>
            </div>

            <div class="p-6 bg-white border-t border-gray-200 relative">
              <form phx-submit="send_message" class="flex gap-4 items-end max-w-5xl mx-auto">
                <div class="flex-1 relative group">
                  <input
                    type="text"
                    name="message"
                    value={@input_value}
                    phx-change="update_input"
                    placeholder="Ask a question..."
                    disabled={@loading}
                    class="w-full rounded-2xl border-2 border-gray-300/50 bg-white px-6 py-4 text-base font-medium focus:border-blue-500 focus:outline-none focus:ring-4 focus:ring-blue-500/20 transition-all placeholder:text-gray-400 disabled:opacity-50"
                    autocomplete="off"
                  />
                  <div class="absolute right-4 top-1/2 -translate-y-1/2 flex items-center gap-2">
                    <span class="hidden md:inline text-[10px] font-bold text-gray-400 bg-gray-100 px-2 py-1 rounded-md uppercase tracking-wider">
                      Press Enter
                    </span>
                  </div>
                </div>
                <button
                  type="submit"
                  disabled={@loading || String.trim(@input_value) == ""}
                  class="flex h-[58px] w-[58px] items-center justify-center rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 text-white shadow-lg shadow-blue-500/20 hover:shadow-blue-500/40 hover:scale-105 active:scale-95 transition-all duration-200 disabled:opacity-50 disabled:grayscale disabled:scale-100"
                >
                  <.icon
                    name="hero-paper-airplane"
                    class="h-6 w-6 transform rotate-45 -translate-x-0.5"
                  />
                </button>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
