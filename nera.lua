local Players, Workspace, ReplicatedStorage = game:GetService("Players"), game:GetService("Workspace"), game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer
local character = plr.Character or plr.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid")

local maximGunTP = Vector3.new(57, -5, -9000)
local afterHorseTP = Vector3.new(147, 10, 29928)
local tpInterval, horseScanInterval, retryDelay = 2, 0.15, 20

local horseSearchLocations = {
    Vector3.new(-119.63, 20, -5667.43),
    Vector3.new(-118.63, 20, -6942.88),
    Vector3.new(-118.09, 20, -8288.66),
    Vector3.new(-132.12, 20, -9690.39),
    Vector3.new(-122.83, 20, -11051.38),
    Vector3.new(-117.53, 20, -12412.74),
    Vector3.new(-129.85, 20, -17884.73),
    Vector3.new(-127.23, 20, -19234.89),
    Vector3.new(-133.49, 20, -20584.07),
}

local function findAnyHorse()
    -- Returns ANY Model_Horse regardless of parent or outlaws/anything
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and obj.Name == "Model_Horse" then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                return obj, part.Position
            end
        end
    end
    local animals = Workspace:FindFirstChild("Baseplates")
    animals = animals and animals:FindFirstChild("Baseplate")
    animals = animals and animals:FindFirstChild("CenterBaseplate")
    animals = animals and animals:FindFirstChild("Animals")
    if animals then
        for _, obj in ipairs(animals:GetChildren()) do
            if obj:IsA("Model") and obj.Name == "Model_Horse" then
                local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    return obj, part.Position
                end
            end
        end
    end
    return nil, nil
end

local function getSackCount()
    local c = plr.Character
    local s = c and c:FindFirstChild("Sack") or plr.Backpack:FindFirstChild("Sack")
    local l = s and s:FindFirstChild("BillboardGui") and s.BillboardGui:FindFirstChild("TextLabel")
    return l and tonumber(l.Text:match("^(%d+)/")) or nil
end

local function destroyBookcases()
    local castle = Workspace:FindFirstChild("VampireCastle")
    if castle then
        for _, d in ipairs(castle:GetDescendants()) do
            if d:IsA("Model") and d.Name == "Bookcase" then d:Destroy() end
        end
    end
end

local function getMaximGunSeat()
    destroyBookcases()
    local ri = Workspace:FindFirstChild("RuntimeItems")
    for _, g in ipairs(ri and ri:GetChildren() or {}) do
        if g.Name == "MaximGun" then
            return g:FindFirstChildWhichIsA("VehicleSeat")
        end
    end
end

local function ensureSeatedInMaximGun()
    local seat = getMaximGunSeat()
    if seat and humanoid.SeatPart ~= seat then
        repeat
            hrp.CFrame = seat.CFrame
            seat.Disabled = false
            task.wait(0.1)
        until humanoid.SeatPart == seat or not seat.Parent
    end
end

local function sitAndJumpOutSeat(seat)
    local jumped = false
    while true do
        if humanoid.SeatPart ~= seat then
            hrp.CFrame = seat.CFrame; task.wait(0.1)
        else
            local weld = seat:FindFirstChild("SeatWeld")
            if weld and weld.Part1 and weld.Part1:IsDescendantOf(plr.Character) then
                if not jumped then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.15)
                    hrp.CFrame = seat.CFrame
                    jumped = true
                else break end
            end
        end
    end
end

local function claimHorseLoop(model, doMaximGunLoop)
    local lastPos, storeTries = nil, 0
    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not model or not part then
        return nil, false
    end
    while model and part do
        if doMaximGunLoop then ensureSeatedInMaximGun() end
        local pos = part.Position
        -- Only allow max 4 blocks above the horse to attempt storing
        if math.abs(hrp.Position.Y - pos.Y) > 4 then
            hrp.CFrame = CFrame.new(pos.X, pos.Y + 4, pos.Z)
        else
            hrp.CFrame = CFrame.new(pos.X, hrp.Position.Y, pos.Z)
        end
        lastPos = pos
        humanoid.Jump = true
        ReplicatedStorage.Remotes.StoreItem:FireServer(model)
        storeTries = storeTries + 1
        task.wait(0.15)
        if getSackCount() == 1 then return pos, true end
        if storeTries >= 5 then return pos, false end
    end
    return lastPos, false
end

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

local function robustAfterHorseTP()
    local stayStart = nil
    while true do
        hrp.CFrame = CFrame.new(afterHorseTP)
        if (hrp.Position - afterHorseTP).Magnitude < 10 then
            if not stayStart then
                stayStart = tick()
            elseif tick() - stayStart >= 1 then
                break
            end
        else
            stayStart = nil
        end
        task.wait(0.1)
    end
end

local function searchHorseAtLocations()
    -- Start fly at the first location
    local firstLoc = horseSearchLocations[1]
    hrp.CFrame = CFrame.new(firstLoc.X, 50, firstLoc.Z)
    task.wait(0.5)
    -- Start fly script ONCE at the first search location
    task.spawn(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/fly.github.io/refs/heads/main/fly.lua"))()
    end)
    for idx, loc in ipairs(horseSearchLocations) do
        if idx ~= 1 then
            hrp.CFrame = CFrame.new(loc.X, 50, loc.Z)
            task.wait(2)
        end
        local horseModel, horsePos = findAnyHorse()
        if horseModel and horsePos then
            return horseModel, horsePos
        end
    end
    return nil, nil
end

local function startRoutine()
    -- Step 1: Maxim Gun sit/jump logic
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

    -- Step 2: Search for horse at specific locations, starting fly at the first spot
    local horseModel, horsePos = searchHorseAtLocations()
    if not horseModel or not horsePos then
        warn("No valid horse found at any location!")
        return
    end

    -- Step 3: Back-and-forth TP farming
    local horseCFrame = CFrame.new(horsePos.X, 50, horsePos.Z)
    local tpForward = 10000
    local delayTime = 1.5
    for i = 1, 4 do
        if i % 2 == 1 then
            hrp.CFrame = CFrame.new(horsePos.X, 50, horsePos.Z + tpForward)
        else
            hrp.CFrame = horseCFrame
        end
        task.wait(delayTime)
    end
    hrp.CFrame = horseCFrame
    task.wait(0.5)

    -- Step 4: Claim horse with maxim gun seat maintenance
    local horseLastPos, horseClaimed = claimHorseLoop(horseModel, true)
    if horseClaimed and horseLastPos then
        ensureSeatedInMaximGun()
        task.wait(1)
        hrp.CFrame = CFrame.new(horseLastPos.X, horseLastPos.Y + 80, horseLastPos.Z)
        task.wait(2)
        robustAfterHorseTP()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ringtaa/unfly.github.io/refs/heads/main/unfly.lua"))()
    else
        task.wait(retryDelay)
        startRoutine()
    end
end

startRoutine()
