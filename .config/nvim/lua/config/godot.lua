-- godot editor setting: --server {project}/server.pipe --remote-send "<C-\><C-N>:e {file}<CR>:call cursor({line}+1,{col})<CR>"
local project_root = vim.fs.root(vim.fn.getcwd(), "project.godot")

if project_root then
	local pipe = project_root .. "/server.pipe"
	if not vim.uv.fs_stat(pipe) then
		vim.fn.serverstart(pipe)
	end
end
