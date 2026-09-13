// components/fuzzy.js
//
// Simple subsequence-based fuzzy matcher, case-insensitive. Every character
// of `query` must appear in `target` IN ORDER (not necessarily contiguous),
// same basic idea as VS Code / Sublime's "type letters that appear in the
// name" matching. Returns -1 for no match, otherwise a score where HIGHER
// is a better match - consecutive-character runs and word-start matches are
// weighted more heavily than scattered single-character hits.
.pragma library

function score(query, target) {
    if (!query || query.length === 0)
        return 0;
    if (!target)
        return -1;

    var q = query.toLowerCase();
    var t = target.toLowerCase();

    var qi = 0;
    var total = 0;
    var consecutiveRun = 0;
    var prevMatchIndex = -1;

    for (var ti = 0; ti < t.length && qi < q.length; ti++) {
        if (t[ti] === q[qi]) {
            var isWordStart = ti === 0 || t[ti - 1] === " " || t[ti - 1] === "-" || t[ti - 1] === "_";
            var isConsecutive = prevMatchIndex === ti - 1;

            var charScore = 1;
            if (isWordStart) charScore += 3;
            if (isConsecutive) {
                consecutiveRun++;
                charScore += consecutiveRun * 2;
            } else {
                consecutiveRun = 0;
            }

            total += charScore;
            prevMatchIndex = ti;
            qi++;
        }
    }

    if (qi < q.length)
        return -1; // not every query character was found in order

    // Slight penalty for longer targets so shorter, more precise matches
    // (e.g. "Firefox" over "Firefox Developer Edition") rank a bit higher
    // for the same query when scores would otherwise tie closely.
    total -= t.length * 0.01;

    return total;
}
