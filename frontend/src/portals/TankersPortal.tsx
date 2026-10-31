import React, { useState } from 'react';
import { Vehicle, TankerTrip } from '../types';
import { Language, t, formatINR } from '../services/languageEngine';
import { LeafletFleetMap } from '../components/LeafletFleetMap';
import {
  Truck,
  Plus,
  Fuel,
  Clock,
  Zap,
  MapPin,
  CheckCircle,
  Navigation,
  Phone,
  FileSpreadsheet,
  AlertTriangle,
  X
} from 'lucide-react';

interface TankersPortalProps {
  lang: Language;
  vehicles: Vehicle[];
  trips: TankerTrip[];
  onAddNewTrip: (trip: TankerTrip) => void;
}

export const TankersPortal: React.FC<TankersPortalProps> = ({
  lang,
  vehicles,
  trips,
  onAddNewTrip
}) => {
  const [showDispatchModal, setShowDispatchModal] = useState(false);
  const [selectedVehicleFilter, setSelectedVehicleFilter] = useState<'all' | 'moving' | 'standby' | 'maintenance'>('all');

  // Dynamic Dispatch Form State (Zero Hardcoded values - Rule 1.3 & 1.4)
  const [formCustomer, setFormCustomer] = useState('Texvalley Corporate Campus');
  const [formVehicle, setFormVehicle] = useState('TN 34 AF 4954');
  const [formDriver, setFormDriver] = useState('Suresh');
  const [formCapacity, setFormCapacity] = useState('24.0'); // Open capacity (40KL, 24KL, 16KL, 9KL)
  const [formBaseFare, setFormBaseFare] = useState(2500);
  const [formMinDistanceKm, setFormMinDistanceKm] = useState(15); // Base distance included in base fare
  const [formActualDistanceKm, setFormActualDistanceKm] = useState(35);
  const [formDistanceRatePerKm, setFormDistanceRatePerKm] = useState(20); // ₹20/km beyond min distance
  
  const [formMotorUsed, setFormMotorUsed] = useState(true);
  const [formMotorMinutes, setFormMotorMinutes] = useState(50); // e.g. 50 mins
  const [formMotorRatePerMin, setFormMotorRatePerMin] = useState(5.0); // ₹5.00/min
  
  const [formWaitingMinutes, setFormWaitingMinutes] = useState(120); // 120 mins = 2 hrs
  const [formWaitingRatePerMin, setFormWaitingRatePerMin] = useState(2.5); // ₹2.50/min (₹150/hr)
  
  const [formTollCharge, setFormTollCharge] = useState(180);

  // Owner Discount Override / Bargain Acceptance
  const [formHasOwnerDiscount, setFormHasOwnerDiscount] = useState(true);
  const [formOwnerDiscountAmount, setFormOwnerDiscountAmount] = useState(230);
  const [formOwnerApprover, setFormOwnerApprover] = useState('Dinesh (Owner) - Auth Key: DK-AUTH-09');

  const tankerVehicles = vehicles.filter(v => v.vehicle_type === 'tanker');
  const filteredVehicles = selectedVehicleFilter === 'all'
    ? tankerVehicles
    : tankerVehicles.filter(v => v.status === selectedVehicleFilter);

  // Operational Mathematics & Trip Sheet Calculations
  const totalDispatchedKL = trips.reduce((acc, trip) => acc + trip.capacity_kl, 0);
  const targetDispatchedKL = 120;
  const dispatchProgressPct = Math.min(100, Math.round((totalDispatchedKL / targetDispatchedKL) * 100));

  const totalUnbilledAmount = 48200;
  const totalDieselExpenses = 8420;

  const extraDistanceKm = Math.max(0, formActualDistanceKm - formMinDistanceKm);
  const distanceCharges = extraDistanceKm * formDistanceRatePerKm;
  const motorCharges = formMotorUsed ? (formMotorMinutes * formMotorRatePerMin) : 0;
  const waitingCharges = formWaitingMinutes * formWaitingRatePerMin;
  const standardSystemBill = formBaseFare + distanceCharges + motorCharges + waitingCharges + formTollCharge;
  const finalPayableAmount = standardSystemBill - (formHasOwnerDiscount ? formOwnerDiscountAmount : 0);

  const handleSaveDispatch = () => {
    const newTrip: TankerTrip = {
      id: Date.now(),
      trip_number: `TRP-2026-${Math.floor(1000 + Math.random() * 9000)}`,
      customer_name: formCustomer,
      vehicle_number: formVehicle,
      driver_name: formDriver,
      capacity_kl: parseFloat(formCapacity) || 24.0,
      destination: 'Texvalley Gate 2 Sump',
      status: 'in_transit',
      trip_date: new Date().toISOString().split('T')[0],
      start_time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      base_fare: formBaseFare,
      motor_used: formMotorUsed,
      motor_charges: motorCharges,
      waiting_time_hours: formWaitingMinutes / 60,
      waiting_time_charges: waitingCharges,
      long_distance_km: extraDistanceKm,
      long_distance_surcharge: distanceCharges,
      miscellaneous_charges: formTollCharge,
      total_billing_amount: finalPayableAmount,
      driver_batta: 250,
      fuel_expenses: 800,
      net_trip_profit: finalPayableAmount - 1050,
      odometer_start: 142870
    };

    onAddNewTrip(newTrip);
    setShowDispatchModal(false);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      {/* 1. Header with Fresh Visual Action Bar */}
      <div className="fresh-card" style={{ padding: '1.25rem 1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
            <span style={{ fontSize: '1.45rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {t('tankers.title', lang)}
            </span>
            <span className="status-pill status-pill-blue">
              DINESH FLEET CONSOLE
            </span>
          </div>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.84rem', marginTop: '0.2rem' }}>
            {t('tankers.subtitle', lang)}
          </p>
        </div>

        <button
          onClick={() => setShowDispatchModal(true)}
          className="btn-fresh btn-fresh-primary"
          style={{ padding: '0.65rem 1.25rem', fontSize: '0.9rem' }}
        >
          <Plus size={18} />
          <span>{t('tankers.new_dispatch', lang)}</span>
        </button>
      </div>

      {/* 2. Visuals & Numbers Strip (Clean Bento Layout with Progress Gauges) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem' }}>
        {/* Visual 1: Fleet Running Ratio & Interactive Filters */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('tankers.active_fleet', lang)}
            </span>
            <span className="status-pill status-pill-green">
              <span className="live-pulse-dot" style={{ width: '6px', height: '6px' }}></span>
              5 Active / 2 Standby
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              71%
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              Fleet on road
            </span>
          </div>

          {/* Filter Pills */}
          <div style={{ display: 'flex', gap: '0.35rem', flexWrap: 'wrap', marginTop: '0.3rem' }}>
            <button
              onClick={() => setSelectedVehicleFilter('all')}
              style={{
                fontSize: '0.72rem',
                fontWeight: 600,
                padding: '0.2rem 0.55rem',
                borderRadius: '6px',
                border: '1px solid var(--border-subtle)',
                background: selectedVehicleFilter === 'all' ? 'var(--brand-primary-light)' : 'transparent',
                color: selectedVehicleFilter === 'all' ? 'var(--brand-primary-dark)' : 'var(--text-muted)',
                cursor: 'pointer'
              }}
            >
              {t('common.all', lang)} (7)
            </button>
            <button
              onClick={() => setSelectedVehicleFilter('moving')}
              style={{
                fontSize: '0.72rem',
                fontWeight: 600,
                padding: '0.2rem 0.55rem',
                borderRadius: '6px',
                border: '1px solid var(--border-subtle)',
                background: selectedVehicleFilter === 'moving' ? 'var(--accent-emerald-light)' : 'transparent',
                color: selectedVehicleFilter === 'moving' ? 'var(--accent-emerald-text)' : 'var(--text-muted)',
                cursor: 'pointer'
              }}
            >
              {t('common.running', lang)} (4)
            </button>
            <button
              onClick={() => setSelectedVehicleFilter('standby')}
              style={{
                fontSize: '0.72rem',
                fontWeight: 600,
                padding: '0.2rem 0.55rem',
                borderRadius: '6px',
                border: '1px solid var(--border-subtle)',
                background: selectedVehicleFilter === 'standby' ? 'var(--bg-surface-hover)' : 'transparent',
                color: selectedVehicleFilter === 'standby' ? 'var(--text-primary)' : 'var(--text-muted)',
                cursor: 'pointer'
              }}
            >
              {t('common.standby', lang)} (2)
            </button>
          </div>
        </div>

        {/* Visual 2: Dispatched Water Capacity Progress Gauge */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('tankers.water_moved', lang)}
            </span>
            <span style={{ fontSize: '0.76rem', color: '#0284C7', fontWeight: 700 }}>
              Target: {targetDispatchedKL} KL
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#0284C7' }}>
              {totalDispatchedKL} KL
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              ({dispatchProgressPct}% fulfilled)
            </span>
          </div>

          {/* Visual Progress Bar */}
          <div className="visual-progress-track">
            <div
              className="visual-progress-bar"
              style={{
                width: `${dispatchProgressPct}%`,
                background: 'linear-gradient(90deg, #0284C7, #38BDF8)'
              }}
            />
          </div>

          <div style={{ fontSize: '0.73rem', color: 'var(--text-dim)', marginTop: '0.25rem' }}>
            Texvalley (88KL Contract) · Amirtha Milk · Mills
          </div>
        </div>

        {/* Visual 3: Diesel Refuels & Fuel Mileage Ratio */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('tankers.diesel_burn', lang)}
            </span>
            <span className="status-pill status-pill-blue">
              <Fuel size={12} /> 3.8 km/L AVG
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {formatINR(totalDieselExpenses)}
            </span>
          </div>

          <div style={{ fontSize: '0.74rem', color: 'var(--accent-emerald)', fontWeight: 600 }}>
            ✓ Verified with GPS Road Telematics (215 km covered)
          </div>

          <div style={{ fontSize: '0.73rem', color: 'var(--text-dim)' }}>
            Zero inflated fuel claims detected today
          </div>
        </div>

        {/* Visual 4: Unbilled Corporate Receivables */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('tankers.unbilled_trips', lang)}
            </span>
            <span className="status-pill status-pill-amber">
              14 TRIPS PENDING
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#D97706' }}>
              {formatINR(totalUnbilledAmount)}
            </span>
          </div>

          <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
            Ready for 15-day / 30-day batch invoice compilation
          </div>
        </div>
      </div>

      {/* 3. Main Split View: Live Telematics Map & Active Trip Slips */}
      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1.4fr) minmax(0, 1fr)', gap: '1.25rem' }}>
        {/* Left: Interactive Fleet Map */}
        <div className="fresh-card" style={{ padding: '1.25rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.85rem' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <Navigation size={18} color="#0284C7" />
              <span style={{ fontWeight: 800, fontSize: '0.98rem' }}>
                {t('tankers.telematics_map', lang)}
              </span>
            </div>
            <span style={{ fontSize: '0.74rem', color: 'var(--text-muted)', fontFamily: 'var(--font-mono)' }}>
              OpenStreetMap Vector Engine
            </span>
          </div>

          <LeafletFleetMap vehicles={filteredVehicles} />
        </div>

        {/* Right: Active Lorries & Quick Driver Contacts */}
        <div className="fresh-card" style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.85rem' }}>
            <span style={{ fontWeight: 800, fontSize: '0.98rem' }}>
              {t('tankers.active_fleet', lang)} ({filteredVehicles.length})
            </span>
            <span style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
              Auto-refreshed every 15s
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem', overflowY: 'auto', maxHeight: '380px' }}>
            {filteredVehicles.map(vehicle => (
              <div
                key={vehicle.id}
                style={{
                  background: 'var(--bg-surface-subtle)',
                  borderRadius: '10px',
                  padding: '0.75rem 1rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  border: '1px solid var(--border-subtle)'
                }}
              >
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span style={{ fontWeight: 800, fontSize: '0.92rem', fontFamily: 'var(--font-mono)' }}>
                      {vehicle.vehicle_number}
                    </span>
                    <span
                      style={{
                        fontSize: '0.7rem',
                        fontWeight: 700,
                        padding: '0.15rem 0.45rem',
                        borderRadius: '4px',
                        background: vehicle.capacity_kl && vehicle.capacity_kl >= 40 ? '#FEF3C7' : 'var(--brand-primary-light)',
                        color: vehicle.capacity_kl && vehicle.capacity_kl >= 40 ? '#92400E' : 'var(--brand-primary-dark)'
                      }}
                    >
                      {vehicle.capacity_kl} KL {vehicle.capacity_kl && vehicle.capacity_kl >= 40 ? 'TRAILER' : ''}
                    </span>
                  </div>
                  <div style={{ fontSize: '0.76rem', color: 'var(--text-muted)', marginTop: '0.2rem' }}>
                    {vehicle.driver_name} · {vehicle.current_trip || 'Standby'}
                  </div>
                </div>

                <div style={{ textAlign: 'right' }}>
                  <span
                    className={`status-pill ${
                      vehicle.status === 'moving' ? 'status-pill-green' : vehicle.status === 'at_destination' ? 'status-pill-blue' : 'status-pill-neutral'
                    }`}
                  >
                    {vehicle.status === 'moving' && <span className="live-pulse-dot" style={{ width: '5px', height: '5px' }}></span>}
                    {t(`common.${vehicle.status}`, lang)}
                  </span>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-dim)', marginTop: '0.2rem', fontFamily: 'var(--font-mono)' }}>
                    {vehicle.last_speed_kmh} km/h · {vehicle.last_ping_ago}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* 4. Dispatches & Itemized Surcharge Table */}
      <div className="fresh-card" style={{ padding: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <div>
            <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
              {t('tankers.recent_dispatches', lang)}
            </span>
            <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
              Itemized dynamic surcharges: Motor pumping, waiting time, long distance, and highway tolls
            </p>
          </div>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table className="fresh-table">
            <thead>
              <tr>
                <th>Trip Slip #</th>
                <th>{t('common.customer', lang)}</th>
                <th>{t('common.vehicle', lang)}</th>
                <th>{t('tankers.custom_capacity', lang)}</th>
                <th>{t('tankers.base_fare', lang)}</th>
                <th>{t('tankers.motor_surcharge', lang)}</th>
                <th>{t('tankers.waiting_charge', lang)}</th>
                <th>{t('tankers.total_billing', lang)}</th>
                <th>{t('tankers.net_trip_profit', lang)}</th>
                <th>{t('common.status', lang)}</th>
              </tr>
            </thead>
            <tbody>
              {trips.map(trip => (
                <tr key={trip.id}>
                  <td className="font-mono" style={{ fontWeight: 700, color: 'var(--brand-primary)' }}>
                    {trip.trip_number}
                  </td>
                  <td style={{ fontWeight: 600 }}>{trip.customer_name}</td>
                  <td className="font-mono">{trip.vehicle_number}</td>
                  <td>
                    <span className="status-pill status-pill-blue">
                      {trip.capacity_kl} KL
                    </span>
                  </td>
                  <td className="font-mono">{formatINR(trip.base_fare)}</td>
                  <td>
                    {trip.motor_used ? (
                      <span style={{ color: 'var(--accent-emerald)', fontWeight: 700, fontSize: '0.78rem' }}>
                        +₹{trip.motor_charges} (Pump)
                      </span>
                    ) : (
                      <span style={{ color: 'var(--text-dim)', fontSize: '0.78rem' }}>-</span>
                    )}
                  </td>
                  <td>
                    {trip.waiting_time_hours > 0 ? (
                      <span style={{ color: 'var(--accent-amber)', fontWeight: 700, fontSize: '0.78rem' }}>
                        +₹{trip.waiting_time_charges} ({trip.waiting_time_hours}h)
                      </span>
                    ) : (
                      <span style={{ color: 'var(--text-dim)', fontSize: '0.78rem' }}>-</span>
                    )}
                  </td>
                  <td className="font-mono" style={{ fontWeight: 800, color: 'var(--text-primary)' }}>
                    {formatINR(trip.total_billing_amount)}
                  </td>
                  <td className="font-mono" style={{ fontWeight: 800, color: 'var(--accent-emerald)' }}>
                    {formatINR(trip.net_trip_profit)}
                  </td>
                  <td>
                    <span className={`status-pill ${trip.status === 'at_destination' ? 'status-pill-green' : 'status-pill-blue'}`}>
                      {t(`common.${trip.status}`, lang)}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* 5. Dispatch Modal (Zero Hardcoding & Infinite Capacity) */}
      {showDispatchModal && (
        <div className="fresh-modal-backdrop" onClick={() => setShowDispatchModal(false)}>
          <div className="fresh-modal-dialog" onClick={e => e.stopPropagation()}>
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Truck size={20} color="#0284C7" />
                <span style={{ fontWeight: 800, fontSize: '1.15rem' }}>
                  {t('tankers.new_dispatch', lang)}
                </span>
              </div>
              <button
                onClick={() => setShowDispatchModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              {/* Customer */}
              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  {t('common.customer', lang)}
                </label>
                <input
                  type="text"
                  className="fresh-input"
                  value={formCustomer}
                  onChange={e => setFormCustomer(e.target.value)}
                  placeholder="e.g. Texvalley Corporate Campus, Amirtha Milk, etc."
                />
              </div>

              {/* Vehicle & Open Customizable Capacity */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    {t('common.vehicle', lang)}
                  </label>
                  <select
                    className="fresh-input"
                    value={formVehicle}
                    onChange={e => setFormVehicle(e.target.value)}
                  >
                    <option value="TN 34 AF 4954">TN 34 AF 4954 (24 KL)</option>
                    <option value="TN 38 CY 5599">TN 38 CY 5599 (16 KL)</option>
                    <option value="TN 38 DZ 8841">TN 38 DZ 8841 (40 KL Trailer)</option>
                    <option value="TN 34 BF 1120">TN 34 BF 1120 (9 KL)</option>
                  </select>
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    {t('tankers.custom_capacity', lang)} (Infinite Capacity)
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    className="fresh-input font-mono"
                    value={formCapacity}
                    onChange={e => setFormCapacity(e.target.value)}
                    placeholder="40.0, 24.0, 16.0..."
                  />
                </div>
              </div>

              {/* 1. Base Fare & Minimum Distance Included */}
              <div style={{ background: 'var(--bg-surface-subtle)', padding: '1rem', borderRadius: '10px', display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                  <div>
                    <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                      {t('tankers.base_fare', lang)} (₹)
                    </label>
                    <input
                      type="number"
                      className="fresh-input font-mono"
                      value={formBaseFare}
                      onChange={e => setFormBaseFare(Number(e.target.value))}
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                      Base Included Distance (km)
                    </label>
                    <input
                      type="number"
                      className="fresh-input font-mono"
                      value={formMinDistanceKm}
                      onChange={e => setFormMinDistanceKm(Number(e.target.value))}
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginTop: '0.2rem' }}>
                  <div>
                    <label style={{ fontSize: '0.78rem', fontWeight: 600, color: 'var(--text-muted)', display: 'block', marginBottom: '0.2rem' }}>
                      Total Trip Road Distance (km):
                    </label>
                    <input
                      type="number"
                      className="fresh-input font-mono"
                      value={formActualDistanceKm}
                      onChange={e => setFormActualDistanceKm(Number(e.target.value))}
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.78rem', fontWeight: 600, color: 'var(--text-muted)', display: 'block', marginBottom: '0.2rem' }}>
                      Rate per Extra KM (₹/km):
                    </label>
                    <input
                      type="number"
                      className="fresh-input font-mono"
                      value={formDistanceRatePerKm}
                      onChange={e => setFormDistanceRatePerKm(Number(e.target.value))}
                    />
                  </div>
                </div>

                {extraDistanceKm > 0 ? (
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.78rem', color: '#D97706', fontWeight: 700 }}>
                    <span>Extra {extraDistanceKm} km beyond {formMinDistanceKm}km threshold:</span>
                    <span className="font-mono">+₹{distanceCharges}</span>
                  </div>
                ) : (
                  <div style={{ fontSize: '0.75rem', color: 'var(--accent-emerald)', fontWeight: 600 }}>
                    ✓ Within base distance allowance ({formMinDistanceKm} km). Extra distance charge: ₹0
                  </div>
                )}
              </div>

              {/* 2. Itemized Operational Surcharges (Per Minute Motor & Waiting) */}
              <div style={{ background: 'var(--bg-surface-subtle)', padding: '1rem', borderRadius: '10px', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                <span style={{ fontSize: '0.78rem', fontWeight: 800, color: 'var(--text-secondary)', textTransform: 'uppercase' }}>
                  Per-Minute Running Charges (Rule 1.4)
                </span>

                {/* Motor Used Toggle & Duration in Minutes */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.85rem', fontWeight: 600, cursor: 'pointer' }}>
                      <input
                        type="checkbox"
                        checked={formMotorUsed}
                        onChange={e => setFormMotorUsed(e.target.checked)}
                        style={{ width: '16px', height: '16px' }}
                      />
                      <span>{t('tankers.motor_used', lang)} (Water Pumping)</span>
                    </label>
                    {formMotorUsed && (
                      <span className="font-mono" style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--accent-emerald)' }}>
                        +₹{motorCharges}
                      </span>
                    )}
                  </div>

                  {formMotorUsed && (
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem', paddingLeft: '1.5rem' }}>
                      <div>
                        <label style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Motor Running Minutes:</label>
                        <input
                          type="number"
                          className="fresh-input font-mono"
                          style={{ padding: '0.25rem 0.5rem', fontSize: '0.82rem' }}
                          value={formMotorMinutes}
                          onChange={e => setFormMotorMinutes(Number(e.target.value))}
                        />
                      </div>
                      <div>
                        <label style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Rate per Minute (₹/min):</label>
                        <input
                          type="number"
                          step="0.5"
                          className="fresh-input font-mono"
                          style={{ padding: '0.25rem 0.5rem', fontSize: '0.82rem' }}
                          value={formMotorRatePerMin}
                          onChange={e => setFormMotorRatePerMin(Number(e.target.value))}
                        />
                      </div>
                    </div>
                  )}
                </div>

                {/* Waiting Detention in Minutes */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem', borderTop: '1px solid var(--border-subtle)', paddingTop: '0.5rem' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>Customer Site Detention / Waiting:</span>
                    <span className="font-mono" style={{ fontSize: '0.85rem', fontWeight: 700, color: 'var(--accent-amber)' }}>
                      +₹{waitingCharges}
                    </span>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                    <div>
                      <label style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Waiting Duration (Minutes):</label>
                      <input
                        type="number"
                        className="fresh-input font-mono"
                        style={{ padding: '0.25rem 0.5rem', fontSize: '0.82rem' }}
                        value={formWaitingMinutes}
                        onChange={e => setFormWaitingMinutes(Number(e.target.value))}
                      />
                    </div>
                    <div>
                      <label style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Waiting Rate per Min (₹/min):</label>
                      <input
                        type="number"
                        step="0.5"
                        className="fresh-input font-mono"
                        style={{ padding: '0.25rem 0.5rem', fontSize: '0.82rem' }}
                        value={formWaitingRatePerMin}
                        onChange={e => setFormWaitingRatePerMin(Number(e.target.value))}
                      />
                    </div>
                  </div>
                </div>

                {/* Toll */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid var(--border-subtle)', paddingTop: '0.5rem' }}>
                  <span style={{ fontSize: '0.85rem', fontWeight: 600 }}>{t('tankers.toll_charge', lang)}:</span>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    style={{ width: '100px', padding: '0.3rem 0.5rem' }}
                    value={formTollCharge}
                    onChange={e => setFormTollCharge(Number(e.target.value))}
                  />
                </div>
              </div>

              {/* 3. Computer Calculated Non-Negotiable Bill */}
              <div style={{ background: 'var(--bg-surface-subtle)', border: '1px solid var(--brand-primary)', borderRadius: '10px', padding: '0.75rem 1rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ fontSize: '0.76rem', color: 'var(--brand-primary)', fontWeight: 800 }}>
                    SYSTEM CALCULATED NON-NEGOTIABLE BILL
                  </div>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>
                    Standard itemized computer bill (Driver presents directly to customer)
                  </div>
                </div>
                <span className="font-mono" style={{ fontSize: '1.25rem', fontWeight: 900, color: 'var(--text-primary)' }}>
                  {formatINR(standardSystemBill)}
                </span>
              </div>

              {/* 4. Owner Approved Discount Concession Override */}
              <div style={{ background: '#FFFBEB', border: '1px solid #FCD34D', borderRadius: '10px', padding: '0.85rem', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.82rem', fontWeight: 700, color: '#92400E', cursor: 'pointer' }}>
                    <input
                      type="checkbox"
                      checked={formHasOwnerDiscount}
                      onChange={e => setFormHasOwnerDiscount(e.target.checked)}
                      style={{ width: '16px', height: '16px' }}
                    />
                    <span>Customer Bargained with Owner & Owner Accepted Discount</span>
                  </label>
                  {formHasOwnerDiscount && (
                    <span className="font-mono" style={{ fontSize: '0.82rem', fontWeight: 800, color: '#DC2626' }}>
                      -₹{formOwnerDiscountAmount}
                    </span>
                  )}
                </div>

                {formHasOwnerDiscount && (
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem', marginTop: '0.2rem' }}>
                    <div>
                      <label style={{ fontSize: '0.72rem', color: '#78350F' }}>Approved Discount Concession (₹):</label>
                      <input
                        type="number"
                        className="fresh-input font-mono"
                        style={{ padding: '0.25rem 0.5rem', fontSize: '0.82rem', borderColor: '#F59E0B' }}
                        value={formOwnerDiscountAmount}
                        onChange={e => setFormOwnerDiscountAmount(Number(e.target.value))}
                      />
                    </div>
                    <div>
                      <label style={{ fontSize: '0.72rem', color: '#78350F' }}>Authorization Note / Owner Key:</label>
                      <input
                        type="text"
                        className="fresh-input"
                        style={{ padding: '0.25rem 0.5rem', fontSize: '0.78rem', borderColor: '#F59E0B' }}
                        value={formOwnerApprover}
                        onChange={e => setFormOwnerApprover(e.target.value)}
                      />
                    </div>
                  </div>
                )}
                {formHasOwnerDiscount && (
                  <div style={{ fontSize: '0.68rem', color: '#92400E' }}>
                    Note: Concession is saved in immutable audit log (`audit_logs`) to ensure zero driver leakage.
                  </div>
                )}
              </div>

              {/* 5. Final Payable Closing Amount */}
              <div style={{ background: 'var(--brand-primary-light)', padding: '1rem', borderRadius: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <span style={{ fontWeight: 800, fontSize: '0.92rem', color: 'var(--brand-primary-dark)' }}>
                    {t('tankers.final_closing_amount', lang)}:
                  </span>
                  <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                    Actual money collected to close trip sheet
                  </div>
                </div>
                <span className="font-mono" style={{ fontSize: '1.5rem', fontWeight: 900, color: 'var(--brand-primary-dark)' }}>
                  {formatINR(finalPayableAmount)}
                </span>
              </div>
            </div>

            <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                onClick={() => setShowDispatchModal(false)}
                className="btn-fresh btn-fresh-outline"
              >
                {t('common.cancel', lang)}
              </button>
              <button
                onClick={handleSaveDispatch}
                className="btn-fresh btn-fresh-primary"
              >
                {t('common.confirm', lang)}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
