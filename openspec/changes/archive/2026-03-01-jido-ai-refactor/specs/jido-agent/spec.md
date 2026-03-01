## ADDED Requirements

### Requirement: Jido.AI.Agent Chat Integration
The system SHALL use Jido.AI.Agent behavior for the chat agent, replacing the custom GenServer implementation.

#### Scenario: Agent starts successfully
- **WHEN** the application starts and ChatAgent is initialized
- **THEN** the Jido.AI.Agent SHALL be registered with Jido.AgentServer

#### Scenario: Ask sync returns response
- **WHEN** `ChatAgent.ask_sync/3` is called with a message
- **THEN** the agent SHALL return a response via the ask/await pattern
- **AND** the response SHALL include the assistant's message text

#### Scenario: Tool calling works
- **WHEN** the user asks about weather or user information
- **THEN** the agent SHALL invoke the appropriate tool
- **AND** return the tool result to the user

### Requirement: Backward Compatibility
The public API of ChatAgent SHALL remain compatible with the existing LiveView integration.

#### Scenario: Same interface
- **WHEN** the LiveView calls `ChatAgent.ask_sync(agent, message, opts)`
- **THEN** it SHALL work identically to the previous implementation
- **AND** return `{:ok, response}` or `{:error, reason}`
