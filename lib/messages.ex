defmodule BattleBoxClient.Messages do
  def auth(token, lobby) do
    encode(%{"token" => token, "lobby" => lobby})
  end

  def accept_game(%{"game_id" => game_id}) do
    encode(%{"action" => "accept_game", "game_id" => game_id})
  end

  def commands(request_id, commands) do
    encode(%{
      "action" => "send_commands",
      "request_id" => request_id,
      "commands" => commands
    })
  end

  def start_matchmaking do
    encode(%{"action" => "start_match_making"})
  end

  defmacro game_request(game_info) do
    quote do
      %{
        "request_type" => "game_request",
        "game_info" => unquote(game_info)
      }
    end
  end

  defmacro commands_request(game_id, request_id, game_state) do
    quote do
      %{
        "request_type" => "commands_request",
        "commands_request" => %{
          "request_id" => unquote(request_id),
          "game_id" => unquote(game_id),
          "game_state" => unquote(game_state)
        }
      }
    end
  end

  defmacro status(status) do
    quote do
      %{"status" => unquote(status)}
    end
  end

  defmacro status(status, bot_server_id) do
    quote do
      %{"status" => unquote(status), "bot_server_id" => unquote(bot_server_id)}
    end
  end

  defmacro bot_instance_failure do
    quote do
      %{"error" => "bot_instance_failure"}
    end
  end

  defmacro invalid_msg_sent do
    quote do
      %{"error" => "invalid_msg_sent"}
    end
  end

  defmacro game_over(game_id, winner) do
    quote do
      %{
        "info" => "game_over",
        "result" => %{"game_id" => unquote(game_id), "winner" => unquote(winner)}
      }
    end
  end

  defmacro game_cancelled(game_id) do
    quote do
      %{"game_id" => unquote(game_id), "info" => "game_cancelled"}
    end
  end

  defp encode(msg) do
    Jason.encode!(msg)
  end
end
