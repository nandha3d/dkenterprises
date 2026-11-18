<?php

namespace App\Services\Notifications;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class ActivityNotificationService
{
    /**
     * Persist real-time activity notifications for Super Admins and vertical Incharges,
     * plus record the operational event on the actor's feed.
     */
    public function notifyActivity(
        int $companyId,
        int $actorUserId,
        string $actorName,
        string $activityType,
        string $title,
        string $body,
        array $metadata = [],
        string $severity = 'info',
        string $route = '/notifications'
    ): void {
        try {
            $superAdminIds = DB::table('users')
                ->where('role_id', 1)
                ->where('is_active', true)
                ->where('is_deleted', false)
                ->pluck('id')
                ->map(fn ($id) => (int) $id)
                ->all();

            $inchargeIds = DB::table('company_user')
                ->join('users', 'company_user.user_id', '=', 'users.id')
                ->leftJoin('roles', 'users.role_id', '=', 'roles.id')
                ->where('company_user.company_id', $companyId)
                ->where('users.is_active', true)
                ->where('users.is_deleted', false)
                ->where(function ($q) {
                    $q->where('users.role_id', 1)
                        ->orWhereIn(DB::raw("LOWER(COALESCE(users.name, ''))"), ['admin', 'agent', 'field_agent'])
                        ->orWhereIn(DB::raw("LOWER(COALESCE(roles.name, ''))"), ['admin', 'superadmin', 'field agent', 'agent', 'incharge', 'manager']);
                })
                ->pluck('users.id')
                ->map(fn ($id) => (int) $id)
                ->all();

            $recipientIds = collect(array_merge($superAdminIds, $inchargeIds, [$actorUserId]))
                ->filter(fn ($id) => $id > 0)
                ->unique()
                ->values()
                ->all();

            $now = now();
            $payload = json_encode([
                'kind' => 'activity',
                'type' => $activityType,
                'title' => $title,
                'body' => $body,
                'severity' => $severity,
                'route' => $route,
                'company_id' => $companyId,
                'actor_user_id' => $actorUserId,
                'actor_name' => $actorName,
                'metadata' => $metadata,
                'created_at' => $now->toIso8601String(),
            ]);

            foreach ($recipientIds as $recipientId) {
                DB::table('notifications')->insert([
                    'id' => (string) Str::uuid(),
                    'type' => 'App\\Notifications\\ErpActivityNotification',
                    'notifiable_type' => User::class,
                    'notifiable_id' => $recipientId,
                    'data' => $payload,
                    'read_at' => $recipientId === $actorUserId ? $now : null,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }
        } catch (\Throwable $e) {
            Log::warning('Activity notification persist skipped: ' . $e->getMessage());
        }
    }
}

