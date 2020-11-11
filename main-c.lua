local ui_elements = {}
local rows_in_grid = {}

local function adding_value_to_table(self, name, surname, adress, row)
    
    if type( self[name] ) ~= "table" then
        self[name] = {}
        self[name][surname] = {}
    elseif type( self[name][surname] ) ~= "table" then
		self[name][surname] = {}
	end
	self[name][surname][adress] = row
end

local function call_handler(self, method, name, surname, adress, row)
    if method == "add" then
        adding_value_to_table( self, name, surname, adress, row )
    
    elseif method == "check" then
        if type( self[name] ) ~= "table" then return end
        
        if type( self[name][surname] ) ~= "table" then return end
        return self[name][surname][adress]
	elseif method == "del" then
		if type( self[name] ) ~= "table" then return end

		if type( self[name][surname] ) ~= "table" then return end

		local value = self[name][surname][adress]

		self[name][surname][adress] = nil
		if not next(self[name][surname]) then
			self[name][surname] = nil
		end

		if not next(self[name]) then
			self[name] = nil
		end

		return value
    end
end
setmetatable( rows_in_grid, { __call = call_handler } )

loadstring(exports.dgs:dgsImportFunction())()

local selected_par = {}

local tmp_table_for_searcing_rows = {}

local sx, sy = guiGetScreenSize()

local function destroy_ui_handler( is_closed_by_keyboard )
	showCursor( false )
	if is_closed_by_keyboard then 
		destroyElement( ui_elements.window )
	else
		triggerServerEvent( "onDestroyWindow", resourceRoot )
	end
	ui_elements = {}
	rows_in_grid = {}
	selected_par = {}
	tmp_table_for_searcing_rows = {}
end

local function add_row_to_grid( name, surname, adress )
	local row = dgsGridListAddRow( ui_elements.gridlist_main )
	dgsGridListSetItemText( ui_elements.gridlist_main, row, 1, name )
	dgsGridListSetItemText( ui_elements.gridlist_main, row, 2, surname )
	dgsGridListSetItemText( ui_elements.gridlist_main, row, 3, adress )
	rows_in_grid( "add", name, surname, adress, row )

	dgsSetEnabled( ui_elements.button_to_modify_user, false )

	local searched_text = dgsGetText( ui_elements.search_edit )
	if not searched_text or searched_text == "" then return end

	if name:find( searched_text ) or surname:find( searched_text ) or adress:find( searched_text ) then
		tmp_table_for_searcing_rows( "add", name, surname, adress, row )
		return
	end

	dgsGridListRemoveRow( ui_elements.gridlist_main, row )
end

local function del_row_from_grid( name_main, surname_main, adress_main )
	local needed_row = rows_in_grid( "check", name_main, surname_main, adress_main )

	if not needed_row or needed_row <= 0 then return end

	rows_in_grid( "del", name_main, surname_main, adress_main )
	triggerEvent( "onDgsTextChange", ui_elements.name_edit)

	for name, table_surname_adress in pairs( rows_in_grid ) do
		for surname, table_adress in pairs( table_surname_adress ) do
			for adress, row in pairs( table_adress ) do
				local needed = row
				if row > needed_row then
					rows_in_grid[name][surname][adress] = row - 1
					needed = needed - 1
				end
			end
		end
	end

	if next( tmp_table_for_searcing_rows ) then
		local virtual_row = tmp_table_for_searcing_rows( "del", name_main, surname_main, adress_main )
		if virtual_row then
			dgsGridListRemoveRow( ui_elements.gridlist_main, virtual_row )
		end
	else
		dgsGridListRemoveRow( ui_elements.gridlist_main, needed_row )
	end

	if dgsGridListGetSelectedItem( ui_elements.gridlist_main ) <= 1 then return end

	dgsSetEnabled( ui_elements.button_to_delete_user, false )
	dgsSetEnabled( ui_elements.button_to_modify_user, false )
end

