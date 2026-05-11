--- Image previewer using `chafa --format=symbols`.
--- Renders images as Unicode-block art with truecolor — works in any
--- terminal (incl. Alacritty), no graphics protocol required.
--- Replace this previewer once you switch to a terminal that supports
--- Kitty / iTerm2 / Sixel — Yazi's built-in image previewer is sharper.

local M = {}

function M:peek(job)
	local w = math.max(1, job.area.w)
	local h = math.max(1, job.area.h)

	local output = Command("chafa")
		:arg({
			"--format=symbols",
			"--symbols=block",
			"--colors=truecolor",
			"--size=" .. w .. "x" .. h,
			"--polite=on",
			"--passthrough=none",
			"--",
			tostring(job.file.url),
		})
		:output()

	if not output then
		return ya.preview_widget(
			job,
			ui.Text("chafa-image: failed to invoke `chafa`."):area(job.area)
		)
	end
	if not output.status.success then
		return ya.preview_widget(
			job,
			ui.Text("chafa error:\n" .. (output.stderr or "")):area(job.area)
		)
	end

	ya.preview_widget(job, ui.Text.parse(output.stdout):area(job.area))
end

function M:seek() end

return M
