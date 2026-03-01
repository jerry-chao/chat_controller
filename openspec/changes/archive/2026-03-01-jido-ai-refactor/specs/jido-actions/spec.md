## ADDED Requirements

### Requirement: Weather Action
The system SHALL provide a WeatherAction using Jido.Action behavior.

#### Scenario: Weather action schema
- **WHEN** the WeatherAction is loaded
- **THEN** it SHALL have a Zoi schema with required `city` parameter (string)

#### Scenario: Weather action execution
- **WHEN** the action is called with valid city
- **THEN** it SHALL return weather data including temperature, condition, humidity, wind_speed

### Requirement: UserInfo Action
The system SHALL provide a UserInfoAction using Jido.Action behavior.

#### Scenario: UserInfo action schema
- **WHEN** the UserInfoAction is loaded
- **THEN** it SHALL have a Zoi schema with required `user_id` parameter (integer)

#### Scenario: UserInfo action execution
- **WHEN** the action is called with valid user_id
- **THEN** it SHALL return user data including id, name, email, role, created_at

### Requirement: HttpFetch Action
The system SHALL provide an HttpFetchAction using Jido.Action behavior.

#### Scenario: HttpFetch action schema
- **WHEN** the HttpFetchAction is loaded
- **THEN** it SHALL have a Zoi schema with required `url` parameter (string) and optional `method` parameter (string)

#### Scenario: HttpFetch action execution
- **WHEN** the action is called with a valid URL
- **THEN** it SHALL fetch data from the URL (whitelisted to jsonplaceholder.typicode.com)
- **AND** return the response data

#### Scenario: HttpFetch security
- **WHEN** the action is called with a non-whitelisted URL
- **THEN** it SHALL return mock data (matching existing behavior)
