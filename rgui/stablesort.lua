-- Based on the stable hybrid merge-insertion sort by S. Fisher
-- <http://lua.2524044.n2.nabble.com/A-stable-sort-td7648892.html>
-- Licensed under Creative Commons 0 (CC0)

-- if you're using LuaJIT, change to 72
local max_chunk_size = 12

local function insertion_sort(array, first, last, goes_before)
    for i = first + 1, last do
        local k = first
        local v = array[i]
        for j = i, first + 1, -1 do
            if goes_before(v, array[j-1]) then
                array[j] = array[j-1]
            else
                k = j
                break
            end
        end
        array[k] = v
    end
end

local function merge(array, workspace, low, middle, high, goes_before)
    local i, j, k
    i = 1
    -- Copy first half of array to auxiliary array
    for j = low, middle do
        workspace[i] = array[j]
        i = i + 1
    end
    i = 1
    j = middle + 1
    k = low
    while true do
        if (k >= j) or (j > high) then
            break
        end
        if goes_before(array[j], workspace[i]) then
            array[k] = array[j]
            j = j + 1
        else
            array[k] = workspace[i]
            i = i + 1
        end
        k = k + 1
    end
    -- Copy back any remaining elements of first half
    for k = k, j-1 do
        array[k] = workspace[i]
        i = i + 1
    end
end

local function merge_sort(array, workspace, low, high, goes_before)
    if high - low < max_chunk_size then
        insertion_sort(array, low, high, goes_before)
    else
        local middle = math.floor((low + high)/2)
        merge_sort(array, workspace, low, middle, goes_before)
        merge_sort(array, workspace, middle + 1, high, goes_before)
        merge(array, workspace, low, middle, high, goes_before)
    end
end

local function stable_sort(array, goes_before)
    local n = #array
    if n < 2 then return array end
    goes_before = goes_before or function(a, b) return a < b end
    local workspace = {}
    -- Allocate some room
    workspace[math.floor((n+1) / 2)] = array[1]
    if goes_before(array[1], array[1]) then
        error("invalid order function for sorting")
    end
    merge_sort(array, workspace, 1, n, goes_before)
    return array
end