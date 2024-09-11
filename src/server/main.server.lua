local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Remotes)

Remotes.Server:Get("PlayerEquipItem"):Connect(function(player: Player, text: string)
  print("Received " ..text.. " from" .. player.Name)
end)
