## ADDED Requirements

### Requirement: ReAct Strategy Support
The system SHALL use ReAct (Reasoning + Acting) as the default strategy for tool-using agents.

#### Scenario: Default strategy is ReAct
- **WHEN** a ChatAgent is started without specifying a strategy
- **THEN** it SHALL use Jido.AI.Agent (ReAct) by default

#### Scenario: Tool reasoning loop
- **WHEN** the model generates a tool call
- **THEN** the agent SHALL execute the tool
- **AND** add the result back to the context
- **AND** continue the reasoning loop until a final response

### Requirement: Strategy Configuration
The system SHALL allow configuration of different reasoning strategies.

#### Scenario: Strategy can be configured
- **WHEN** an agent is defined with a specific strategy
- **THEN** the agent SHALL use that strategy's reasoning pattern

#### Scenario: Available strategies
- **WHEN** evaluating strategy options
- **THEN** the following strategies SHALL be available: ReAct, CoD, CoT, AoT, ToT, GoT, TRM, Adaptive
