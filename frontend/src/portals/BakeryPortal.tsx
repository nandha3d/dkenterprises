import React, { useState } from 'react';
import { BakeryPurchase, BakeryClosing } from '../types';
import { Language, t, formatINR } from '../services/languageEngine';
import {
  Store,
  Plus,
  CheckCircle,
  Coins,
  Wallet,
  Receipt,
  Trash2,
  AlertTriangle,
  X,
  CreditCard
} from 'lucide-react';

interface BakeryPortalProps {
  lang: Language;
  purchases: BakeryPurchase[];
  closing: BakeryClosing;
  onAddPurchase: (purchase: BakeryPurchase) => void;
  onUpdateClosing: (closing: BakeryClosing) => void;
}

export const INGREDIENT_TEMPLATES = [
  { name_en: 'Fresh Milk Packets', name_ta: 'பால் பாக்கெட்', vendor: 'Aavin / Local Farm', unit: 'packet', rate: 32, cat: 'Dairy' },
  { name_en: 'Maida (Wheat Flour)', name_ta: 'மைதா மாவு (50kg)', vendor: 'Sri Murugan Flour Mill', unit: 'bag (50kg)', rate: 1850, cat: 'Flours' },
  { name_en: 'Atta / Wheat Flour', name_ta: 'ஆட்டா கோதுமை மாவு', vendor: 'Local Wholesale Mandi', unit: 'kg', rate: 42, cat: 'Flours' },
  { name_en: 'White Sugar', name_ta: 'வெள்ளை சர்க்கரை', vendor: 'Balaji Grocery', unit: 'kg', rate: 46, cat: 'Sweeteners' },
  { name_en: 'Cooking Oil / Dalda', name_ta: 'சமையல் எண்ணெய்', vendor: 'City Oil Agency', unit: 'tin (15L)', rate: 1980, cat: 'Oils' },
  { name_en: 'Fresh Butter & Ghee', name_ta: 'வெண்ணெய் & நெய்', vendor: 'Dairy Depot', unit: 'kg', rate: 580, cat: 'Dairy' },
  { name_en: 'Yeast & Baking Powder', name_ta: 'ஈஸ்ட் & பேக்கிங் பவுடர்', vendor: 'Bakery Essentials', unit: 'box', rate: 260, cat: 'Bakery' },
  { name_en: 'Eggs (Crate)', name_ta: 'முட்டை (கிரேட்)', vendor: 'Namakkal Poultry', unit: 'tray (30pcs)', rate: 180, cat: 'Produce' },
  { name_en: 'Onions / Bellary', name_ta: 'வெங்காயம் (மூட்டை)', vendor: 'Uzhavar Sandhai', unit: 'sack', rate: 450, cat: 'Produce' },
  { name_en: 'Tomato', name_ta: 'தக்காளி', vendor: 'Local Mandi', unit: 'box', rate: 34, cat: 'Produce' },
  { name_en: 'Coriander & Mint', name_ta: 'கொத்தமல்லி & புதினா', vendor: 'Local Mandi', unit: 'bundle', rate: 210, cat: 'Produce' },
  { name_en: 'Cake & Bun Base', name_ta: 'கேக் & பன்', vendor: 'Sri Murugan Supplies', unit: 'crate', rate: 390, cat: 'Confectionery' },
  { name_en: 'Puffs Sheets & Ready', name_ta: 'பப்ஸ்', vendor: 'Sri Murugan Supplies', unit: 'tray', rate: 300, cat: 'Confectionery' },
  { name_en: 'Brownies & Pastries', name_ta: 'பிரவுனி & கேக்', vendor: 'City Confectionery', unit: 'box', rate: 530, cat: 'Confectionery' },
  { name_en: 'Soft Drinks (7up, Pepsi)', name_ta: 'குளிர்பானங்கள்', vendor: 'City Beverage Depot', unit: 'crate', rate: 270, cat: 'Beverages' },
  { name_en: 'Tea Dust (Chakra Gold)', name_ta: 'டீ தூள்', vendor: 'Nilgiri Agency', unit: 'kg', rate: 340, cat: 'Beverages' },
  { name_en: 'Coffee Powder (Narasu)', name_ta: 'காபி தூள்', vendor: 'Salem Depot', unit: 'packet', rate: 220, cat: 'Beverages' },
  { name_en: 'Daily Finance Instalment', name_ta: 'தினசரி பைனான்ஸ் தவணை', vendor: 'Finance Agent', unit: 'instalment', rate: 1000, cat: 'Expenses' },
  { name_en: 'Paati Wages & Advance', name_ta: 'பாட்டி கூலி & அட்வான்ஸ்', vendor: 'Store Helper', unit: 'day', rate: 350, cat: 'Expenses' },
  { name_en: 'Vim Lemon & Cleaning', name_ta: 'விம் லெமன் & வாஷிங்', vendor: 'Balaji Grocery', unit: 'bottle', rate: 139, cat: 'Expenses' },
  { name_en: 'Bakery Paper Boxes & Bags', name_ta: 'பேக்கிங் பாக்ஸ் & கவர்கள்', vendor: 'Universal Packaging', unit: 'bundle', rate: 420, cat: 'Expenses' }
];

