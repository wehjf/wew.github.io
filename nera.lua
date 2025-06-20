local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")

local maximGunTP = Vector3.new(57, -5, -9000)
local afterHorseTP = Vector3.new(57, 7, 30000) -- updated destination

local pathPoints = {
    Vector3.new(13.66, 20, 29620.67),
    Vector3.new(-15.98, 20, 28227.97),
    Vector3.new(-63.54, 20, 26911.59),
    Vector3.new(-15.98, 20, 28227.97),
    Vector3.new(-75.71, 20, 25558.11),
    Vector3.new(-49.51, 20, 24038.67),
    Vector3.new(-34.48, 20, 22780.89),
    Vector3.new(-63.71, 20, 21477.32),
    Vector3.new(-84.23, 20, 19970.94),
    Vector3.new(-84.76, 20, 18676.13),
    Vector3.new(-87.32, 20, 17246.92),
    Vector3.new(-95.48, 20, 15988.29),
    Vector3.new(-93.76, 20, 14597.43),
    Vector3.new(-86.29, 20, 13223.68),
    Vector3.new(-97.56, 20, 11824.61),
    Vector3.new(-92.71, 20, 10398.51),
    Vector3.new(-98.43, 20, 9092.45),
    Vector3.new(-90.89, 20, 7741.15),
    Vector3.new(-86.46, 20, 6482.59),
    Vector3.new(-77.49, 20, 5081.21),
    Vector3.new(-73.84, 20, 3660.66),
    Vector3.new(-73.84, 20, 2297.51),
    Vector3.new(-76.56, 20, 933.68),
    Vector3.new(-81.48, 20, -429.93),
    Vector3.new(-83.47, 20, -1683.45),
    Vector3.new(-94.18, 20, -3035.25),
    Vector3.new(-109.96, 20, -4317.15),
    Vector3.new(-119.63, 20, -5667.43),
    Vector3.new(-118.63, 20, -6942.88),
    Vector3.new(-118.09, 20, -8288.66),
    Vector3.new(-132.12, 20, -9690.39),
    Vector3.new(-122.83, 20, -11051.38),
    Vector3.new(-117.53, 20, -12412.74),
    Vector3.new(-119.81, 20, -13762.14),
    Vector3.new(-126.27, 20, -15106.33),
    Vector3.new(-134.45, 20, -16563.82),
    Vector3.new(-129.85, 20, -17884.73),
    Vector3.new(-127.23, 20, -19234.89),
    Vector3.new(-133.49, 20, -20584.07),
    Vector3.new(-137.89, 20, -21933.47),
    Vector3.new(-139.93, 20, -23272.51),
    Vector3.new(-144.12, 20, -24612.54),
    Vector3.new(-142.93, 20, -25962.13),
    Vector3.new(-149.21, 20, -27301.58),
    Vector3.new(-156.19, 20, -28640.93),
    Vector3.new(-164.87, 20, -29990.78),
    Vector3.new(-177.65, 20, -31340.21),
    Vector3.new(-184.67, 20, -32689.24),
    Vector3.new(-208.92, 20, -34027.44),
    Vector3.new(-227.96, 20, -35376.88),
    Vector3.new(-239.45, 20, -36726.59),
    Vector3.new(-250.48, 20, -38075.91),
    Vector3.new(-260.28, 20, -39425.56),
    Vector3.new(-274.86, 20, -40764.67),
    Vector3.new(-297.45, 20, -42103.61),
    Vector3.new(-321.64, 20, -43442.59),
    Vector3.new(-356.78, 20, -44771.52),
    Vector3.new(-387.68, 20, -46100.94),
    Vector3.new(-415.83, 20, -47429.85),
    Vector3.new(-452.39, 20, -49407.44),
}

local tpInterval = 0.8
local horseScanInterval = 0.15
local retryDelay = 20

local runtimeItems = Workspace:FindFirstChild("RuntimeItems")
local radius = 2000
local updateInterval = 1
local hideLoopStarted = false
local hideLoopShouldRun = true
local showLoopStarted = false

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

local hideLoopThread = nil
local function startHideLoop()
    if hideLoopStarted then return end
    hideLoopStarted = true
    hideLoopShouldRun = true
    hideLoopThread = task.spawn(function()
        while hideLoopShouldRun do
            for _, instance in ipairs(Workspace:GetDescendants()) do
                hideVisuals(instance)
            end
            task.wait(updateInterval)
        end
    end)
end

local function stopHideLoop()
    hideLoopShouldRun = false
end

