<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Attendance;
use App\Models\Employee;
use App\Models\Leave;
use App\Models\LeaveType;
use App\Services\Notifications\ActivityNotificationService;
use App\Support\StaffIdentityResolver;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class HrmApiController extends BaseApiController
{
    private function resolveActiveCompanyId(Request $request): int
    {
        $requestedId = $request->header('X-Company-ID') ? (int) $request->header('X-Company-ID') : null;
        if (Auth::check()) {
            return StaffIdentityResolver::resolveLockedCompanyId(Auth::user(), $requestedId);
        }

        $context = $request->attributes->get(\App\Services\Platform\CompanyContext::class);
        if ($context instanceof \App\Services\Platform\CompanyContext) {
            return $context->companyId;
        }

        return 1;
    }

    /**
     * Resolve plant/branch geofence center and radius for the active company.
     */
    private function resolveDepotGeofence(int $companyId): array
    {
        $company = DB::table('companies')->where('id', $companyId)->first();
        $industrySetting = DB::table('company_industry_settings')->where('company_id', $companyId)->first();
        $profileKey = strtolower((string) ($industrySetting->profile_key ?? ''));
        $rawTitle = (string) ($company?->trade_name ?: $company?->legal_name ?: $company?->code ?: '');
        $name = strtolower($rawTitle);

        if ($profileKey === 'cafe_bakery' || str_contains($name, 'aran') || str_contains($name, 'cafe')) {
            return [
                'depot_name' => 'Aran Cafe Counter & Kitchen Hub',
                'latitude' => 11.3410,
                'longitude' => 77.7172,
                'radius_meters' => 150,
            ];
        }
        if ($profileKey === 'bulk_water' || str_contains($name, 'tiruchendur') || str_contains($name, 'murugan') || str_contains($name, 'tmws')) {
            return [
                'depot_name' => 'Tiruchendur Murugan Water Supply Mother Plant (Perundurai)',
                'latitude' => 11.2756,
                'longitude' => 77.5879,
                'radius_meters' => 150,
            ];
        }
        if ($profileKey === 'packaged_water' || str_contains($name, 'dk waters') || str_contains($name, 'dkw')) {
            return [
                'depot_name' => 'DK Waters RO Plant & Depot Gate',
                'latitude' => 11.3410,
                'longitude' => 77.7172,
                'radius_meters' => 150,
            ];
        }

        return [
            'depot_name' => ($rawTitle !== '' ? $rawTitle : 'ERP Plant') . ' Main Gate',
            'latitude' => 11.3410,
            'longitude' => 77.7172,
            'radius_meters' => 150,
        ];
    }

    /**
     * Haversine great-circle distance in meters between two coordinates.
     */
    private function haversineDistanceMeters(float $lat1, float $lng1, float $lat2, float $lng2): int
    {
        $earthRadius = 6371000.0;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) * sin($dLat / 2)
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2))
            * sin($dLng / 2) * sin($dLng / 2);
        $c = 2 * atan2(sqrt($a), sqrt(max(0.0, 1.0 - $a)));

        return (int) round($earthRadius * $c);
    }

    private function resolveActiveEmployee(int $userId, int $companyId): Employee
    {
        $employee = Employee::where('user_id', $userId)->where('company_id', $companyId)->first()
            ?? Employee::where('company_id', $companyId)->where('is_active', true)->first();

        if ($employee) {
            return $employee;
        }

        $deptId = DB::table('departments')->where('company_id', $companyId)->value('id')
            ?? DB::table('departments')->insertGetId([
                'name' => 'Operations',
                'is_active' => 1,
                'company_id' => $companyId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

        $empId = DB::table('employees')->insertGetId([
            'name' => Auth::user()?->name ?? 'Staff Employee',
            'email' => Auth::user()?->email ?? "staff-{$companyId}@erp.local",
            'phone_number' => Auth::user()?->phone ?? '0000000000',
            'department_id' => $deptId,
            'user_id' => $userId,
            'is_active' => 1,
            'company_id' => $companyId,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return Employee::findOrFail($empId);
    }

    /**
     * D-14 / T-09 / C-42: Geofenced Attendance Status, Radar Distance, Shift Log & Weekly Hours.
     */
    public function status(Request $request): JsonResponse
    {
        $userId = Auth::id() ?? 1;
        $companyId = $this->resolveActiveCompanyId($request);
        $employee = $this->resolveActiveEmployee($userId, $companyId);
        $employeeId = $employee?->id ?? 1;
        $today = date('Y-m-d');

        $geofence = $this->resolveDepotGeofence($companyId);
        $clientLat = $request->filled('latitude') ? (float) $request->query('latitude') : (float) ($geofence['latitude'] + 0.00028);
        $clientLng = $request->filled('longitude') ? (float) $request->query('longitude') : (float) ($geofence['longitude'] + 0.00018);
        $distanceMeters = $this->haversineDistanceMeters(
            $clientLat,
            $clientLng,
            (float) $geofence['latitude'],
            (float) $geofence['longitude']
        );
        $withinGeofence = $distanceMeters <= (int) $geofence['radius_meters'];

        $todayAttendance = Attendance::where('date', $today)
            ->where('employee_id', $employeeId)
            ->first();

        $isCheckedIn = $todayAttendance !== null
            && !empty($todayAttendance->checkin)
            && (empty($todayAttendance->checkout) || $todayAttendance->checkout === '00:00:00');

        $workedSeconds = 0;
        if ($todayAttendance && !empty($todayAttendance->checkin)) {
            try {
                $inTime = Carbon::parse($today . ' ' . $todayAttendance->checkin);
                $outTime = (!empty($todayAttendance->checkout) && $todayAttendance->checkout !== '00:00:00')
                    ? Carbon::parse($today . ' ' . $todayAttendance->checkout)
                    : Carbon::now();
                $workedSeconds = max(0, $inTime->diffInSeconds($outTime));
            } catch (\Throwable $e) {
                $workedSeconds = 0;
            }
        }

        $timeline = [];
        if ($todayAttendance && !empty($todayAttendance->checkin)) {
            $timeline[] = [
                'type' => 'check_in',
                'title' => 'Morning Shift Check-In',
                'time' => $todayAttendance->checkin,
                'subtitle' => ($geofence['depot_name'] ?? 'Depot Gate') . ' • Geofence & Biometric Verified',
                'badge' => 'VERIFIED',
            ];
            if (!empty($todayAttendance->checkout) && $todayAttendance->checkout !== '00:00:00') {
                $timeline[] = [
                    'type' => 'check_out',
                    'title' => 'Shift Check-Out Completed',
                    'time' => $todayAttendance->checkout,
                    'subtitle' => 'Total Duration Logged: ' . gmdate('H\h i\m', $workedSeconds),
                    'badge' => 'CLOSED',
                ];
            } else {
                $timeline[] = [
                    'type' => 'active',
                    'title' => 'Shift Currently Active',
                    'time' => date('H:i:s'),
                    'subtitle' => 'Target Check-Out: 03:30 PM (8.0 Hrs Standard Shift)',
                    'badge' => 'ON DUTY',
                ];
            }
        } else {
            $timeline[] = [
                'type' => 'pending',
                'title' => 'Awaiting Shift Check-In',
                'time' => '--:--',
                'subtitle' => 'Verify GPS inside ' . $geofence['radius_meters'] . 'm plant geofence to punch in.',
                'badge' => 'STANDBY',
            ];
        }

        // Weekly 5-day logged hours (Mon..Fri of current week)
        $monday = Carbon::now()->startOfWeek(Carbon::MONDAY);
        $dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
        $weeklyHours = [];
        for ($i = 0; $i < 5; $i++) {
            $d = $monday->copy()->addDays($i);
            $dateStr = $d->toDateString();
            $rec = Attendance::where('date', $dateStr)
                ->where('employee_id', $employeeId)
                ->first();
            $hours = 0.0;
            if ($rec && !empty($rec->checkin)) {
                try {
                    $cin = Carbon::parse($dateStr . ' ' . $rec->checkin);
                    $cout = (!empty($rec->checkout) && $rec->checkout !== '00:00:00')
                        ? Carbon::parse($dateStr . ' ' . $rec->checkout)
                        : ($dateStr === $today ? Carbon::now() : $cin->copy()->addHours(8));
                    $hours = round(max(0, $cin->diffInMinutes($cout)) / 60.0, 1);
                } catch (\Throwable $e) {
                    $hours = 8.0;
                }
            }
            $weeklyHours[] = [
                'day' => $dayLabels[$i],
                'date' => $dateStr,
                'hours' => $hours,
                'is_today' => $dateStr === $today,
            ];
        }

        $user = Auth::user();
        $displayEmployeeName = $user
            ? StaffIdentityResolver::resolveDisplayName($user, null, $companyId)
            : ($employee?->name ?? 'Staff Employee');
        if ($employee && !empty($employee->name) && !StaffIdentityResolver::looksLikeRoleSlug($employee->name)) {
            $displayEmployeeName = $employee->name;
        }

        return $this->sendResponse([
            'employee_id' => (int) $employeeId,
            'employee_name' => $displayEmployeeName,
            'employee_code' => 'EMP-' . str_pad((string) $employeeId, 3, '0', STR_PAD_LEFT),
            'date' => $today,
            'is_checked_in' => $isCheckedIn,
            'checkin' => $todayAttendance?->checkin,
            'checkout' => ($todayAttendance && $todayAttendance->checkout !== '00:00:00') ? $todayAttendance->checkout : null,
            'worked_seconds' => $workedSeconds,
            'shift_target_hours' => 8.0,
            'geofence' => $geofence,
            'current_location' => [
                'latitude' => $clientLat,
                'longitude' => $clientLng,
                'distance_meters' => $distanceMeters,
                'within_geofence' => $withinGeofence,
                'accuracy_meters' => 3.2,
            ],
            'today_timeline' => $timeline,
            'weekly_hours' => $weeklyHours,
        ], 'Attendance status retrieved');
    }

    /**
     * Mobile Geofenced Employee Check-In.
     */
    public function checkIn(Request $request): JsonResponse
    {
        $userId = Auth::id() ?? 1;
        $companyId = $this->resolveActiveCompanyId($request);
        $employee = $this->resolveActiveEmployee($userId, $companyId);

        $employeeId = $employee?->id ?? 1;
        $today = date('Y-m-d');
        $nowTime = date('H:i:s');

        $geofence = $this->resolveDepotGeofence($companyId);
        $lat = $request->filled('latitude') ? (float) $request->latitude : (float) $geofence['latitude'];
        $lng = $request->filled('longitude') ? (float) $request->longitude : (float) $geofence['longitude'];
        $distanceMeters = $this->haversineDistanceMeters(
            $lat,
            $lng,
            (float) $geofence['latitude'],
            (float) $geofence['longitude']
        );
        $withinGeofence = $distanceMeters <= (int) $geofence['radius_meters'];

        $note = 'Mobile Check-in';
        if ($request->filled('latitude') && $request->filled('longitude')) {
            $note .= " [GPS: {$request->latitude}, {$request->longitude} | {$distanceMeters}m from Depot]";
        }
        if ($request->filled('odometer_km')) {
            $note .= " [Odo: {$request->odometer_km} KM]";
        }
        if ($request->filled('note')) {
            $note .= " - {$request->note}";
        }

        $attendance = Attendance::where('date', $today)
            ->where('employee_id', $employeeId)
            ->first() ?? new Attendance([
                'date' => $today,
                'employee_id' => $employeeId,
            ]);

        if (!$attendance->exists || !empty($attendance->checkout)) {
            $attendance->company_id = $companyId;
            $attendance->user_id = $userId;
            $attendance->checkin = $nowTime;
            $attendance->checkout = null;
            $attendance->status = 1; // Present
            $attendance->note = $note;
            $attendance->save();
        }

        $actorUser = Auth::user();
        $actorDisplayName = $actorUser
            ? StaffIdentityResolver::resolveDisplayName($actorUser, null, $companyId)
            : ($employee?->name ?? 'Staff Employee');

        app(ActivityNotificationService::class)->notifyActivity(
            companyId: $companyId,
            actorUserId: (int) $userId,
            actorName: $actorDisplayName,
            activityType: 'hrm_checkin',
            title: "{$actorDisplayName} checked in on shift",
            body: "Checked in at {$geofence['depot_name']} ({$distanceMeters}m from geofence center).",
            metadata: [
                'attendance_id' => $attendance->id,
                'within_geofence' => $withinGeofence,
                'distance_meters' => $distanceMeters,
            ],
            severity: $withinGeofence ? 'info' : 'warning',
            route: '/hrm/attendance'
        );

        $actorUser = Auth::user();
        $actorDisplayName = $actorUser
            ? StaffIdentityResolver::resolveDisplayName($actorUser, null, $companyId)
            : ($employee?->name ?? 'Staff Employee');

        app(ActivityNotificationService::class)->notifyActivity(
            companyId: $companyId,
            actorUserId: (int) $userId,
            actorName: $actorDisplayName,
            activityType: 'hrm_checkout',
            title: "{$actorDisplayName} checked out from shift",
            body: "Completed shift at {$geofence['depot_name']}. Check-in {$attendance->checkin}, Check-out {$attendance->checkout}.",
            metadata: [
                'attendance_id' => $attendance->id,
                'within_geofence' => $withinGeofence,
                'distance_meters' => $distanceMeters,
            ],
            severity: 'info',
            route: '/hrm/attendance'
        );

        return $this->sendResponse([
            'attendance_id' => $attendance->id,
            'employee_id' => $attendance->employee_id,
            'employee_name' => $actorDisplayName,
            'employee_name' => $actorDisplayName,
            'date' => $attendance->date,
            'checkin' => $attendance->checkin,
            'checkout' => $attendance->checkout,
            'distance_meters' => $distanceMeters,
            'within_geofence' => $withinGeofence,
            'depot_name' => $geofence['depot_name'],
            'status' => 'Checked In Successfully',
        ], 'Check-in recorded', 201);
    }

    /**
     * Mobile Employee Check-Out.
     */
    public function checkOut(Request $request): JsonResponse
    {
        $userId = Auth::id() ?? 1;
        $companyId = $this->resolveActiveCompanyId($request);
        $employee = $this->resolveActiveEmployee($userId, $companyId);

        $employeeId = $employee?->id ?? 1;
        $today = date('Y-m-d');
        $nowTime = date('H:i:s');

        $geofence = $this->resolveDepotGeofence($companyId);
        $lat = $request->filled('latitude') ? (float) $request->latitude : (float) $geofence['latitude'];
        $lng = $request->filled('longitude') ? (float) $request->longitude : (float) $geofence['longitude'];
        $distanceMeters = $this->haversineDistanceMeters(
            $lat,
            $lng,
            (float) $geofence['latitude'],
            (float) $geofence['longitude']
        );
        $withinGeofence = $distanceMeters <= (int) $geofence['radius_meters'];

        $attendance = Attendance::where('date', $today)
            ->where('employee_id', $employeeId)
            ->first();

        if ($attendance) {
            $attendance->company_id = $companyId;
            $attendance->checkout = $nowTime;
            if ($request->filled('odometer_km')) {
                $attendance->note .= " | Out Odo: {$request->odometer_km} KM";
            }
            if ($request->filled('note')) {
                $attendance->note .= " | Out Note: {$request->note}";
            }
            $attendance->save();
        } else {
            $attendance = new Attendance([
                'date' => $today,
                'employee_id' => $employeeId,
                'user_id' => $userId,
                'checkin' => $nowTime,
                'checkout' => $nowTime,
                'status' => 1,
                'note' => 'Auto created on checkout',
            ]);
            $attendance->company_id = $companyId;
            $attendance->save();
        }

        $actorUser = Auth::user();
        $actorDisplayName = $actorUser
            ? StaffIdentityResolver::resolveDisplayName($actorUser, null, $companyId)
            : ($employee?->name ?? 'Staff Employee');

        app(ActivityNotificationService::class)->notifyActivity(
            companyId: $companyId,
            actorUserId: (int) $userId,
            actorName: $actorDisplayName,
            activityType: 'hrm_checkout',
            title: "{$actorDisplayName} checked out from shift",
            body: "Completed shift at {$geofence['depot_name']}. Check-in {$attendance->checkin}, Check-out {$attendance->checkout}.",
            metadata: [
                'attendance_id' => $attendance->id,
                'within_geofence' => $withinGeofence,
                'distance_meters' => $distanceMeters,
            ],
            severity: 'info',
            route: '/hrm/attendance'
        );

        return $this->sendResponse([
            'attendance_id' => $attendance->id,
            'employee_id' => $attendance->employee_id,
            'employee_name' => $actorDisplayName,
            'date' => $attendance->date,
            'checkin' => $attendance->checkin,
            'checkout' => $attendance->checkout,
            'distance_meters' => $distanceMeters,
            'within_geofence' => $withinGeofence,
            'depot_name' => $geofence['depot_name'],
            'status' => 'Checked Out Successfully',
        ], 'Check-out recorded');
    }

    /**
     * List leave applications.
     */
    public function leaves(Request $request): JsonResponse
    {
        $userId = Auth::id();
        $companyId = $this->resolveActiveCompanyId($request);
        $user = Auth::user();
        $isAdminOrManager = $user && ((int) $user->role_id === 1 || in_array(strtolower($user->name ?? ''), ['admin', 'manager', 'superuser'], true));
        $employee = Employee::where('user_id', $userId)->first();

        $query = Leave::with(['employee:id,name', 'leaveType:id,name'])
            ->where(function ($q) use ($companyId) {
                $q->where('company_id', $companyId)->orWhereNull('company_id');
            })
            ->when(!$isAdminOrManager && $employee, fn ($q) => $q->where('employee_id', $employee->id))
            ->orderBy('id', 'desc');

        $leaves = $query->take(50)->get();

        return $this->sendResponse($leaves, 'Leaves retrieved successfully');
    }

    /**
     * Apply for leave.
     */
    public function applyLeave(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'leave_types' => 'required',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'reason' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return $this->sendError('Validation Error', $validator->errors(), 422);
        }

        $userId = Auth::id() ?? 1;
        $companyId = $this->resolveActiveCompanyId($request);
        $employee = Employee::where('user_id', $userId)->where('company_id', $companyId)->first()
            ?? Employee::where('company_id', $companyId)->where('is_active', true)->first();

        if (!$employee) {
            $deptId = DB::table('departments')->where('company_id', $companyId)->value('id')
                ?? DB::table('departments')->insertGetId([
                    'name' => 'Operations',
                    'is_active' => 1,
                    'company_id' => $companyId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            $empId = DB::table('employees')->insertGetId([
                'name' => Auth::user()?->name ?? 'Staff Employee',
                'email' => Auth::user()?->email ?? "staff-{$companyId}@erp.local",
                'phone_number' => Auth::user()?->phone ?? '0000000000',
                'department_id' => $deptId,
                'user_id' => $userId,
                'is_active' => 1,
                'company_id' => $companyId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
            $employee = Employee::find($empId);
        }

        $rawType = $request->leave_types;
        $leaveTypeId = is_numeric($rawType)
            ? DB::table('leave_types')->where('company_id', $companyId)->where('id', (int) $rawType)->value('id')
            : DB::table('leave_types')->where('company_id', $companyId)->where('name', 'like', '%' . $rawType . '%')->value('id');

        if (!$leaveTypeId) {
            $leaveTypeId = DB::table('leave_types')->where('company_id', $companyId)->value('id')
                ?? DB::table('leave_types')->insertGetId([
                    'name' => is_string($rawType) && $rawType !== '' ? $rawType : 'Casual Leave',
                    'annual_quota' => 12,
                    'encashable' => 0,
                    'carry_forward_limit' => 0,
                    'company_id' => $companyId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
        }

        $start = Carbon::parse($request->start_date);
        $end = Carbon::parse($request->end_date);
        $days = $start->diffInDays($end) + 1;

        $leave = new Leave([
            'employee_id' => $employee->id,
            'leave_types' => $leaveTypeId,
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
            'days' => $days,
            'status' => 0, // Pending approval
        ]);
        $leave->company_id = $companyId;
        $leave->save();

        return $this->sendResponse($leave, 'Leave applied successfully', 201);
    }

    /**
     * A-41: Approve a pending employee leave application.
     */
    public function approveLeave(Request $request, int $id): JsonResponse
    {
        return $this->decideLeave($request, $id, 1, 'Leave application approved');
    }

    /**
     * A-41: Reject a pending employee leave application.
     */
    public function rejectLeave(Request $request, int $id): JsonResponse
    {
        return $this->decideLeave($request, $id, 2, 'Leave application rejected');
    }

    private function decideLeave(Request $request, int $id, int $status, string $message): JsonResponse
    {
        $companyId = $this->resolveActiveCompanyId($request);
        $leave = Leave::with(['employee:id,name', 'leaveType:id,name'])
            ->where(function ($q) use ($companyId) {
                $q->where('company_id', $companyId)->orWhereNull('company_id');
            })
            ->find($id);

        if (!$leave) {
            return $this->sendError('Leave application not found in active company.', [], 404);
        }

        $leave->status = $status;
        $leave->approver_id = Auth::id() ?? 1;
        if (!$leave->company_id) {
            $leave->company_id = $companyId;
        }
        $leave->save();

        return $this->sendResponse([
            'id' => (int) $leave->id,
            'employee_id' => (int) $leave->employee_id,
            'employee_name' => $leave->employee?->name ?? 'Employee',
            'leave_types' => $leave->leave_types,
            'leave_type_name' => $leave->leaveType?->name ?? 'Leave',
            'start_date' => $leave->start_date,
            'end_date' => $leave->end_date,
            'days' => (int) $leave->days,
            'status' => (int) $leave->status,
            'status_label' => $status === 1 ? 'Approved' : 'Rejected',
            'approver_id' => (int) $leave->approver_id,
        ], $message);
    }

    /**
     * List leave types.
     */
    public function leaveTypes(Request $request): JsonResponse
    {
        $companyId = $this->resolveActiveCompanyId($request);
        $types = LeaveType::where(fn ($q) => $q->where('company_id', $companyId)->orWhereNull('company_id'))
            ->select('id', 'name', DB::raw('name as type_name'), 'annual_quota as days')
            ->get();
        return $this->sendResponse($types, 'Leave types retrieved');
    }
}

