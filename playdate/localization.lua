-- docs: https://sdk.play.date/3.0.0/Inside%20Playdate.html#_localization

playdate.getSystemLanguage = playdate.getSystemLanguage or function()
    -- TODO: save language to file
    return playdate.graphics.font.kLanguageEnglish
end