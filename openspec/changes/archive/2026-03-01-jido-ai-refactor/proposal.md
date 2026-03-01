## Why

The project currently uses a custom Jido-style orchestration pattern built on top of ReqLLM for AI agent functionality. While this works, it lacks the official Jido ecosystem benefits: proper agent lifecycle management, built-in reasoning strategies (ReAct, CoT, ToT, etc.), model routing, retries, and observability. The jido_ai 2.0.0-rc.0 release provides a mature, production-ready AI runtime that should replace the custom implementation.

## What Changes

- Replace custom `Orchestration` module with jido_ai's official agent system
- Convert `Tools` module to use `Jido.Action` behavior for typed tool definitions
- Replace `ChatAgent` GenServer with `Jido.AI.Agent` for proper agent lifecycle management
- Add support for multiple reasoning strategies (ReAct, CoT, AoT, ToT, GoT, TRM, Adaptive)
- Leverage built-in model routing and retry mechanisms
- Enable production observability via `Jido.AI.Observe` telemetry
- Remove custom orchestration code (model_step, tool_step, completion_step)
- Keep the LLM wrapper for provider abstraction but integrate with jido_ai's req_llm

## Capabilities

### New Capabilities
- `jido-agent`: Full jido_ai agent integration with ReAct strategy (default)
- `jido-strategies`: Support for multiple reasoning strategies (CoT, AoT, ToT, GoT, TRM, Adaptive)
- `jido-actions`: Convert existing tools to Jido.Action modules with typed schemas
- `jido-observability`: Built-in telemetry for production monitoring

### Modified Capabilities
- `ai-chat`: Modified to use jido_ai agent instead of custom orchestration

## Impact

- **Dependencies**: Add `jido_ai` (~> 2.0.0-rc.0) and `jido` (~> 2.0) to mix.exs
- **Code Changes**: 
  - New: `lib/chat_controller/ai/jido_ai/weather_action.ex`
  - New: `lib/chat_controller/ai/jido_ai/user_info_action.ex`
  - New: `lib/chat_controller/ai/jido_ai/http_fetch_action.ex`
  - New: `lib/chat_controller/ai/jido_ai/chat_agent.ex` (replaces current)
  - Removed: `lib/chat_controller/ai/jido/` (custom orchestration)
  - Modified: `lib/chat_controller/ai/chat_agent.ex` (delegate to jido_ai)
- **Configuration**: Update config for jido_ai model aliases and provider credentials
