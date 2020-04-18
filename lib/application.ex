defmodule BattleBoxClient.Application do
  use Application

  def start(_type, _args) do
    :ok = BattleBoxClient.ConsoleLogger.attach!()

    children = [
      BattleBoxClient.BotSupervisor
    ]

    opts = [strategy: :one_for_one, name: BattleBox.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
