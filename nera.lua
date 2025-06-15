local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")
local chairTP = Vector3.new(57, -5, -9000)

local function isUnanchored(model)
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part.Anchored then return false end
    end
    return true
end

local function findAnyValidChair()
    local runtimeFolder = workspace:FindFirstChild("RuntimeItems")
    if not runtimeFolder then return nil end
    for _, item in pairs(runtimeFolder:GetChildren()) do
        if item:IsA("Model") and item.Name == "Chair" and isUnanchored(item) then
            local seat = item:FindFirstChildWhichIsA("Seat", true)
            if seat and not seat.Occupant then
                return seat
            end
        end
    end
    return nil
end

local function sitAndJumpOutChair(seat)
    -- Returns true if actually sat and jumped, false otherwise
    local jumped = false
    local timeStart = tick()
    while tick() - timeStart < 10 do -- Timeout after 10s to prevent infinite loop if seat broken
        if humanoid.SeatPart ~= seat then
            hrp.CFrame = seat.CFrame
            task.wait(0.1)
        else
            local weld = seat:FindFirstChild("SeatWeld")
            if weld and weld.Part1 and weld.Part1:IsDescendantOf(char) then
                if not jumped then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.2)
                    hrp.CFrame = seat.CFrame
                    jumped = true
                else
                    return true
                end
            end
        end
    end
    return false -- Timed out
end

-- Main: keep trying until success
while true do
    hrp.CFrame = CFrame.new(chairTP)
    task.wait(0.5)
    local seat = findAnyValidChair()
    if seat then
        local success = sitAndJumpOutChair(seat)
        if success then
            break
        end
    end
    task.wait(0.5)
end
