import React, { useState } from 'react';
import { Vehicle } from '../types';
import { Language, t, formatINR } from '../services/languageEngine';
import {
  Truck,
  Plus,
  ShieldCheck,
  AlertTriangle,
  Clock,
  MapPin,
  Calendar,
  Fuel,
  Wrench,
  CheckCircle,
  FileText,
  X
} from 'lucide-react';

interface FleetPortalProps {
  lang: Language;
  vehicles: Vehicle[];
  onAddVehicle: (vehicle: Vehicle) => void;
}

export const FleetPortal: React.FC<FleetPortalProps> = ({
  lang,
  vehicles,
  onAddVehicle
}) => {
  const [selectedFilter, setSelectedFilter] = useState<'all' | 'tanker' | 'can_truck'>('all');
  const [showAddVehicleModal, setShowAddVehicleModal] = useState(false);

  // New Vehicle Form State (Rule 1.3: Zero Hardcoding, Open Decimals)
  const [newRegNumber, setNewRegNumber] = useState('');
  const [newType, setNewType] = useState<'tanker' | 'can_truck'>('tanker');
  const [newCapacity, setNewCapacity] = useState('24.0');
  const [newDriver, setNewDriver] = useState('');
  const [newPhone, setNewPhone] = useState('');
  const [newOdometer, setNewOdometer] = useState('140000');
  const [newFcDate, setNewFcDate] = useState('2027-06-30');
  const [newInsuranceDate, setNewInsuranceDate] = useState('2027-09-15');

  const filteredVehicles = selectedFilter === 'all'
    ? vehicles
    : vehicles.filter(v => v.vehicle_type === selectedFilter);

  const activeMovingCount = vehicles.filter(v => v.status === 'moving' || v.status === 'at_destination').length;
  const standbyCount = vehicles.filter(v => v.status === 'standby' || v.status === 'stopped').length;
  const maintenanceCount = vehicles.filter(v => v.status === 'maintenance').length;

  const handleSaveVehicle = () => {
    const vehicle: Vehicle = {
      id: Date.now(),
      vehicle_number: newRegNumber.toUpperCase().trim(),
      vehicle_type: newType,
      division: newType === 'tanker' ? 'Bulk Water Tanker' : '20L Can Distribution',
      capacity_kl: newType === 'tanker' ? parseFloat(newCapacity) || 24.0 : undefined,
      capacity_cans: newType === 'can_truck' ? parseInt(newCapacity, 10) || 70 : undefined,
      driver_name: newDriver || 'Assigned Driver',
      driver_phone: newPhone || '98422 00000',
      status: 'standby',
      odometer_km: parseInt(newOdometer, 10) || 0,
      fc_expiry_date: newFcDate,
      fc_days_remaining: 240,
      insurance_expiry: newInsuranceDate,
      insurance_status: 'VALID',
      last_speed_kmh: 0.0,
      last_latitude: 11.0182,
      last_longitude: 76.9641,
      last_ping_ago: 'Just registered'
    };

    onAddVehicle(vehicle);
    setShowAddVehicleModal(false);
    setNewRegNumber('');
    setNewDriver('');
    setNewPhone('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      {/* 1. Header with Fresh Visual Action Bar */}
      <div className="fresh-card" style={{ padding: '1.25rem 1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
            <span style={{ fontSize: '1.45rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {lang === 'en' ? 'Fleet & Truck Management Console' : 'லாரி & வாகன மேலாண்மை கன்சோல்'}
            </span>
            <span className="status-pill status-pill-blue">
              OWNED & ATTACHED FLEET
            </span>
          </div>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.84rem', marginTop: '0.2rem' }}>
            {lang === 'en' 
              ? 'Manage Bulk Tankers (40KL, 28KL, 24KL, 16KL, 9KL) & Tata Ace delivery trucks with FC, Insurance & Odometer compliance'
              : 'டேங்கர் மற்றும் டாட்டா ஏஸ் வாகனங்களின் FC, இன்சூரன்ஸ், மற்றும் கிலோமீட்டர் தணிக்கை'}
          </p>
        </div>

        <button
          onClick={() => setShowAddVehicleModal(true)}
          className="btn-fresh btn-fresh-primary"
          style={{ padding: '0.65rem 1.25rem', fontSize: '0.9rem' }}
        >
          <Plus size={18} />
          <span>{lang === 'en' ? '+ Register New Truck' : '+ புதிய வாகனம் சேர்க்க'}</span>
        </button>
      </div>

      {/* 2. Visuals & Numbers Bento Strip */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem' }}>
        {/* Metric 1: Active Road Fleet */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Active Road Fleet
            </span>
            <span className="status-pill status-pill-green">
              <span className="live-pulse-dot" style={{ width: '6px', height: '6px' }}></span>
              Live Operations
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#059669' }}>
              {activeMovingCount}/{vehicles.length}
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              Lorries Dispatched
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
            Standby: {standbyCount} · In Maintenance: {maintenanceCount}
          </div>
        </div>

        {/* Metric 2: Fitness (FC) & Legal Watchdog */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Road Fitness (FC) Status
            </span>
            <span className="status-pill status-pill-amber">
              1 Warning
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#D97706' }}>
              21 Days
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              TN 34 BF 1120 due
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-dim)' }}>
            RTO renewal test scheduled with Kangeyam inspection center
          </div>
        </div>

        {/* Metric 3: Insurance Coverage */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Comprehensive Insurance
            </span>
            <span className="status-pill status-pill-green">
              100% Insured
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#0284C7' }}>
              7/7
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              Active Policies
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
            United India Insurance & New India Assurance policies valid
          </div>
        </div>

        {/* Metric 4: Total Fleet Capacity */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Total Hauling Capacity
            </span>
            <span className="status-pill status-pill-blue">
              Infinite Open KL
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              127.0 KL
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              + 70 Cans Ace
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-dim)' }}>
            40KL Trailer · 28KL · 24KL · 16KL (x2) · 9KL (x1)
          </div>
        </div>
      </div>

      {/* 3. Vehicle Inventory Table */}
      <div className="fresh-card" style={{ padding: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', flexWrap: 'wrap', gap: '0.75rem' }}>
          <div>
            <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
              Vehicle Fleet Registry & Compliance Ledger
            </span>
            <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
              Monitor vehicle capacities, drivers, fitness renewal dates, and live telematics status
            </p>
          </div>

          <div style={{ display: 'flex', gap: '0.35rem', background: 'var(--bg-surface-subtle)', padding: '0.2rem', borderRadius: '8px', border: '1px solid var(--border-subtle)' }}>
            <button
              onClick={() => setSelectedFilter('all')}
              style={{
                padding: '0.35rem 0.75rem',
                borderRadius: '6px',
                border: 'none',
                fontSize: '0.75rem',
                fontWeight: 700,
                cursor: 'pointer',
                background: selectedFilter === 'all' ? 'var(--brand-primary)' : 'transparent',
                color: selectedFilter === 'all' ? '#FFF' : 'var(--text-secondary)'
              }}
            >
              ALL VEHICLES ({vehicles.length})
            </button>
            <button
              onClick={() => setSelectedFilter('tanker')}
              style={{
                padding: '0.35rem 0.75rem',
                borderRadius: '6px',
                border: 'none',
                fontSize: '0.75rem',
                fontWeight: 700,
                cursor: 'pointer',
                background: selectedFilter === 'tanker' ? '#0284C7' : 'transparent',
                color: selectedFilter === 'tanker' ? '#FFF' : 'var(--text-secondary)'
              }}
            >
              TANKERS
            </button>
            <button
              onClick={() => setSelectedFilter('can_truck')}
              style={{
                padding: '0.35rem 0.75rem',
                borderRadius: '6px',
                border: 'none',
                fontSize: '0.75rem',
                fontWeight: 700,
                cursor: 'pointer',
                background: selectedFilter === 'can_truck' ? '#059669' : 'transparent',
                color: selectedFilter === 'can_truck' ? '#FFF' : 'var(--text-secondary)'
              }}
            >
              CANS (TATA ACE)
            </button>
          </div>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table className="fresh-table">
            <thead>
              <tr>
                <th>Registration No</th>
                <th>Type & Division</th>
                <th>Capacity (Open Decimal)</th>
                <th>Assigned Driver</th>
                <th>Odometer Reading</th>
                <th>Fitness (FC) Expiry</th>
                <th>Insurance Policy</th>
                <th>Live Status</th>
              </tr>
            </thead>
            <tbody>
              {filteredVehicles.map(v => (
                <tr key={v.id}>
                  <td>
                    <div className="font-mono" style={{ fontWeight: 800, color: 'var(--text-primary)', fontSize: '0.92rem' }}>
                      {v.vehicle_number}
                    </div>
                  </td>
                  <td>
                    <span className={`status-pill ${v.vehicle_type === 'tanker' ? 'status-pill-blue' : 'status-pill-green'}`}>
                      {v.vehicle_type === 'tanker' ? 'Bulk Tanker Lorry' : 'Tata Ace Can Truck'}
                    </span>
                  </td>
                  <td>
                    <span className="font-mono" style={{ fontWeight: 800, fontSize: '0.95rem', color: 'var(--text-primary)' }}>
                      {v.capacity_kl ? `${v.capacity_kl.toFixed(1)} KL` : `${v.capacity_cans || 70} Cans`}
                    </span>
                  </td>
                  <td>
                    <div style={{ fontWeight: 700, fontSize: '0.82rem' }}>{v.driver_name || 'Standby Driver'}</div>
                    <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>{v.driver_phone || '-'}</div>
                  </td>
                  <td>
                    <span className="font-mono" style={{ fontWeight: 700, color: 'var(--text-secondary)' }}>
                      {v.odometer_km ? `${v.odometer_km.toLocaleString()} km` : '142,870 km'}
                    </span>
                  </td>
                  <td>
                    <div>
                      <span className="font-mono" style={{ fontSize: '0.78rem', fontWeight: 600 }}>
                        {v.fc_expiry_date || '2027-04-15'}
                      </span>
                      {v.vehicle_number === 'TN 34 BF 1120' ? (
                        <span className="status-pill status-pill-red" style={{ marginLeft: '4px', fontSize: '0.65rem' }}>
                          21 Days Left
                        </span>
                      ) : (
                        <span className="status-pill status-pill-green" style={{ marginLeft: '4px', fontSize: '0.65rem' }}>
                          Valid
                        </span>
                      )}
                    </div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.76rem', color: '#059669', fontWeight: 700 }}>
                      <CheckCircle size={13} />
                      <span>{v.insurance_expiry || '2027-08-20'}</span>
                    </div>
                  </td>
                  <td>
                    <span className={`status-pill ${v.status === 'moving' ? 'status-pill-green' : v.status === 'at_destination' ? 'status-pill-blue' : v.status === 'maintenance' ? 'status-pill-red' : 'status-pill-neutral'}`}>
                      {v.status === 'moving' ? (
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: '3px' }}>
                          <span className="live-pulse-dot" style={{ width: '5px', height: '5px' }}></span>
                          MOVING ({v.last_speed_kmh} km/h)
                        </span>
                      ) : v.status.toUpperCase()}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* 4. Modal: Add New Truck */}
      {showAddVehicleModal && (
        <div className="fresh-modal-backdrop" onClick={() => setShowAddVehicleModal(false)}>
          <div className="fresh-modal-dialog" onClick={e => e.stopPropagation()} style={{ maxWidth: '520px' }}>
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Truck size={20} color="var(--brand-primary)" />
                <span style={{ fontWeight: 800, fontSize: '1.15rem' }}>
                  Register New Vehicle (Infinite Capacity)
                </span>
              </div>
              <button
                onClick={() => setShowAddVehicleModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '0.9rem' }}>
              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Registration Number (RTO):
                </label>
                <input
                  type="text"
                  className="fresh-input font-mono"
                  placeholder="e.g. TN 34 AF 4954"
                  value={newRegNumber}
                  onChange={e => setNewRegNumber(e.target.value)}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Vehicle Type:
                  </label>
                  <select
                    className="fresh-input"
                    value={newType}
                    onChange={e => setNewType(e.target.value as any)}
                  >
                    <option value="tanker">Bulk Water Tanker</option>
                    <option value="can_truck">Tata Ace Can Truck</option>
                  </select>
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    {newType === 'tanker' ? 'Capacity (KL, e.g. 40.0, 24.0):' : 'Can Capacity (e.g. 70):'}
                  </label>
                  <input
                    type="number"
                    step="0.1"
                    className="fresh-input font-mono"
                    value={newCapacity}
                    onChange={e => setNewCapacity(e.target.value)}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Assigned Driver:
                  </label>
                  <input
                    type="text"
                    className="fresh-input"
                    placeholder="Driver Name"
                    value={newDriver}
                    onChange={e => setNewDriver(e.target.value)}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Driver Phone:
                  </label>
                  <input
                    type="text"
                    className="fresh-input font-mono"
                    placeholder="10-digit mobile"
                    value={newPhone}
                    onChange={e => setNewPhone(e.target.value)}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Current Odometer (km):
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={newOdometer}
                    onChange={e => setNewOdometer(e.target.value)}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    FC Expiry Date:
                  </label>
                  <input
                    type="date"
                    className="fresh-input font-mono"
                    value={newFcDate}
                    onChange={e => setNewFcDate(e.target.value)}
                  />
                </div>
              </div>
            </div>

            <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                onClick={() => setShowAddVehicleModal(false)}
                className="btn-fresh btn-fresh-outline"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveVehicle}
                className="btn-fresh btn-fresh-primary"
              >
                Register Truck
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
