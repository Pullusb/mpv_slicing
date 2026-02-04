local msg = require "mp.msg"
local utils = require "mp.utils"
local options = require "mp.options"

-- v1.2 - Updated to use subprocess instead of os.execute

local cut_pos = nil
local copy_audio = 0
-- iterate on three modes
-- 0 'normal' (video+audio), 1 'only_audio' (mp3), 2 'no_audio' (video)

-- Reencode to mp4
local o = {
    target_dir = "~",
    vcodec = "",-- add custom reencode settings here (basic mp4 settings is pretty good already)
    acodec = "",
    opts = "",
    ext = "mp4",
}

options.read_options(o)

function timestamp(duration)
    local hours = duration / 3600
    local minutes = duration % 3600 / 60
    local seconds = duration % 60
    return string.format("%02d_%02d_%02.03f", hours, minutes, seconds)
end

function timestamp_sec_round(duration)
    local hours = duration / 3600
    local minutes = duration % 3600 / 60
    local seconds = duration % 60
    return string.format("%02d_%02d_%02.0f", hours, minutes, seconds)
end

function osd(str)
    return mp.osd_message(str, 3)
end

function get_homedir()
    return os.getenv("HOME") or os.getenv("USERPROFILE") or ""
end

function log(str)
    local logpath = utils.join_path(
        mp.get_property("working-directory"),
        "mpv_slicing.log")
    f = io.open(logpath, "a")
    f:write(string.format("# %s\n%s\n",
        os.date("%Y-%m-%d %H:%M:%S"),
        str))
    f:close()
end

function get_outname(shift, endpos)
    local name = mp.get_property("filename")
    local dotidx = name:reverse():find(".", 1, true)
    if dotidx then name = name:sub(1, -dotidx-1) end
    name = name:gsub(" ", "_")
    name = name:gsub(":", "-")
    name = name .. string.format("-%s-%s", timestamp_sec_round(shift), timestamp_sec_round(endpos))
    return name
end

function cut(shift, endpos)
    local inpath = utils.join_path(
        utils.getcwd(),
        mp.get_property("stream-path"))
    local outpath = utils.join_path(
        mp.get_property("working-directory"),
        get_outname(shift, endpos))
    
    local ext = copy_audio == 1 and "mp3" or o.ext
    local outfile = outpath .. "." .. ext
    
    local args = {
        "ffmpeg",
        "-v", "warning",
        "-y",
        "-stats",
        "-ss", tostring(shift),
        "-i", inpath,
        "-t", tostring(endpos - shift),
    }
    
    -- Add video codec if specified
    if o.vcodec ~= "" then
        table.insert(args, "-c:v")
        table.insert(args, o.vcodec)
    end
    
    -- Add audio codec if specified
    if o.acodec ~= "" then
        table.insert(args, "-c:a")
        table.insert(args, o.acodec)
    end
    
    -- Audio handling
    if copy_audio == 1 then
        -- Audio only mode (mp3)
        table.insert(args, "-vn")
    elseif copy_audio == 2 then
        -- No audio mode
        table.insert(args, "-an")
    end
    
    -- Add extra options if specified
    if o.opts ~= "" then
        for opt in o.opts:gmatch("%S+") do
            table.insert(args, opt)
        end
    end
    
    table.insert(args, outfile)
    
    local cmd_str = table.concat(args, " ")
    msg.info(cmd_str)
    log(cmd_str)
    
    osd("Encoding started...")
    
    mp.command_native_async({
        name = "subprocess",
        args = args,
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
    }, function(success, result, error)
        if success and result.status == 0 then
            local out_name = get_outname(shift, endpos) .. "." .. ext
            osd("Slice saved: " .. out_name)
            msg.info("Slice completed successfully: " .. out_name)
        else
            local err_msg = "FFmpeg failed"
            if result and result.status then
                err_msg = err_msg .. " (code " .. result.status .. ")"
            end
            if error then
                err_msg = err_msg .. ": " .. tostring(error)
                msg.error("Error: " .. tostring(error))
            end
            if result and result.stderr and result.stderr ~= "" then
                msg.error("stderr: " .. result.stderr)
            end
            osd(err_msg)
            msg.error(err_msg)
            log("ERROR: " .. err_msg)
        end
    end)
end

function toggle_mark()
    local pos = mp.get_property_number("time-pos")
    if cut_pos then
        local shift, endpos = cut_pos, pos
        if shift > endpos then
            shift, endpos = endpos, shift
        end
        if shift == endpos then
            osd("Cut fragment is empty")
        else
            cut_pos = nil
            osd(string.format("Cut fragment: %s - %s",
                timestamp(shift),
                timestamp(endpos)))
            cut(shift, endpos)
        end
    else
        cut_pos = pos
        osd(string.format("Marked %s as start position", timestamp(pos)))
    end
end

function toggle_audio()
    if copy_audio == 0 then
        copy_audio = 1
        osd("Audio Only")
    elseif copy_audio == 1 then
        copy_audio = 2
        osd("Audio Disabled")
    else
        copy_audio = 0
        osd("Audio Enabled")
    end
end

mp.add_key_binding("c", "slicing_mark", toggle_mark)
mp.add_key_binding("a", "slicing_audio", toggle_audio)