export const BakeryPortal: React.FC<BakeryPortalProps> = ({
  lang,
  purchases,
  closing,
  onAddPurchase,
  onUpdateClosing
}) => {
  const [showPurchaseModal, setShowPurchaseModal] = useState(false);
  const [showClosingModal, setShowClosingModal] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('All');

  // New Purchase Form
  const [itemName, setItemName] = useState('Fresh Milk Packets');
  const [vendorName, setVendorName] = useState('Aavin / Local Farm');
  const [qty, setQty] = useState(20);
  const [unit, setUnit] = useState('packet');
  const [rate, setRate] = useState(32);
  const [payMode, setPayMode] = useState<'cash_drawer' | 'gpay_kavin' | 'vendor_credit'>('cash_drawer');

  // Template Quick Filler
  const applyTemplate = (tpl: typeof INGREDIENT_TEMPLATES[0]) => {
    setItemName(lang === 'ta' ? tpl.name_ta : tpl.name_en);
    setVendorName(tpl.vendor);
    setUnit(tpl.unit);
    setRate(tpl.rate);
    setQty(1);
    setShowPurchaseModal(true);
  };

  // Evening Closing State (Image 1 Page 152)
  const [drawerCash, setDrawerCash] = useState(closing.physical_drawer_cash);
  const [coins, setCoins] = useState(closing.coins_amount);
  const [drawerExp, setDrawerExp] = useState(closing.expenses_paid_from_drawer);
  const [upi, setUpi] = useState(closing.upi_collections);
  const [bajjiWastage, setBajjiWastage] = useState(closing.wastage.bajji);
  const [bondaWastage, setBondaWastage] = useState(closing.wastage.egg_bonda);
  const [puffWastage, setPuffWastage] = useState(closing.wastage.puff);
  const [milkWastage, setMilkWastage] = useState(closing.wastage.milk_pockets);

  const totalRawPurchases = purchases.reduce((acc, p) => acc + p.total_amount, 0);
  const cashPurchases = purchases.filter(p => p.payment_mode === 'cash_drawer').reduce((acc, p) => acc + p.total_amount, 0);
  const gpayPurchases = purchases.filter(p => p.payment_mode === 'gpay_kavin').reduce((acc, p) => acc + p.total_amount, 0);

  const handleSavePurchase = () => {
    const newPurchase: BakeryPurchase = {
      id: Date.now(),
      purchase_date: new Date().toISOString().split('T')[0],
      item_name_en: itemName,
      item_name_ta: itemName,
      vendor_name: vendorName,
      quantity: qty,
      unit: unit,
      rate: rate,
      total_amount: qty * rate,
      payment_mode: payMode
    };

    onAddPurchase(newPurchase);
    setShowPurchaseModal(false);
  };

  const handleSaveClosing = () => {
    const totalRev = (drawerCash + coins) + upi;
    const netBanked = (drawerCash + coins) - drawerExp;

    const newClosing: BakeryClosing = {
      closing_date: new Date().toISOString().split('T')[0],
      physical_drawer_cash: drawerCash,
      coins_amount: coins,
      expenses_paid_from_drawer: drawerExp,
      upi_collections: upi,
      total_counter_revenue: totalRev,
      net_cash_banked: netBanked,
      wastage: {
        bajji: bajjiWastage,
        egg_bonda: bondaWastage,
        puff: puffWastage,
        milk_pockets: milkWastage
      },
      closed_by: 'Kavin / Wife'
    };

    onUpdateClosing(newClosing);
    setShowClosingModal(false);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      {/* 1. Header with Fresh Visual Action Bar */}
      <div className="fresh-card" style={{ padding: '1.25rem 1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
            <span style={{ fontSize: '1.45rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {t('bakery.title', lang)}
            </span>
            <span className="status-pill status-pill-amber">
              RETAIL STORE & COUNTER CASH RECONCILER
            </span>
          </div>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.84rem', marginTop: '0.2rem' }}>
            {t('bakery.subtitle', lang)}
          </p>
        </div>

        <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
          <button
            onClick={() => setShowPurchaseModal(true)}
            className="btn-fresh btn-fresh-outline"
          >
            <Plus size={16} />
            <span>{t('bakery.add_purchase_btn', lang)}</span>
          </button>

          <button
            onClick={() => setShowClosingModal(true)}
            className="btn-fresh btn-fresh-primary"
            style={{ background: '#D97706' }}
          >
            <Receipt size={16} />
            <span>{t('bakery.counter_closing', lang)}</span>
          </button>
        </div>
      </div>

      {/* 2. Visuals & Numbers Strip (Page 152 Ground Ledger) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem' }}>
        {/* Visual 1: Total Sales Breakdown */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('bakery.total_sales', lang)}
            </span>
            <span className="status-pill status-pill-green">
              Page 152 Reconciled
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {formatINR(closing.total_counter_revenue)}
            </span>
          </div>

          {/* Cash vs UPI Split Bar */}
          <div style={{ display: 'flex', height: '8px', borderRadius: '999px', overflow: 'hidden', background: 'var(--bg-surface-subtle)' }}>
            <div style={{ width: '36%', background: '#059669' }} title="Cash: ₹2,064 (36%)"></div>
            <div style={{ width: '64%', background: '#0284C7' }} title="UPI: ₹3,700 (64%)"></div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', color: 'var(--text-muted)' }}>
            <span>Cash: {formatINR(closing.physical_drawer_cash + closing.coins_amount)}</span>
            <span>UPI: {formatINR(closing.upi_collections)}</span>
          </div>
        </div>

        {/* Visual 2: Drawer Box Cash & Coins */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Drawer Box Cash + Coins
            </span>
            <span className="status-pill status-pill-neutral">
              Physical Drawer
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {formatINR(closing.physical_drawer_cash + closing.coins_amount)}
            </span>
          </div>

          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <span style={{ fontSize: '0.74rem', background: 'var(--bg-surface-subtle)', padding: '0.2rem 0.5rem', borderRadius: '4px', border: '1px solid var(--border-subtle)' }}>
              Notes: {formatINR(closing.physical_drawer_cash)}
            </span>
            <span style={{ fontSize: '0.74rem', background: 'var(--bg-surface-subtle)', padding: '0.2rem 0.5rem', borderRadius: '4px', border: '1px solid var(--border-subtle)' }}>
              Coins: {formatINR(closing.coins_amount)}
            </span>
          </div>

          <div style={{ fontSize: '0.72rem', color: 'var(--text-dim)' }}>
            Counted at 6:36 PM by Kavin / Wife
          </div>
        </div>

        {/* Visual 3: Drawer Expenses & Net Banked */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('bakery.net_banked', lang)}
            </span>
            <span className="status-pill status-pill-green">
              Ready for Deposit
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: '#059669' }}>
              {formatINR(closing.net_cash_banked)}
            </span>
          </div>

          <div style={{ fontSize: '0.74rem', color: '#DC2626' }}>
            - {formatINR(closing.expenses_paid_from_drawer)} Paid from Drawer (Expenses)
          </div>

          <div style={{ fontSize: '0.72rem', color: 'var(--text-dim)' }}>
            Formula: (₹1,960 + ₹104) - ₹700 = ₹1,364 Net Banked
          </div>
        </div>

        {/* Visual 4: Daily 10-Item Raw Purchases */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Raw Materials Today
            </span>
            <span className="status-pill status-pill-blue">
              {purchases.length} Items Purchased
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.1rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {formatINR(totalRawPurchases)}
            </span>
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', color: 'var(--text-muted)' }}>
            <span>Cash: {formatINR(cashPurchases)}</span>
            <span>GPay Kavin: {formatINR(gpayPurchases)}</span>
          </div>

          <div style={{ fontSize: '0.72rem', color: 'var(--text-dim)' }}>
            Coriander, Tomato, Cake, Puffs, Paati wages
          </div>
        </div>
      </div>

      {/* 3. Physical Wastage Counter Bar (Page 152 Ground Counts) */}
      <div className="fresh-card" style={{ padding: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
          <div>
            <span style={{ fontWeight: 800, fontSize: '0.98rem' }}>
              {t('bakery.wastage_section', lang)}
            </span>
            <p style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
              Logged during 3-minute evening shift closure to prevent unaccounted leakage
            </p>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
          <div style={{ background: 'var(--bg-surface-subtle)', padding: '0.75rem 1.25rem', borderRadius: '10px', border: '1px solid var(--border-subtle)', flex: 1, minWidth: '160px' }}>
            <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>பஜ்ஜி (Bajji)</div>
            <div className="font-mono" style={{ fontSize: '1.4rem', fontWeight: 800, color: '#D97706' }}>
              {closing.wastage.bajji} pcs
            </div>
          </div>

          <div style={{ background: 'var(--bg-surface-subtle)', padding: '0.75rem 1.25rem', borderRadius: '10px', border: '1px solid var(--border-subtle)', flex: 1, minWidth: '160px' }}>
            <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>முட்டை போண்டா (Egg Bonda)</div>
            <div className="font-mono" style={{ fontSize: '1.4rem', fontWeight: 800, color: '#D97706' }}>
              {closing.wastage.egg_bonda} pcs
            </div>
          </div>

          <div style={{ background: 'var(--bg-surface-subtle)', padding: '0.75rem 1.25rem', borderRadius: '10px', border: '1px solid var(--border-subtle)', flex: 1, minWidth: '160px' }}>
            <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>பப்ஸ் (Puff)</div>
            <div className="font-mono" style={{ fontSize: '1.4rem', fontWeight: 800, color: '#D97706' }}>
              {closing.wastage.puff} pcs
            </div>
          </div>

          <div style={{ background: 'var(--bg-surface-subtle)', padding: '0.75rem 1.25rem', borderRadius: '10px', border: '1px solid var(--border-subtle)', flex: 1, minWidth: '160px' }}>
            <div style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>பால் பாக்கெட் (Unsold Milk)</div>
            <div className="font-mono" style={{ fontSize: '1.4rem', fontWeight: 800, color: '#0284C7' }}>
              {closing.wastage.milk_pockets} pockets
            </div>
          </div>
        </div>
      </div>

      {/* 4. Daily Raw Material Purchases Table (Open Master Catalog) */}
      <div className="fresh-card" style={{ padding: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', flexWrap: 'wrap', gap: '0.75rem' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
                {t('bakery.raw_materials', lang)}
              </span>
              <span className="status-pill status-pill-green">
                UNLIMITED ITEMS SUPPORTED
              </span>
            </div>
            <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
              Open ingredient catalog · Cash Drawer payments separated from Kavin Anna GPay transactions
            </p>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <input
              type="text"
              placeholder="Search ingredient or vendor..."
              className="fresh-input"
              style={{ width: '220px', padding: '0.4rem 0.75rem', fontSize: '0.82rem' }}
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
            />
          </div>
        </div>

        {/* Quick Add Recurring Templates Ribbon */}
        <div style={{ background: 'var(--bg-surface-subtle)', padding: '0.85rem', borderRadius: '10px', marginBottom: '1.25rem', border: '1px solid var(--border-subtle)' }}>
          <div style={{ fontSize: '0.74rem', fontWeight: 800, color: 'var(--text-secondary)', textTransform: 'uppercase', marginBottom: '0.5rem' }}>
            ⚡ {t('bakery.recurring_templates', lang)} (Click to 1-Click Pre-fill & Add):
          </div>
          <div style={{ display: 'flex', gap: '0.45rem', flexWrap: 'wrap' }}>
            {INGREDIENT_TEMPLATES.map(tpl => (
              <button
                key={tpl.name_en}
                onClick={() => applyTemplate(tpl)}
                style={{
                  fontSize: '0.74rem',
                  fontWeight: 600,
                  padding: '0.25rem 0.6rem',
                  borderRadius: '6px',
                  background: 'var(--bg-surface)',
                  color: 'var(--text-primary)',
                  border: '1px solid var(--border-subtle)',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                  transition: 'all 0.15s ease'
                }}
              >
                <span>+</span>
                <span>{lang === 'ta' ? tpl.name_ta : tpl.name_en}</span>
                <span style={{ color: 'var(--text-dim)', fontSize: '0.7rem' }}>₹{tpl.rate}</span>
              </button>
            ))}
          </div>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table className="fresh-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Item Name</th>
                <th>Vendor / Mandi</th>
                <th>Quantity</th>
                <th>Rate (₹)</th>
                <th>Total (₹)</th>
                <th>Payment Mode</th>
              </tr>
            </thead>
            <tbody>
              {purchases
                .filter(p => {
                  const matchSearch = searchTerm === '' ||
                    p.item_name_en.toLowerCase().includes(searchTerm.toLowerCase()) ||
                    p.item_name_ta.toLowerCase().includes(searchTerm.toLowerCase()) ||
                    p.vendor_name.toLowerCase().includes(searchTerm.toLowerCase());
                  return matchSearch;
                })
                .map(p => (
                <tr key={p.id}>
                  <td className="font-mono" style={{ color: 'var(--text-dim)' }}>{p.id}</td>
                  <td style={{ fontWeight: 700 }}>
                    {lang === 'ta' ? p.item_name_ta : p.item_name_en}
                  </td>
                  <td>{p.vendor_name}</td>
                  <td className="font-mono">{p.quantity} {p.unit}</td>
                  <td className="font-mono">₹{p.rate}</td>
                  <td className="font-mono" style={{ fontWeight: 800 }}>
                    {formatINR(p.total_amount)}
                  </td>
                  <td>
                    <span
                      className={`status-pill ${
                        p.payment_mode === 'cash_drawer' ? 'status-pill-green' : 'status-pill-blue'
                      }`}
                    >
                      {p.payment_mode === 'cash_drawer' ? 'CASH DRAWER' : 'GPAY KAVIN ANNA'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* 5. 3-Minute Evening Closing Modal */}
      {showClosingModal && (
        <div className="fresh-modal-backdrop" onClick={() => setShowClosingModal(false)}>
          <div className="fresh-modal-dialog" onClick={e => e.stopPropagation()}>
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 800, fontSize: '1.15rem' }}>
                {t('bakery.counter_closing', lang)} (Page 152)
              </span>
              <button
                onClick={() => setShowClosingModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    {t('bakery.drawer_cash', lang)}
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={drawerCash}
                    onChange={e => setDrawerCash(Number(e.target.value))}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    {t('bakery.drawer_coins', lang)}
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={coins}
                    onChange={e => setCoins(Number(e.target.value))}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    {t('bakery.drawer_expenses', lang)}
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={drawerExp}
                    onChange={e => setDrawerExp(Number(e.target.value))}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    {t('bakery.upi_sales', lang)}
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={upi}
                    onChange={e => setUpi(Number(e.target.value))}
                  />
                </div>
              </div>

              {/* Physical Wastage Counter Inputs */}
              <div style={{ background: 'var(--bg-surface-subtle)', padding: '1rem', borderRadius: '10px' }}>
                <span style={{ fontSize: '0.78rem', fontWeight: 800, color: 'var(--text-secondary)', textTransform: 'uppercase', display: 'block', marginBottom: '0.5rem' }}>
                  Wastage Pieces Left Unsold
                </span>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '0.5rem' }}>
                  <div>
                    <label style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Bajji</label>
                    <input type="number" className="fresh-input font-mono" value={bajjiWastage} onChange={e => setBajjiWastage(Number(e.target.value))} />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Bonda</label>
                    <input type="number" className="fresh-input font-mono" value={bondaWastage} onChange={e => setBondaWastage(Number(e.target.value))} />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Puff</label>
                    <input type="number" className="fresh-input font-mono" value={puffWastage} onChange={e => setPuffWastage(Number(e.target.value))} />
                  </div>
                  <div>
                    <label style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>Milk</label>
                    <input type="number" className="fresh-input font-mono" value={milkWastage} onChange={e => setMilkWastage(Number(e.target.value))} />
                  </div>
                </div>
              </div>

              {/* Net Banked Calculation Banner */}
              <div style={{ background: 'var(--accent-emerald-light)', padding: '1rem', borderRadius: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontWeight: 700, color: 'var(--accent-emerald-text)' }}>
                  {t('bakery.net_banked', lang)}:
                </span>
                <span className="font-mono" style={{ fontSize: '1.4rem', fontWeight: 900, color: 'var(--accent-emerald-text)' }}>
                  {formatINR((drawerCash + coins) - drawerExp)}
                </span>
              </div>
            </div>

            <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                onClick={() => setShowClosingModal(false)}
                className="btn-fresh btn-fresh-outline"
              >
                {t('common.cancel', lang)}
              </button>
              <button
                onClick={handleSaveClosing}
                className="btn-fresh btn-fresh-primary"
              >
                {t('common.save', lang)}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* 6. Add Purchase Modal */}
      {showPurchaseModal && (
        <div className="fresh-modal-backdrop" onClick={() => setShowPurchaseModal(false)}>
          <div className="fresh-modal-dialog" onClick={e => e.stopPropagation()}>
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontWeight: 800, fontSize: '1.15rem' }}>
                {t('bakery.add_purchase_btn', lang)}
              </span>
              <button
                onClick={() => setShowPurchaseModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Item Name
                </label>
                <input
                  type="text"
                  className="fresh-input"
                  value={itemName}
                  onChange={e => setItemName(e.target.value)}
                  placeholder="e.g. Coriander, Tomato, Cake, Puffs..."
                />
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Vendor / Supplier
                </label>
                <input
                  type="text"
                  className="fresh-input"
                  value={vendorName}
                  onChange={e => setVendorName(e.target.value)}
                  placeholder="Local Mandi, Grocery..."
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '1rem' }}>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Quantity
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={qty}
                    onChange={e => setQty(Number(e.target.value))}
                  />
                </div>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Unit
                  </label>
                  <input
                    type="text"
                    className="fresh-input"
                    value={unit}
                    onChange={e => setUnit(e.target.value)}
                    placeholder="kg, bundle..."
                  />
                </div>
                <div>
                  <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                    Rate (₹)
                  </label>
                  <input
                    type="number"
                    className="fresh-input font-mono"
                    value={rate}
                    onChange={e => setRate(Number(e.target.value))}
                  />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', display: 'block', marginBottom: '0.3rem' }}>
                  Payment Source
                </label>
                <select
                  className="fresh-input"
                  value={payMode}
                  onChange={e => setPayMode(e.target.value as any)}
                >
                  <option value="cash_drawer">Physical Drawer Cash</option>
                  <option value="gpay_kavin">GPay Kavin Anna</option>
                  <option value="vendor_credit">Vendor Credit (Pay Later)</option>
                </select>
              </div>
            </div>

            <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                onClick={() => setShowPurchaseModal(false)}
                className="btn-fresh btn-fresh-outline"
              >
                {t('common.cancel', lang)}
              </button>
              <button
                onClick={handleSavePurchase}
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
