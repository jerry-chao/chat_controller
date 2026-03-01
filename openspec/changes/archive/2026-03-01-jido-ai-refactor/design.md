## Context

The project currently implements a custom Jido-style AI orchestration using ReqLLM. This includes:
- Custom `ChatAgent` GenServer managing chat sessions
- Custom orchestration flow (ModelStep → ToolStep → CompletionStep)
- ReqLLM Tool definitions with callback-based approach

The jido_ai 2.0.0-rc.0 package provides official agent runtime with:
- `Jido.AI.Agent` behavior for agent definitions
- `Jido.Action` behavior for typed tools with Zod-like schemas
- Built-in reasoning strategies (ReAct, CoT, AoT, ToT, GoT, TRM, Adaptive)
- Request handles with `ask/await` for concurrent safety
- `Jido.AI.Observe` for observability

## Goals / Non-Goals

**Goals:**
1. Replace custom orchestration with jido_ai official agent system
2. Convert existing tools to Jido.Action modules with typed schemas
3. Maintain existing functionality (weather, user info, HTTP fetch tools)
4. Add support for multiple reasoning strategies
5. Enable production observability via built-in telemetry

**Non-Goals:**
1. Change the chat UI or user experience
2. Add new AI capabilities beyond current tools
3. Migrate the database schema
4. Support additional LLM providers (beyond current OpenAI/Ollama)

## Decisions

### Decision 1: Use Jido.AI.Agent over custom GenServer

**Choice:** Use `Jido.AI.Agent` behavior for the chat agent.

**Rationale:** 
- Built-in request handles prevent concurrent result overwrites
- Proper lifecycle management (start, stop, state)
- Works with Jido.AgentServer for distributed deployments
- Maintains compatibility with the existing `ask_sync` interface

**Alternative Considered:** Keep GenServer but delegate to jido_ai internally.
- Rejected because it adds complexity without benefits.

### Decision 2: Convert Tools to Jido.Action modules

**Choice:** Create separate Action modules for each tool.

**Rationale:**
- Compile-time safety with typed schemas (Zoi)
- Consistent with jido_ai ecosystem patterns
- Better error messages and validation

**Alternative Considered:** Use adapter pattern to wrap existing ReqLLM.Tools.
- Rejected because it adds indirection without benefit.

### Decision 3: Keep LLM wrapper module

**Choice:** Keep `ChatController.AI.LLM` module but integrate with jido_ai's provider system.

**Rationale:**
- Maintains configuration consistency with existing app config
- Provides a migration path rather than big-bang replacement
- Allows gradual transition if needed

**Alternative Considered:** Remove LLM module entirely and use jido_ai directly.
- Rejected for gradual migration benefits.

### Decision 4: Default to ReAct strategy

**Choice:** Use `Jido.AI.Agent` (ReAct) as the default strategy.

**Rationale:**
- It's the default for tool-calling agents
- Matches current behavior (tool usage loop)
- Well-suited for chat with tools

**Alternative Considered:** Use CoT for more explicit reasoning.
- Rejected: Current tool-calling behavior works well with ReAct.

## Risks / Trade-offs

**Risk:** jido_ai 2.0.0-rc.0 is a release candidate
→ **Mitigation:** Test thoroughly in dev environment before production use. The API is stable per the documentation.

**Risk:** Zoi schema library dependency
→ **Mitigation:** Zoi is a lightweight schema validation library used by jido_ai. Add to deps.

**Risk:** Breaking changes from custom orchestration to jido_ai
→ **Mitigation:** Maintain the same public API (`ask_sync/3`) for backward compatibility with LiveView.

**Risk:** Migration complexity
→ **Mitigation:** Incremental migration - add jido_ai deps first, create parallel implementation, then switch.

## Migration Plan

1. **Phase 1: Dependency Setup**
   - Add `jido` (~> 2.0) and `jido_ai` (~> 2.0.0-rc.0) to mix.exs
   - Add `zoi` for schema validation
   - Update config with jido_ai model aliases

2. **Phase 2: Action Modules**
   - Create `WeatherAction` with Zoi schema
   - Create `UserInfoAction` with Zoi schema
   - Create `HttpFetchAction` with Zoi schema

3. **Phase 3: Agent Definition**
   - Create `ChatAgent` using `Jido.AI.Agent` behavior
   - Configure tools and system prompt
   - Test with LiveView

4. **Phase 4: Cleanup**
   - Remove custom orchestration code (`lib/chat_controller/ai/jido/`)
   - Update ChatLive if needed

**Rollback:** Keep old implementation in a backup branch or directory until verified.

## Open Questions

1. Should we expose all jido_ai strategies to users, or keep a simple default?
2. Do we need streaming responses (currently not supported)?
3. Should we add Jido.AI.Observe telemetry events to dashboards?
