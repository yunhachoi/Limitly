on run argv
    if (count of argv) is 0 then return

    set volumeName to item 1 of argv
    set backgroundPath to missing value
    if (count of argv) > 1 then set backgroundPath to item 2 of argv

    tell application "Finder"
        delay 5
        set installerDisk to disk (volumeName as text)

        -- A newly-created image has no root .DS_Store yet. Give Finder one
        -- open/close cycle to create that record before applying custom view
        -- options; otherwise the first mount can overwrite them with the
        -- 48px/name-sorted defaults while it finishes loading the volume.
        open installerDisk
        delay 5
        try
            close container window of installerDisk
        end try
        delay 8

        -- Reopen after the initial metadata flush, then apply the final
        -- layout to the stable Finder window.
        open installerDisk
        delay 5
        set installerWindow to missing value
        repeat 10 times
            try
                set installerWindow to container window of installerDisk
                exit repeat
            on error
                delay 1
            end try
        end repeat
        if installerWindow is missing value then return

        set current view of installerWindow to icon view
        set toolbar visible of installerWindow to false
        set statusbar visible of installerWindow to true
        -- Finder stores bounds in screen coordinates. Keep the distributed
        -- installer window at 700x400 while leaving it resizable by the user.
        set bounds of installerWindow to {120, 100, 820, 500}

        -- Positions are icon centers. The second item is deliberately to the
        -- right; automatic name sorting would otherwise put Applications first.
        set position of item "Limitly.app" of installerDisk to {190, 190}
        set position of item "Applications" of installerDisk to {510, 190}

        -- Set view options after item positions. Finder may reapply its
        -- default name arrangement when positions are changed, so options
        -- must be the final view mutation before the window is closed.
        set viewOptions to icon view options of installerWindow
        set icon size of viewOptions to 128
        set arrangement of viewOptions to not arranged
        set shows item info of viewOptions to false
        if backgroundPath is not missing value then
            set background picture of viewOptions to POSIX file backgroundPath
        end if

        delay 3
        close installerWindow
        -- Finder writes .DS_Store asynchronously after closing the window.
        -- Wait before hdiutil detaches the writable image or the next mount
        -- will fall back to 48px/name-sorted defaults.
        delay 20
    end tell
end run
