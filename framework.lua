--// deployment framework:
local deploymentFramework = {}

deploymentFramework.__index = deploymentFramework

--// framework constructors:
function deploymentFramework.new()
    local object_data = setmetatable({}, deploymentFramework)
    
    return object_data
end

--// framework methods:
function deploymentFramework:register_deployables(wave, deploy_table)
    if not self[wave] then
        self[wave] = {}
    end
    
    --// create copys of the deploy_table each wave. this should allow for different configs for different waves.
    for object_name, object_info in pairs(deploy_table) do
        if not self[wave][object_name] then
            self[wave][object_name] = { positions = {} }
        end

        for _, objectCFrames in ipairs(object_info.positions or object_info) do
            table.insert(self[wave][object_name].positions, objectCFrames)
        end
    end
end

function deploymentFramework:deploy_wave(wave)
    local create_deploy = game:GetService("ReplicatedStorage"):FindFirstChild('RemoteFunctions'):FindFirstChild('CreateDeployable')
    local waveDeploys = self[wave]

    if not waveDeploys then
        return warn("No deployables registered for wave", wave)
    end

    for object_name, object_info in pairs(waveDeploys) do
        local positions = object_info.positions

        if wave == 1 then
            --// deploy deployables on wave1, to prevent game.Workspace.Deployables[lplr.Name] from returning nil & place x amount of deployables based on the max number of indexes in the positions array.
            --// Example: 3 indexes means 3 deployables will be placed.
            
            for _, targetPosition in ipairs(positions) do
                create_deploy:InvokeServer(object_name, targetPosition, "Close")
            end
        else
            --// "placed_deployables" represents the amount of deployables placed down at any given time:

            local placed_deployables = 0
            
            for _, targetPosition in ipairs(positions) do
                placed_deployables = 0
            
                --// in-game deployables are counted to keep track of them here, this is important since we need to know how many are placed for later.

                for _, v in pairs(workspace.Deployables[game.Players.LocalPlayer.Name]:GetChildren()) do
                    if v.Name == object_name:gsub(" ", "") then
                        placed_deployables += 1
                    end
                end
                
                --// iterate through the positions array and keep track of the number of positions in the array, this is important since we need to know how many positions there are for later.
                --// this is due to a bug that occured when there is multiple positions stored inside the positions array with the same "x, y, z" values.

                local samePositionCount = 0
                for _, pos in ipairs(positions) do
                    if pos == targetPosition then
                        samePositionCount += 1
                    end
                end

                --// if the number of in-game deployables, is below the samePositionCount then deploy.
                --// would do #positions but since we are comparing if the target position matches the pos on line 82 this would cause a bug.
                --// this allows item stacking to be handled properly.

                if placed_deployables < samePositionCount then
                    create_deploy:InvokeServer(object_name, targetPosition, "Close")

                    placed_deployables += 1
                else
                    local matched = false

                    -- this compares the in-game deployable position with the position inside of the positions array, if they match then ignore placement.
                    for _, v in pairs(workspace.Deployables[game.Players.LocalPlayer.Name]:GetChildren()) do
                        if v.Name == object_name:gsub(" ", "") and v.WorldPivot == targetPosition then
                            matched = true
                            
                            break
                        end
                    end

                    -- this compares the in-game deployable position with the position inside of the positions array, if they dont match then placement.
                    if not matched and placed_deployables < #positions then
                        create_deploy:InvokeServer(object_name, targetPosition, "Close")
                        placed_deployables += 1
                    end
                end
            end
        end
    end

    return self
end

--// this method simply handles respawning in-game deployables on removed:
function deploymentFramework:enableAutoReplace()
    workspace.Deployables[game.Players.LocalPlayer.Name].ChildRemoved:Connect(function(v)
        create_deploy:InvokeServer(v.Name:gsub("(%l)(%u)", "%1 %2"), v.WorldPivot, "Close")
    end)
end

return deploymentFramework
