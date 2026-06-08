local Pager = {}
Pager.__index = Pager

function Pager:Destroy()
	table.clear(self)
end

function Pager:GetBlacklist(v)
	if not self.Blacklist then
		return
	end
	
	if typeof(v) == "string" then
		if string.match(v, self.Blacklist) then
			return true
		end

		return
	end

	if typeof(v) == "table" and self.Indexer then
		local v = v[self.Indexer]

		if string.match(v, self.Blacklist) then
			return true
		end

		return
	end
end

function Pager:GetListCount()
	local List = self.List
	local Count = 0
	
	if not self.Blacklist then
		return #List
	end
	
	for i, v in List do
		if self:GetBlacklist(v) then
			Count += 1
		end
	end
	
	return Count
end

function Pager:GetNewList()
	local List = self.List
	local newList = {}
	
	if not self.Blacklist then
		return List
	end
	
	for i, v in List do
		if self:GetBlacklist(v) then
			table.insert(
				newList,
				v
			)
		end
	end

	return newList
end

function Pager:GetMaxPage()
	local ListCount = math.clamp(self:GetListCount(), 1, math.huge)
	local MaxPageCount = self.MaxListCount
	
	return 1 + math.floor((ListCount-1)/MaxPageCount)
end

function Pager:GetPageCount(Page)
	local vPage = Page or self.Page
	local Subpage = (vPage - 1)
	local MaxPageCount = self.MaxListCount
	
	return math.clamp(
		Subpage * MaxPageCount, -- + Subpage,
		1,
		math.huge
	)
end

function Pager:GetList()
	local SearchBlockNum = 0
	local List = self:GetNewList()
	
	local Page = self.Page
	local PageCount = self:GetPageCount()
	local MaxPageCount = self.MaxListCount
	local Subpage = math.clamp(Page - 1, 0, 1)
	local Addpage = math.clamp(Page, 0, 1)
	
	local amtUsed = 0
	
	local _List = {}
	
	local NextPageCount = Page * MaxPageCount
	
	PageCount += Subpage
	
	for i, v in List do
		if i < PageCount then
			continue
		end
		
		if i > NextPageCount then
			break
		end
		
		table.insert(
			_List,
			v
		)
	end
	
	return _List
end

function Pager:NextPage()
	local ListCount = self:GetListCount()
	local LastPage = self.Page
	
	self:switchPage(LastPage + 1)
	
	local PageCount = self:GetPageCount()

	if PageCount > ListCount then
		return self:switchPage(LastPage)
	end
	
	local Grid = self.Grid
	
	self:Update()
	
	if not Grid then
		return
	end
	
	Grid.CanvasPosition = Vector2.new()
end

function Pager:PreviousPage()
	local LastPage = self.Page
	
	self:switchPage(LastPage - 1)
	self:switchPage(
		math.clamp(
			self.Page,
			1,
			math.huge
		)
	)
	
	if self.Page == LastPage then
		return
	end
	
	local Grid = self.Grid

	self:Update()

	if not Grid then
		return
	end

	Grid.CanvasPosition = Vector2.new()
end

function Pager:switchPage(page)
	self.Page = page
end

function Pager:switchMaxListCount(maxlistcount)
	self.MaxListCount = maxlistcount
end

function Pager:SetIndexer(indexer)
	self.Indexer = indexer
end

function Pager:Search(Blacklist)
	if Blacklist == "" then
		Blacklist = nil
	end
	
	if self.Blacklist == Blacklist then
		return
	end
	
	self.Blacklist = Blacklist
	self:Update()
end

function Pager:AssignGrid(Grid)
	self.Grid = Grid
end

function Pager:UpdateList(list)
	self.List = list
	
	self:Update()
end

function Pager:Update()
	local Page = self.Page
	local MaxPageCount = self:GetMaxPage()
	
	if Page > MaxPageCount then
		self:switchPage(MaxPageCount)
	elseif Page < 0 then
		self:switchPage(1)
	end
	
	local Updater = self.Updater
	
	if not Updater then
		return
	end
	
	coroutine.wrap(
		Updater
	)(
		self,
		self:GetList()
	)
end

function Pager.new(list, maxlistcount, Updater)
	for _ in list do
		if list[1] then
			break
		end
		
		return warn("List must be indexed with a number, i.e; [1] = a, [2] = b")
	end
	
	return setmetatable({
		List = list or {},
		Page = 1,
		MaxListCount = maxlistcount or 1,
		Updater = Updater
	}, Pager)
end

return Pager