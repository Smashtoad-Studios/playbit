local module = {}
playbit = playbit or {}
playbit.table = module

function module.getSize(table)
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
end