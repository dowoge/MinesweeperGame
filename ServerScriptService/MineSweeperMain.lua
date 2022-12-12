local MineSweeper = require(game:GetService('ServerScriptService'):WaitForChild('MineSweeper'))
local Types = require(script.Parent:WaitForChild('MineSweeper'):WaitForChild('Types'))

local Solver = require(script.Parent:WaitForChild('MineSweeper'):WaitForChild('Solver'))

local Network = require(game:GetService('ServerScriptService'):WaitForChild('Network'))

local BOARDS = workspace:WaitForChild('BOARDS')

local MAX_PLAYERS = 6

local DISTANCE_BETWEEN_BOARDS = 100 --in part sizes (part.Size.X*DISTANCE_BETWEEN_BOARDS)

local function CreatePart(board, pos: Types.Position)
	local part = Instance.new("Part")
	part.Size = Vector3.new(5, 2, 5)
	
	local Offset = board.Offset
	
	part.Parent = board.pBoard
	part.Position = Vector3.new(part.Size.X * pos.X, part.Size.Y/2, part.Size.Z * pos.Y) + Vector3.new(0,0,((board.SizeX*part.Size.X)+(part.Size.X*DISTANCE_BETWEEN_BOARDS))*(Offset)) -- this is wrong but i dont care
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.Name = board.SizeX*pos.Y+pos.X
	
	if (pos.X + pos.Y) % 2 == 0 then
		part.Color = Color3.new(0.5, 0.6, 0.5)
	else
		part.Color = Color3.new(1/3, 0.5, 1/3)
	end
	
	local gui = Instance.new("SurfaceGui")
	local textlabel = Instance.new("TextLabel")
	
	local clickdetector = Instance.new('ClickDetector')
	clickdetector.MaxActivationDistance = 1e10
	clickdetector.Parent = part
	
	gui.Parent = part
	gui.AlwaysOnTop = false
	gui.Face = Enum.NormalId.Top
	
	local cell = board.Cells[board.SizeX*pos.Y+pos.X]
	
	local bombs = cell:NeighboringCells()
	local ismine = cell:IsMine()
	
	textlabel.Parent = gui
	textlabel.Size = UDim2.new(1, 0, 1, 0)
	textlabel.BackgroundTransparency = 1
	textlabel.Text = ''
	textlabel.RichText = true
	textlabel.FontFace.Bold = true
	textlabel.TextScaled = true
	
	clickdetector.MouseClick:Connect(function(player)
		if player == board.Player or board.Coop[player] then
			cell:Open(false,player)
		end
	end)
	
	clickdetector.RightMouseClick:Connect(function(player)
		if player == board.Player or board.Coop[player] then
			if cell:IsOpened() then
				cell:Open(true,player)
			elseif not cell:IsOpened() then
				cell:Flag()
			end
		end
	end)
	
end

local function VisualizeBoard(board: MineSweeper.Board)
	for i = 1, board.SizeX do
		for j = 1, board.SizeY do
			CreatePart(board, {X=i, Y=j})
		end
	end
end

function missingPlayer()
	for i=-(MAX_PLAYERS/2),MAX_PLAYERS/2 do
		if not BOARDS:FindFirstChild(tostring(i)) then
			return i
		end
	end 
end

local Players = {}

function clear(pBoard: Folder)
	pBoard:ClearAllChildren()
	pBoard:Destroy()
end

function restart(player)
	local Offset = Players[player].Offset
	local pBoard = BOARDS:FindFirstChild(Offset)
	
	clear(pBoard)
	MakeBoard(player)
	player.Character.HumanoidRootPart.CFrame = CFrame.new(Players[player].Board.Position)+Vector3.new(0,5,0)
end


function MakeBoard(Player)
	
	local playerData = Players[Player]
	
	local newBoard = MineSweeper.new(playerData.SizeX,playerData.SizeY,playerData.MineCount,playerData.Offset,Players[Player].Coop,Player)
	
	Players[Player].Board=newBoard
	
	VisualizeBoard(newBoard)
	
	newBoard.Position = newBoard.pBoard[math.floor((newBoard.SizeX*newBoard.SizeY)/2)].Position
	
	Player.PlayerGui:WaitForChild('Debug').FlagCounter.Text=newBoard.FlaggedCells
	
	Network.SendAll('SetState',Types._States[Types.States.Playing])
	
	newBoard.WinEvent.Event:Connect(function()
		restart(newBoard.Player)
	end)
	newBoard.LoseEvent.Event:Connect(function()
		restart(newBoard.Player)
	end)

	local cell=nil
	
	local lowestBombCount = math.huge
	
	for _,_cell in next,newBoard.Cells do
		if _cell:NeighboringCells()<lowestBombCount then
			lowestBombCount=_cell:NeighboringCells()
		end
	end
	
	repeat
		local startx,starty = math.random(1,newBoard.SizeX),math.random(1,newBoard.SizeY)
		cell = newBoard.Cells[newBoard.SizeX*starty+startx]
	until
		not cell:IsMine() and (cell:NeighboringCells()==0 or cell:NeighboringCells()==lowestBombCount)
	
	cell:Open(false,Player)
	
	wait()
	Player.Character.HumanoidRootPart.CFrame = CFrame.new(newBoard.Position)+Vector3.new(0,5,0)
	
