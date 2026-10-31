import React, { useState } from 'react';
import { CanDelivery } from '../types';
import { Language, t, formatINR } from '../services/languageEngine';
import {
  Smartphone,
  X,
  Droplets,
  Truck,
  Check,
  Plus,
  Minus,
  MapPin,
  Clock,
  ShieldCheck,
  Camera,
  RotateCcw,
  Percent,
  CheckCircle,
  Globe,
  Image as ImageIcon
} from 'lucide-react';

interface MobileSimulatorModalProps {
  isOpen: boolean;
  onClose: () => void;
  lang: Language;
  onNewDeliverySimulated: (delivery: CanDelivery) => void;
}

export const MobileSimulatorModal: React.FC<MobileSimulatorModalProps> = ({
  isOpen,
  onClose,
  lang: initialLang,
  onNewDeliverySimulated
}) => {
  if (!isOpen) return null;

  const [mobileLang, setMobileLang] = useState<Language>(initialLang);
  const [activeTab, setActiveTab] = useState<'water_can' | 'plant_refill' | 'tanker_trip'>('water_can');

  // Tab 1: Water Can Customer Delivery State
  const [selectedShop, setSelectedShop] = useState('Aran Cafe - 1');
  const [cansDelivered, setCansDelivered] = useState(14);
  const [cansReturned, setCansReturned] = useState(14);
  const [ratePerCan] = useState(20);
  const [payMode, setPayMode] = useState<'cash' | 'upi' | 'credit'>('cash');
  const [isSuccessFeedback, setIsSuccessFeedback] = useState(false);

  // Tab 2: Plant Refill & Photo Proof State (Trip 1, 2, 3...)
  const [refillTripSeq, setRefillTripSeq] = useState(3); // Trip #3 of today
  const [refillCansCount, setRefillCansCount] = useState(57);
  const [refillOdometer, setRefillOdometer] = useState(12485);
  const [refillPhotoAttached, setRefillPhotoAttached] = useState(true);
  const [refillSubmitted, setRefillSubmitted] = useState(false);
  const [todayCumulativeLoads, setTodayCumulativeLoads] = useState([
    { trip: 1, time: '08:15 AM', cans: 72, km: 12420, photo: 'TRUCK_LOAD1_0815.JPG' },
    { trip: 2, time: '12:45 PM', cans: 84, km: 12455, photo: 'TRUCK_LOAD2_1245.JPG' },
    { trip: 3, time: '04:15 PM', cans: 57, km: 12485, photo: 'TRUCK_LOAD3_1615.JPG' }
  ]);

  // Tab 3: Customizable Tanker Trip Sheet State
  const [tankerBaseFare, setTankerBaseFare] = useState(2500);
  const [tankerMinDistanceKm] = useState(15); // Base distance included in base fare
  const [tankerActualDistanceKm, setTankerActualDistanceKm] = useState(35);
  const [tankerDistanceRate] = useState(20); // ₹20 per extra km

  const [tankerMotorUsed, setTankerMotorUsed] = useState(true);
  const [tankerMotorMinutes, setTankerMotorMinutes] = useState(50); // e.g. 50 mins
  const [tankerMotorRatePerMin] = useState(5); // ₹5/min

  const [tankerWaitingMinutes, setTankerWaitingMinutes] = useState(120); // 120 mins = 2 hrs
  const [tankerWaitingRatePerMin] = useState(2.5); // ₹2.5/min (₹150/hr)

  const [tankerToll, setTankerToll] = useState(180);

  // Owner Discount Override / Bargain Acceptance
  const [hasOwnerDiscount, setHasOwnerDiscount] = useState(true);
  const [ownerDiscountAmount, setOwnerDiscountAmount] = useState(230);
  const [ownerApprover] = useState('Dinesh (Owner)');
  const [tankerSubmitted, setTankerSubmitted] = useState(false);

  // Mathematics: Extra Distance
  const extraDistanceKm = Math.max(0, tankerActualDistanceKm - tankerMinDistanceKm);
  const distanceCharges = extraDistanceKm * tankerDistanceRate;
  const motorCharges = tankerMotorUsed ? (tankerMotorMinutes * tankerMotorRatePerMin) : 0;
  const waitingCharges = tankerWaitingMinutes * tankerWaitingRatePerMin;
  const standardSystemBill = tankerBaseFare + distanceCharges + motorCharges + waitingCharges + tankerToll;
  const finalPayableAmount = standardSystemBill - (hasOwnerDiscount ? ownerDiscountAmount : 0);

  const totalAmount = cansDelivered * ratePerCan;

  const handleConfirmDelivery = () => {
    const newDelivery: CanDelivery = {
      id: Date.now(),
      customer_name: selectedShop,
      cans_delivered: cansDelivered,
      empty_cans_collected: cansReturned,
      rate_per_can: ratePerCan,
      total_amount: totalAmount,
      payment_mode: payMode,
      amount_paid: payMode === 'credit' ? 0 : totalAmount,
      unpaid_balance: payMode === 'credit' ? totalAmount : 0,
      payment_time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
      delivery_lat: 11.018221,
      delivery_lng: 76.964119,
      is_synced: true
    };

    onNewDeliverySimulated(newDelivery);
    setIsSuccessFeedback(true);
    setTimeout(() => {
      setIsSuccessFeedback(false);
    }, 2500);
  };

  const handleSavePlantRefill = () => {
    setTodayCumulativeLoads(prev => [
      ...prev,
      {
        trip: prev.length + 1,
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        cans: refillCansCount,
        km: refillOdometer,
        photo: `TRUCK_LOAD${prev.length + 1}_PHOTO.JPG`
      }
    ]);
    setRefillSubmitted(true);
    setTimeout(() => {
      setRefillSubmitted(false);
    }, 2500);
  };

  const handleConfirmTanker = () => {
    setTankerSubmitted(true);
    setTimeout(() => {
      setTankerSubmitted(false);
    }, 2500);
  };

  return (
    <div className="fresh-modal-backdrop" onClick={onClose} style={{ zIndex: 10000 }}>
      <div
        onClick={e => e.stopPropagation()}
        style={{
          width: '390px',
          height: '790px',
          background: '#0F172A',
          borderRadius: '44px',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.7), 0 0 0 10px #1E293B',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
          position: 'relative',
          color: '#F8FAFC'
        }}
      >
        {/* Phone Notch & Status Bar */}
        <div style={{ padding: '0.65rem 1.25rem 0.35rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#0F172A', color: '#94A3B8', fontSize: '0.72rem' }}>
          <span className="font-mono">09:41</span>
          <div style={{ width: '90px', height: '16px', background: '#020617', borderRadius: '12px' }} />
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ fontSize: '0.68rem', color: '#10B981', fontWeight: 700 }}>4G</span>
            <span>100%</span>
          </div>
        </div>

        {/* Mobile Top Navigation Bar with Language Switcher */}
        <div style={{ padding: '0.5rem 1rem', background: '#1E293B', borderBottom: '1px solid #334155', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.45rem' }}>
            <Truck size={16} color="#38BDF8" />
            <span style={{ fontWeight: 800, fontSize: '0.85rem' }}>DK TRACK MOBILE</span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
            <button
              onClick={() => setMobileLang(l => l === 'en' ? 'ta' : 'en')}
              style={{
                background: '#0F172A',
                border: '1px solid #334155',
                color: '#38BDF8',
                borderRadius: '6px',
                padding: '0.2rem 0.5rem',
                fontSize: '0.7rem',
                fontWeight: 700,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '3px'
              }}
            >
              <Globe size={11} />
              <span>{mobileLang === 'en' ? 'தமிழ்' : 'ENG'}</span>
            </button>

            <button
              onClick={onClose}
              style={{ background: 'none', border: 'none', color: '#94A3B8', cursor: 'pointer', padding: '2px' }}
            >
              <X size={18} />
            </button>
          </div>
        </div>

        {/* 3 Dedicated Field Mode Selector Tabs */}
        <div style={{ display: 'flex', background: '#0F172A', padding: '0.35rem 0.5rem', gap: '0.3rem', borderBottom: '1px solid #1E293B' }}>
          <button
            onClick={() => setActiveTab('water_can')}
            style={{
              flex: 1,
              padding: '0.45rem 0.2rem',
              border: 'none',
              borderRadius: '6px',
              fontSize: '0.68rem',
              fontWeight: 800,
              cursor: 'pointer',
              background: activeTab === 'water_can' ? '#059669' : 'transparent',
              color: activeTab === 'water_can' ? '#FFFFFF' : '#94A3B8',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '3px'
            }}
          >
            <Droplets size={11} />
            <span>{mobileLang === 'en' ? 'Drop (<15s)' : 'கேன் விநியோகம்'}</span>
          </button>

          <button
            onClick={() => setActiveTab('plant_refill')}
            style={{
              flex: 1,
              padding: '0.45rem 0.2rem',
              border: 'none',
              borderRadius: '6px',
              fontSize: '0.68rem',
              fontWeight: 800,
              cursor: 'pointer',
              background: activeTab === 'plant_refill' ? '#0D9488' : 'transparent',
              color: activeTab === 'plant_refill' ? '#FFFFFF' : '#94A3B8',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '3px'
            }}
          >
            <Camera size={11} />
            <span>{mobileLang === 'en' ? 'Plant Refill' : 'பிளாண்ட் லோடு'}</span>
          </button>

          <button
            onClick={() => setActiveTab('tanker_trip')}
            style={{
              flex: 1,
              padding: '0.45rem 0.2rem',
              border: 'none',
              borderRadius: '6px',
              fontSize: '0.68rem',
              fontWeight: 800,
              cursor: 'pointer',
              background: activeTab === 'tanker_trip' ? '#0284C7' : 'transparent',
              color: activeTab === 'tanker_trip' ? '#FFFFFF' : '#94A3B8',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '3px'
            }}
          >
            <Truck size={11} />
            <span>{mobileLang === 'en' ? 'Tanker Trip' : 'டேங்கர் சீட்'}</span>
          </button>
        </div>

        {/* Phone Content Body */}
        <div style={{ flex: 1, overflowY: 'auto', padding: '0.9rem', display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          {/* TAB 1: Fast Customer Delivery (<15s) */}
          {activeTab === 'water_can' && (
            <>
              {isSuccessFeedback && (
                <div style={{ background: '#065F46', border: '1px solid #10B981', borderRadius: '10px', padding: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.5rem', animation: 'modalEnter 0.2s ease' }}>
                  <Check size={18} color="#34D399" />
                  <div style={{ fontSize: '0.74rem', color: '#FFFFFF', fontWeight: 700 }}>
                    {t('mobile.gps_captured', mobileLang)} (11.0182, 76.9641)
                  </div>
                </div>
              )}

              {/* Live Truck Stock Strip */}
              <div style={{ background: '#1E293B', borderRadius: '8px', padding: '0.55rem 0.85rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', border: '1px solid #334155' }}>
                <span style={{ fontSize: '0.76rem', color: '#94A3B8' }}>{t('cans.stock_on_truck', mobileLang)}:</span>
                <span className="font-mono" style={{ fontSize: '0.9rem', fontWeight: 800, color: '#38BDF8' }}>
                  25 Cans
                </span>
              </div>

              {/* Shop Selector */}
              <div>
                <label style={{ fontSize: '0.74rem', fontWeight: 700, color: '#94A3B8', display: 'block', marginBottom: '0.3rem' }}>
                  {t('mobile.customer_select', mobileLang)}
                </label>
                <select
                  style={{ width: '100%', background: '#1E293B', border: '1px solid #334155', borderRadius: '8px', padding: '0.55rem', color: '#FFFFFF', fontSize: '0.82rem', fontWeight: 600 }}
                  value={selectedShop}
                  onChange={e => setSelectedShop(e.target.value)}
                >
                  <option value="Aran Cafe - 1">அரண் கஃபே - 1 (Aran Cafe - 1)</option>
                  <option value="Aran Cafe - 2">அரண் கஃபே - 2 (Aran Cafe - 2)</option>
                  <option value="Balaji Cafe">பாலாஜி கஃபே (Balaji Cafe)</option>
                  <option value="Black Pekoe Tea">ப்ளாக் பெக்கோ டீ (Black Pekoe Tea)</option>
                  <option value="One Cup Tea">ஒன் கப் டீ (One Cup Tea)</option>
                  <option value="Surya Tex - 1">சூர்யா டெக்ஸ் (Surya Tex - 1)</option>
                  <option value="Santha Company">சாந்தா கம்பெனி (Santha Company)</option>
                </select>
              </div>

              {/* Steppers: Full Cans Delivered & Empty Returned */}
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.65rem' }}>
                <div style={{ background: '#1E293B', borderRadius: '10px', padding: '0.75rem', textAlign: 'center', border: '1px solid #334155' }}>
                  <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#38BDF8' }}>
                    {t('mobile.cans_delivered', mobileLang)}
                  </div>
                  <div className="font-mono" style={{ fontSize: '1.9rem', fontWeight: 900, color: '#FFFFFF', margin: '0.2rem 0' }}>
                    {cansDelivered}
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'center', gap: '0.5rem' }}>
                    <button
                      onClick={() => setCansDelivered(c => Math.max(1, c - 1))}
                      style={{ width: '34px', height: '34px', borderRadius: '50%', background: '#EF4444', border: 'none', color: '#FFF', fontWeight: 900, cursor: 'pointer' }}
                    >
                      -
                    </button>
                    <button
                      onClick={() => setCansDelivered(c => c + 1)}
                      style={{ width: '34px', height: '34px', borderRadius: '50%', background: '#10B981', border: 'none', color: '#FFF', fontWeight: 900, cursor: 'pointer' }}
                    >
                      +
                    </button>
                  </div>
                </div>

                <div style={{ background: '#1E293B', borderRadius: '10px', padding: '0.75rem', textAlign: 'center', border: '1px solid #334155' }}>
                  <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#FBBF24' }}>
                    {t('mobile.cans_returned', mobileLang)}
                  </div>
                  <div className="font-mono" style={{ fontSize: '1.9rem', fontWeight: 900, color: '#FFFFFF', margin: '0.2rem 0' }}>
                    {cansReturned}
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'center', gap: '0.5rem' }}>
                    <button
                      onClick={() => setCansReturned(c => Math.max(0, c - 1))}
                      style={{ width: '34px', height: '34px', borderRadius: '50%', background: '#EF4444', border: 'none', color: '#FFF', fontWeight: 900, cursor: 'pointer' }}
                    >
                      -
                    </button>
                    <button
                      onClick={() => setCansReturned(c => c + 1)}
                      style={{ width: '34px', height: '34px', borderRadius: '50%', background: '#10B981', border: 'none', color: '#FFF', fontWeight: 900, cursor: 'pointer' }}
                    >
                      +
                    </button>
                  </div>
                </div>
              </div>

              {/* Payment Mode */}
              <div>
                <label style={{ fontSize: '0.74rem', fontWeight: 700, color: '#94A3B8', display: 'block', marginBottom: '0.3rem' }}>
                  {t('mobile.payment_mode', mobileLang)}
                </label>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '0.4rem' }}>
                  <button
                    onClick={() => setPayMode('cash')}
                    style={{
                      padding: '0.55rem',
                      borderRadius: '8px',
                      border: 'none',
                      fontSize: '0.78rem',
                      fontWeight: 700,
                      cursor: 'pointer',
                      background: payMode === 'cash' ? '#059669' : '#1E293B',
                      color: '#FFFFFF'
                    }}
                  >
                    {t('mobile.cash', mobileLang)}
                  </button>
                  <button
                    onClick={() => setPayMode('upi')}
                    style={{
                      padding: '0.55rem',
                      borderRadius: '8px',
                      border: 'none',
                      fontSize: '0.78rem',
                      fontWeight: 700,
                      cursor: 'pointer',
                      background: payMode === 'upi' ? '#0284C7' : '#1E293B',
                      color: '#FFFFFF'
                    }}
                  >
                    {t('mobile.upi', mobileLang)}
                  </button>
                  <button
                    onClick={() => setPayMode('credit')}
                    style={{
                      padding: '0.55rem',
                      borderRadius: '8px',
                      border: 'none',
                      fontSize: '0.78rem',
                      fontWeight: 700,
                      cursor: 'pointer',
                      background: payMode === 'credit' ? '#D97706' : '#1E293B',
                      color: '#FFFFFF'
                    }}
                  >
                    {t('mobile.credit', mobileLang)}
                  </button>
                </div>
              </div>

              {/* Amount Display */}
              <div style={{ background: '#0F172A', border: '1px solid #334155', borderRadius: '10px', padding: '0.65rem 0.85rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: '0.8rem', color: '#94A3B8' }}>{t('common.amount', mobileLang)}:</span>
                <span className="font-mono" style={{ fontSize: '1.35rem', fontWeight: 900, color: '#10B981' }}>
                  {formatINR(totalAmount)}
                </span>
              </div>

              {/* Giant Confirm Button */}
              <button
                onClick={handleConfirmDelivery}
                style={{
                  background: 'linear-gradient(135deg, #0284C7, #0369A1)',
                  border: 'none',
                  borderRadius: '12px',
                  padding: '0.85rem',
                  color: '#FFFFFF',
                  fontWeight: 900,
                  fontSize: '0.92rem',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '0.5rem'
                }}
              >
                <Check size={18} />
                <span>{t('mobile.confirm_btn', mobileLang)}</span>
              </button>
            </>
          )}

          {/* TAB 2: Plant Refill & Photo Proof (Sequential Loads & Anti-Fraud GPS) */}
          {activeTab === 'plant_refill' && (
            <>
              {refillSubmitted && (
                <div style={{ background: '#065F46', border: '1px solid #10B981', borderRadius: '10px', padding: '0.75rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <CheckCircle size={18} color="#34D399" />
                  <div style={{ fontSize: '0.74rem', color: '#FFFFFF', fontWeight: 700 }}>
                    Load Run #{todayCumulativeLoads.length} Logged with Photo Proof & GPS!
                  </div>
                </div>
              )}

              {/* Cumulative Refill Tally */}
              <div style={{ background: '#1E293B', borderRadius: '10px', padding: '0.75rem', border: '1px solid #334155' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: '0.74rem', color: '#38BDF8', fontWeight: 800 }}>
                    {mobileLang === 'en' ? 'TODAY PLANT RUN SUMMARY' : 'இன்றைய லோடு விபரம்'}
                  </span>
                  <span className="status-pill status-pill-green" style={{ fontSize: '0.68rem' }}>
                    {todayCumulativeLoads.length} Trips Today
                  </span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '0.5rem', fontSize: '0.8rem' }}>
                  <span>Total Cans: <strong>{todayCumulativeLoads.reduce((a, b) => a + b.cans, 0)} Loaded</strong></span>
                  <span>Total KM: <strong>72.0 km Covered</strong></span>
                </div>
              </div>

              {/* Log Next Load Run Input */}
              <div style={{ background: '#0F172A', borderRadius: '10px', padding: '0.75rem', border: '1px solid #334155', display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
                <div style={{ fontSize: '0.76rem', fontWeight: 800, color: '#34D399' }}>
                  + LOG LOAD TRIP #{todayCumulativeLoads.length + 1}
                </div>

                {/* Cans Count */}
                <div>
                  <label style={{ fontSize: '0.72rem', color: '#94A3B8', display: 'block', marginBottom: '2px' }}>
                    Number of Cans Loaded at Plant:
                  </label>
                  <input
                    type="number"
                    style={{ width: '100%', background: '#1E293B', border: '1px solid #334155', borderRadius: '6px', padding: '0.45rem', color: '#FFF', fontFamily: 'monospace', fontWeight: 700 }}
                    value={refillCansCount}
                    onChange={e => setRefillCansCount(Number(e.target.value))}
                  />
                </div>

                {/* Photo Capture Proof Button & Simulated Viewfinder */}
                <div>
                  <label style={{ fontSize: '0.72rem', color: '#94A3B8', display: 'block', marginBottom: '2px' }}>
                    Take Photo Proof of Filled Truck / Plant Slip:
                  </label>
                  <div
                    onClick={() => setRefillPhotoAttached(true)}
                    style={{
                      background: refillPhotoAttached ? '#064E3B' : '#1E293B',
                      border: refillPhotoAttached ? '1px solid #10B981' : '1px dashed #64748B',
                      borderRadius: '8px',
                      padding: '0.65rem',
                      textAlign: 'center',
                      cursor: 'pointer',
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      gap: '4px'
                    }}
                  >
                    <Camera size={20} color={refillPhotoAttached ? '#34D399' : '#94A3B8'} />
                    <span style={{ fontSize: '0.72rem', fontWeight: 700, color: refillPhotoAttached ? '#34D399' : '#FFFFFF' }}>
                      {refillPhotoAttached ? '✓ Photo Captured & Attached (WATERMARK VERIFIED)' : 'Tap to Snap Photo of Loaded Cans'}
                    </span>
                    {refillPhotoAttached && (
                      <span style={{ fontSize: '0.65rem', color: '#A7F3D0', fontFamily: 'monospace' }}>
                        RO_PLANT_OCT30_LOAD{todayCumulativeLoads.length + 1}_PROOF.JPG (11.0182N, 76.9641E)
                      </span>
                    )}
                  </div>
                </div>

                {/* Odometer at Plant */}
                <div>
                  <label style={{ fontSize: '0.72rem', color: '#94A3B8', display: 'block', marginBottom: '2px' }}>
                    Odometer at Plant (km):
                  </label>
                  <input
                    type="number"
                    style={{ width: '100%', background: '#1E293B', border: '1px solid #334155', borderRadius: '6px', padding: '0.45rem', color: '#FFF', fontFamily: 'monospace' }}
                    value={refillOdometer}
                    onChange={e => setRefillOdometer(Number(e.target.value))}
                  />
                </div>

                {/* Anti-Fraud Locked Location Notice */}
                <div style={{ background: '#1E293B', padding: '0.45rem', borderRadius: '6px', fontSize: '0.68rem', color: '#94A3B8', display: 'flex', alignItems: 'center', gap: '5px' }}>
                  <ShieldCheck size={14} color="#10B981" />
                  <span>GPS Location & seconds timestamp locked to eliminate fraudulent claims.</span>
                </div>

                <button
                  onClick={handleSavePlantRefill}
                  style={{
                    background: '#0D9488',
                    border: 'none',
                    borderRadius: '8px',
                    padding: '0.75rem',
                    color: '#FFF',
                    fontWeight: 800,
                    fontSize: '0.85rem',
                    cursor: 'pointer',
                    marginTop: '0.25rem'
                  }}
                >
                  Confirm & Save Plant Refill
                </button>
              </div>

              {/* Today's Previous Runs List */}
              <div style={{ fontSize: '0.72rem', fontWeight: 700, color: '#94A3B8', textTransform: 'uppercase' }}>
                Completed Loads Today ({todayCumulativeLoads.length})
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                {todayCumulativeLoads.map(load => (
                  <div key={load.trip} style={{ background: '#1E293B', borderRadius: '6px', padding: '0.5rem 0.75rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.74rem' }}>
                    <div>
                      <span style={{ fontWeight: 800, color: '#38BDF8' }}>Trip #{load.trip}</span>
                      <span style={{ color: '#94A3B8', marginLeft: '6px' }}>{load.time}</span>
                    </div>
                    <div>
                      <span style={{ fontWeight: 800, color: '#10B981' }}>+{load.cans} Cans</span>
                      <span style={{ color: '#94A3B8', marginLeft: '6px' }}>({load.km} km)</span>
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}

          {/* TAB 3: Customizable Tanker Trip Sheet (Per-Minute Motor/Wait, Base Distance, Owner Discount) */}
          {activeTab === 'tanker_trip' && (
            <>
              {tankerSubmitted && (
                <div style={{ background: '#065F46', border: '1px solid #10B981', borderRadius: '8px', padding: '0.65rem', color: '#FFF', fontSize: '0.78rem', fontWeight: 700 }}>
                  ✓ Trip Sheet Closed & Submitted to Server!
                </div>
              )}

              {/* Trip Header Banner */}
              <div style={{ background: '#1E293B', borderRadius: '10px', padding: '0.65rem 0.85rem', border: '1px solid #334155' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: '0.72rem', color: '#38BDF8', fontWeight: 700 }}>TRP-2026-0841 · 24.0 KL</span>
                  <span className="status-pill status-pill-blue" style={{ fontSize: '0.65rem' }}>TN 34 AF 4954</span>
                </div>
                <div style={{ fontSize: '0.88rem', fontWeight: 800, marginTop: '2px' }}>Texvalley Corporate Campus</div>
              </div>

              {/* 1. Base Fare & Distance Rules */}
              <div style={{ background: '#0F172A', borderRadius: '8px', padding: '0.65rem', border: '1px solid #334155', display: 'flex', flexDirection: 'column', gap: '0.45rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.74rem' }}>
                  <span style={{ color: '#94A3B8' }}>Base Fare (Includes up to {tankerMinDistanceKm} km):</span>
                  <span className="font-mono" style={{ fontWeight: 700 }}>₹{tankerBaseFare}</span>
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '0.5rem' }}>
                  <span style={{ fontSize: '0.72rem', color: '#94A3B8' }}>Total Trip Distance (km):</span>
                  <input
                    type="number"
                    style={{ width: '75px', background: '#1E293B', border: '1px solid #334155', borderRadius: '4px', padding: '0.25rem 0.4rem', color: '#FFF', fontFamily: 'monospace', textAlign: 'right' }}
                    value={tankerActualDistanceKm}
                    onChange={e => setTankerActualDistanceKm(Number(e.target.value))}
                  />
                </div>

                {extraDistanceKm > 0 && (
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', color: '#FBBF24' }}>
                    <span>Extra {extraDistanceKm} km beyond {tankerMinDistanceKm}km (@ ₹{tankerDistanceRate}/km):</span>
                    <span className="font-mono" style={{ fontWeight: 700 }}>+₹{distanceCharges}</span>
                  </div>
                )}
              </div>

              {/* 2. Motor Pumping Charge (Per Minute) */}
              <div style={{ background: '#0F172A', borderRadius: '8px', padding: '0.65rem', border: '1px solid #334155', display: 'flex', flexDirection: 'column', gap: '0.45rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.74rem', fontWeight: 700, cursor: 'pointer' }}>
                    <input
                      type="checkbox"
                      checked={tankerMotorUsed}
                      onChange={e => setTankerMotorUsed(e.target.checked)}
                    />
                    <span>Water Pumping Motor Used</span>
                  </label>
                  {tankerMotorUsed && (
                    <span className="font-mono" style={{ fontSize: '0.74rem', fontWeight: 700, color: '#34D399' }}>
                      +₹{motorCharges}
                    </span>
                  )}
                </div>

                {tankerMotorUsed && (
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.72rem', color: '#94A3B8' }}>
                    <span>Running Duration (Minutes @ ₹{tankerMotorRatePerMin}/min):</span>
                    <input
                      type="number"
                      style={{ width: '65px', background: '#1E293B', border: '1px solid #334155', borderRadius: '4px', padding: '0.25rem 0.4rem', color: '#FFF', fontFamily: 'monospace', textAlign: 'right' }}
                      value={tankerMotorMinutes}
                      onChange={e => setTankerMotorMinutes(Number(e.target.value))}
                    />
                  </div>
                )}
              </div>

              {/* 3. Waiting Detention Cost (Per Minute) */}
              <div style={{ background: '#0F172A', borderRadius: '8px', padding: '0.65rem', border: '1px solid #334155', display: 'flex', flexDirection: 'column', gap: '0.45rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: '0.74rem', fontWeight: 700 }}>Waiting / Detention Cost:</span>
                  <span className="font-mono" style={{ fontSize: '0.74rem', fontWeight: 700, color: '#FBBF24' }}>
                    +₹{waitingCharges}
                  </span>
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.72rem', color: '#94A3B8' }}>
                  <span>Waiting Duration (Minutes @ ₹{tankerWaitingRatePerMin}/min):</span>
                  <input
                    type="number"
                    style={{ width: '65px', background: '#1E293B', border: '1px solid #334155', borderRadius: '4px', padding: '0.25rem 0.4rem', color: '#FFF', fontFamily: 'monospace', textAlign: 'right' }}
                    value={tankerWaitingMinutes}
                    onChange={e => setTankerWaitingMinutes(Number(e.target.value))}
                  />
                </div>
              </div>

              {/* 4. Non-Negotiable System Calculated Bill */}
              <div style={{ background: '#1E293B', borderRadius: '8px', padding: '0.55rem 0.85rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', border: '1px solid #38BDF8' }}>
                <div>
                  <div style={{ fontSize: '0.7rem', color: '#38BDF8', fontWeight: 800 }}>SYSTEM CALCULATED BILL (NO BARGAIN)</div>
                  <div style={{ fontSize: '0.65rem', color: '#94A3B8' }}>Every minute of motor, wait & km itemized</div>
                </div>
                <span className="font-mono" style={{ fontSize: '1.15rem', fontWeight: 900, color: '#FFF' }}>
                  ₹{standardSystemBill}
                </span>
              </div>

              {/* 5. Owner Approved Discount / Bargained Concession Override */}
              <div style={{ background: '#1C1917', borderRadius: '8px', padding: '0.65rem', border: '1px solid #78350F', display: 'flex', flexDirection: 'column', gap: '0.4rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.72rem', fontWeight: 700, color: '#FBBF24', cursor: 'pointer' }}>
                    <input
                      type="checkbox"
                      checked={hasOwnerDiscount}
                      onChange={e => setHasOwnerDiscount(e.target.checked)}
                    />
                    <span>Customer Bargained & Owner Accepted</span>
                  </label>
                  {hasOwnerDiscount && (
                    <span className="font-mono" style={{ fontSize: '0.72rem', fontWeight: 800, color: '#EF4444' }}>
                      -₹{ownerDiscountAmount}
                    </span>
                  )}
                </div>

                {hasOwnerDiscount && (
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.7rem', color: '#A8A29E' }}>
                    <span>Approved Discount Concession:</span>
                    <input
                      type="number"
                      style={{ width: '70px', background: '#292524', border: '1px solid #78350F', borderRadius: '4px', padding: '0.2rem 0.4rem', color: '#FFF', fontFamily: 'monospace', textAlign: 'right' }}
                      value={ownerDiscountAmount}
                      onChange={e => setOwnerDiscountAmount(Number(e.target.value))}
                    />
                  </div>
                )}
                {hasOwnerDiscount && (
                  <div style={{ fontSize: '0.65rem', color: '#78716C' }}>
                    Authorized by: <strong>{ownerApprover}</strong> · Stored in immutable audit log
                  </div>
                )}
              </div>

              {/* 6. Final Trip Closing Payable */}
              <div style={{ background: '#064E3B', borderRadius: '10px', padding: '0.75rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', border: '1px solid #10B981' }}>
                <span style={{ fontSize: '0.8rem', fontWeight: 800, color: '#A7F3D0' }}>
                  {t('tankers.final_closing_amount', mobileLang)}:
                </span>
                <span className="font-mono" style={{ fontSize: '1.4rem', fontWeight: 900, color: '#FFFFFF' }}>
                  {formatINR(finalPayableAmount)}
                </span>
              </div>

              <button
                onClick={handleConfirmTanker}
                style={{
                  background: '#059669',
                  border: 'none',
                  borderRadius: '12px',
                  padding: '0.85rem',
                  color: '#FFFFFF',
                  fontWeight: 800,
                  fontSize: '0.9rem',
                  cursor: 'pointer'
                }}
              >
                Close & Submit Trip Sheet
              </button>
            </>
          )}
        </div>

        {/* Phone Bottom Home Indicator */}
        <div style={{ padding: '0.45rem', display: 'flex', justifyContent: 'center', background: '#0F172A' }}>
          <div style={{ width: '110px', height: '4px', background: '#475569', borderRadius: '999px' }} />
        </div>
      </div>
    </div>
  );
};
