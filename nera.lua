local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local positions = {
    Vector3.new(57, 3, 30000), Vector3.new(57, 3, 28000),
    Vector3.new(57, 3, 26000), Vector3.new(57, 3, 24000),
    Vector3.new(57, 3, 22000), Vector3.new(57, 3, 20000),
    Vector3.new(57, 3, 18000), Vector3.new(57, 3, 16000),
    Vector3.new(57, 3, 14000), Vector3.new(57, 3, 12000),
    Vector3.new(57, 3, 10000), Vector3.new(57, 3, 8000),
    Vector3.new(57, 3, 6000), Vector3.new(57, 3, 4000),
    Vector3.new(57, 3, 2000), Vector3.new(57, 3, 0),
    Vector3.new(57, 3, -2000), Vector3.new(57, 3, -4000),
    Vector3.new(57, 3, -6000), Vector3.new(57, 3, -8000),
    Vector3.new(57, 3, -10000), Vector3.new(57, 3, -12000),
    Vector3.new(57, 3, -14000), Vector3.new(57, 3, -16000),
    Vector3.new(57, 3, -18000), Vector3.new(57, 3, -20000),
    Vector3.new(57, 3, -22000), Vector3.new(57, 3, -24000),
    Vector3.new(57, 3, -26000), Vector3.new(57, 3, -28000),
    Vector3.new(57, 3, -30000), Vector3.new(57, 3, -32000),
    Vector3.new(57, 3, -34000), Vector3.new(57, 3, -36000),
    Vector3.new(57, 3, -38000), Vector3.new(57, 3, -40000),
    Vector3.new(57, 3, -42000), Vector3.new(57, 3, -44000),
    Vector3.new(57, 3, -46000), Vector3.new(57, 3, -48000),
    Vector3.new(-434, 3, -48998)
}

local WaitTime = 0.9
local BDWaitTime = 0.9

local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

local BondFound = {}
local BondCount = 0

local function TPTo(position)
    pcall(function()
        hrp.CFrame = CFrame.new(position)
    end)
end

local function getSeat()
    local gun = workspace:FindFirstChild("RuntimeItems") and workspace.RuntimeItems:FindFirstChild("MaximGun")
    if not gun then return nil end
    local seat = gun:FindFirstChildWhichIsA("VehicleSeat")
    if not seat then return nil end
    return seat
end

local function SitSeat(seat)
    while true do
        if humanoid.SeatPart and humanoid.SeatPart ~= seat then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        if humanoid.SeatPart ~= seat then
            hrp.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
            task.wait(0.2)
        else
            local weld = seat:FindFirstChild("SeatWeld")
            if weld and weld.Part1 and weld.Part1:IsDescendantOf(player.Character) then
                break
            end
        end
    end
end

local teleportPosition = Vector3.new(57, -5, -9000)
local teleportCount = 10
local delayTime = 0.1

if hrp then
    for i = 1, teleportCount do
        hrp.CFrame = CFrame.new(teleportPosition)
        wait(delayTime)
    end
else
    warn("HumanoidRootPart not found!") -- Debugging message
end

task.spawn(function()
    TPTo(Vector3.new(57, -5, -9000))
    task.wait(1)

    local seat = getSeat()
    if not seat then
        return
    end
    seat.Disabled = false

    SitSeat(seat)

    for i, pos in ipairs(positions) do
        TPTo(pos)
        task.wait(WaitTime)

        -- 2nd position: inject fly.lua
        if i == 2 then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/fly.github.io/refs/heads/main/fly.lua"))()
        end

        -- 3rd position: hide everything
        if i == 3 then
            task.spawn(function()
                local Players = game:GetService("Players")
                local player = Players.LocalPlayer
                local runtimeItems = workspace:FindFirstChild("RuntimeItems")
                local updateInterval = 1

                local function isInRuntimeItems(instance)
                    if not runtimeItems then return false end
                    return instance:IsDescendantOf(runtimeItems)
                end

                local function hideVisuals(instance)
                    if isInRuntimeItems(instance) then return end
                    if instance:IsA("BasePart") then
                        instance.LocalTransparencyModifier = 1
                        instance.CanCollide = false
                    elseif instance:IsA("Decal") or instance:IsA("Texture") then
                        instance.Transparency = 1
                    elseif instance:IsA("Beam") or instance:IsA("Trail") then
                        instance.Enabled = false
                    end
                end

                while true do
                    for _, instance in ipairs(workspace:GetDescendants()) do
                        hideVisuals(instance)
                    end
                    task.wait(updateInterval)
                end
            end)
        end

        if pos == Vector3.new(-434, 3, -48998) then
            task.wait(6)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ewewe514/lowserver.github.io/refs/heads/main/lowserver.lua"))()
        end

        local bonds = workspace.RuntimeItems:GetChildren()
        for _, bond in ipairs(bonds) do
            if bond:IsA("Model") and bond.PrimaryPart and (bond.Name == "Bond" or bond.Name == "Bonds") then
                local bondPos = bond.PrimaryPart.Position
                local wasChecked = false

                for _, storedPos in ipairs(BondFound) do
                    if (bondPos - storedPos).Magnitude < 1 then
                        wasChecked = true
                        break
                    end
                end

                if not wasChecked then
                    table.insert(BondFound, bondPos)
                    BondCount = BondCount + 1
                    -- Teleport 5 blocks under the bond
                    TPTo(bondPos - Vector3.new(0, 5, 0))
                    task.wait(BDWaitTime)
                    TPTo(pos)
                end
            end
        end
    end
end)

task.spawn(function()
    task.wait(2)
    while true do
        task.wait(0.1)
        local items = workspace:WaitForChild("RuntimeItems")
        for _, bond in pairs(items:GetChildren()) do
            if bond:IsA("Model") and bond.Name == "Bond" and bond.PrimaryPart then
                local dist = (bond.PrimaryPart.Position - hrp.Position).Magnitude
                if dist < 100 then
                    game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("RemotePromise"):WaitForChild("Remotes"):WaitForChild("C_ActivateObject"):FireServer(bond)
                end
            end
        end
    end
end)
