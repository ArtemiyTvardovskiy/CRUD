function update_information_from_players( name, surname, adress, event_to_trigger, new_name, new_surname, new_adress )
    for player, player_data in pairs( PlayerData ) do
        if player_data.UI then
            triggerClientEvent( player, event_to_trigger, resourceRoot, name, surname, adress, new_name, new_surname, new_adress  )
        end
    end
end