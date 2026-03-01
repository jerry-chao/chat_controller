## MODIFIED Requirements

### Requirement: AI Chat Response
The system SHALL provide AI-powered chat responses using the configured LLM.

#### Scenario: Direct response
- **WHEN** the user asks a general question without tool context
- **THEN** the system SHALL return an AI-generated text response

#### Scenario: Tool-augmented response
- **WHEN** the user's message indicates a tool need (weather, user info, data fetch)
- **THEN** the system SHALL invoke the appropriate tool
- **AND** include the tool result in the final response

### Requirement: Chat Persistence
The system SHALL maintain conversation history in PostgreSQL.

#### Scenario: Message saved
- **WHEN** a user sends a message
- **THEN** the message SHALL be saved to the database with conversation association

#### Scenario: History restored
- **WHEN** a user refreshes the page
- **THEN** previous conversation messages SHALL be restored from the database
