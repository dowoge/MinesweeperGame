export type Position = {
	X: number,
	Y: number,
}

export type Board = {
	SizeX: number,
	SizeY: number,

	State: number, --0 == playing, 1 == won, 2 == lost
	
	WinEvent: BindableEvent,
	LoseEvent: BindableEvent,

	Player: Player,

	pBoard: Folder,

	MineCount: number,
	FlaggedCells: number,

	OpenedCells: number,

	Cells: {Cell} 
}

export type Cell = {
	Position: Position,

	_IsFlagged: boolean,
	_IsMine: boolean,
	_IsOpen: boolean,
	
	Board: Board
}

CustomEnums = {
	NumberColors = {
		[0] = Color3.new(), --0.6, 0.18, 0.67
		[1] = Color3.new(0, 0.45, 1),
		[2] = Color3.new(0, 0.57, 0),
		[3] = Color3.new(0.6, 0, 0),
		[4] = Color3.new(0.24, 0.24, 0.24),
		[5] = Color3.new(0.4, 0, 0.6),
		[6] = Color3.new(0.7, 0.7, 0),
		[7] = Color3.new(1/3, 1/3, 1),
		[8] = Color3.new(0.7, 0.5, 0)
	},
	States = {
		Playing = 0,
		Won = 1,
		Lost = 2,
	},
	_States = {
		[0] = 'Playing',
		[1] = 'Won',
		[2] = 'Lost'
	}
}


return CustomEnums