local function modify_row_from_grid( name_old, surname_old, adress_old, name_new, surname_new, adress_new )
	local row = rows_in_grid( "check", name_old, surname_old, adress_old )
	rows_in_grid( "add", name_new, surname_new, adress_new, row )
	dgsSetEnabled( ui_elements.button_to_add_new, false )
	dgsSetEnabled( ui_elements.button_to_modify_user, false )

	if next( tmp_table_for_searcing_rows ) then
		row = tmp_table_for_searcing_rows( "check", name_old, surname_old, adress_old )

		if not row then return end

		tmp_table_for_searcing_rows( "add", name_new, surname_new, adress_new, row )
	end

	dgsGridListSetItemText( ui_elements.gridlist_main, row, 1, name_new )
	dgsGridListSetItemText( ui_elements.gridlist_main, row, 2, surname_new )
	dgsGridListSetItemText( ui_elements.gridlist_main, row, 3, adress_new )
end

local function fill_in_gridlist( data_table )
	for name, table_surname_adress in pairs(data_table) do
		for surname, table_adress in pairs( table_surname_adress ) do
			for adress, value in pairs( table_adress ) do
				if value ~= true then return end

				add_row_to_grid( name, surname, adress )
			end
		end
	end
end

local function check_adding_valid()
	dgsSetEnabled( ui_elements.button_to_add_new, false )
	dgsSetEnabled( ui_elements.button_to_modify_user, false )
	if source == ui_elements.name_edit then
		selected_par.name = dgsGetText(source)
	elseif source == ui_elements.surname_edit then
		selected_par.surname = dgsGetText(source)
	elseif source == ui_elements.adress_edit then
		selected_par.adress = dgsGetText(source)
	end

	if not selected_par.name or not selected_par.surname or not selected_par.adress then return end

	if selected_par.name == "" or selected_par.surname == "" or selected_par.adress == "" then return end

	if rows_in_grid( "check", selected_par.name, selected_par.surname, selected_par.adress ) then return end

	dgsSetEnabled( ui_elements.button_to_add_new, true )

	if dgsGridListGetSelectedItem( ui_elements.gridlist_main ) <= 0 then return end

	dgsSetEnabled( ui_elements.button_to_modify_user, true )
end

local function for_delete_and_modify( event_to_trigger )
	local selected_row = dgsGridListGetSelectedItem( ui_elements.gridlist_main )

	if selected_row <= 0 then return end

	local name_main, surname_main, adress_main = dgsGridListGetItemText( ui_elements.gridlist_main, selected_row, 1 ), 
		dgsGridListGetItemText( ui_elements.gridlist_main, selected_row, 2 ), 
			dgsGridListGetItemText( ui_elements.gridlist_main, selected_row, 3 )
	triggerServerEvent( event_to_trigger, resourceRoot, name_main, surname_main, adress_main, 
		selected_par.name, selected_par.surname, selected_par.adress )

end

local function init_confirmation_deleting_window()
	dgsSetEnabled( ui_elements.window, false )
	ui_elements.confirmation = {}
	ui_elements.confirmation.window = dgsCreateWindow( 3 * sx / 8, 3 * sy / 8, sx / 5, sy / 5, "Подтверждение", false, 0xFFFFFFFF )
	ui_elements.confirmation.button_to_confirm = dgsCreateButton( sx * 0.02, sy * 0.07, 0.05 * sx, 0.05 * sy, "Da", false, ui_elements.confirmation.window )
	ui_elements.confirmation.button_to_refuse = dgsCreateButton( sx * 0.12, sy * 0.07, 0.05 * sx, 0.05 * sy, "Net", false, ui_elements.confirmation.window )

	addEventHandler( "onDgsMouseClickDown", ui_elements.confirmation.button_to_confirm, function()
		destroyElement( dgsGetParent( source ) )
		ui_elements.confirmation = nil
		dgsSetEnabled( ui_elements.window, true )
		for_delete_and_modify( "onDelPersonFromDB" )
	end, false )

	addEventHandler( "onDgsMouseClickDown", ui_elements.confirmation.button_to_refuse, function()
		destroyElement( dgsGetParent( source ) )
		ui_elements.confirmation = nil
		dgsSetEnabled( ui_elements.window, true )
	end, false )

	addEventHandler( "onDgsWindowClose", ui_elements.confirmation.window, function()
		ui_elements.confirmation = nil
		dgsSetEnabled( ui_elements.window, true )
	end )

	dgsWindowSetSizable( ui_elements.confirmation.window, false )
	dgsWindowSetMovable( ui_elements.confirmation.window, false )
