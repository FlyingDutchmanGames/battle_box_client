defmodule BattleBoxClient.ConsoleLogger do
  require Logger

  def attach! do
    :telemetry.attach_many(
      __MODULE__,
      [
        [:battle_box_client, :invalid_token],
        [:battle_box_client, :start_match_making],
        [:battle_box_client, :game_cancelled],
        [:battle_box_client, :completed_commands_request]
      ],
      &handle_event/4,
      nil
    )
  end

  def handle_event([:battle_box_client, event_name], event, metadata, _config) do
    case event_name do
      :invalid_token ->
        Logger.error(
          "Unable to start bot in lobby: \"#{metadata.lobby}\", token: \"#{metadata.token}\" is invalid"
        )

      :start_match_making ->
        Logger.info(
          "Bot Server \"#{metadata.bot_server_id}\": started match making in lobby \"#{
            metadata.lobby
          }\""
        )

      :game_cancelled ->
        Logger.warn(
          "Bot Server: \"#{metadata.bot_server_id}\": game \"#{metadata.game_info["game_id"]}\" cancelled"
        )

      :completed_commands_request ->
        time = System.convert_time_unit(event.time, :native, :microsecond)

        Logger.info(
          "Bot Server: \"#{metadata.bot_server_id}\": completed commands request in #{time} microseconds using logic: \"#{
            inspect(metadata.logic)
          }\""
        )

      :bot_instance_failure ->
        Logger.error(
          "Bot Server: \"#{metadata.bot_server_id}\" Bot instace failure! Check Server Logs"
        )
    end
  end
end
