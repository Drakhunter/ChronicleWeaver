-- =========================================================================
-- UI/ThemeEngine.lua
-- Dual-theme visual skin manager (Archivist Parchment vs. Midnight Obsidian).
-- Target Client: World of Warcraft: Forever (Interface: 16001, Client 1.60.1)
-- =========================================================================
local _, ns = ...

function ns.GetActiveTheme()
    local themeKey = (ns.db and ns.db.theme) or "PARCHMENT"
    return ns.THEMES[themeKey] or ns.THEMES.PARCHMENT
end

function ns.ApplyTheme()
    local theme = ns.GetActiveTheme()
    local isDark = theme.isDark
    local main = ChronicleWeaverMainFrame
    if not main then return end

    -- 1. Main Window Outer Frame (Always Solid Dark Obsidian / Espresso)
    main:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 20,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    main:SetBackdropColor(0.08, 0.07, 0.06, 0.98)
    main:SetBackdropBorderColor(0.70, 0.55, 0.20, 1.0)

    -- 2. Sidebar List Panel (Always Solid Dark Slate in Both Themes for High Contrast)
    if main.listPanel then
        local lp = main.listPanel
        lp:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        lp:SetBackdropColor(0.06, 0.05, 0.05, 0.95)
        lp:SetBackdropBorderColor(0.40, 0.35, 0.25, 0.85)
    end

    -- 3. Right-Hand Reader Panel (Theme Applied Specifically Here!)
    if main.readerPanel then
        local rp = main.readerPanel
        rp:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })

        if isDark then
            -- Midnight Obsidian Theme
            rp:SetBackdropColor(0.06, 0.05, 0.04, 0.96)
            rp:SetBackdropBorderColor(0.28, 0.32, 0.40, 1.00)

            -- Vignette Overlay: Hidden in Dark mode
            if rp.vignette then
                rp.vignette:Hide()
            end

            -- Filigree Divider & Extending Wings
            if rp.divider then
                rp.divider:SetVertexColor(0.95, 0.80, 0.40, 0.85)
            end
            if rp.dividerLineL then rp.dividerLineL:SetColorTexture(0.83, 0.66, 0.35, 0.45) end
            if rp.dividerLineR then rp.dividerLineR:SetColorTexture(0.83, 0.66, 0.35, 0.45) end

            -- Portrait Medallion Ring
            if rp.portraitRing then
                rp.portraitRing:SetVertexColor(1.00, 0.88, 0.50, 1.00)
            end

            -- Typography: Light Ivory & Gold with 1px drop shadow
            if rp.entryHeading then
                rp.entryHeading:SetTextColor(0.95, 0.80, 0.45)
                rp.entryHeading:SetShadowColor(0, 0, 0, 1)
                rp.entryHeading:SetShadowOffset(1, -1)
            end
            if rp.entryMeta then
                rp.entryMeta:SetTextColor(0.65, 0.75, 0.85)
                rp.entryMeta:SetShadowColor(0, 0, 0, 1)
                rp.entryMeta:SetShadowOffset(1, -1)
            end
            if rp.entrySummary then
                rp.entrySummary:SetTextColor(0.95, 0.85, 0.55)
                rp.entrySummary:SetShadowColor(0, 0, 0, 1)
                rp.entrySummary:SetShadowOffset(1, -1)
            end
            if rp.entryStory then
                rp.entryStory:SetTextColor(0.90, 0.86, 0.78)
                rp.entryStory:SetShadowColor(0, 0, 0, 1)
                rp.entryStory:SetShadowOffset(1, -1)
            end
            if rp.notesLabel then
                rp.notesLabel:SetTextColor(0.83, 0.66, 0.35)
                rp.notesLabel:SetShadowColor(0, 0, 0, 1)
                rp.notesLabel:SetShadowOffset(1, -1)
            end
            if rp.connLabel then
                rp.connLabel:SetTextColor(0.83, 0.66, 0.35)
                rp.connLabel:SetShadowColor(0, 0, 0, 1)
                rp.connLabel:SetShadowOffset(1, -1)
            end

            -- Notes Box: Dark Slate Fill
            if rp.notesBg then
                rp.notesBg:SetBackdropColor(0.04, 0.04, 0.05, 0.95)
                rp.notesBg:SetBackdropBorderColor(0.40, 0.35, 0.25, 0.80)
            end
            if rp.notesBox then
                rp.notesBox:SetTextColor(0.90, 0.88, 0.82)
                rp.notesBox:SetShadowColor(0, 0, 0, 1)
                rp.notesBox:SetShadowOffset(1, -1)
            end
        else
            -- Archivist Parchment Theme (Warm Ivory Paper & Dark Ink)
            rp:SetBackdropColor(0.92, 0.85, 0.72, 1.00)
            rp:SetBackdropBorderColor(0.65, 0.50, 0.28, 1.00)

            -- Vignette Overlay: Rich Aged Burnt-Umber Edges
            if rp.vignette then
                rp.vignette:SetAlpha(0.65)
                rp.vignette:Show()
            end

            -- Filigree Divider & Extending Wings
            if rp.divider then
                rp.divider:SetVertexColor(0.85, 0.68, 0.35, 0.90)
            end
            if rp.dividerLineL then rp.dividerLineL:SetColorTexture(0.65, 0.50, 0.28, 0.50) end
            if rp.dividerLineR then rp.dividerLineR:SetColorTexture(0.65, 0.50, 0.28, 0.50) end

            -- Portrait Medallion Ring
            if rp.portraitRing then
                rp.portraitRing:SetVertexColor(0.92, 0.82, 0.55, 1.00)
            end

            -- Typography: Deep Ink with NO drop shadows on light paper
            if rp.entryHeading then
                rp.entryHeading:SetTextColor(0.32, 0.14, 0.04)
                rp.entryHeading:SetShadowColor(0, 0, 0, 0)
                rp.entryHeading:SetShadowOffset(0, 0)
            end
            if rp.entryMeta then
                rp.entryMeta:SetTextColor(0.42, 0.30, 0.18)
                rp.entryMeta:SetShadowColor(0, 0, 0, 0)
                rp.entryMeta:SetShadowOffset(0, 0)
            end
            if rp.entrySummary then
                rp.entrySummary:SetTextColor(0.48, 0.24, 0.06)
                rp.entrySummary:SetShadowColor(0, 0, 0, 0)
                rp.entrySummary:SetShadowOffset(0, 0)
            end
            if rp.entryStory then
                rp.entryStory:SetTextColor(0.14, 0.10, 0.06)
                rp.entryStory:SetShadowColor(0, 0, 0, 0)
                rp.entryStory:SetShadowOffset(0, 0)
            end
            if rp.notesLabel then
                rp.notesLabel:SetTextColor(0.35, 0.22, 0.10)
                rp.notesLabel:SetShadowColor(0, 0, 0, 0)
                rp.notesLabel:SetShadowOffset(0, 0)
            end
            if rp.connLabel then
                rp.connLabel:SetTextColor(0.35, 0.22, 0.10)
                rp.connLabel:SetShadowColor(0, 0, 0, 0)
                rp.connLabel:SetShadowOffset(0, 0)
            end

            -- Notes Box: Tanned Parchment Fill & Dark Ink Text
            if rp.notesBg then
                rp.notesBg:SetBackdropColor(0.85, 0.78, 0.65, 1.00)
                rp.notesBg:SetBackdropBorderColor(0.58, 0.44, 0.26, 1.00)
            end
            if rp.notesBox then
                rp.notesBox:SetTextColor(0.14, 0.10, 0.06)
                rp.notesBox:SetShadowColor(0, 0, 0, 0)
                rp.notesBox:SetShadowOffset(0, 0)
            end
        end
    end

    -- 4. Theme Button Label
    if main.themeBtn then
        main.themeBtn:SetText("Theme: " .. theme.name)
    end

    if ns.SendMessage then
        ns.SendMessage("THEME_CHANGED", theme)
    end
end