end

local function delete_user_handler()
	init_confirmation_deleting_window()
end

local function modify_user_handler()
	for_delete_and_modify("onModifyPersonInDB")
end

local function search_needed_parameters()
	local new_text = dgsGetText( ui_elements.search_edit )

	if new_text == "" then
		if not next( tmp_table_for_searcing_rows ) and dgsGridListGetRowCount( ui_elements.gridlist_main ) > 0 then return

		else

		end
	end

	tmp_table_for_searcing_rows = {}
	setmetatable( tmp_table_for_searcing_rows, { __call = call_handler } )
	dgsGridListClearRow( ui_elements.gridlist_main, false, false )

	for name, table_surname_adress in pairs( rows_in_grid ) do
		for surname, table_adress in pairs( table_surname_adress ) do
			for adress, row in pairs( table_adress ) do
				local new_row
				if new_text == "" then
					new_row = row
					dgsGridListAddRow( ui_elements.gridlist_main, row )
				elseif adress:find( new_text ) or surname:find( new_text ) or name:find( new_text ) then
					new_row = dgsGridListAddRow( ui_elements.gridlist_main )
					tmp_table_for_searcing_rows( "add", name, surname, adress, new_row )
				end
				if new_row then
					dgsGridListSetItemText( ui_elements.gridlist_main, new_row, 1, name )
					dgsGridListSetItemText( ui_elements.gridlist_main, new_row, 2, surname )
					dgsGridListSetItemText( ui_elements.gridlist_main, new_row, 3, adress )
				end
			end
		end
	end

	if dgsGridListGetSelectedItem( ui_elements.gridlist_main) == -1 then
		dgsSetEnabled( ui_elements.button_to_delete_user, false )
		dgsSetEnabled( ui_elements.button_to_modify_user, false )
	end
end

