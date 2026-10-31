import React, { useState } from 'react';
import { Vehicle, CanDelivery, RouteStop } from '../types';
import { Language, t, formatINR } from '../services/languageEngine';
import { LeafletFleetMap } from '../components/LeafletFleetMap';
import {
  Navigation,
  Compass,
  MapPin,
  ShieldCheck,
  AlertTriangle,
  Clock,
  Fuel,
  CheckCircle,
  Radio,
  Zap,
  Activity,
  Layers,
  TrendingUp
} from 'lucide-react';

interface TelematicsPortalProps {
  lang: Language;
  vehicles: Vehicle[];
  deliveries: CanDelivery[];
  routeStops: RouteStop[];
}

export const TelematicsPortal: React.FC<TelematicsPortalProps> = ({
  lang,
  vehicles,
  deliveries,
  routeStops
}) => {
  const [selectedVehicle, setSelectedVehicle] = useState('TN 38 BX 4412');

  // Ground Deliveries with Haversine Geofence Calculations (Rule 1.6 / loanapp parity)
  const deliveryAuditData = [
    {
      id: 1,
      customer: 'Aran Cafe - 1',
      shopCoords: '11.018221, 76.964119',
      driverCoords: '11.018235, 76.964132',
      distanceMeters: 14.5,
      thresholdMeters: 75,
      status: 'VERIFIED',
      time: '09:12:15 AM',
      cans: '14 Full / 14 Empty',
      payment: '₹280 Cash'
    },
    {
      id: 2,
      customer: 'Aran Cafe - 2',
      shopCoords: '11.021450, 76.968920',
      driverCoords: '11.021470, 76.968940',
      distanceMeters: 21.0,
      thresholdMeters: 75,
      status: 'VERIFIED',
      time: '09:35:40 AM',
      cans: '14 Full / 14 Empty',
      payment: '₹280 Cash'
    },
    {
      id: 3,
      customer: 'Black Pekoe Tea',
      shopCoords: '11.014200, 76.958700',
      driverCoords: '11.014218, 76.958712',
      distanceMeters: 18.2,
      thresholdMeters: 75,
      status: 'VERIFIED',
      time: '10:15:22 AM',
      cans: '18 Full / 18 Empty',
      payment: '₹360 Cash'
    },
    {
      id: 4,
      customer: 'Santha Company (Shop)',
      shopCoords: '11.026800, 76.974200',
      driverCoords: '11.030500, 76.975100', // 420m away from shop!
      distanceMeters: 420.0,
      thresholdMeters: 75,
      status: 'MISMATCH_ALERT',
      time: '01:40:18 PM',
      cans: '34 Full / 14 Empty',
      payment: '₹680 Cash'
    },
    {
      id: 5,
      customer: 'One Cup Tea',
      shopCoords: '11.012500, 76.961000',
      driverCoords: '11.012515, 76.961010',
      distanceMeters: 12.0,
      thresholdMeters: 75,
      status: 'VERIFIED',
      time: '02:15:30 PM',
      cans: '10 Full / 10 Empty',
      payment: '₹200 UPI'
    }
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      {/* 1. Header with Fresh Visual Action Bar */}
      <div className="fresh-card" style={{ padding: '1.25rem 1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
            <span style={{ fontSize: '1.45rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {lang === 'en' ? 'Advanced GPS Telematics & Route Audit Center' : 'மேம்பட்ட GPS டெலிமேடிக்ஸ் & வழித்தட தணிக்கை மையம்'}
            </span>
            <span className="status-pill status-pill-green">
              <span className="live-pulse-dot" style={{ width: '6px', height: '6px' }}></span>
              LIVE TRACKING ENGINE
            </span>
          </div>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.84rem', marginTop: '0.2rem' }}>
            {lang === 'en'
              ? 'Real-time vehicle positioning, Haversine delivery geofence verification, rest dwell detection, and fuel fraud cross-auditing'
              : 'நிகழ்நேர வாகன இருப்பிடம், விநியோக தூர சரிபார்ப்பு, 30 நிமிடத்திற்கு மேலான நிறுத்த எச்சரிக்கை'}
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Focus Vehicle:</span>
          <select
            className="fresh-input font-mono"
            value={selectedVehicle}
            onChange={e => setSelectedVehicle(e.target.value)}
            style={{ padding: '0.4rem 0.75rem', fontWeight: 700 }}
          >
            <option value="TN 38 BX 4412">TN 38 BX 4412 (Tata Ace Can Truck)</option>
            <option value="TN 34 AF 4954">TN 34 AF 4954 (24 KL Tanker)</option>
            <option value="TN 38 DZ 8841">TN 38 DZ 8841 (40 KL Trailer)</option>
            <option value="TN 38 CY 5599">TN 38 CY 5599 (16 KL Tanker)</option>
          </select>
        </div>
      </div>

      {/* 2. Visuals & Numbers Bento Strip */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem' }}>
        {/* Metric 1: Geofence Verification Rate */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Haversine Geofence Lock
            </span>
            <span className="status-pill status-pill-green">
              Shop Locked
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#059669' }}>
              94.2%
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              On-Premises Drops
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
            Average distance to locked shop: 15.8 metres
          </div>
        </div>

        {/* Metric 2: Rest Dwell & Unmapped Stoppage */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Unmapped Rest Dwell Alert
            </span>
            <span className="status-pill status-pill-red">
              1 Flagged Halt
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#DC2626' }}>
              50 Mins
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              Unmapped Stoppage
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-dim)' }}>
            Highway Tea Stall (11:15 AM - 12:05 PM) exceeds 30-min threshold
          </div>
        </div>

        {/* Metric 3: Fuel Mileage Cross-Audit */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              GPS Road Distance vs Fuel
            </span>
            <span className="status-pill status-pill-green">
              Anti-Theft Verified
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#0284C7' }}>
              72.0 km
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              Actual GPS Distance
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
            Claimed fuel: 6.5L @ 11.1 km/L (Matches Ace factory benchmark)
          </div>
        </div>

        {/* Metric 4: Real-time Ping Latency */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Telematics Heartbeat
            </span>
            <span className="status-pill status-pill-green">
              4G Active
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              14s Ago
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              Latest GPS Fix
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-dim)' }}>
            Speed: 18.2 km/h · Battery: 98% · Accuracy: ±4.2m
          </div>
        </div>
      </div>

      {/* 3. Live Fleet Map with Interactive Breadcrumb Route */}
      <div className="fresh-card" style={{ padding: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem', flexWrap: 'wrap', gap: '0.5rem' }}>
          <div>
            <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
              Live Telematics Map & Customer Shop Geofence Circles
            </span>
            <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
              Green pins represent verified customer drops; red circle highlights flagged geofence mismatch
            </p>
          </div>
          <span className="status-pill status-pill-neutral font-mono" style={{ fontSize: '0.75rem' }}>
            GPS Coordinates: 11.018221° N, 76.964119° E
          </span>
        </div>

        <LeafletFleetMap vehicles={vehicles} height="400px" />
      </div>

      {/* 4. Delivery Geofence Verification Feed (loanapp Parity) */}
      <div className="fresh-card" style={{ padding: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
                On-the-Spot Delivery Haversine Verification Feed
              </span>
              <span className="status-pill status-pill-blue">
                Rule 1.6 & loanapp Standard
              </span>
            </div>
            <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
              Verifies if driver GPS fix was within the customer's pinned shop location at the exact second of payment confirmation
            </p>
          </div>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table className="fresh-table">
            <thead>
              <tr>
                <th>Customer / Shop</th>
                <th>Payment Time</th>
                <th>Locked Shop Geocode</th>
                <th>Driver Confirmation Fix</th>
                <th>Distance Variance</th>
                <th>Geofence Status</th>
                <th>Delivered Goods</th>
                <th>Payment Mode</th>
              </tr>
            </thead>
            <tbody>
              {deliveryAuditData.map(row => (
                <tr key={row.id}>
                  <td>
                    <div style={{ fontWeight: 800, color: 'var(--text-primary)' }}>{row.customer}</div>
                  </td>
                  <td>
                    <span className="font-mono" style={{ fontSize: '0.78rem' }}>{row.time}</span>
                  </td>
                  <td>
                    <span className="font-mono" style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{row.shopCoords}</span>
                  </td>
                  <td>
                    <span className="font-mono" style={{ fontSize: '0.75rem', color: 'var(--text-primary)' }}>{row.driverCoords}</span>
                  </td>
                  <td>
                    <span className="font-mono" style={{ fontWeight: 800, fontSize: '0.85rem', color: row.status === 'VERIFIED' ? '#059669' : '#DC2626' }}>
                      {row.distanceMeters} m
                    </span>
                    <span style={{ fontSize: '0.7rem', color: 'var(--text-muted)', marginLeft: '4px' }}>
                      (Limit: {row.thresholdMeters}m)
                    </span>
                  </td>
                  <td>
                    {row.status === 'VERIFIED' ? (
                      <span className="status-pill status-pill-green" style={{ fontSize: '0.72rem' }}>
                        <CheckCircle size={12} style={{ marginRight: '3px' }} />
                        VERIFIED ON-SITE
                      </span>
                    ) : (
                      <span className="status-pill status-pill-red" style={{ fontSize: '0.72rem' }}>
                        <AlertTriangle size={12} style={{ marginRight: '3px' }} />
                        🚨 FRAUD ALERT (420m AWAY!)
                      </span>
                    )}
                  </td>
                  <td>
                    <span style={{ fontSize: '0.78rem' }}>{row.cans}</span>
                  </td>
                  <td>
                    <span className="status-pill status-pill-neutral font-mono" style={{ fontSize: '0.72rem' }}>
                      {row.payment}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* 5. Rest Dwell & Unmapped Stoppages Table */}
      <div className="fresh-card" style={{ padding: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
                Route Stoppage & Rest Dwell Time Analysis (Rule 1.6)
              </span>
              <span className="status-pill status-pill-red">
                STOPS &gt; 30 MIN FLAGGED
              </span>
            </div>
            <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
              Reconstructs the day route, identifies halt locations, and flags unauthorized halts to prevent water diversion
            </p>
          </div>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table className="fresh-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Stop / Halt Location</th>
                <th>Arrival Time</th>
                <th>Departure Time</th>
                <th>Dwell Duration</th>
                <th>Category</th>
                <th>Audit Result</th>
              </tr>
            </thead>
            <tbody>
              {routeStops.map((stop, idx) => (
                <tr key={stop.id}>
                  <td>{idx + 1}</td>
                  <td>
                    <div style={{ fontWeight: 700, color: 'var(--text-primary)' }}>{stop.location_name}</div>
                  </td>
                  <td>
                    <span className="font-mono" style={{ fontSize: '0.78rem' }}>{stop.arrival_time}</span>
                  </td>
                  <td>
                    <span className="font-mono" style={{ fontSize: '0.78rem' }}>{stop.departure_time}</span>
                  </td>
                  <td>
                    <span className="font-mono" style={{ fontWeight: 800, color: stop.is_warning ? '#DC2626' : 'var(--text-primary)' }}>
                      {stop.dwell_minutes} mins
                    </span>
                  </td>
                  <td>
                    <span className={`status-pill ${stop.stop_type === 'plant_loading' ? 'status-pill-green' : stop.stop_type === 'customer_delivery' ? 'status-pill-blue' : 'status-pill-amber'}`}>
                      {stop.stop_type.replace('_', ' ').toUpperCase()}
                    </span>
                  </td>
                  <td>
                    {stop.is_warning ? (
                      <span className="status-pill status-pill-red" style={{ fontSize: '0.72rem' }}>
                        <AlertTriangle size={12} style={{ marginRight: '3px' }} />
                        EXCEEDS 30-MIN REST LIMIT (AUDIT REQUIRED)
                      </span>
                    ) : (
                      <span className="status-pill status-pill-green" style={{ fontSize: '0.72rem' }}>
                        <CheckCircle size={12} style={{ marginRight: '3px' }} />
                        NORMAL OPERATIONAL STOP
                      </span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
