import React, { useState } from 'react';
import { Vehicle, PlantIntake, CanDelivery, RouteStop } from '../types';
import { Language, t, formatINR } from '../services/languageEngine';
import {
  Droplets,
  Plus,
  ShieldAlert,
  CheckCircle,
  Clock,
  MapPin,
  Fuel,
  AlertTriangle,
  ArrowRight,
  TrendingUp,
  X,
  Truck,
  Camera,
  ShieldCheck
} from 'lucide-react';

interface WaterCansPortalProps {
  lang: Language;
  vehicles: Vehicle[];
  plantIntakes: PlantIntake[];
  deliveries: CanDelivery[];
  routeStops: RouteStop[];
  onAddPlantIntake: (intake: PlantIntake) => void;
  onAddDelivery: (delivery: CanDelivery) => void;
}

export const WaterCansPortal: React.FC<WaterCansPortalProps> = ({
  lang,
  vehicles,
  plantIntakes,
  deliveries,
  routeStops,
  onAddPlantIntake
}) => {
  const [showRefillModal, setShowRefillModal] = useState(false);
  const [showSpotAuditModal, setShowSpotAuditModal] = useState(false);

  // New Refill Form
  const [refillCans, setRefillCans] = useState(50);
  const [refillSlip, setRefillSlip] = useState('RO-PLANT-1022');

  // Spot audit verification inputs
  const [auditCansObserved, setAuditCansObserved] = useState('25');
  const [auditCashObserved, setAuditCashObserved] = useState('1810');

  // Ground Mathematics (Image 3)
  const totalLoadedCans = plantIntakes.reduce((acc, curr) => acc + curr.cans_loaded, 0); // 213
  const totalDeliveredCans = deliveries.reduce((acc, curr) => acc + curr.cans_delivered, 0); // 188
  const totalEmptyReturned = deliveries.reduce((acc, curr) => acc + curr.empty_cans_collected, 0); // 188
  const expectedCansOnTruck = totalLoadedCans - totalDeliveredCans; // 25 cans

  const totalCashCollected = deliveries
    .filter(d => d.payment_mode === 'cash')
    .reduce((acc, curr) => acc + curr.amount_paid, 0); // 1810

  const totalCreditIssued = deliveries
    .filter(d => d.payment_mode === 'credit')
    .reduce((acc, curr) => acc + curr.total_amount, 0); // 1960

  const grossSales = totalCashCollected + totalCreditIssued; // 3770
  const plantCost = totalLoadedCans * 8; // 1704 (213 cans @ ₹8)
  const driverWage = 1000;
  const netProfit = grossSales - (plantCost + driverWage); // 1066

  const stockPercentage = Math.round((expectedCansOnTruck / totalLoadedCans) * 100);

  const handleSaveRefill = () => {
    const nextSeq = plantIntakes.length + 1;
    const newIntake: PlantIntake = {
      id: Date.now(),
      intake_sequence: nextSeq,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      cans_loaded: refillCans,
      purchase_rate: 8.0,
      total_cost: refillCans * 8.0,
      slip_number: refillSlip || `RO-PLANT-${Math.floor(1000 + Math.random() * 9000)}`
    };
    onAddPlantIntake(newIntake);
    setShowRefillModal(false);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      {/* 1. Header with Fresh Visual Action Bar */}
      <div className="fresh-card" style={{ padding: '1.25rem 1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
            <span style={{ fontSize: '1.45rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {t('cans.title', lang)}
            </span>
            <span className="status-pill status-pill-green">
              SAVARI CAN DISTRIBUTION & ANTI-THEFT
            </span>
          </div>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.84rem', marginTop: '0.2rem' }}>
            {t('cans.subtitle', lang)}
          </p>
        </div>

        <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
          <button
            onClick={() => setShowSpotAuditModal(true)}
            className="btn-fresh"
            style={{ background: '#FEF3C7', color: '#92400E', border: '1px solid #FDE68A' }}
          >
            <ShieldAlert size={16} />
            <span>{t('cans.spot_audit_btn', lang)}</span>
          </button>

          <button
            onClick={() => setShowRefillModal(true)}
            className="btn-fresh btn-fresh-emerald"
          >
            <Plus size={16} />
            <span>{t('cans.record_refill_btn', lang)}</span>
          </button>
        </div>
      </div>

      {/* 2. Visuals & Numbers Strip (Clean Bento Layout) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem' }}>
        {/* Visual 1: Live Stock on Truck Formula */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('cans.stock_on_truck', lang)}
            </span>
            <span className="status-pill status-pill-blue">
              Tata Ace TN 38 BX 4412
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#059669' }}>
              {expectedCansOnTruck} Cans
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              ({stockPercentage}% remaining)
            </span>
          </div>

          <div className="visual-progress-track">
            <div
              className="visual-progress-bar"
              style={{
                width: `${stockPercentage}%`,
                background: 'linear-gradient(90deg, #059669, #10B981)'
              }}
            />
          </div>

          <div style={{ fontSize: '0.73rem', color: 'var(--text-dim)', fontFamily: 'var(--font-mono)' }}>
            Formula: {totalLoadedCans} Loaded - {totalDeliveredCans} Delivered = {expectedCansOnTruck} Cans
          </div>
        </div>

        {/* Visual 2: Cash in Pocket vs Credit Breakdown */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('cans.cash_collected', lang)}
            </span>
            <span className="status-pill status-pill-green">
              Driver Pocket Cash
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {formatINR(totalCashCollected)}
            </span>
          </div>

          {/* Cash vs Credit Split Stacked Bar */}
          <div style={{ display: 'flex', height: '8px', borderRadius: '999px', overflow: 'hidden', background: 'var(--bg-surface-subtle)' }}>
            <div style={{ width: '48%', background: '#059669' }} title="Cash: ₹1,810 (48%)"></div>
            <div style={{ width: '52%', background: '#D97706' }} title="Credit: ₹1,960 (52%)"></div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', color: 'var(--text-muted)' }}>
            <span>Cash: {formatINR(totalCashCollected)} (48%)</span>
            <span>Credit: {formatINR(totalCreditIssued)} (52%)</span>
          </div>
        </div>

        {/* Visual 3: Sequential Plant Refill Loads */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('cans.multi_refills', lang)}
            </span>
            <span className="status-pill status-pill-neutral">
              3 Runs Today
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {totalLoadedCans} Cans
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              @ ₹8/can
            </span>
          </div>

          <div style={{ display: 'flex', gap: '0.4rem', flexWrap: 'wrap' }}>
            {plantIntakes.map(intake => (
              <span
                key={intake.id}
                style={{
                  fontSize: '0.72rem',
                  fontWeight: 700,
                  padding: '0.15rem 0.45rem',
                  borderRadius: '4px',
                  background: 'var(--bg-surface-subtle)',
                  color: 'var(--text-primary)',
                  border: '1px solid var(--border-subtle)'
                }}
              >
                L{intake.intake_sequence}: {intake.cans_loaded} cans ({intake.time})
              </span>
            ))}
          </div>

          <div style={{ fontSize: '0.72rem', color: 'var(--text-dim)' }}>
            Plant Loading Cost: {formatINR(plantCost)}
          </div>
        </div>

        {/* Visual 4: Route Net Margin */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('cans.net_margin', lang)}
            </span>
            <span className="status-pill status-pill-green">
              Margin: 28.3%
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#059669' }}>
              {formatINR(netProfit)}
            </span>
          </div>

          <div style={{ fontSize: '0.74rem', color: 'var(--text-secondary)' }}>
            Gross {formatINR(grossSales)} - (Plant {formatINR(plantCost)} + Driver {formatINR(driverWage)})
          </div>

          <div style={{ fontSize: '0.72rem', color: 'var(--text-dim)' }}>
            Total 72.0 km route covered · 16 customer stops
          </div>
        </div>
      </div>

      {/* 3. Split View: Route Stoppage Analyzer & Sequential Refill Slips */}
      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 1.3fr) minmax(0, 1fr)', gap: '1.25rem' }}>
        {/* Left: Route Stoppage & Rest Dwell Time Analyzer */}
        <div className="fresh-card" style={{ padding: '1.25rem' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.85rem' }}>
            <div>
              <span style={{ fontWeight: 800, fontSize: '0.98rem' }}>
                {t('cans.dwell_analyzer', lang)}
              </span>
              <p style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
                Rule 1.6: Flagging unmapped rest stops &gt; 30 minutes to protect delivery efficiency
              </p>
            </div>
            <span className="status-pill status-pill-blue">
              <Fuel size={12} /> 11.1 km/L Mileage
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
            {routeStops.map(stop => (
              <div
                key={stop.id}
                style={{
                  background: stop.is_warning ? '#FEF2F2' : 'var(--bg-surface-subtle)',
                  borderRadius: '8px',
                  padding: '0.75rem 1rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  border: stop.is_warning ? '1px solid #FECACA' : '1px solid var(--border-subtle)'
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
                  {stop.is_warning ? (
                    <AlertTriangle size={18} color="#EF4444" />
                  ) : (
                    <MapPin size={18} color="#059669" />
                  )}
                  <div>
                    <div style={{ fontWeight: 700, fontSize: '0.88rem', color: stop.is_warning ? '#991B1B' : 'var(--text-primary)' }}>
                      {stop.location_name}
                    </div>
                    <div style={{ fontSize: '0.74rem', color: stop.is_warning ? '#B91C1C' : 'var(--text-muted)' }}>
                      {stop.arrival_time} - {stop.departure_time} · {stop.stop_type.replace('_', ' ').toUpperCase()}
                    </div>
                  </div>
                </div>

                <div style={{ textAlign: 'right' }}>
                  <span
                    style={{
                      fontSize: '0.75rem',
                      fontWeight: 800,
                      padding: '0.2rem 0.55rem',
                      borderRadius: '6px',
                      background: stop.is_warning ? '#EF4444' : 'var(--border-subtle)',
                      color: stop.is_warning ? '#FFFFFF' : 'var(--text-secondary)'
                    }}
                  >
                    {stop.dwell_minutes} mins dwell
                  </span>
                  {stop.is_warning && (
                    <div style={{ fontSize: '0.7rem', color: '#DC2626', fontWeight: 700, marginTop: '0.2rem' }}>
                      ⚠️ DWELL &gt; 30 MINS
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Right: Sequential Plant Refills Log */}
        <div className="fresh-card" style={{ padding: '1.25rem', display: 'flex', flexDirection: 'column' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.85rem' }}>
            <span style={{ fontWeight: 800, fontSize: '0.98rem' }}>
              {t('cans.multi_refills', lang)}
            </span>
            <span style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
              RO Plant Intake Slips
            </span>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
            {plantIntakes.map(intake => (
              <div
                key={intake.id}
                style={{
                  background: 'var(--bg-surface-subtle)',
                  borderRadius: '10px',
                  padding: '0.85rem 1rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  border: '1px solid var(--border-subtle)',
                  flexWrap: 'wrap',
                  gap: '0.5rem'
                }}
              >
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span style={{ fontWeight: 800, fontSize: '0.95rem', color: '#059669' }}>
                      Trip / Run #{intake.intake_sequence}
                    </span>
                    <span className="font-mono" style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
                      {intake.slip_number}
                    </span>
                    <span className="status-pill status-pill-green" style={{ fontSize: '0.65rem', padding: '0.1rem 0.35rem' }}>
                      <Camera size={10} style={{ marginRight: '2px' }} /> Photo Verified
                    </span>
                  </div>
                  <div style={{ fontSize: '0.76rem', color: 'var(--text-muted)', marginTop: '0.2rem', display: 'flex', alignItems: 'center', gap: '0.75rem', flexWrap: 'wrap' }}>
                    <span>{intake.time} · Rate ₹{intake.purchase_rate}/can</span>
                    <span className="font-mono" style={{ color: 'var(--text-secondary)' }}>
                      Odometer: {12420 + (intake.intake_sequence - 1) * 35} km
                    </span>
                    <span style={{ color: '#059669', display: 'inline-flex', alignItems: 'center', gap: '2px', fontSize: '0.7rem' }}>
                      <ShieldCheck size={12} /> GPS Locked: 11.0182N, 76.9641E
                    </span>
                  </div>
                </div>

                <div style={{ textAlign: 'right' }}>
                  <div className="font-mono" style={{ fontWeight: 800, fontSize: '1.05rem', color: 'var(--text-primary)' }}>
                    +{intake.cans_loaded} Cans
                  </div>
                  <div style={{ fontSize: '0.74rem', color: 'var(--text-dim)' }}>
                    Cost: {formatINR(intake.total_cost)}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* 4. Customer Deliveries Table */}
      <div className="fresh-card" style={{ padding: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <div>
            <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
              Customer Deliveries (Notebook Image 3 Ground Record)
            </span>
            <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
              16 customer drops with exact GPS coordinates and payment mode
            </p>
          </div>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table className="fresh-table">
            <thead>
              <tr>
                <th>#</th>
                <th>{t('common.customer', lang)}</th>
                <th>{t('cans.loaded_count', lang)}</th>
                <th>{t('cans.empty_returned', lang)}</th>
                <th>{t('common.rate', lang)}</th>
                <th>{t('common.amount', lang)}</th>
                <th>Payment Mode</th>
                <th>{t('common.time', lang)}</th>
                <th>GPS Fix</th>
              </tr>
            </thead>
            <tbody>
              {deliveries.map(del => (
                <tr key={del.id}>
                  <td className="font-mono" style={{ color: 'var(--text-dim)' }}>{del.id}</td>
                  <td style={{ fontWeight: 700 }}>{del.customer_name}</td>
                  <td className="font-mono" style={{ fontWeight: 700, color: '#059669' }}>
                    {del.cans_delivered} cans
                  </td>
                  <td className="font-mono" style={{ color: '#D97706' }}>
                    {del.empty_cans_collected} empty
                  </td>
                  <td className="font-mono">₹{del.rate_per_can}</td>
                  <td className="font-mono" style={{ fontWeight: 800 }}>
                    {formatINR(del.total_amount)}
                  </td>
                  <td>
                    <span
                      className={`status-pill ${
                        del.payment_mode === 'cash' ? 'status-pill-green' : del.payment_mode === 'upi' ? 'status-pill-blue' : 'status-pill-amber'
                      }`}
                    >
                      {del.payment_mode.toUpperCase()}
                    </span>
                  </td>
                  <td className="font-mono" style={{ fontSize: '0.78rem' }}>{del.payment_time}</td>
                  <td className="font-mono" style={{ fontSize: '0.74rem', color: 'var(--text-dim)' }}>
                    {del.delivery_lat.toFixed(3)}, {del.delivery_lng.toFixed(3)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* 5. Surprise Spot Audit Modal */}
      {showSpotAuditModal && (
        <div className="fresh-modal-backdrop" onClick={() => setShowSpotAuditModal(false)}>
          <div className="fresh-modal-dialog" onClick={e => e.stopPropagation()}>
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <ShieldAlert size={20} color="#D97706" />
                <span style={{ fontWeight: 800, fontSize: '1.15rem' }}>
                  {t('cans.spot_audit_btn', lang)}
                </span>
              </div>
              <button
                onClick={() => setShowSpotAuditModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div style={{ background: '#FEF3C7', padding: '0.85rem', borderRadius: '8px', border: '1px solid #FDE68A', color: '#92400E', fontSize: '0.82rem' }}>
                🚨 <strong>Anti-Theft Protocol:</strong> The supervisor inspects the truck on the road, counts physical loaded cans, and counts cash in the driver's pocket without prior warning.
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Physical Loaded Cans Counted on Truck
                </label>
                <input
                  type="number"
                  className="fresh-input font-mono"
                  value={auditCansObserved}
                  onChange={e => setAuditCansObserved(e.target.value)}
                />
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Physical Cash Counted in Hand / Glovebox (₹)
                </label>
                <input
                  type="number"
                  className="fresh-input font-mono"
                  value={auditCashObserved}
                  onChange={e => setAuditCashObserved(e.target.value)}
                />
              </div>

              <div style={{ background: 'var(--bg-surface-subtle)', padding: '1rem', borderRadius: '10px', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Expected Cans by Server:</span>
                  <span className="font-mono" style={{ fontWeight: 700 }}>{expectedCansOnTruck} Cans</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.85rem' }}>
                  <span style={{ color: 'var(--text-muted)' }}>Expected Cash by Server:</span>
                  <span className="font-mono" style={{ fontWeight: 700 }}>{formatINR(totalCashCollected)}</span>
                </div>
                <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: '0.4rem', marginTop: '0.2rem', display: 'flex', justifyContent: 'space-between', fontSize: '0.9rem', fontWeight: 800 }}>
                  <span>Audit Variance:</span>
                  <span style={{ color: Number(auditCansObserved) === expectedCansOnTruck ? '#059669' : '#DC2626' }}>
                    {Number(auditCansObserved) === expectedCansOnTruck ? '✓ 0 CANS DIFF (100% RECONCILED)' : `${Number(auditCansObserved) - expectedCansOnTruck} CANS DISCREPANCY`}
                  </span>
                </div>
              </div>
            </div>

            <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                onClick={() => setShowSpotAuditModal(false)}
                className="btn-fresh btn-fresh-outline"
              >
                {t('common.close', lang)}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 6. Record Plant Refill Modal */}
      {showRefillModal && (
        <div className="fresh-modal-backdrop" onClick={() => setShowRefillModal(false)}>
          <div className="fresh-modal-dialog" onClick={e => e.stopPropagation()}>
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 800, fontSize: '1.15rem' }}>
                {t('cans.record_refill_btn', lang)} (Run #{plantIntakes.length + 1})
              </span>
              <button
                onClick={() => setShowRefillModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Number of Cans Loaded
                </label>
                <input
                  type="number"
                  className="fresh-input font-mono"
                  value={refillCans}
                  onChange={e => setRefillCans(Number(e.target.value))}
                />
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Plant Loading Slip Number
                </label>
                <input
                  type="text"
                  className="fresh-input font-mono"
                  value={refillSlip}
                  onChange={e => setRefillSlip(e.target.value)}
                />
              </div>
            </div>

            <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                onClick={() => setShowRefillModal(false)}
                className="btn-fresh btn-fresh-outline"
              >
                {t('common.cancel', lang)}
              </button>
              <button
                onClick={handleSaveRefill}
                className="btn-fresh btn-fresh-emerald"
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