local function init_ui( data_from_db )
	setmetatable( rows_in_grid, { __call = call_handler } )
	setmetatable( tmp_table_for_searcing_rows, { __call = call_handler } )
	ui_elements.window = dgsCreateWindow( sx / 4, sy / 4, sx / 2, sy / 2, "Main", false, 0xFFFFFFFF )
	dgsWindowSetSizable( ui_elements.window, false )
	dgsWindowSetMovable( ui_elements.window, false )
	ui_elements.tab_panel = dgsCreateTabPanel(0, 0, sx / 2, sy / 2, false, ui_elements.window)
	ui_elements.main_tab = dgsCreateTab( "Main", ui_elements.tab_panel )
	ui_elements.gridlist_main = dgsCreateGridList( sy / 200, sx / 200, sx / 4, sy / 4, false, ui_elements.main_tab, 20, 0xffffffff )
	ui_elements.name_edit = dgsCreateEdit( sx * 0.28, sy * 0.03, 0.17 * sx, 0.03 * sy, "", false, ui_elements.main_tab )
	dgsEditSetPlaceHolder( ui_elements.name_edit, "Name" )
	addEventHandler( "onDgsTextChange", ui_elements.name_edit, check_adding_valid )

	ui_elements.surname_edit = dgsCreateEdit( sx * 0.28, sy * 0.07, 0.17 * sx, 0.03 * sy, "", false, ui_elements.main_tab )
	dgsEditSetPlaceHolder( ui_elements.surname_edit, "SurName" )
	addEventHandler( "onDgsTextChange", ui_elements.surname_edit, check_adding_valid )

	ui_elements.adress_edit = dgsCreateEdit( sx * 0.28, sy * 0.11, 0.17 * sx, 0.03 * sy, "", false, ui_elements.main_tab )
	dgsEditSetPlaceHolder( ui_elements.adress_edit, "Adress" )
	addEventHandler( "onDgsTextChange", ui_elements.adress_edit, check_adding_valid )

	ui_elements.search_edit = dgsCreateEdit( sx * 0.005, sy * 0.31, 0.17 * sx, 0.03 * sy, "", false, ui_elements.main_tab )
	dgsEditSetPlaceHolder( ui_elements.search_edit , "Введите параметр поиска" )

	ui_elements.button_to_add_new = dgsCreateButton( sx * 0.28, sy * 0.15, 0.17 * sx, 0.05 * sy, "Add", false, ui_elements.main_tab )
	dgsSetEnabled( ui_elements.button_to_add_new, false )
	addEventHandler ( "onDgsMouseClickDown", ui_elements.button_to_add_new, function()

		triggerServerEvent( "onAddNewPersonInDB", resourceRoot, selected_par.name, selected_par.surname, selected_par.adress )
		dgsSetEnabled( ui_elements.button_to_add_new, false )

	end, false )

	ui_elements.button_to_delete_user = dgsCreateButton( sx * 0.28, sy * 0.23, 0.17 * sx, 0.05 * sy, "Delete", false, ui_elements.main_tab )
	dgsSetEnabled( ui_elements.button_to_delete_user, false )
	addEventHandler ( "onDgsMouseClickDown", ui_elements.button_to_delete_user, delete_user_handler, false )

	ui_elements.button_to_modify_user = dgsCreateButton( sx * 0.28, sy * 0.31, 0.17 * sx, 0.05 * sy, "Редактировать", false, ui_elements.main_tab )
	dgsSetEnabled( ui_elements.button_to_modify_user, false )
	addEventHandler ( "onDgsMouseClickDown", ui_elements.button_to_modify_user, modify_user_handler, false )

	ui_elements.button_search = dgsCreateButton( sx * 0.005, sy * 0.35, 0.17 * sx, 0.05 * sy, "Искать", false, ui_elements.main_tab )
	addEventHandler( "onDgsMouseClickDown", ui_elements.button_search, search_needed_parameters, false )

	dgsGridListAddColumn( ui_elements.gridlist_main, "Имя", 0.3 )
	dgsGridListAddColumn( ui_elements.gridlist_main, "Фамилия", 0.3 )
	dgsGridListAddColumn( ui_elements.gridlist_main, "Адрес", 0.3 )

	addEventHandler( "onDgsGridListSelect", ui_elements.gridlist_main, function()
		dgsSetEnabled( ui_elements.button_to_delete_user, true )
		dgsSetEnabled( ui_elements.button_to_modify_user, dgsGetEnabled( ui_elements.button_to_add_new ) )
	end )

	addEventHandler( "onDgsWindowClose", ui_elements.window, destroy_ui_handler )

	showCursor( true )
	dgsSetInputMode( "no_binds_when_editing" )
	fill_in_gridlist( data_from_db )
end
addEvent( "onInitWindow", true )
addEventHandler( "onInitWindow", resourceRoot, init_ui )

addEvent( "onCloseWindow", true )
addEventHandler( "onCloseWindow", resourceRoot, destroy_ui_handler )

addEvent( "onAddPlayerToGrid", true )
addEventHandler( "onAddPlayerToGrid", resourceRoot, add_row_to_grid )

addEvent( "onDelPlayerFromGrid", true )
addEventHandler( "onDelPlayerFromGrid", resourceRoot, del_row_from_grid )

addEvent( "onModifyPlayerInGrid", true )
addEventHandler( "onModifyPlayerInGrid", resourceRoot, modify_row_from_grid )