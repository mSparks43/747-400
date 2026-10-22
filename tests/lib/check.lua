-- Assertion helpers for the regression tests (tests/README.md).
-- Each check counts; failures are collected and reported together by done().
--   local T = dofile("tests/lib/check.lua")("suite name")
--   T.check(cond, "message")  T.equal(a, b, "message")  T.near(a, b, tol, "message")
--   T.done()
return function(suite)
    local T = {checks = 0, failures = {}}
    function T.check(condition, message)
        T.checks = T.checks + 1
        if not condition then T.failures[#T.failures + 1] = message end
        return condition
    end
    function T.equal(actual, expected, message)
        return T.check(actual == expected,
            message .. ": got " .. tostring(actual) .. ", want " .. tostring(expected))
    end
    function T.near(actual, expected, tolerance, message)
        return T.check(type(actual) == "number" and math.abs(actual - expected) <= tolerance,
            message .. ": got " .. tostring(actual) .. ", want " .. tostring(expected) .. " +/- " .. tostring(tolerance))
    end
    function T.done()
        if #T.failures > 0 then
            error(string.format("%s: %d of %d checks failed:\n  %s", suite, #T.failures, T.checks,
                table.concat(T.failures, "\n  ")), 0)
        end
        print(string.format("%s: %d checks passed", suite, T.checks))
    end
    return T
end
