ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Scraphex.Repo, :manual)

Mox.defmock(Scraphex.HttpClientMock, for: Scraphex.Http.Client)
