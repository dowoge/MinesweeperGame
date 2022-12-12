local Types = require(script.Parent:WaitForChild('Types'))

local Cell = {}
Cell.__index = Cell

function Cell.new(X: number, Y: number, board: Types.Board): Types.Cell
	local cell: Types.Cell = {
		Position = {X=X,Y=Y},
		
		_IsFlagged = false,
		_IsMine = false,
		_IsOpen = false,
		
		Board = board
	}
	
	return setmetatable(cell,Cell)
end

function Cell:IsFlagged(): boolean
	return self._IsFlagged
end

function Cell:IsMine(): boolean
	return self._IsMine
end

function Cell:IsOpened(): boolean
	return self._IsOpen
end

function Cell:SetIsMine(state: boolean): nil
	self._IsMine = state
end

function Cell:SetFlagged(state: boolean): nil
	self._IsFlagged = state
end

function Cell:SetOpened(state: boolean): nil
	self._IsOpen = state
end

function Cell:NeighboringCells(): number
	
	local board = self.Board
	local position = self.Position
	
	local n = 0

	for i = -1,1 do
		for j = -1,1 do
			if i~=0 or j~=0 then
				local xx,yy = position.X+i,position.Y+j
				if xx>0 and yy>0 and (not (xx>board.SizeX) and not (yy>board.SizeY)) then
					if board.Cells[board.SizeX*yy+xx]:IsMine() then
						n+=1
					end
				end
			end
		end
	end

	return n
end

function Cell:GetNeighboringCells(): {Types.Cell}
	
	local board = self.Board
	local position = self.Position
	
	local Cells = {}

	for i = -1,1 do
		for j = -1,1 do
			local xx,yy = position.X+i,position.Y+j
			if xx>0 and yy>0 and (not (xx>board.SizeX) and not (yy>board.SizeY)) then
				table.insert(Cells,board.Cells[board.SizeX*yy+xx])
			end
		end
	end

	return Cells
end

function Cell:Open(chord,PlayerWhoLostAndShouldKillThemselves) --i spent a SOLID 20 minutes figuring this shit out, #### Roblox
	
	if self:IsFlagged() or self.Board.State==Types.States.Lost then return end
	
	if self:IsMine() then -- lose
		self:Bomb()
		return self.Board:Lose(PlayerWhoLostAndShouldKillThemselves)
	end
	
	local board = self.Board
	local position = self.Position
	
	local bombs = self:NeighboringCells()
	
	if chord and self:IsOpened() then
		local mineCount = self:NeighboringCells()
		if mineCount>0 then
			local neighbors = self:GetNeighboringCells()
			local flags = 0
			for _,cell in next,neighbors do
				if cell:IsFlagged() then
					flags+=1
				end
			end
			if flags==mineCount then
				for _,cell in next,neighbors do
					if not cell:IsOpened() and not cell:IsFlagged() then
						task.spawn(function()
							cell:Open(false,PlayerWhoLostAndShouldKillThemselves)
						end)
					end
				end
			end
		end
		return
	end
	
	self:SetOpened(true)
	board.OpenedCells+=1

	local BOARDcell = self.Board.pBoard[board.SizeX*position.Y+position.X]
	local textlabel = BOARDcell:FindFirstChild('TextLabel',true)

	textlabel.Text = bombs>0 and tostring(bombs) or ''
	textlabel.TextColor3 = bombs>0 and Types.NumberColors[bombs] or Color3.new()

	BOARDcell.Color=Color3.new(3/4, 3/5, 1/3)
	
	if board.OpenedCells==board.SizeX*board.SizeY-board.MineCount then -- win
		return self.Board:Win() 	
	end
	
	if bombs==0 then
		local neighborcells = self:GetNeighboringCells()
		for _, cell in next,neighborcells do
			if not cell:IsMine() and not cell:IsOpened() then
				task.spawn(function()
					cell:Open(false,PlayerWhoLostAndShouldKillThemselves)
				end)
			end
		end
	end
end

function Cell:Flag()
	
	local board = self.Board
	local position = self.Position

	if self:IsOpened() or board.State==Types.States.Lost then return end

	local BOARDcell = self.Board.pBoard[board.SizeX*position.Y+position.X]
	
	self:SetFlagged(not self:IsFlagged())

	board.FlaggedCells+=self:IsFlagged() and 1 or -1

	BOARDcell:FindFirstChild('TextLabel',true).Text = self:IsFlagged() and '🚩' or ''
	
	
	board.Player.PlayerGui.Debug.FlagCounter.Text=board.FlaggedCells
	for _,Player in next,board.Coop do
		Player.PlayerGui.Debug.FlagCounter.Text=board.FlaggedCells
	end
	
end

function Cell:Bomb()
	
	local board = self.Board
	local position = self.Position

	local pCell = self.Board.pBoard[board.SizeX*position.Y+position.X]
	
	self:SetOpened(true)
	
	pCell:FindFirstChild('TextLabel',true).Text = '💣'
	pCell.Color = Color3.new(2/3, 1/3, 1)
	
	local Explosion = Instance.new('Explosion',workspace)
	Explosion.BlastRadius = 0
	Explosion.Position = pCell.Position
end

return Cell