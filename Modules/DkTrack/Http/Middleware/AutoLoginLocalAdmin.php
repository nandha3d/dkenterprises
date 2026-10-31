<?php

namespace Modules\DkTrack\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AutoLoginLocalAdmin
{
    public function handle(Request $request, Closure $next)
    {
        if (!Auth::check() && app()->environment('local')) {
            $user = \App\Models\User::find(1);
            if ($user) {
                Auth::setUser($user);
                Auth::login($user);
                $request->setUserResolver(fn () => $user);
            }
        }
        return $next($request);
    }
}