local function showVisuals()
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local origin = character.HumanoidRootPart.Position
        for _, instance in ipairs(Workspace:GetDescendants()) do
            if instance:IsA("BasePart") and (instance.Position - origin).Magnitude <= radius then
                instance.LocalTransparencyModifier = 0
                instance.CanCollide = true
            elseif (instance:IsA("Decal") or instance:IsA("Texture")) and instance:IsDescendantOf(Workspace) then
                local parent = instance.Parent
                if parent and parent:IsA("BasePart") and (parent.Position - origin).Magnitude <= radius then
                    instance.Transparency = 0
                end
            elseif (instance:IsA("Beam") or instance:IsA("Trail")) and instance:IsDescendantOf(Workspace) then
                local parent = instance.Parent
                if parent and parent:IsA("BasePart") and (parent.Position - origin).Magnitude <= radius then
                    instance.Enabled = true
                end
            end
        end
    end
end

local function startShowLoop()
    if showLoopStarted then return end
    showLoopStarted = true
    task.spawn(function()
        while true do
            showVisuals()
            task.wait(updateInterval)
        end
    end)
end

local function getSackCount()
    local character = player.Character
    local sack = character and character:FindFirstChild("Sack") or player.Backpack:FindFirstChild("Sack")
    if sack then
        local label = sack:FindFirstChild("BillboardGui") and sack.BillboardGui:FindFirstChild("TextLabel")
        if label and label.Text then
            local current = tonumber(label.Text:match("^(%d+)/"))
            return current
        end
    end
    return nil
end

local function destroyBookcases()
    local castle = Workspace:FindFirstChild("VampireCastle")
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
    local runtime = Workspace:FindFirstChild("RuntimeItems")
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

-- Optimized: Only search for horses in the Animals folder
local function findHorse()
    local animalsFolder = Workspace:FindFirstChild("Baseplates")
        and Workspace.Baseplates:FindFirstChild("Baseplate")
        and Workspace.Baseplates.Baseplate:FindFirstChild("CenterBaseplate")
        and Workspace.Baseplates.Baseplate.CenterBaseplate:FindFirstChild("Animals")
    if not animalsFolder then return nil, nil end
    for _, obj in ipairs(animalsFolder:GetChildren()) do
        if obj:IsA("Model") and obj.Name == "Model_Horse" then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                return obj, part.Position
            end
        end
    end
    return nil, nil
end

local function claimHorseLoop(model)
    local lastPos = nil
    local storeTries = 0
    while model and model.Parent do
        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
        if not part then break end
        local pos = part.Position
        if not lastPos or (pos - lastPos).Magnitude > 2 then
            hrp.CFrame = CFrame.new(pos.X, pos.Y + 4, pos.Z)
            lastPos = pos
        end
        humanoid.Jump = true
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("StoreItem"):FireServer(model)
        storeTries = storeTries + 1
        task.wait(0.15)
        if getSackCount() == 1 then
            return pos, true
        end
        if storeTries >= 5 then
            return pos, false
        end
    end
    return lastPos, false
end

local function startRoutine()
    local seat
    while true do
        hrp.CFrame = CFrame.new(maximGunTP)
        task.wait(0.5)
        seat = getMaximGunSeat()
        if seat then
            seat.Disabled = false
            sitAndJumpOutSeat(seat)
            break
        else
            task.wait(1)
        end
    end

    while true do
        local horseClaimed = false
        local horseLastPos
        local horseClaimSuccess = false
        for i, pt in ipairs(pathPoints) do
            hrp.CFrame = CFrame.new(pt)
            if i == 1 then
                task.spawn(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/fly.github.io/refs/heads/main/fly.lua"))()
                end)
            end
            if i == 2 then
                startHideLoop()
            end
            local t0 = tick()
            while tick() - t0 < tpInterval do
                local model, pos = findHorse()
                if model and pos then
                    stopHideLoop()
                    startShowLoop()
                    horseLastPos, horseClaimSuccess = claimHorseLoop(model)
                    horseClaimed = true
                    break
                end
                task.wait(horseScanInterval)
            end
            if horseClaimed then break end
        end
        if horseClaimed and horseLastPos then
            task.wait(2)
            hrp.CFrame = CFrame.new(horseLastPos.X, horseLastPos.Y + 80, horseLastPos.Z)
            task.wait(2)
            hrp.CFrame = afterHorseTP
            return
        else
            task.wait(retryDelay)
        end
    end
end

startRoutine()


local function UseSack()
    local sack = plr.Backpack:FindFirstChild("Sack")
    if sack then
        character:WaitForChild("Humanoid"):EquipTool(sack)
        return true
    end
    return false
end

task.spawn(function()
    task.wait(4)
    UseSack()
end)

startRoutine()
