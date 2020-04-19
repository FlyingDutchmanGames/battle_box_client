defmodule BattleBoxClient.Games.RobotGame.ShelterInPlace do
  def make_commands(%{"robots" => robots}, %{"player" => player}) do
    robots
    |> Enum.filter(fn robot -> robot["player_id"] == player end)
    |> Enum.map(fn robot ->
      %{
        "type" => "guard",
        "robot_id" => robot["id"],
      }
    end)
  end
end
