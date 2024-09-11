local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Remotes)

Remotes.Client:Get("PlayerEquipItem"):SendToServer("Hey!")