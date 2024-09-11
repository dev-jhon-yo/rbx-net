local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Packages.Net)

return Net.CreateDefinitions({
    GetPlayerInventory = Net.Definitions.ServerFunction(),
    GetPlayerEquipped = Net.Definitions.ServerFunction(),

    PlayerInventoryUpdated = Net.Definitions.ServerToClientEvent(),
    PlayerEquippedUpdated = Net.Definitions.ServerToClientEvent(),

    PlayerUnequipItem = Net.Definitions.ClientToServerEvent(),
    PlayerEquipItem = Net.Definitions.ClientToServerEvent(),
})
