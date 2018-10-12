defmodule FCIdentity.IdentifierGenerationTest do
  use FCIdentity.UnitCase, async: true

  alias Commanded.Middleware.Pipeline
  alias FCIdentity.IdentifierGeneration
  alias FCIdentity.DummyCommand

  describe "generate/1" do
    test "if identity value is nil" do
      cmd = %DummyCommand{a: nil}
      pipeline = IdentifierGeneration.generate(%Pipeline{command: cmd, identity: :a})

      assert pipeline.command.a
    end

    test "if identity value is already provided" do
      cmd = %DummyCommand{a: UUID.uuid4()}
      pipeline = IdentifierGeneration.generate(%Pipeline{command: cmd, identity: :a})

      assert pipeline.command.a == cmd.a
    end
  end
end