module MirageReviseExt

# Optional integration: when the user loads `Revise`, this extension wires
# Mirage's `live_revise!` hook to `Revise.revise()` so the live-development
# workflow (`run_live!`) hot-reloads edited code while the app keeps running.
# Without Revise loaded, `live_revise!` is a harmless no-op and Mirage carries
# no hard dependency on a development-only tool.

import Mirage
import Revise

# Tracks the last Revise error so we only warn once per distinct failure.
const last_error = Ref{Union{Nothing, String}}(nothing)

function _revise!(_app)
    try
        Revise.revise()
        last_error[] = nothing
    catch e
        msg = sprint(showerror, e)
        if msg != last_error[]
            @warn "Revise failed; fix the error and the live app will retry." exception = (e, catch_backtrace())
            last_error[] = msg
        end
    end
    return nothing
end

function __init__()
    Mirage._live_revise_hook[] = _revise!
    return nothing
end

end # module MirageReviseExt
