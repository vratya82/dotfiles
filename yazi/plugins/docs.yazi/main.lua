--- Preview office / rich-text documents (docx, doc, odt, rtf, epub) by
--- shelling out to `pandoc -t plain` and rendering the result as text.

local M = {}

function M:peek(job)
	local output = Command("pandoc")
		:arg({ "-t", "plain", "--wrap=preserve", "--", tostring(job.file.url) })
		:output()

	if not output then
		return ya.preview_widget(
			job,
			ui.Text("docs.yazi: failed to invoke `pandoc` — is it on your PATH?"):area(job.area)
		)
	end

	if not output.status.success then
		return ya.preview_widget(
			job,
			ui.Text("pandoc error:\n" .. (output.stderr or "")):area(job.area)
		)
	end

	-- collect lines and clip to the visible window
	local lines = {}
	for line in (output.stdout .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = line
	end

	local skip = job.skip or 0
	local visible = {}
	for i = skip + 1, math.min(#lines, skip + job.area.h) do
		visible[#visible + 1] = lines[i]
	end

	ya.preview_widget(job, ui.Text(visible):area(job.area))
end

function M:seek(job)
	local h = cx.active.current.hovered
	if not h or h.url ~= job.file.url then
		return
	end
	local step = math.floor(job.units * job.area.h / 2)
	ya.manager_emit("peek", {
		math.max(0, (cx.active.preview.skip or 0) + step),
		only_if = job.file.url,
	})
end

return M
