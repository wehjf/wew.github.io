local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

-- Sits on the seat if not already seated
local function sitOnSeat(seat)
    for i = 1, 50 do
        if humanoid.SeatPart ~= seat then
            hrp.CFrame = seat.CFrame * CFrame.new(0, 1, 0)
            seat:Sit(humanoid)
            task.wait(0.1)
        else
            print("Now sitting on seat at:", seat.Position)
            break -- now sitting!
        end
    end
end

for z = 30000, -49032.99, -250 do
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {CFrame = CFrame.new(57, 3, z)}
    )
    tween:Play()
    tween.Completed:Wait()
    local animals = workspace:FindFirstChild("Baseplates")
        and workspace.Baseplates:FindFirstChild("Baseplate")
        and workspace.Baseplates.Baseplate:FindFirstChild("CenterBaseplate")
        and workspace.Baseplates.Baseplate.CenterBaseplate:FindFirstChild("Animals")
    if animals then
        for _, obj in ipairs(animals:GetChildren()) do
            if obj.Name == "Model_Horse" and obj:IsA("Model") then
                local pos
                if obj.GetPivot then
                    pos = obj:GetPivot().Position
                elseif obj.PrimaryPart then
                    pos = obj.PrimaryPart.Position
                end
                print("Passed horse at:", pos)
                local seat = obj:FindFirstChild("VehicleSeat")
                if seat then
                    sitOnSeat(seat)
                end
            end
        end
    end
end
