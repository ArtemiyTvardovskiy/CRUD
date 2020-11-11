PlayerData = {}
local db_connection
local cash  = {}

local function adding_value_to_table(self, name, surname, adress, value)
    
    if type( self[name] ) ~= "table" then
        self[name] = {}
        self[name][surname] = {}
    elseif type( self[name][surname] ) ~= "table" then
		self[name][surname] = {}
	end
	self[name][surname][adress] = value and value or true
end

local function call_handler(self, method, name, surname, adress, value)
    if method == "add" then
        adding_value_to_table( self, name, surname, adress, value )
    
    elseif method == "check" then
        if type( self[name] ) ~= "table" then return end
        
        if type( self[name][surname] ) ~= "table" then return end
		return self[name][surname][adress]
	elseif method == "del" then
		if type( self[name] ) ~= "table" then return end

		if type( self[name][surname] ) ~= "table" then return end

		self[name][surname][adress] = nil
		if not next(self[name][surname]) then
			self[name][surname] = nil
		end

		if not next(self[name]) then
			self[name] = nil
		end
    end
end
setmetatable( cash, { __call = call_handler } )

local function press_handler(player)
	if not next( cash ) then
		outputChatBox( "Данные пока не получены", player )
		return
	end

	if PlayerData[player] and PlayerData[player].UI then
		triggerClientEvent( player, "onCloseWindow", resourceRoot, true )
		PlayerData[player].UI = nil
		return
	end

	triggerClientEvent( player, "onInitWindow", resourceRoot, cash )
	PlayerData[player] = { UI = true }
end

addEvent( "onDestroyWindow", true )
addEventHandler( "onDestroyWindow", resourceRoot, function()
	PlayerData[client].UI = nil
end  )

addEventHandler( "onResourceStart", resourceRoot, function()

	for _, player in pairs(getElementsByType("player")) do
		bindKey( player, "L", "down", press_handler )
	end

	db_connection = dbConnect("mysql", "dbname=users_organization;host=127.0.0.1;port=3306", "root", "")

	if not db_connection then
		iprint("Connection to DB failed!")
		stopResource( getThisResource() )
		return
	end

	dbQuery( function(qh)
		local result = dbPoll( qh, 0 )
		for i = 1, #result do
			local data_user = fromJSON( result[i].another_data )
			cash( "add", result[i].name, data_user.surname, data_user.adress )
		end
	 
	end, db_connection, "SELECT * FROM data" )
end )

addEvent( "onAddNewPersonInDB", true )
addEventHandler( "onAddNewPersonInDB", resourceRoot, function( name, surname, adress )
	if cash( "check", name, surname, adress ) then
		outputChatBox( "Такой уже есть", client )
		return
	end

	cash( "add", name, surname, adress, "adding" )

	dbQuery( function( qh, player, name, surname, adress )
		local result = dbPoll( qh, 0 )
		if not result then
			outputChatBox( "Error!", player )
			cash("del", name, surname, adress)
			return
		end

		cash( "add", name, surname, adress )

		update_information_from_players( name, surname, adress, "onAddPlayerToGrid" )

		outputChatBox( "Good!", player )
	 
	end, { client, name, surname, adress }, db_connection, "INSERT INTO data VALUES(?, ?)", name, toJSON( {surname = surname, adress = adress} ) )
end  )

addEvent( "onDelPersonFromDB", true )
addEventHandler( "onDelPersonFromDB", resourceRoot, function( name, surname, adress )

	if cash( "check", name, surname, adress ) ~= true then
		outputChatBox( "Ошибка", client )
		return
	end

	cash( "add", name, surname, adress, "deleting" )

	dbQuery( function( qh, player, name, surname, adress )
		local result = dbPoll( qh, 0 )
		if not result then
			outputChatBox( "Error!", player )
			cash( "add", name, surname, adress, true )
			return
		end

		cash( "del", name, surname, adress )

		update_information_from_players( name, surname, adress, "onDelPlayerFromGrid" )

		outputChatBox( "Good!", player )
	 
	end, { client, name, surname, adress }, db_connection, "DELETE FROM data WHERE name = ? AND another_data = ?", 
		name, toJSON( {surname = surname, adress = adress} ) )
end  )

addEvent( "onModifyPersonInDB", true )
addEventHandler( "onModifyPersonInDB", resourceRoot, function( name, surname, adress, new_name, new_surname, new_adress )

	if cash( "check", name, surname, adress ) ~= true or cash( "check", new_name, new_surname, new_adress ) then
		outputChatBox( "Ошибка", client )
		return
	end

	cash( "add", name, surname, adress, "modifing" )
	cash( "add", new_name, new_surname, new_adress, "adding" )

	dbQuery( function( qh, player, name, surname, adress, new_name, new_surname, new_adress )
		local result = dbPoll( qh, 0 )
		if not result then
			outputChatBox( "Error!", player )
			cash( "del", new_name, new_surname, new_adress )
			return
		end

		cash( "del", name, surname, adress )
		cash( "add", new_name, new_surname, new_adress, true )

		update_information_from_players( name, surname, adress, "onModifyPlayerInGrid", new_name, new_surname, new_adress )

		outputChatBox( "Good!", player )
	 
	end, { client, name, surname, adress, new_name, new_surname, new_adress }, db_connection, "UPDATE data SET name = ?, another_data = ? WHERE name = ? AND another_data = ?", 
		new_name, toJSON( {surname = new_surname, adress = new_adress} ), name, toJSON( {surname = surname, adress = adress} ) )
end  )

addEventHandler( "onPlayerJoin", root, function()

	bindKey( source, "L", "down", press_handler )

end )