end

Network.Listen('command',function(player,command,data)
	if not Players[player] then
		warn('what the fuck')
		return
	end
	local playerData = Players[player]
	if command == 'setting' then
		local x,y = data.x,data.y
		local minecount = data.minecount
		if x and y and x*y>playerData.MineCount then
			Players[player].SizeX=x
			Players[player].SizeY=y
			Network.Send('ChatMakeSystemMessage',player,{
				Text='[Settings] Set BoardSize to '..tostring(x)..'x'..tostring(y),
				Color=Color3.new(1,1,1),
				Font=Enum.Font.SourceSansBold,
				FontSize=Enum.FontSize.Size18
			})
		end
		if minecount and playerData.SizeX*playerData.SizeY>minecount then
			Players[player].MineCount=minecount
			Network.Send('ChatMakeSystemMessage',player,{
				Text='[Settings] Set MineCount to '..tostring(minecount),
				Color=Color3.new(1,1,1),
				Font=Enum.Font.SourceSansBold,
				FontSize=Enum.FontSize.Size18
			})
		end
	elseif command == 'goto' then
		local Player = data.Player
		if Player and Players[Player] then
			player.Character.HumanoidRootPart.CFrame = CFrame.new(Players[Player].Board.Position)+Vector3.new(0,5,0)
			Network.Send('ChatMakeSystemMessage',player,{
				Text='[TP] Teleported to '..Player.Name..'\'s board',
				Color=Color3.new(1,1,1),
				Font=Enum.Font.SourceSansBold,
				FontSize=Enum.FontSize.Size18
			})
		end
	elseif command == 'add' then
		local Player = data.Player
		if Player == player then return end
		local board = playerData.Board
		board.Coop[Player]=Player
		Players[Player].Coop[Player]=Player
		Network.Send('ChatMakeSystemMessage',player,{
			Text='[Coop] Added '..Player.Name..' to board',
			Color=Color3.new(1,1,1),
			Font=Enum.Font.SourceSansBold,
			FontSize=Enum.FontSize.Size18
		})
		Network.Send('ChatMakeSystemMessage',Player,{
			Text='[Coop] you have been added to '..player.Name..'\'s board',
			Color=Color3.new(1,1,1),
			Font=Enum.Font.SourceSansBold,
			FontSize=Enum.FontSize.Size18
		})
	elseif command == 'remove' then
		local Player = data.Player
		if Player == player then return end
		local board = playerData.Board
		if board.Coop[Player] then
			board.Coop[Player]=nil
			Players[Player].Coop[Player]=nil
			Network.Send('ChatMakeSystemMessage',player,{
				Text='[Coop] Removed '..Player.Name..' to board',
				Color=Color3.new(1,1,1),
				Font=Enum.Font.SourceSansBold,
				FontSize=Enum.FontSize.Size18
			})
			Network.Send('ChatMakeSystemMessage',Player,{
				Text='[Coop] you have been removed from '..player.Name..'\'s board',
				Color=Color3.new(1,1,1),
				Font=Enum.Font.SourceSansBold,
				FontSize=Enum.FontSize.Size18
			})
		end
	elseif command == 'walkspeed' then
		local speed = data.Speed
		if speed then
			player.Character.Humanoid.WalkSpeed=math.clamp(speed,1,75)
		end
	elseif command == 'solve' then
		--do solve shijt here!!!
		local PlayerData = Players[player]
		
		local PlayerBoard = PlayerData.Board
		
		Solver.Solve(PlayerBoard)
		
		
		Network.Send('ChatMakeSystemMessage',player,{
			Text='#### Jeft',
			Color=Color3.new(1,1,1),
			Font=Enum.Font.SourceSansBold,
			FontSize=Enum.FontSize.Size18
		})
	elseif command == 'restart' then
		restart(player)
	end
end)

game.Players.PlayerAdded:Connect(function(player)
	Players[player]={
		Offset=missingPlayer(),
		Coop = {},
		
		SizeX = 25,
		SizeY = 25,
		
		MineCount = 115
	}
	MakeBoard(player)
end)
game.Players.PlayerRemoving:Connect(function(player)
	local Offset = Players[player].Offset
	local board = workspace:WaitForChild('BOARDS'):FindFirstChild(Offset)
	clear(board)
	Players[player]=nil
end)