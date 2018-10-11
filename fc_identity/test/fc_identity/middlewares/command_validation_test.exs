defmodule FCIdentity.CommandValidationTest do
  use FCIdentity.UnitCase, async: true

  alias Commanded.Middleware.Pipeline
  alias FCIdentity.CommandValidation
  alias FCIdentity.{DummyCommand, DummyCommandWithEffectiveKeys}

  describe "validate/1 given command with effective keys" do
    test "when command invalid should halt the pipeline with errors" do
      cmd = %DummyCommandWithEffectiveKeys{effective_keys: [:b]}

      pipeline = CommandValidation.validate(%Pipeline{command: cmd, identity: :a})
      {:error, {:validation_failed, errors}} = Pipeline.response(pipeline)

      assert Pipeline.halted?(pipeline)
      assert has_error(errors, :a, :required)
      assert has_error(errors, :b, :required)
      refute has_error(errors, :c, :required)
    end

    test "when command is valid should not halt pipeline" do
      cmd = %DummyCommandWithEffectiveKeys{
        effective_keys: [:b],
        a: Faker.Lorem.word(),
        b: Faker.Lorem.word()
      }

      pipeline = CommandValidation.validate(%Pipeline{command: cmd, identity: :a})

      assert Pipeline.halted?(pipeline) == false
      refute Pipeline.response(pipeline)
    end
  end

  describe "validate/1 given command without effective keys" do
    test "when command is invalid should halt pipeline with errors" do
      cmd = %DummyCommand{}

      pipeline = CommandValidation.validate(%Pipeline{command: cmd})
      {:error, {:validation_failed, errors}} = Pipeline.response(pipeline)

      assert Pipeline.halted?(pipeline)
      assert has_error(errors, :a, :required)
      assert has_error(errors, :b, :required)
      assert has_error(errors, :c, :required)
    end

    test "when command is valid should not halt pipeline" do
      cmd = %DummyCommand{
        a: Faker.Lorem.word(),
        b: Faker.Lorem.word(),
        c: Faker.Lorem.word()
      }

      pipeline = CommandValidation.validate(%Pipeline{command: cmd})

      assert Pipeline.halted?(pipeline) == false
      refute Pipeline.response(pipeline)
    end
  end
end