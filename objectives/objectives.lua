--[[
* Ashita - Copyright (c) 2014 - 2016 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

_addon.author   = 'towbes';
_addon.name     = 'objectives';
_addon.version  = '0.0.1';

require 'common';


local __debug = false;
local __write = false;


----------------------------------------------------------------------------------------------------
-- func: print_help
-- desc: Displays a help block for proper command usage.
----------------------------------------------------------------------------------------------------
local function print_help(cmd, help)
    -- Print the invalid format header..
    print('\31\200[\31\05' .. _addon.name .. '\31\200]\30\01 ' .. '\30\68Invalid format for command:\30\02 ' .. cmd .. '\30\01'); 

    -- Loop and print the help commands..
    for k, v in pairs(help) do
        print('\31\200[\31\05' .. _addon.name .. '\31\200]\30\01 ' .. '\30\68Syntax:\30\02 ' .. v[1] .. '\30\71 ' .. v[2]);
    end
end

---------------------------------------------------------------------------------------------------
-- func: clean_str
-- desc: Cleans a string of auto-translate and color tags.
---------------------------------------------------------------------------------------------------
local function clean_str(str)
    -- Parse auto-translate tags..
    str = ParseAutoTranslate(str, true);

    -- Strip the string of color tags..
    str = (str:gsub('[' .. string.char(0x1E, 0x1F, 0x7F) .. '].', ''));

    -- Strip the string of auto-translate tags..
    str = (str:gsub(string.char(0xEF) .. '[' .. string.char(0x27) .. ']', '{'));
    str = (str:gsub(string.char(0xEF) .. '[' .. string.char(0x28) .. ']', '}'));

    -- Trim linebreaks from end of strings..
    while true do
        local hasN = str:endswith('\n');
        local hasR = str:endswith('\r');
        if (hasN or hasR) then
            if (hasN) then
                str = str:trimend('\n');
            end
            if (hasR) then
                str = str:trimend('\r');
            end
        else
            break;
        end
    end
        
    -- Convert mid-linebreaks to real linebreaks..
    str = (str:gsub(string.char(0x07), '\n'));
    
    return str;
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end


---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Event called when the addon is asked to handle an incoming data.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, data, modified, blocked)
    if (id == 0x111) then
		if (__debug) then
			print(string.format("Incoming packet: 0x%X ", id));
		end
	end
    if (id == 0x029) then
		if (__debug) then
			msg = struct.unpack('I4', data, 0x18 + 1);
			print(string.format("Sent quest packet with Objective id of: 0x%X", obj));
		end
	end
	return false;
end);

ashita.register_event('outgoing_packet', function(id, size, data, modified, blocked)
    if (id == 0x10C) then
		obj = struct.unpack('I4', data, 0x04 + 1);
			if (__debug) then
				print(string.format("Sent quest packet with Objective id of: 0x%X", obj));
			end
--	ashita.timer.create('castTimer', 7, 1, new_cast)
	--	print("The Client just sent data:", struct.unpack('I2I2II2I2I2BBI', data))
    end
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Event called when the addon is asked to handle an incoming chat line.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, message, modifiedmode, modifiedmessage, blocked)

	if(__write) then
		--Logs name of Regime with current packet object value
		-- Create the file name and ensure the path to it exists..
		local d = os.date('*t');
		local n = string.format('%.2u.%.2u.%.4u.log', d.month, d.day, d.year);
		local p = string.format('%s/%s/', AshitaCore:GetAshitaInstallPath(), 'roelogs');
		if (not ashita.file.dir_exists(p)) then
			ashita.file.create_dir(p);
		end
		if string.starts(message, "You have undertaken") then
			-- Append the new chat line to the file..
			local f = io.open(string.format('%s/%s', p, n), 'a');
			if (f ~= nil) then
				--change the objective ID to hex
				print("Wrote objective to file");
				objhex = string.format("%X", obj)
				--Get the regime name from chat message by getting text within quotes You have undertaken "$regime"
				cleaned = clean_str(message)
				regime = string.sub(cleaned,23,string.len(cleaned)-3)
				local t = os.date(timestamp, os.time());
				f:write('$' .. objhex .. ';' .. regime .. '\n');
				f:close();
			end
		end
	end
    
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: get_quest
-- desc: Event called when the addon is asked to handle an incoming data.
---------------------------------------------------------------------------------------------------
function get_objective(objectiveId)
	if(__debug) then
		print("Registering ROE objective");
	end
	local getcommand = struct.pack('I2I2I4', 0x050C, 0x0000, objectiveId):totable();
	AddOutgoingPacket(0x10C, getcommand);
end;

---------------------------------------------------------------------------------------------------
-- func: get_quest
-- desc: Event called when the addon is asked to handle an incoming data.
---------------------------------------------------------------------------------------------------
function remove_objective(objectiveId)
	print("Removing RoE Objective " .. objectiveId)
	local getcommand = struct.pack('I2I2I4', 0x050D, 0x0000, objectiveId):totable();
	AddOutgoingPacket(0x10D, getcommand);
end;

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    -- Get the arguments of the command..
    local args = command:args();

    if (args[1] ~= '/objectives') then
        return false;
    end

    -- Get an RoE Objective
    if (#args == 3 and args[2] == 'get' and string.starts(args[3], "0x") and string.len(args[3]) == 6) then
		get_objective(args[3]);
        return true;
    end
	
    -- Remove an RoE objective
    if (#args == 3 and args[2] == 'remove' and string.starts(args[3], "0x") and string.len(args[3]) == 6) then
		remove_objective(args[3]);
        return true;
    end
	
	if (#args >= 2 and args[2] == 'debug') then
		if (__debug) then
			print("Debug off");
			__debug = false;
		else
			print("Debug on");
			__debug = true;
		end
		return true;
	end	
	
	if (#args >= 2 and args[2] == 'write') then
		if (__write) then
			print("Objective Writing Off");
			__write = false;
		else
			print("Objective Writing On");
			__write = true;
		end
		return true;
	end	

    -- Prints the addon help..
    print_help('/objectives', {
		{ '/objectives get id', ' - Gets RoE objective with id format: 0x0ABC'},
		{ '/objectives remove id', ' - Removes RoE objective with id format: 0x0ABC'},
		{ '/objectives debug',   '- Toggles Debug flag on or off' },
        { '/objectives write',     '- Toggles writing RoE Hex + Description to Ashita folder/roelogs' },
		{ 'With write enabled, hex id + description will be written to file when accepting a new RoE objective', ''}
    });
    return true;

end);