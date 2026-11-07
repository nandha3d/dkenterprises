<?php

namespace App\Http\Controllers\Api\V1;

use App\Models\Attendance;
use App\Models\Employee;
use App\Models\Leave;
use App\Models\LeaveType;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class HrmApiController extends BaseApiController
{
    /**
     * Mobile Geofenced Employee Check-In.
     */
    public function checkIn(Request $request): JsonResponse
    {
        $userId = Auth::id() ?? 1;
        $employee = Employee::where('user_id', $userId)->first()
            ?? Employee::where('is_active', true)->first();

        $employeeId = $employee?->id ?? 1;
        $today = date('Y-m-d');
        $nowTime = date('H:i:s');

        $note = 'Mobile Check-in';
        if ($request->filled('latitude') && $request->filled('longitude')) {
            $note .= " [GPS: {$request->latitude}, {$request->longitude}]";
        }
        if ($request->filled('note')) {
            $note .= " - {$request->note}";
        }

        $attendance = Attendance::firstOrNew([
            'date' => $today,
            'employee_id' => $employeeId,
        ]);

        if (!$attendance->exists) {
            $attendance->user_id = $userId;
            $attendance->checkin = $nowTime;
            $attendance->status = 1; // Present
            $attendance->note = $note;
            $attendance->save();
        }

        return $this->sendResponse([
            'attendance_id' => $attendance->id,
            'employee_id' => $attendance->employee_id,
            'employee_name' => $employee?->name ?? 'Staff Employee',
            'date' => $attendance->date,
            'checkin' => $attendance->checkin,
            'checkout' => $attendance->checkout,
            'status' => 'Checked In Successfully',
        ], 'Check-in recorded', 201);
    }

    /**
     * Mobile Employee Check-Out.
     */
    public function checkOut(Request $request): JsonResponse
    {
        $userId = Auth::id() ?? 1;
        $employee = Employee::where('user_id', $userId)->first()
            ?? Employee::where('is_active', true)->first();

        $employeeId = $employee?->id ?? 1;
        $today = date('Y-m-d');
        $nowTime = date('H:i:s');

        $attendance = Attendance::where('date', $today)
            ->where('employee_id', $employeeId)
            ->first();

        if ($attendance) {
            $attendance->checkout = $nowTime;
            if ($request->filled('note')) {
                $attendance->note .= " | Out Note: {$request->note}";
            }
            $attendance->save();
        } else {
            $attendance = Attendance::create([
                'date' => $today,
                'employee_id' => $employeeId,
                'user_id' => $userId,
                'checkin' => $nowTime,
                'checkout' => $nowTime,
                'status' => 1,
                'note' => 'Auto created on checkout',
            ]);
        }

        return $this->sendResponse([
            'attendance_id' => $attendance->id,
            'employee_id' => $attendance->employee_id,
            'date' => $attendance->date,
            'checkin' => $attendance->checkin,
            'checkout' => $attendance->checkout,
            'status' => 'Checked Out Successfully',
        ], 'Check-out recorded');
    }

    /**
     * List leave applications.
     */
    public function leaves(Request $request): JsonResponse
    {
        $userId = Auth::id();
        $employee = Employee::where('user_id', $userId)->first();

        $query = Leave::with(['employee:id,name', 'leaveType:id,type_name'])
            ->when($employee, fn ($q) => $q->where('employee_id', $employee->id))
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
        $employee = Employee::where('user_id', $userId)->first()
            ?? Employee::where('is_active', true)->first();

        $start = Carbon::parse($request->start_date);
        $end = Carbon::parse($request->end_date);
        $days = $start->diffInDays($end) + 1;

        $leave = Leave::create([
            'employee_id' => $employee?->id ?? 1,
            'leave_types' => $request->leave_types,
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
            'days' => $days,
            'status' => 0, // Pending approval
        ]);

        return $this->sendResponse($leave, 'Leave applied successfully', 201);
    }

    /**
     * List leave types.
     */
    public function leaveTypes(Request $request): JsonResponse
    {
        $types = LeaveType::select('id', 'type_name', 'type_code', 'days')->get();
        return $this->sendResponse($types, 'Leave types retrieved');
    }
}

