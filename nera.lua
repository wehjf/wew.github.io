local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")

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

-- Fire remote for all bonds within 15 studs, always running in background
task.spawn(function()
    task.wait(2)
    while true do
        task.wait(0.1)
        local items = workspace:WaitForChild("RuntimeItems")
        for _, bond in pairs(items:GetChildren()) do
            if bond:IsA("Model") and (bond.Name == "Bond" or bond.Name == "Bonds") and bond.PrimaryPart then
                local dist = (bond.PrimaryPart.Position - hrp.Position).Magnitude
                if dist < 15 then
                    ReplicatedStorage.Shared.Network.RemotePromise.Remotes.C_ActivateObject:FireServer(bond)
                end
            end
        end
    end
end)

-- Main farm loop
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

        -- Only move on when ALL bonds are collected at this position
        while true do
            local allGone = true
            local bonds = workspace:FindFirstChild("RuntimeItems") and workspace.RuntimeItems:GetChildren() or {}
            for _, bond in ipairs(bonds) do
                if bond:IsA("Model") and (bond.Name == "Bond" or bond.Name == "Bonds") and bond.PrimaryPart then
                    local dist = (bond.PrimaryPart.Position - hrp.Position).Magnitude
                    if dist >= 15 then
                        -- TP directly under bond if it's far away, don't TP back
                        TPTo(bond.PrimaryPart.Position - Vector3.new(0, 5, 0))
                        task.wait(0.2)
                        allGone = false
                        break -- after each TP, re-check all bonds
                    elseif dist < 15 then
                        -- Near bond: let remote spammer handle it, do not TP
                        allGone = false
                    end
                end
            end
            if allGone then break end
            task.wait(0.2)
        end

        if pos == Vector3.new(-434, 3, -48998) then
            task.wait(6)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ewewe514/lowserver.github.io/refs/heads/main/lowserver.lua"))()
        end
    end
end)

-- Hide visuals function (unchanged)
function startHideLoop()
    task.spawn(function()
        while true do
            for _, instance in ipairs(workspace:GetDescendants()) do
                if instance:IsA("BasePart") then
                    instance.LocalTransparencyModifier = 1
                    instance.CanCollide = false
                elseif instance:IsA("Decal") or instance:IsA("Texture") then
                    instance.Transparency = 1
                elseif instance:IsA("Beam") or instance:IsA("Trail") then
                    instance.Enabled = false
                end
            end
            task.wait(1)
        end
    end)
end
