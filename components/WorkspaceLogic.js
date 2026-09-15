.pragma library

// Use the plugin's focused flag, never derive a vdesk from workspace IDs:
// custom layouts can put the same workspace on more than one virtual desktop.
function parseVdesks(text) {
    var parsed = JSON.parse(text)
    if (!Array.isArray(parsed)) throw new Error("Virtual desktop state is not an array")
    var desks = parsed.filter(function(d) { return Number.isInteger(d.id) && d.id > 0 })
    var active = desks.find(function(d) { return d.focused === true })
    if (!active) throw new Error("No active virtual desktop reported")
    return {active: active.id, desks: desks}
}

function entries(activeId, count, existing) {
    count = Math.max(1, Math.min(12, Math.floor(count)))
    // Named native workspaces are negative IDs. Preserve their names and IDs.
    if (activeId < 0) {
        var named = existing.filter(function(w) { return w.id < 0 && w.name !== "special" && String(w.name).indexOf("special:") !== 0 })
        var activeIndex = Math.max(0, named.findIndex(function(w) { return w.id === activeId }))
        return named.slice(Math.floor(activeIndex / count) * count, (Math.floor(activeIndex / count) + 1) * count)
    }
    var start = Math.floor((Math.max(1, activeId) - 1) / count) * count + 1
    var result = []
    for (var i = 0; i < count; ++i) {
        var id = start + i
        result.push(existing.find(function(w) { return w.id === id }) || {id: id, name: String(id)})
    }
    return result
}

function command(id, name, vdesk) {
    if (!Number.isInteger(id) || id === 0) return ""
    if (vdesk) return id > 0 ? "vdesk " + id : ""
    return "workspace " + (id > 0 ? id : "name:" + name)
}
