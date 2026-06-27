-- ============================================
-- Signals.lua — Kingdom Siege
-- Central event bus for creating and retrieving BindableEvents.
-- Side: Shared
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SignalsFolder = ReplicatedStorage:FindFirstChild("Signals")
if not SignalsFolder then
	SignalsFolder = Instance.new("Folder")
	SignalsFolder.Name = "Signals"
	SignalsFolder.Parent = ReplicatedStorage
end

local Signals = {}

-- Retrieve or create a BindableEvent by name
function Signals.Get(name)
	local sig = SignalsFolder:FindFirstChild(name)
	if not sig then
		sig = Instance.new("BindableEvent")
		sig.Name = name
		sig.Parent = SignalsFolder
	end
	return sig
end

return Signals
