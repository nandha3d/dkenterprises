import React, { useState } from 'react';
import { Customer } from '../types';
import { Language, t, formatINR } from '../services/languageEngine';
import {
  Users,
  MapPin,
  ShieldCheck,
  AlertTriangle,
  Plus,
  Search,
  CheckCircle,
  Phone,
  Compass,
  Lock,
  Layers,
  X
} from 'lucide-react';

interface CustomersPortalProps {
  lang: Language;
  customers: Customer[];
  onAddCustomer: (customer: Customer) => void;
  onUpdateGeoLock: (customerId: number, lat: number, lng: number, radius: number) => void;
}

export const CustomersPortal: React.FC<CustomersPortalProps> = ({
  lang,
  customers,
  onAddCustomer,
  onUpdateGeoLock
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedDivisionFilter, setSelectedDivisionFilter] = useState<'all' | 'can' | 'tanker' | 'bakery'>('all');
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedCustomerForGeoLock, setSelectedCustomerForGeoLock] = useState<Customer | null>(null);

  // New Customer Form State
  const [newCompanyName, setNewCompanyName] = useState('');
  const [newContactPerson, setNewContactPerson] = useState('');
  const [newPhone, setNewPhone] = useState('');
  const [newDivision, setNewDivision] = useState<'can' | 'tanker' | 'bakery' | 'both'>('can');
  const [newLat, setNewLat] = useState('11.018221');
  const [newLng, setNewLng] = useState('76.964119');
  const [newRadius, setNewRadius] = useState('75');
  const [newRatePerCan, setNewRatePerCan] = useState('20');
  const [newCreditLimit, setNewCreditLimit] = useState('5000');

  // GeoLock Editor State
  const [editLat, setEditLat] = useState('');
  const [editLng, setEditLng] = useState('');
  const [editRadius, setEditRadius] = useState('75');

  const filteredCustomers = customers.filter(c => {
    const matchesSearch = c.company_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          c.phone.includes(searchTerm) ||
                          c.contact_person.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesDiv = selectedDivisionFilter === 'all' || c.division_type === selectedDivisionFilter || c.division_type === 'both';
    return matchesSearch && matchesDiv;
  });

  const totalOutstanding = customers.reduce((acc, c) => acc + c.current_credit_balance, 0);
  const totalLockedShops = customers.filter(c => c.is_gps_locked).length;
  const flaggedMismatches = customers.filter(c => c.last_geofence_status === 'mismatch').length;

  const handleOpenGeoLockModal = (cust: Customer) => {
    setSelectedCustomerForGeoLock(cust);
    setEditLat(cust.delivery_location_lat.toString());
    setEditLng(cust.delivery_location_lng.toString());
    setEditRadius(cust.geofence_radius_meters.toString());
  };

  const handleSaveGeoLock = () => {
    if (!selectedCustomerForGeoLock) return;
    onUpdateGeoLock(
      selectedCustomerForGeoLock.id,
      parseFloat(editLat) || 11.018221,
      parseFloat(editLng) || 76.964119,
      parseInt(editRadius, 10) || 75
    );
    setSelectedCustomerForGeoLock(null);
  };

  const handleSaveCustomer = () => {
    const customer: Customer = {
      id: Date.now(),
      company_name: newCompanyName,
      customer_code: `CUST-${newDivision.toUpperCase().slice(0, 3)}-${Math.floor(100 + Math.random() * 900)}`,
      contact_person: newContactPerson,
      phone: newPhone,
      division_type: newDivision,
      delivery_location_lat: parseFloat(newLat) || 11.018221,
      delivery_location_lng: parseFloat(newLng) || 76.964119,
      geofence_radius_meters: parseInt(newRadius, 10) || 75,
      is_gps_locked: true,
      default_rate_per_can: parseFloat(newRatePerCan) || 20.0,
      credit_limit: parseFloat(newCreditLimit) || 5000.0,
      current_credit_balance: 0.0,
      last_geofence_status: 'verified',
      last_distance_meters: 10.0
    };

    onAddCustomer(customer);
    setShowAddModal(false);
    setNewCompanyName('');
    setNewContactPerson('');
    setNewPhone('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      {/* 1. Header with Fresh Visual Action Bar */}
      <div className="fresh-card" style={{ padding: '1.25rem 1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
            <span style={{ fontSize: '1.45rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {lang === 'en' ? 'Customer Master & GPS Shop Geo-Locking' : 'வாடிக்கையாளர் மேலாண்மை & கடை GPS பூட்டு'}
            </span>
            <span className="status-pill status-pill-blue">
              ANTI-FRAUD GEOFENCE ENABLED
            </span>
          </div>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.84rem', marginTop: '0.2rem' }}>
            {lang === 'en' 
              ? 'Lock shop GPS coordinates to prevent delivery boys from logging fake deliveries away from customer premises'
              : 'கடை அமைவிடத்தை GPS மூலம் பூட்டி, போலி விநியோகங்களை தடுக்கவும்'}
          </p>
        </div>

        <button
          onClick={() => setShowAddModal(true)}
          className="btn-fresh btn-fresh-primary"
          style={{ padding: '0.65rem 1.25rem', fontSize: '0.9rem' }}
        >
          <Plus size={18} />
          <span>{lang === 'en' ? '+ Register New Customer' : '+ புதிய வாடிக்கையாளர்'}</span>
        </button>
      </div>

      {/* 2. Visuals & Numbers Bento Strip */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem' }}>
        {/* Metric 1: Total Registered Customers */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Active Client Network
            </span>
            <span className="status-pill status-pill-green">
              {customers.length} Shops / Mills
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {customers.length}
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              verified accounts
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
            Tankers: 2 Mills · Cans: 4 Shops · Retail Wholesale: Active
          </div>
        </div>

        {/* Metric 2: GPS Geo-Locked Shops */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              GPS Locked Delivery Points
            </span>
            <span className="status-pill status-pill-blue">
              <Lock size={11} style={{ marginRight: '3px' }} /> 100% Protected
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#0284C7' }}>
              {totalLockedShops}/{customers.length}
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              Shops Geo-Locked
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-dim)' }}>
            Deliveries outside 75m threshold immediately raise fraud alert
          </div>
        </div>

        {/* Metric 3: Geofence Verification Status */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Delivery GPS Audit
            </span>
            <span className={`status-pill ${flaggedMismatches > 0 ? 'status-pill-red' : 'status-pill-green'}`}>
              {flaggedMismatches > 0 ? `${flaggedMismatches} Discrepancy Flagged` : 'All Verified On-Site'}
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: flaggedMismatches > 0 ? '#DC2626' : '#059669' }}>
              {customers.length - flaggedMismatches}/{customers.length}
            </span>
            <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
              On-Premises Deliveries
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
            Santha Company: 420m away from shop (Supervisor Audit Required)
          </div>
        </div>

        {/* Metric 4: Total Outstanding Receivables */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Total Credit Outstanding
            </span>
            <span className="status-pill status-pill-amber">
              Customer Ledger
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#D97706' }}>
              {formatINR(totalOutstanding)}
            </span>
          </div>
          <div style={{ fontSize: '0.74rem', color: 'var(--text-dim)' }}>
            All 3 verticals aggregated · Live payment sync
          </div>
        </div>
      </div>

      {/* 3. Customer Master Table with Search, Filter & GPS Controls */}
      <div className="fresh-card" style={{ padding: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', flexWrap: 'wrap', gap: '0.75rem' }}>
          <div>
            <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
              Registered Customer Master & Delivery Locations
            </span>
            <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
              Click 'Geo-Lock' to pin or calibrate exact customer shop GPS coordinates
            </p>
          </div>

          <div style={{ display: 'flex', gap: '0.5rem', alignItems: 'center', flexWrap: 'wrap' }}>
            {/* Search Input */}
            <div style={{ position: 'relative' }}>
              <input
                type="text"
                placeholder="Search by shop name, contact, phone..."
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
                className="fresh-input"
                style={{ paddingLeft: '2rem', width: '280px', fontSize: '0.82rem' }}
              />
              <Search size={15} color="#94A3B8" style={{ position: 'absolute', left: '0.65rem', top: '50%', transform: 'translateY(-50%)' }} />
            </div>

            {/* Division Filters */}
            <div style={{ display: 'flex', gap: '0.25rem', background: 'var(--bg-surface-subtle)', padding: '0.2rem', borderRadius: '8px', border: '1px solid var(--border-subtle)' }}>
              {(['all', 'can', 'tanker', 'bakery'] as const).map(div => (
                <button
                  key={div}
                  onClick={() => setSelectedDivisionFilter(div)}
                  style={{
                    padding: '0.35rem 0.75rem',
                    borderRadius: '6px',
                    border: 'none',
                    fontSize: '0.75rem',
                    fontWeight: 700,
                    cursor: 'pointer',
                    background: selectedDivisionFilter === div ? 'var(--brand-primary)' : 'transparent',
                    color: selectedDivisionFilter === div ? '#FFF' : 'var(--text-secondary)'
                  }}
                >
                  {div.toUpperCase()}
                </button>
              ))}
            </div>
          </div>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table className="fresh-table">
            <thead>
              <tr>
                <th>Customer / Shop</th>
                <th>Division</th>
                <th>Contact & Phone</th>
                <th>Locked Shop GPS Fix</th>
                <th>Geofence</th>
                <th>Rate Slab</th>
                <th>Balance</th>
                <th>Last Delivery Verification</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {filteredCustomers.map(cust => (
                <tr key={cust.id}>
                  <td>
                    <div style={{ fontWeight: 800, color: 'var(--text-primary)' }}>{cust.company_name}</div>
                    <div className="font-mono" style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{cust.customer_code}</div>
                  </td>
                  <td>
                    <span className={`status-pill ${cust.division_type === 'tanker' ? 'status-pill-blue' : cust.division_type === 'can' ? 'status-pill-green' : 'status-pill-amber'}`}>
                      {cust.division_type.toUpperCase()}
                    </span>
                  </td>
                  <td>
                    <div style={{ fontSize: '0.82rem', fontWeight: 600 }}>{cust.contact_person}</div>
                    <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <Phone size={11} /> {cust.phone}
                    </div>
                  </td>
                  <td>
                    <div className="font-mono" style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--brand-primary)' }}>
                      <MapPin size={12} style={{ display: 'inline', marginRight: '3px' }} />
                      {cust.delivery_location_lat.toFixed(6)}, {cust.delivery_location_lng.toFixed(6)}
                    </div>
                  </td>
                  <td>
                    <span className="status-pill status-pill-neutral font-mono" style={{ fontSize: '0.72rem' }}>
                      ±{cust.geofence_radius_meters}m Radius
                    </span>
                  </td>
                  <td>
                    {cust.division_type === 'can' ? (
                      <span className="font-mono" style={{ fontWeight: 700, color: '#059669' }}>
                        ₹{cust.default_rate_per_can}/can
                      </span>
                    ) : cust.division_type === 'tanker' && cust.rate_slab ? (
                      <div className="font-mono" style={{ fontSize: '0.74rem' }}>
                        <div>₹{cust.rate_slab.base_fare} ({cust.rate_slab.base_included_km}km)</div>
                        <div style={{ color: 'var(--text-muted)' }}>+₹{cust.rate_slab.extra_per_km_rate}/extra km</div>
                      </div>
                    ) : (
                      <span className="font-mono" style={{ color: 'var(--text-muted)' }}>Standard</span>
                    )}
                  </td>
                  <td>
                    <span className="font-mono" style={{ fontWeight: 800, color: cust.current_credit_balance > 0 ? '#D97706' : '#059669' }}>
                      {formatINR(cust.current_credit_balance)}
                    </span>
                  </td>
                  <td>
                    {cust.last_geofence_status === 'verified' ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#059669', fontSize: '0.76rem', fontWeight: 700 }}>
                        <CheckCircle size={14} />
                        <span>VERIFIED ({cust.last_distance_meters}m from shop)</span>
                      </div>
                    ) : (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#DC2626', fontSize: '0.76rem', fontWeight: 800 }}>
                        <AlertTriangle size={14} />
                        <span>FRAUD ALERT ({cust.last_distance_meters}m away!)</span>
                      </div>
                    )}
                    <div style={{ fontSize: '0.68rem', color: 'var(--text-dim)' }}>
                      {cust.last_delivery_at || 'Recent drop'}
                    </div>
                  </td>
                  <td>
                    <button
                      onClick={() => handleOpenGeoLockModal(cust)}
                      className="btn-fresh btn-fresh-outline"
                      style={{ padding: '0.35rem 0.75rem', fontSize: '0.75rem', display: 'flex', alignItems: 'center', gap: '4px' }}
                    >
                      <Lock size={12} />
                      <span>Geo-Lock</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* 4. Modal: Lock / Calibrate Customer Shop Location */}
      {selectedCustomerForGeoLock && (
        <div className="fresh-modal-backdrop" onClick={() => setSelectedCustomerForGeoLock(null)}>
          <div className="fresh-modal-dialog" onClick={e => e.stopPropagation()} style={{ maxWidth: '480px' }}>
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <Lock size={20} color="var(--brand-primary)" />
                <span style={{ fontWeight: 800, fontSize: '1.1rem' }}>
                  Lock GPS Location: {selectedCustomerForGeoLock.company_name}
                </span>
              </div>
              <button
                onClick={() => setSelectedCustomerForGeoLock(null)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div style={{ background: 'var(--brand-primary-light)', padding: '0.85rem', borderRadius: '8px', color: 'var(--brand-primary-dark)', fontSize: '0.82rem' }}>
                📍 <strong>Delivery Geo-Locking:</strong> Pin the exact latitude and longitude of this customer's shop. When the delivery boy confirms a drop in their app, the server measures the Haversine distance. If they are farther than the radius, the transaction is flagged.
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Shop Latitude:
                </label>
                <input
                  type="number"
                  step="0.000001"
                  className="fresh-input font-mono"
                  value={editLat}
                  onChange={e => setEditLat(e.target.value)}
                />
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Shop Longitude:
                </label>
                <input
                  type="number"
                  step="0.000001"
                  className="fresh-input font-mono"
                  value={editLng}
                  onChange={e => setEditLng(e.target.value)}
                />
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Geofence Tolerance Radius (Metres):
                </label>
                <input
                  type="number"
                  className="fresh-input font-mono"
                  value={editRadius}
                  onChange={e => setEditRadius(e.target.value)}
                />
                <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>
                  Recommended: 50m to 100m for urban shops; 200m for large spinning mills.
                </span>
              </div>
            </div>

            <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                onClick={() => setSelectedCustomerForGeoLock(null)}
                className="btn-fresh btn-fresh-outline"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveGeoLock}
                className="btn-fresh btn-fresh-primary"
              >
                Save & Lock Geocode
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 5. Modal: Add New Customer */}
      {showAddModal && (
        <div className="fresh-modal-backdrop" onClick={() => setShowAddModal(false)}>
          <div className="fresh-modal-dialog" onClick={e => e.stopPropagation()} style={{ maxWidth: '540px' }}>
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 800, fontSize: '1.15rem' }}>
                Register New Customer & Lock Geofence
              </span>
              <button
                onClick={() => setShowAddModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '0.9rem' }}>
              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Company / Shop Name:
                </label>
                <input
                  type="text"
                  className="fresh-input"
                  placeholder="e.g. Royal Tea Stall, Texvalley Dyeing..."
                  value={newCompanyName}
                  onChange={e => setNewCompanyName(e.target.value)}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.75rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Contact Person:
                  </label>
                  <input
                    type="text"
                    className="fresh-input"
                    placeholder="Owner / Manager"
                    value={newContactPerson}
                    onChange={e => setNewContactPerson(e.target.value)}
                  />
                </div>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Phone Number:
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
                    Division:
                  </label>
                  <select
                    className="fresh-input"
                    value={newDivision}
                    onChange={e => setNewDivision(e.target.value as any)}
                  >
                    <option value="can">20L Water Can Distribution</option>
                    <option value="tanker">Bulk Water Tankers</option>
                    <option value="bakery">Bakery Wholesale / B2B</option>
                    <option value="both">Both Tanker & Can</option>
                  </select>
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Rate per Can / Unit (₹):
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={newRatePerCan}
                    onChange={e => setNewRatePerCan(e.target.value)}
                  />
                </div>
              </div>

              {/* Locked GPS coordinates */}
              <div style={{ background: 'var(--bg-surface-subtle)', padding: '0.85rem', borderRadius: '8px', display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <span style={{ fontSize: '0.78rem', fontWeight: 800, color: 'var(--text-secondary)' }}>
                  Locked GPS Geocode:
                </span>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '0.5rem' }}>
                  <div>
                    <label style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Latitude:</label>
                    <input
                      type="number"
                      step="0.000001"
                      className="fresh-input font-mono"
                      style={{ padding: '0.25rem 0.5rem', fontSize: '0.8rem' }}
                      value={newLat}
                      onChange={e => setNewLat(e.target.value)}
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Longitude:</label>
                    <input
                      type="number"
                      step="0.000001"
                      className="fresh-input font-mono"
                      style={{ padding: '0.25rem 0.5rem', fontSize: '0.8rem' }}
                      value={newLng}
                      onChange={e => setNewLng(e.target.value)}
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.7rem', color: 'var(--text-muted)' }}>Radius (m):</label>
                    <input
                      type="number"
                      className="fresh-input font-mono"
                      style={{ padding: '0.25rem 0.5rem', fontSize: '0.8rem' }}
                      value={newRadius}
                      onChange={e => setNewRadius(e.target.value)}
                    />
                  </div>
                </div>
              </div>
            </div>

            <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                onClick={() => setShowAddModal(false)}
                className="btn-fresh btn-fresh-outline"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveCustomer}
                className="btn-fresh btn-fresh-primary"
              >
                Save Customer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
