defmodule Lightning.KafkaTriggersTest do
  use Lightning.DataCase, async: true

  alias Lightning.KafkaTriggers
  alias Lightning.Workflows.Trigger

  describe ".find_enabled_triggers/0" do
    test "returns enabled kafka triggers" do
      trigger_1 =
        insert(:trigger, type: :kafka, kafka_configuration: %{}, enabled: true)
      trigger_2 =
        insert(:trigger, type: :kafka, kafka_configuration: %{}, enabled: true)
      not_kafka_trigger =
        insert(:trigger, type: :cron, enabled: true)
      not_enabled =
        insert(:trigger, type: :kafka, kafka_configuration: %{}, enabled: false)

      triggers = KafkaTriggers.find_enabled_triggers()

      assert triggers |> contains?(trigger_1)
      assert triggers |> contains?(trigger_2)
      refute triggers |> contains?(not_kafka_trigger)
      refute triggers |> contains?(not_enabled)
    end

    defp contains?(triggers, %Trigger{id: id}) do
      triggers
      |> Enum.any?(& &1.id == id)
    end
  end

  describe ".update_partition_data" do
    setup do
      %{partition: 7, timestamp: 124}
    end

    test "adds data for partition if the trigger has no partition data", %{
      partition: partition,
      timestamp: timestamp
    } do
      trigger = insert(:trigger, kafka_configuration: configuration(%{}))

      trigger
      |> KafkaTriggers.update_partition_data(partition, timestamp)

      trigger
      |> assert_persisted_config(%{"#{partition}" => timestamp})
    end

    test "adds data for partition if partition is new but there is data", %{
      partition: partition,
      timestamp: timestamp
    } do
      trigger = insert(:trigger, kafka_configuration: configuration(%{"3" => 123}))

      trigger
      |> KafkaTriggers.update_partition_data(partition, timestamp)

      trigger
      |> assert_persisted_config(%{
        "3" => 123,
        "#{partition}" => timestamp
      })
    end

    defp configuration(partition_timestamps) do
      # TODO Centralise the generation of config to avoid drift
      %{
        "group_id" => "lightning-1",
        "hosts" => [["host-1", 9092], ["other-host-1", 9093]],
        "partition_timestamps" => partition_timestamps,
        "sasl" => nil,
        "ssl" => false,
        "topics" => ["bar_topic"]
      }
    end

    defp assert_persisted_config(trigger, expected_partition_timestamps) do
      reloaded_trigger = Trigger |> Repo.get(trigger.id)

      %Trigger{
        kafka_configuration: %{
          "partition_timestamps" => partition_timestamps
        } 
      } = reloaded_trigger

      assert partition_timestamps == expected_partition_timestamps
    end
  end
end
