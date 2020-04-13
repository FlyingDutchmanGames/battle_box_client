defmodule BattleBoxClient.BotServer do
  use GenStateMachine, callback_mode: [:handle_event_function], restart: :temporary
  require BattleBoxClient.Messages
  import BattleBoxClient.Messages
  require Logger

  @recieve_buffer_bytes 65536

  def start_link(%{token: _, lobby: _, host: _, port: _, logic: _} = data) do
    data = Map.put_new(data, :transport, :gen_tcp)
    GenStateMachine.start_link(__MODULE__, data)
  end

  def init(%{host: host, port: port} = data) do
    {:ok, socket} =
      data.transport.connect(to_charlist(host), port, [
        :binary,
        active: true,
        packet: 2,
        recbuf: @recieve_buffer_bytes
      ])

    :ok = data.transport.send(socket, auth(data.token, data.lobby))
    data = Map.put(data, :socket, socket)
    {:ok, :authing, data}
  end

  def handle_event(:info, {:tcp_closed, _socket}, state, _data) do
    {:stop, :normal}
  end

  def handle_event(:info, {:tcp_error, _socket, _reason}, state, _data) do
    {:stop, :normal}
  end

  def handle_event(:info, {transport, socket, bytes}, _state, %{socket: socket}) do
    case Jason.decode(bytes) do
      {:ok, msg} -> {:keep_state_and_data, {:next_event, :internal, msg}}
      {:error, %Jason.DecodeError{}} -> :keep_state_and_data
    end
  end

  def handle_event(:internal, status("idle"), _, data) do
    :ok = data.transport.send(data.socket, start_matchmaking())
    {:next_state, :match_making, data}
  end

  def handle_event(:internal, status("match_making"), _, data) do
    :keep_state_and_data
  end

  def handle_event(:internal, invalid_msg_sent(), _state, data) do
    :keep_state_and_data
  end

  def handle_event(:internal, game_request(game_info), :match_making, data) do
    :ok = data.transport.send(data.socket, accept_game(game_info))
    data = Map.merge(data, %{game_info: game_info})
    {:next_state, :playing, data}
  end

  def handle_event(:internal, commands_request(_game_id, request_id, game_state), :playing, data) do
    commands = data.logic.make_commands(game_state, data.game_info)
    :ok = data.transport.send(data.socket, commands(request_id, commands))
    :keep_state_and_data
  end

  def handle_event(:internal, game_over(_game_id, winner), :playing, data) do
    :ok = data.transport.send(data.socket, start_matchmaking)
    data = Map.drop(data, [:game_info])
    {:next_state, :match_making, data}
  end

  def handle_event(:internal, game_cancelled(game_id), _, data) do
    :ok = data.transport.send(data.socket, start_matchmaking())
    data = Map.drop(data, [:game_info])
    {:next_state, :match_making, data}
  end

  def handle_event(:internal, bot_instance_failure(), state, data) do
    {:stop, :normal}
  end
end
