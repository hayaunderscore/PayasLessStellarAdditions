PLSA = SMODS.current_mod

-- Loads all files in a folder...
function PLSA.LoadFolder(path)
	local files = SMODS.NFS.getDirectoryItemsInfo(PLSA.path .. "/" .. path)
	for i = 1, #files do
		local file_name = files[i].name
		if file_name:sub(-4) == ".lua" then
			assert(SMODS.load_file(path .. file_name))()
		end
	end
end
