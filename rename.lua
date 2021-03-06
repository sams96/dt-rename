--[[
	dt-rename, a bulk/sequencial file renaming script for darktable
    Copyright (C) 2021  Sam Smith

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]
local dt = require "darktable"
local du = require "lib/dtutils"

local script_data = {}

local rename = {}
rename.widgets = {}
rename.event_registered = false
rename.module_installed = false

local MODULE_NAME = "rename"
local DEFAULT_ENTRY = "{filmroll}{sequence}.{extension}"
local ENTRY_PREFERENCE_KEY = "new_name"

du.check_min_api_version("7.0.0", MODULE_NAME)

-- string pref helper functions, from darktable-org/lua-scripts/video_ffmpeg.lua
local function string_pref_read(name, default)
	local value = dt.preferences.read(MODULE_NAME, name, "string")
	if value ~= nil and value ~= "" then return value end
	return default
end

local function string_pref_write(name, widget_attribute)
	widget_attribute = widget_attribute or "value"
	local writer = function(widget)
		dt.preferences.write(MODULE_NAME, name, "string", widget[widget_attribute])
	end
	return writer
end

-- format string helper function, from darktable-org/lua-scripts/video_ffmpeg.lua
local function format_string(label, symbols)
	local es1, es2 = "\u{ffe0}", "\u{ffe1}"
	local result = label:gsub("\\{", es1):gsub("\\}", es2)
	for s,v in pairs(symbols) do
		result = result:gsub("{"..s.."}", v)
	end
	return result:gsub(es1, "{"):gsub(es2, "}")
end

-- get file extension, from stack overflow
local function get_file_extension(path)
  return path:match("^.+(%..+)$")
end

local function get_file_name(path)
	return path:match("^.+/(.+)$")
end

local name_entry = dt.new_widget("entry") {
	tooltip = "enter pattern for new file names.\n\n"..
		"you can use these variables:\n"..
		"- {sequence} - the number of the image in the sequence\n"..
		"- {extension} - the original extension of the file\n"..
		"- {filmroll} - the name of the filmroll that the image is in",
	text = string_pref_read(ENTRY_PREFERENCE_KEY, DEFAULT_ENTRY),
}

local function rename_files(self)
	local files = {}
	local oldnames = {}
	for _, v in ipairs(dt.collection) do
		table.insert(files, v)
		table.insert(oldnames, tostring(v))
	end

	-- set up temp job indicator
	local tempjob = dt.gui.create_job(
		string.format("temp rename (%d image" .. (#files == 1 and "" or "s") .. ")", #files),
		true
	)
	tempjob.percent = 0.0
	local job_increment = 1.0 / #files

	-- set & get entry value
	string_pref_write(ENTRY_PREFERENCE_KEY, "text")(name_entry)
	local name_input = string_pref_read(ENTRY_PREFERENCE_KEY, DEFAULT_ENTRY)

	-- move to temp locations to avoid collisions.
	for i, v in ipairs(files) do
		dt.database.move_image(v, v.film, get_file_name(os.tmpname()))
		tempjob.percent = tempjob.percent + job_increment
	end
	tempjob.valid = false

	-- set up job indicator
	local job = dt.gui.create_job(
		string.format("rename images (%d image" .. (#files == 1 and "" or "s") .. ")", #files),
		true
	)
	job.percent = 0.0

	local filename_mappings = {}

	-- move files
	for i, v in ipairs(files) do
		filename_mappings.sequence = string.format("%02d", i)
		filename_mappings.extension = get_file_extension(tostring(oldnames[i])) or ".noext"
		filename_mappings.filmroll = get_file_name(tostring(v.film))

		local name = format_string(name_input, filename_mappings)
		dt.database.move_image(v, v.film, name)
		job.percent = job.percent + job_increment
	end
	job.valid = false
end

local function module()
	return dt.new_widget("box") {
		orientation = "vertical",
		dt.new_widget("box") {
			orientation = "horizontal",
			dt.new_widget("label") { label = "name" },
			name_entry
		},
		dt.new_widget("button") {
			label = "rename collection",
			clicked_callback = rename_files
		}
	}
end

local function install_module()
	if not rename.module_installed then
		dt.register_lib(
			MODULE_NAME,
			MODULE_NAME,
			true,
			false,
			{ [dt.gui.views.lighttable] = {"DT_UI_CONTAINER_PANEL_RIGHT_CENTER", 20}, },
			module()
		)
	end
end

-- allow script manager to hide and show widget
local function destroy()
	dt.gui.libs[MODULE_NAME].visible = false
end

local function restart()
	dt.gui.libs[MODULE_NAME].visible = true
end

-- add module if in lighttable, otherwise add event to do so when we are
if dt.gui.current_view().id == "lighttable" then
	install_module()
else
	if not rename.event_registered then
		dt.register_event(
			MODULE_NAME, "view-changed",
			function(event, old_view, new_view)
				if new_view.name == "lighttable" and old_view.name == "darkroom" then
					install_module()
				end
			end
		)
		rename.event_registered = true
	end
end

script_data.destroy = destroy
script_data.restart = restart
script_data.destroy_method = "hide"
script_data.show = restart

return script_data
