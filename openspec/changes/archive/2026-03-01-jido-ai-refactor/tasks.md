## 1. Dependency Setup

- [x] 1.1 Add jido (~> 2.0) and jido_ai (~> 2.0.0-rc.0) to mix.exs deps
- [x] 1.2 Add zoi to mix.exs deps for schema validation
- [x] 1.3 Update config/config.exs with jido_ai model aliases
- [x] 1.4 Run mix deps.get to install new dependencies
- [x] 1.5 Verify compilation succeeds

## 2. Action Module Creation

- [x] 2.1 Create WeatherAction module with Jido.Action and Zoi schema
- [x] 2.2 Create UserInfoAction module with Jido.Action and Zoi schema
- [x] 2.3 Create HttpFetchAction module with Jido.Action and Zoi schema
- [ ] 2.4 Test Action modules individually in IEx

## 3. Agent Definition

- [x] 3.1 Create ChatAgent module using Jido.AI.Agent behavior
- [x] 3.2 Configure system prompt and default tools
- [x] 3.3 Implement ask_sync/3 function for backward compatibility
- [ ] 3.4 Test agent with manual conversation in IEx

## 4. Integration with LiveView

- [x] 4.1 Update ChatLive to use new ChatAgent
- [ ] 4.2 Test chat functionality through UI
- [ ] 4.3 Verify all three tools (weather, user info, HTTP fetch) work

## 5. Cleanup

- [x] 5.1 Remove custom orchestration directory (lib/chat_controller/ai/jido/)
- [x] 5.2 Remove old ChatAgent if redundant (delegates to new JidoAI.Agent)
- [ ] 5.3 Update README if needed
- [x] 5.4 Run mix precommit to verify code quality

## 6. Verification

- [ ] 6.1 Verify agent starts correctly on app boot
- [ ] 6.2 Test conversation persistence
- [ ] 6.3 Test error handling and edge cases
- [ ] 6.4 Document any behavioral changes
