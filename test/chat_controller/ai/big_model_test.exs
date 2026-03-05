defmodule ChatController.AI.BigModelTest do
  use ExUnit.Case, async: true

  alias ChatController.AI.BigModel

  describe "provider configuration" do
    test "has correct provider id" do
      assert BigModel.provider_id() == :bigmodel
    end

    test "has correct default base url" do
      assert BigModel.default_base_url() == "https://open.bigmodel.cn/api/paas/v4"
    end

    test "has correct default env key" do
      assert BigModel.default_env_key() == "BIGMODEL_API_KEY"
    end
  end

  describe "OpenAI compatibility" do
    test "implements required Provider callbacks" do
      functions = BigModel.__info__(:functions) |> Keyword.keys()

      assert :prepare_request in functions
      assert :attach in functions
      assert :encode_body in functions
      assert :decode_response in functions
      assert :attach_stream in functions
      assert :decode_stream_event in functions
    end

    test "uses Provider.Defaults for standard behavior" do
      functions = BigModel.__info__(:functions)

      assert Keyword.has_key?(functions, :extract_usage)
      assert Keyword.has_key?(functions, :translate_options)
    end

    test "provider schema is empty (no custom options)" do
      schema = BigModel.provider_schema()
      assert %NimbleOptions{schema: []} = schema
    end
  end
end
