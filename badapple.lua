--Bad Apple!! in Minecraft! Made by JamnedZ
--You'll need at least 1.8 MB to run video only, and 3 MB for video and audio.
--Use monitor 3x2 with scale 0.5! Or 6x4 with scale 1, I guess
--GitHub repo: https://github.com/JamElyZEuS/badapple_cctweaked

local video = {}
local no_video = false
local no_audio = false

local function download(sUrl) --this code's from rom wget script
    local ok, err = http.checkURL(sUrl)
    if not ok then
        printError(err or "Invalid URL.")
        return
    end

    local response = http.get(sUrl , nil , true)
    if not response then
        print("Failed.")
        return nil
    end

    local sResponse = response.readAll()
    response.close()
    return sResponse or ""
end

local function check_files()
    if not fs.exists('badapple.nfpa') then
        print('Video not found! Downloading...')
        local video_file = download('https://raw.githubusercontent.com/JamElyZEuS/badapple_cctweaked/main/badapple.nfpa')
        if not video_file then
            printError('Couldn\'t download video.')
            no_video = true
        else
            local video_save, err = fs.open('badapple.nfpa', 'w')
            if not video_save then
                printError('Couldn\'t save video file: ' .. err)
                no_video = true
            else
                video_save.write(video_file)
                video_save.close()
                print('Video\'s downloaded successfully!')
            end
        end
    end

    if not fs.exists('badapple.dfpwm') and not no_audio then
        print('Music not found! Downloading...')
        local audio_file = download('https://raw.githubusercontent.com/JamElyZEuS/badapple_cctweaked/main/badapple.dfpwm')
        if not audio_file then
            printError('Couldn\'t download audio.')
            no_audio = true
        else
            local audio_save, err = fs.open('badapple.dfpwm', 'wb')
            if not audio_save then
                printError('Couldn\'t save audio file: ' .. err)
                no_audio = true
            else
                audio_save.write(audio_file)
                audio_save.close()
                print('Audio\'s downloaded successfully!')
            end
        end
    end


end

local function unpack()
    print('Loading video...')

    local line_counter = 1
    local frame_counter = 1
    local current_frame = ''
    for line in io.lines("badapple.nfpa") do
        os.queueEvent('cmonnow')
        if line_counter > 24 then
            video[frame_counter] = current_frame
            current_frame = ''
            line_counter = 1
            frame_counter = frame_counter + 1
        end
        if frame_counter > 2192 then break end

        current_frame = current_frame .. line .. '\n'
        line_counter = line_counter + 1
        os.pullEvent()
    end
end



local function aud()
    local dfpwm = require "cc.audio.dfpwm"
    local speaker = peripheral.find("speaker")

    local decoder = dfpwm.make_decoder()
    for input in io.lines("badapple.dfpwm", 16 * 1024) do
        local decoded = decoder(input)
        while not speaker.playAudio(decoded) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

local function vid()
    local myterm = term.current()
    local buffer = window.create(myterm, 13, 1, 32, 24)
    buffer.setVisible(false)

    local timeformat = os.time('local') < 20 and 'local' or 'utc'
    local starttime = os.time(timeformat)

    local SEC = 0.000277777777

    for i = 1, 2192, 1 do
        if (os.time(timeformat) - starttime) <= ((i - 1) * (SEC / 10)) then
            term.redirect(buffer)

            term.clear()
            local frame = paintutils.parseImage(video[i])
            paintutils.drawImage(frame, 1, 1)

            term.redirect(myterm)
            buffer.setVisible(true)
            buffer.setVisible(false)

            sleep(1/10 + (((i - 1) * (SEC / 10)) - (os.time(timeformat) - starttime)))
        end
    end
end



term.clear()
if not peripheral.find('speaker') then no_audio = true end
check_files()
if not no_audio and not no_video then
    print('Enjoy your full Bad Apple!! experience!')
    unpack()
    term.clear()
    parallel.waitForAll(aud, vid)
elseif no_audio and not no_video then
    print('You will have no audio playback. Connect speakers and download all files for better experience!')
    unpack()
    term.clear()
    vid()
elseif no_video and not no_audio then
    print('You have no video file... Well, at least you\'re able to listen to some classics. Enjoy!')
    aud()
else
    print('Playing failed. Shutting down...')
    return
end

sleep(0.1)