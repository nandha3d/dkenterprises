import React, { useState } from 'react';
import { StaffMember, AttendanceRecord, PayrollRecord, LeaveRecord } from '../types';
import { Language, t, formatINR } from '../services/languageEngine';
import {
  Users,
  Plus,
  CheckCircle,
  Clock,
  Calendar,
  Wallet,
  FileText,
  BadgeCheck,
  ShieldCheck,
  Truck,
  Droplets,
  Store,
  DollarSign,
  UserCheck,
  UserX,
  AlertCircle,
  X
} from 'lucide-react';

interface StaffPortalProps {
  lang: Language;
  staffList: StaffMember[];
  attendanceRecords: AttendanceRecord[];
  payrollRecords: PayrollRecord[];
  leaveRecords: LeaveRecord[];
  onAddStaff: (staff: StaffMember) => void;
  onMarkAttendance: (record: AttendanceRecord) => void;
  onDisbursePayroll: (record: PayrollRecord) => void;
  onRequestLeave: (record: LeaveRecord) => void;
}

export const StaffPortal: React.FC<StaffPortalProps> = ({
  lang,
  staffList,
  attendanceRecords,
  payrollRecords,
  leaveRecords,
  onAddStaff,
  onMarkAttendance,
  onDisbursePayroll,
  onRequestLeave
}) => {
  const [activeSubTab, setActiveSubTab] = useState<'directory' | 'attendance' | 'payroll' | 'leaves'>('directory');
  const [selectedDivisionFilter, setSelectedDivisionFilter] = useState<'all' | 'tanker' | 'can' | 'bakery'>('all');

  // Modals State
  const [showAddStaffModal, setShowAddStaffModal] = useState(false);
  const [showPayrollModal, setShowPayrollModal] = useState(false);
  const [showLeaveModal, setShowLeaveModal] = useState(false);

  // New Staff Form State
  const [newName, setNewName] = useState('');
  const [newRole, setNewRole] = useState<'tanker_driver' | 'can_delivery_boy' | 'bakery_counter' | 'kitchen_cook' | 'store_helper'>('tanker_driver');
  const [newDivision, setNewDivision] = useState<'tanker' | 'can' | 'bakery'>('tanker');
  const [newPhone, setNewPhone] = useState('');
  const [newVehicle, setNewVehicle] = useState('TN 34 AF 4954');
  const [newWageType, setNewWageType] = useState<'daily' | 'monthly' | 'per_trip'>('monthly');
  const [newBaseWage, setNewBaseWage] = useState('22000');
  const [newBattaRate, setNewBattaRate] = useState('250');
  const [newLicense, setNewLicense] = useState('TN-34-2022-008123');

  // Payroll Form State
  const [payStaffId, setPayStaffId] = useState(1);
  const [payMonth, setPayMonth] = useState('October 2026');
  const [payBase, setPayBase] = useState('22000');
  const [payBatta, setPayBatta] = useState('6500');
  const [payAdvanceDeduction, setPayAdvanceDeduction] = useState('2000');
  const [payMode, setPayMode] = useState<'cash_drawer' | 'gpay_kavin' | 'canara_bank' | 'axis_bank'>('canara_bank');

  // Leave Form State
  const [leaveStaffId, setLeaveStaffId] = useState(1);
  const [leaveType, setLeaveType] = useState<'casual' | 'medical' | 'personal'>('personal');
  const [leaveStart, setLeaveStart] = useState('2026-11-01');
  const [leaveEnd, setLeaveEnd] = useState('2026-11-01');
  const [leaveDays, setLeaveDays] = useState(1);
  const [leaveReason, setLeaveReason] = useState('');

  const filteredStaff = selectedDivisionFilter === 'all'
    ? staffList
    : staffList.filter(s => s.division === selectedDivisionFilter);

  const tankerDriversCount = staffList.filter(s => s.division === 'tanker').length;
  const canDeliveryCount = staffList.filter(s => s.division === 'can').length;
  const bakeryStaffCount = staffList.filter(s => s.division === 'bakery').length;

  const totalMonthlyPayroll = staffList.reduce((acc, s) => {
    if (s.wage_type === 'monthly') return acc + s.base_wage;
    if (s.wage_type === 'daily') return acc + (s.base_wage * 30);
    return acc;
  }, 0);

  const totalOutstandingAdvances = staffList.reduce((acc, s) => acc + s.advance_balance, 0);

  const handleSaveStaff = () => {
    const roleLabels: Record<string, string> = {
      tanker_driver: 'Tanker Lorry Driver',
      can_delivery_boy: 'Can Delivery Route Lead',
      bakery_counter: 'Store Counter & Closing',
      kitchen_cook: 'Master Baker & Cook',
      store_helper: 'Store Helper & Washing'
    };

    const newStaff: StaffMember = {
      id: Date.now(),
      name: newName,
      role: newRole,
      role_display: roleLabels[newRole] || 'Staff',
      division: newDivision,
      phone: newPhone,
      assigned_vehicle: newDivision === 'tanker' || newDivision === 'can' ? newVehicle : undefined,
      wage_type: newWageType,
      base_wage: parseFloat(newBaseWage) || 0.0,
      batta_rate: parseFloat(newBattaRate) || 0.0,
      advance_balance: 0.0,
      license_number: newLicense || undefined,
      is_active: true,
      joined_date: new Date().toISOString().split('T')[0]
    };

    onAddStaff(newStaff);
    setShowAddStaffModal(false);
    setNewName('');
    setNewPhone('');
  };

  const handleDisbursePay = () => {
    const staff = staffList.find(s => s.id === payStaffId);
    if (!staff) return;

    const base = parseFloat(payBase) || 0;
    const batta = parseFloat(payBatta) || 0;
    const adv = parseFloat(payAdvanceDeduction) || 0;
    const net = (base + batta) - adv;

    const payroll: PayrollRecord = {
      id: Date.now(),
      staff_id: staff.id,
      staff_name: staff.name,
      division: staff.division,
      settlement_month: payMonth,
      base_earnings: base,
      batta_or_incentives: batta,
      advances_deducted: adv,
      net_payable: net,
      payment_mode: payMode,
      status: 'paid',
      disbursed_at: new Date().toISOString().split('T')[0],
      voucher_no: `PAY-${staff.division.toUpperCase().slice(0, 3)}-${Math.floor(1000 + Math.random() * 9000)}`
    };

    onDisbursePayroll(payroll);
    setShowPayrollModal(false);
  };

  const handleSaveLeave = () => {
    const staff = staffList.find(s => s.id === leaveStaffId);
    if (!staff) return;

    const leave: LeaveRecord = {
      id: Date.now(),
      staff_id: staff.id,
      staff_name: staff.name,
      division: staff.division,
      leave_type: leaveType,
      start_date: leaveStart,
      end_date: leaveEnd,
      days_count: leaveDays,
      reason: leaveReason || 'Personal work',
      status: 'approved'
    };

    onRequestLeave(leave);
    setShowLeaveModal(false);
    setLeaveReason('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      {/* 1. Header with Fresh Visual Action Bar */}
      <div className="fresh-card" style={{ padding: '1.25rem 1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
            <span style={{ fontSize: '1.45rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {lang === 'en' ? 'Staff, Driver & Delivery Boy Management' : 'ஓட்டுநர்கள், விநியோகஸ்தர்கள் & ஊழியர் மேலாண்மை'}
            </span>
            <span className="status-pill status-pill-green">
              3-VERTICAL WORKFORCE
            </span>
          </div>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.84rem', marginTop: '0.2rem' }}>
            {lang === 'en'
              ? 'Tanker heavy drivers, Tata Ace can delivery agents, and Bakery store staff with attendance, wage structures, advances & leave tracking'
              : 'டேங்கர் ஓட்டுநர் பட்டா, கேன் டெலிவரி நாள் கூலி, மற்றும் பேக்கரி ஊழியர் சம்பளக் கணக்கு'}
          </p>
        </div>

        <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
          <button
            onClick={() => setShowLeaveModal(true)}
            className="btn-fresh btn-fresh-outline"
          >
            <Calendar size={16} />
            <span>{lang === 'en' ? '+ Log Leave' : '+ விடுப்பு பதிவு'}</span>
          </button>

          <button
            onClick={() => setShowPayrollModal(true)}
            className="btn-fresh"
            style={{ background: '#FEF3C7', color: '#92400E', border: '1px solid #FDE68A' }}
          >
            <Wallet size={16} />
            <span>{lang === 'en' ? 'Disburse Salary / Advance' : 'சம்பளம் / அட்வான்ஸ்'}</span>
          </button>

          <button
            onClick={() => setShowAddStaffModal(true)}
            className="btn-fresh btn-fresh-primary"
          >
            <Plus size={16} />
            <span>{lang === 'en' ? '+ Register New Staff' : '+ புதிய ஊழியர்'}</span>
          </button>
        </div>
      </div>

      {/* 2. Visuals & Numbers Bento Strip */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem' }}>
        {/* Metric 1: Total Active Workforce */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Total Active Crew
            </span>
            <span className="status-pill status-pill-green">
              100% Operational
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {staffList.length}
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              Registered Staff
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
            Tankers: {tankerDriversCount} · Can Delivery: {canDeliveryCount} · Bakery: {bakeryStaffCount}
          </div>
        </div>

        {/* Metric 2: Today's On-Duty Attendance */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Today's Field Presence
            </span>
            <span className="status-pill status-pill-blue">
              <span className="live-pulse-dot" style={{ width: '6px', height: '6px' }}></span>
              Live Duty
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#0284C7' }}>
              8/9
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              Checked-In Today
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-dim)' }}>
            3 Tankers on Road · 1 Can Ace Dispatched · 1 Half-Day Leave
          </div>
        </div>

        {/* Metric 3: Outstanding Advance Drawn */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Staff Advances Balance
            </span>
            <span className="status-pill status-pill-amber">
              Recoverable
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#D97706' }}>
              {formatINR(totalOutstandingAdvances)}
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-dim)' }}>
            Deducted automatically from month-end / weekly salary
          </div>
        </div>

        {/* Metric 4: Monthly Payroll Run */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Monthly Wage Budget
            </span>
            <span className="status-pill status-pill-green">
              Settled On-Time
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#059669' }}>
              {formatINR(totalMonthlyPayroll)}
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
            Wages + trip batta + can delivery commissions
          </div>
        </div>
      </div>

      {/* 3. Sub-Navigation Tabs: Directory, Attendance, Payroll, Leaves */}
      <div className="fresh-card" style={{ padding: '0.75rem 1.25rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '0.75rem' }}>
        <div style={{ display: 'flex', gap: '0.4rem', background: 'var(--bg-surface-subtle)', padding: '0.25rem', borderRadius: '8px', border: '1px solid var(--border-subtle)' }}>
          <button
            onClick={() => setActiveSubTab('directory')}
            style={{
              padding: '0.45rem 1rem',
              borderRadius: '6px',
              border: 'none',
              fontSize: '0.82rem',
              fontWeight: 700,
              cursor: 'pointer',
              background: activeSubTab === 'directory' ? 'var(--brand-primary)' : 'transparent',
              color: activeSubTab === 'directory' ? '#FFF' : 'var(--text-secondary)'
            }}
          >
            Staff & Driver Directory
          </button>
          <button
            onClick={() => setActiveSubTab('attendance')}
            style={{
              padding: '0.45rem 1rem',
              borderRadius: '6px',
              border: 'none',
              fontSize: '0.82rem',
              fontWeight: 700,
              cursor: 'pointer',
              background: activeSubTab === 'attendance' ? 'var(--brand-primary)' : 'transparent',
              color: activeSubTab === 'attendance' ? '#FFF' : 'var(--text-secondary)'
            }}
          >
            Today's Attendance
          </button>
          <button
            onClick={() => setActiveSubTab('payroll')}
            style={{
              padding: '0.45rem 1rem',
              borderRadius: '6px',
              border: 'none',
              fontSize: '0.82rem',
              fontWeight: 700,
              cursor: 'pointer',
              background: activeSubTab === 'payroll' ? 'var(--brand-primary)' : 'transparent',
              color: activeSubTab === 'payroll' ? '#FFF' : 'var(--text-secondary)'
            }}
          >
            Salary & Advance Settlements
          </button>
          <button
            onClick={() => setActiveSubTab('leaves')}
            style={{
              padding: '0.45rem 1rem',
              borderRadius: '6px',
              border: 'none',
              fontSize: '0.82rem',
              fontWeight: 700,
              cursor: 'pointer',
              background: activeSubTab === 'leaves' ? 'var(--brand-primary)' : 'transparent',
              color: activeSubTab === 'leaves' ? '#FFF' : 'var(--text-secondary)'
            }}
          >
            Leave Approvals ({leaveRecords.length})
          </button>
        </div>

        {/* Division Filter */}
        <div style={{ display: 'flex', gap: '0.25rem' }}>
          {(['all', 'tanker', 'can', 'bakery'] as const).map(div => (
            <button
              key={div}
              onClick={() => setSelectedDivisionFilter(div)}
              style={{
                padding: '0.3rem 0.65rem',
                borderRadius: '6px',
                border: '1px solid var(--border-subtle)',
                fontSize: '0.72rem',
                fontWeight: 700,
                cursor: 'pointer',
                background: selectedDivisionFilter === div ? 'var(--brand-primary-light)' : 'transparent',
                color: selectedDivisionFilter === div ? 'var(--brand-primary-dark)' : 'var(--text-muted)'
              }}
            >
              {div === 'all' ? 'ALL DIVISIONS' : div.toUpperCase()}
            </button>
          ))}
        </div>
      </div>

      {/* 4. Tab 1: Staff & Driver Directory */}
      {activeSubTab === 'directory' && (
        <div className="fresh-card" style={{ padding: '1.25rem' }}>
          <div style={{ overflowX: 'auto' }}>
            <table className="fresh-table">
              <thead>
                <tr>
                  <th>Staff Name</th>
                  <th>Role & Title</th>
                  <th>Division</th>
                  <th>Contact</th>
                  <th>Assigned Vehicle</th>
                  <th>Wage Structure</th>
                  <th>Advance Balance</th>
                  <th>Heavy License / Badge</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {filteredStaff.map(s => (
                  <tr key={s.id}>
                    <td>
                      <div style={{ fontWeight: 800, color: 'var(--text-primary)' }}>{s.name}</div>
                      <div style={{ fontSize: '0.72rem', color: 'var(--text-dim)' }}>Joined: {s.joined_date}</div>
                    </td>
                    <td>
                      <span style={{ fontWeight: 600, fontSize: '0.84rem' }}>{s.role_display}</span>
                    </td>
                    <td>
                      <span className={`status-pill ${s.division === 'tanker' ? 'status-pill-blue' : s.division === 'can' ? 'status-pill-green' : 'status-pill-amber'}`}>
                        {s.division.toUpperCase()}
                      </span>
                    </td>
                    <td>
                      <div className="font-mono" style={{ fontSize: '0.8rem' }}>{s.phone}</div>
                    </td>
                    <td>
                      <span className="font-mono" style={{ fontSize: '0.78rem', color: 'var(--text-secondary)' }}>
                        {s.assigned_vehicle || '-'}
                      </span>
                    </td>
                    <td>
                      <div className="font-mono" style={{ fontWeight: 800, color: '#059669', fontSize: '0.85rem' }}>
                        {formatINR(s.base_wage)}
                        <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', fontWeight: 500 }}>
                          /{s.wage_type === 'monthly' ? 'mo' : s.wage_type === 'daily' ? 'day' : 'trip'}
                        </span>
                      </div>
                      {s.batta_rate && s.batta_rate > 0 && (
                        <div style={{ fontSize: '0.7rem', color: '#D97706' }}>+₹{s.batta_rate}/trip batta</div>
                      )}
                    </td>
                    <td>
                      <span className="font-mono" style={{ fontWeight: 800, color: s.advance_balance > 0 ? '#DC2626' : '#059669' }}>
                        {s.advance_balance > 0 ? `-₹${s.advance_balance}` : '₹0'}
                      </span>
                    </td>
                    <td>
                      <div className="font-mono" style={{ fontSize: '0.72rem' }}>
                        {s.license_number || 'N/A'}
                      </div>
                      {s.badge_expiry && (
                        <div style={{ fontSize: '0.68rem', color: 'var(--text-muted)' }}>Badge exp: {s.badge_expiry}</div>
                      )}
                    </td>
                    <td>
                      <span className="status-pill status-pill-green">
                        ACTIVE
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* 5. Tab 2: Attendance */}
      {activeSubTab === 'attendance' && (
        <div className="fresh-card" style={{ padding: '1.25rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
              Daily Field Attendance Log (30 October 2026)
            </span>
            <span className="status-pill status-pill-green font-mono" style={{ fontSize: '0.75rem' }}>
              Date: 2026-10-30
            </span>
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table className="fresh-table">
              <thead>
                <tr>
                  <th>Staff Member</th>
                  <th>Division</th>
                  <th>Role</th>
                  <th>Check-In</th>
                  <th>Check-Out</th>
                  <th>Attendance Status</th>
                  <th>Trip / Assignment Notes</th>
                </tr>
              </thead>
              <tbody>
                {attendanceRecords.map(att => (
                  <tr key={att.id}>
                    <td>
                      <div style={{ fontWeight: 800, color: 'var(--text-primary)' }}>{att.staff_name}</div>
                    </td>
                    <td>
                      <span className={`status-pill ${att.division === 'tanker' ? 'status-pill-blue' : att.division === 'can' ? 'status-pill-green' : 'status-pill-amber'}`}>
                        {att.division.toUpperCase()}
                      </span>
                    </td>
                    <td>{att.role_display}</td>
                    <td>
                      <span className="font-mono" style={{ fontSize: '0.8rem', fontWeight: 700 }}>{att.check_in}</span>
                    </td>
                    <td>
                      <span className="font-mono" style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{att.check_out || 'On Duty'}</span>
                    </td>
                    <td>
                      <span className={`status-pill ${att.status === 'on_trip' ? 'status-pill-blue' : att.status === 'present' ? 'status-pill-green' : 'status-pill-amber'}`}>
                        {att.status.replace('_', ' ').toUpperCase()}
                      </span>
                    </td>
                    <td>
                      <div style={{ fontSize: '0.76rem', color: 'var(--text-secondary)' }}>{att.notes || '-'}</div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* 6. Tab 3: Payroll & Advance Settlements */}
      {activeSubTab === 'payroll' && (
        <div className="fresh-card" style={{ padding: '1.25rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <div>
              <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
                Payroll Disbursements & Advance Reconciler
              </span>
              <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
                Base Salary + Trip Batta / Can Incentives - Advances Deducted = Net Paid
              </p>
            </div>
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table className="fresh-table">
              <thead>
                <tr>
                  <th>Staff Member</th>
                  <th>Division</th>
                  <th>Settlement Period</th>
                  <th>Base Pay</th>
                  <th>Trip Batta / Incentives</th>
                  <th>Advance Deducted</th>
                  <th>Net Paid</th>
                  <th>Payment Mode</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {payrollRecords.map(pay => (
                  <tr key={pay.id}>
                    <td>
                      <div style={{ fontWeight: 800, color: 'var(--text-primary)' }}>{pay.staff_name}</div>
                      <div className="font-mono" style={{ fontSize: '0.7rem', color: 'var(--text-dim)' }}>{pay.voucher_no}</div>
                    </td>
                    <td>
                      <span className={`status-pill ${pay.division === 'tanker' ? 'status-pill-blue' : pay.division === 'can' ? 'status-pill-green' : 'status-pill-amber'}`}>
                        {pay.division.toUpperCase()}
                      </span>
                    </td>
                    <td>{pay.settlement_month}</td>
                    <td>
                      <span className="font-mono" style={{ fontWeight: 700 }}>{formatINR(pay.base_earnings)}</span>
                    </td>
                    <td>
                      <span className="font-mono" style={{ fontWeight: 700, color: '#059669' }}>+{formatINR(pay.batta_or_incentives)}</span>
                    </td>
                    <td>
                      <span className="font-mono" style={{ fontWeight: 700, color: '#DC2626' }}>-{formatINR(pay.advances_deducted)}</span>
                    </td>
                    <td>
                      <span className="font-mono" style={{ fontWeight: 900, fontSize: '1.05rem', color: '#0284C7' }}>
                        {formatINR(pay.net_payable)}
                      </span>
                    </td>
                    <td>
                      <span className="status-pill status-pill-neutral font-mono" style={{ fontSize: '0.72rem' }}>
                        {pay.payment_mode.replace('_', ' ').toUpperCase()}
                      </span>
                    </td>
                    <td>
                      <span className="status-pill status-pill-green">
                        PAID ✓
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* 7. Tab 4: Leaves */}
      {activeSubTab === 'leaves' && (
        <div className="fresh-card" style={{ padding: '1.25rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
            <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
              Staff Leave Requests & Duty Substitutions
            </span>
          </div>

          <div style={{ overflowX: 'auto' }}>
            <table className="fresh-table">
              <thead>
                <tr>
                  <th>Staff Member</th>
                  <th>Division</th>
                  <th>Leave Type</th>
                  <th>Start Date</th>
                  <th>End Date</th>
                  <th>Duration</th>
                  <th>Reason</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {leaveRecords.map(leave => (
                  <tr key={leave.id}>
                    <td>
                      <div style={{ fontWeight: 800 }}>{leave.staff_name}</div>
                    </td>
                    <td>
                      <span className={`status-pill ${leave.division === 'tanker' ? 'status-pill-blue' : leave.division === 'can' ? 'status-pill-green' : 'status-pill-amber'}`}>
                        {leave.division.toUpperCase()}
                      </span>
                    </td>
                    <td>
                      <span style={{ textTransform: 'capitalize', fontWeight: 600 }}>{leave.leave_type} Leave</span>
                    </td>
                    <td>
                      <span className="font-mono">{leave.start_date}</span>
                    </td>
                    <td>
                      <span className="font-mono">{leave.end_date}</span>
                    </td>
                    <td>
                      <span className="font-mono" style={{ fontWeight: 700 }}>{leave.days_count} Day(s)</span>
                    </td>
                    <td>
                      <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>{leave.reason}</div>
                    </td>
                    <td>
                      <span className={`status-pill ${leave.status === 'approved' ? 'status-pill-green' : 'status-pill-amber'}`}>
                        {leave.status.toUpperCase()}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* 8. Modal: Add New Staff */}
      {showAddStaffModal && (
        <div className="fresh-modal-backdrop" onClick={() => setShowAddStaffModal(false)}>
          <div className="fresh-modal-dialog" onClick={e => e.stopPropagation()} style={{ maxWidth: '540px' }}>
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Users size={20} color="var(--brand-primary)" />
                <span style={{ fontWeight: 800, fontSize: '1.15rem' }}>
                  Register New Crew Member / Driver
                </span>
              </div>
              <button
                onClick={() => setShowAddStaffModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '0.9rem' }}>
              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Full Name:
                </label>
                <input
                  type="text"
                  className="fresh-input"
                  placeholder="e.g. Suresh Kumar, Vignesh..."
                  value={newName}
                  onChange={e => setNewName(e.target.value)}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Business Vertical:
                  </label>
                  <select
                    className="fresh-input"
                    value={newDivision}
                    onChange={e => {
                      const div = e.target.value as any;
                      setNewDivision(div);
                      if (div === 'tanker') setNewRole('tanker_driver');
                      else if (div === 'can') setNewRole('can_delivery_boy');
                      else setNewRole('bakery_counter');
                    }}
                  >
                    <option value="tanker">Bulk Water Tankers</option>
                    <option value="can">20L Water Can Distribution</option>
                    <option value="bakery">Bakery & Store</option>
                  </select>
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Role / Position:
                  </label>
                  <select
                    className="fresh-input"
                    value={newRole}
                    onChange={e => setNewRole(e.target.value as any)}
                  >
                    {newDivision === 'tanker' && <option value="tanker_driver">Tanker Heavy Driver</option>}
                    {newDivision === 'can' && (
                      <>
                        <option value="can_delivery_boy">Can Delivery Route Lead</option>
                        <option value="store_helper">Delivery Assistant / Loader</option>
                      </>
                    )}
                    {newDivision === 'bakery' && (
                      <>
                        <option value="bakery_counter">Store Counter In-Charge</option>
                        <option value="kitchen_cook">Master Baker / Tea Maker</option>
                        <option value="store_helper">Store Helper (Paati)</option>
                      </>
                    )}
                  </select>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Mobile Phone:
                  </label>
                  <input
                    type="text"
                    className="fresh-input font-mono"
                    placeholder="10-digit mobile"
                    value={newPhone}
                    onChange={e => setNewPhone(e.target.value)}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Assigned Vehicle:
                  </label>
                  <input
                    type="text"
                    className="fresh-input font-mono"
                    placeholder="TN 34 AF 4954 or N/A"
                    value={newVehicle}
                    onChange={e => setNewVehicle(e.target.value)}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Wage Type:
                  </label>
                  <select
                    className="fresh-input"
                    value={newWageType}
                    onChange={e => setNewWageType(e.target.value as any)}
                  >
                    <option value="monthly">Monthly Salary</option>
                    <option value="daily">Daily Wage</option>
                    <option value="per_trip">Per Trip</option>
                  </select>
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Base Wage (₹):
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={newBaseWage}
                    onChange={e => setNewBaseWage(e.target.value)}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Trip Batta (₹):
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={newBattaRate}
                    onChange={e => setNewBattaRate(e.target.value)}
                  />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Heavy License & Badge Number:
                </label>
                <input
                  type="text"
                  className="fresh-input font-mono"
                  placeholder="e.g. TN-34-2015-004128"
                  value={newLicense}
                  onChange={e => setNewLicense(e.target.value)}
                />
              </div>
            </div>

            <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                onClick={() => setShowAddStaffModal(false)}
                className="btn-fresh btn-fresh-outline"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveStaff}
                className="btn-fresh btn-fresh-primary"
              >
                Register Staff
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 9. Modal: Disburse Payroll & Settle Advance */}
      {showPayrollModal && (
        <div className="fresh-modal-backdrop" onClick={() => setShowPayrollModal(false)}>
          <div className="fresh-modal-dialog" onClick={e => e.stopPropagation()} style={{ maxWidth: '520px' }}>
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Wallet size={20} color="var(--accent-emerald)" />
                <span style={{ fontWeight: 800, fontSize: '1.15rem' }}>
                  Disburse Wage / Settle Advance
                </span>
              </div>
              <button
                onClick={() => setShowPayrollModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '0.9rem' }}>
              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Select Staff Member:
                </label>
                <select
                  className="fresh-input"
                  value={payStaffId}
                  onChange={e => {
                    const id = Number(e.target.value);
                    setPayStaffId(id);
                    const s = staffList.find(st => st.id === id);
                    if (s) {
                      setPayBase(s.base_wage.toString());
                      setPayAdvanceDeduction(s.advance_balance.toString());
                    }
                  }}
                >
                  {staffList.map(s => (
                    <option key={s.id} value={s.id}>
                      {s.name} ({s.role_display} - {s.division.toUpperCase()})
                    </option>
                  ))}
                </select>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Settlement Month / Week:
                  </label>
                  <input
                    type="text"
                    className="fresh-input"
                    value={payMonth}
                    onChange={e => setPayMonth(e.target.value)}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Base Earnings (₹):
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={payBase}
                    onChange={e => setPayBase(e.target.value)}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Trip Batta / Can Incentives (₹):
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={payBatta}
                    onChange={e => setPayBatta(e.target.value)}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Advance Deducted (₹):
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={payAdvanceDeduction}
                    onChange={e => setPayAdvanceDeduction(e.target.value)}
                  />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Disbursement Account:
                </label>
                <select
                  className="fresh-input"
                  value={payMode}
                  onChange={e => setPayMode(e.target.value as any)}
                >
                  <option value="canara_bank">Canara Bank Current A/c (Bank Transfer)</option>
                  <option value="gpay_kavin">Kavin Anna GPay (Direct UPI)</option>
                  <option value="cash_drawer">Cash Drawer (Physical Cash in Hand)</option>
                  <option value="axis_bank">Axis Bank</option>
                </select>
              </div>

              <div style={{ background: 'var(--brand-primary-light)', padding: '0.85rem', borderRadius: '8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontWeight: 700, color: 'var(--brand-primary-dark)' }}>
                  Net Disbursed Pay:
                </span>
                <span className="font-mono" style={{ fontSize: '1.3rem', fontWeight: 900, color: 'var(--brand-primary-dark)' }}>
                  {formatINR(Math.max(0, (parseFloat(payBase) || 0) + (parseFloat(payBatta) || 0) - (parseFloat(payAdvanceDeduction) || 0)))}
                </span>
              </div>
            </div>

            <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                onClick={() => setShowPayrollModal(false)}
                className="btn-fresh btn-fresh-outline"
              >
                Cancel
              </button>
              <button
                onClick={handleDisbursePay}
                className="btn-fresh btn-fresh-emerald"
              >
                Confirm & Disburse Payment
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 10. Modal: Log Leave */}
      {showLeaveModal && (
        <div className="fresh-modal-backdrop" onClick={() => setShowLeaveModal(false)}>
          <div className="fresh-modal-dialog" onClick={e => e.stopPropagation()} style={{ maxWidth: '480px' }}>
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Calendar size={20} color="var(--brand-primary)" />
                <span style={{ fontWeight: 800, fontSize: '1.15rem' }}>
                  Submit & Approve Staff Leave
                </span>
              </div>
              <button
                onClick={() => setShowLeaveModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '0.9rem' }}>
              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Staff Member:
                </label>
                <select
                  className="fresh-input"
                  value={leaveStaffId}
                  onChange={e => setLeaveStaffId(Number(e.target.value))}
                >
                  {staffList.map(s => (
                    <option key={s.id} value={s.id}>
                      {s.name} ({s.role_display})
                    </option>
                  ))}
                </select>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Leave Type:
                  </label>
                  <select
                    className="fresh-input"
                    value={leaveType}
                    onChange={e => setLeaveType(e.target.value as any)}
                  >
                    <option value="personal">Personal / Family Leave</option>
                    <option value="medical">Medical / Health Leave</option>
                    <option value="casual">Casual Leave</option>
                  </select>
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Number of Days:
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={leaveDays}
                    onChange={e => setLeaveDays(Number(e.target.value))}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Start Date:
                  </label>
                  <input
                    type="date"
                    className="fresh-input font-mono"
                    value={leaveStart}
                    onChange={e => setLeaveStart(e.target.value)}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    End Date:
                  </label>
                  <input
                    type="date"
                    className="fresh-input font-mono"
                    value={leaveEnd}
                    onChange={e => setLeaveEnd(e.target.value)}
                  />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Reason:
                </label>
                <input
                  type="text"
                  className="fresh-input"
                  placeholder="e.g. Temple festival, medical checkup..."
                  value={leaveReason}
                  onChange={e => setLeaveReason(e.target.value)}
                />
              </div>
            </div>

            <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                onClick={() => setShowLeaveModal(false)}
                className="btn-fresh btn-fresh-outline"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveLeave}
                className="btn-fresh btn-fresh-primary"
              >
                Approve & Save Leave
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
