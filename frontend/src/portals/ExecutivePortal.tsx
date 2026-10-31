import React, { useState } from 'react';
import { CustomerCreditAccount } from '../types';
import { Language, t, formatINR } from '../services/languageEngine';
import {
  TrendingUp,
  DollarSign,
  Wallet,
  FileSpreadsheet,
  ArrowUpRight,
  ArrowDownRight,
  ShieldCheck,
  AlertTriangle,
  X,
  CreditCard,
  Building,
  ArrowRight
} from 'lucide-react';

interface ExecutivePortalProps {
  lang: Language;
  creditAccounts: CustomerCreditAccount[];
  onNavigateToVertical: (portal: 'tankers' | 'water-cans' | 'bakery') => void;
}

export const ExecutivePortal: React.FC<ExecutivePortalProps> = ({
  lang,
  creditAccounts,
  onNavigateToVertical
}) => {
  const [showTaxModal, setShowTaxModal] = useState(false);

  // Aggregated Financials
  const grossMoneyIn = 148500;
  const grossMoneyOut = 82230;
  const netProfit = grossMoneyIn - grossMoneyOut;
  const marginPercent = ((netProfit / grossMoneyIn) * 100).toFixed(1);

  // Bank Balances (from Image 4 Google Sheet)
  const bankAccounts = {
    canara: 245000,
    gpayAxis: 89400,
    cashSafe: 34200
  };
  const totalLiquidity = bankAccounts.canara + bankAccounts.gpayAxis + bankAccounts.cashSafe;

  // Division-Wise Net Breakdown
  const divisions = [
    {
      id: 'tankers' as const,
      nameKey: 'portal.tankers',
      icon: '🚛',
      revenue: 98000,
      expenses: 46500,
      net: 51500,
      accent: '#0284C7',
      metric: '14 Trips Dispatched · 280 KL Moved',
      pct: 66
    },
    {
      id: 'water-cans' as const,
      nameKey: 'portal.water_cans',
      icon: '💧',
      revenue: 3770,
      expenses: 2504,
      net: 1266,
      accent: '#059669',
      metric: '188 Cans Delivered · 3 Sequential Plant Loads',
      pct: 3
    },
    {
      id: 'bakery' as const,
      nameKey: 'portal.bakery',
      icon: '🥐',
      revenue: 5764,
      expenses: 3724,
      net: 2040,
      accent: '#D97706',
      metric: '₹2,064 Drawer Cash + ₹3,700 UPI Sales',
      pct: 4
    }
  ];

  const totalOutstandingCredit = creditAccounts.reduce((acc, c) => acc + c.current_balance, 0);
  const criticalOverdueCredit = creditAccounts.reduce((acc, c) => acc + c.aging.days_60_plus, 0);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
      {/* 1. Header with Fresh Visual Action Bar */}
      <div className="fresh-card" style={{ padding: '1.25rem 1.5rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.65rem' }}>
            <span style={{ fontSize: '1.45rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {t('exec.title', lang)}
            </span>
            <span className="status-pill status-pill-green">
              SINGLE-ENTRY CONTROL PLANE
            </span>
          </div>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.84rem', marginTop: '0.2rem' }}>
            {t('exec.subtitle', lang)}
          </p>
        </div>

        <button
          onClick={() => setShowTaxModal(true)}
          className="btn-fresh btn-fresh-outline"
        >
          <FileSpreadsheet size={16} color="var(--accent-emerald)" />
          <span>{t('exec.tax_export_btn', lang)}</span>
        </button>
      </div>

      {/* 2. Visuals & Numbers Strip (Bento High-Clarity Metrics) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '1rem' }}>
        {/* Visual 1: Net Operating Profit */}
        <div className="fresh-metric-card" style={{ background: 'var(--bg-surface)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('exec.net_profit', lang)}
            </span>
            <span className="status-pill status-pill-green">
              {marginPercent}% MARGIN
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.2rem', fontWeight: 900, color: '#059669' }}>
              {formatINR(netProfit)}
            </span>
          </div>

          {/* Visual Profit Ratio Bar */}
          <div className="visual-progress-track">
            <div
              className="visual-progress-bar"
              style={{
                width: `${marginPercent}%`,
                background: 'linear-gradient(90deg, #059669, #10B981)'
              }}
            />
          </div>

          <div style={{ fontSize: '0.73rem', color: 'var(--text-dim)' }}>
            After fuel, plant costs, driver wages, and mandi purchases
          </div>
        </div>

        {/* Visual 2: Gross Money In */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('exec.gross_money_in', lang)}
            </span>
            <span className="status-pill status-pill-blue">
              <ArrowUpRight size={12} /> Today Collections
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.2rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {formatINR(grossMoneyIn)}
            </span>
          </div>

          <div style={{ fontSize: '0.74rem', color: 'var(--text-secondary)' }}>
            Bulk Tankers: ₹98,000 · Cans: ₹3,770 · Bakery: ₹5,764
          </div>

          <div style={{ fontSize: '0.73rem', color: 'var(--text-dim)' }}>
            Plus ₹41,000 client receivables collected today
          </div>
        </div>

        {/* Visual 3: Gross Money Out */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('exec.gross_money_out', lang)}
            </span>
            <span className="status-pill status-pill-amber">
              <ArrowDownRight size={12} /> Total Outflows
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.2rem', fontWeight: 800, color: '#D97706' }}>
              {formatINR(grossMoneyOut)}
            </span>
          </div>

          <div style={{ fontSize: '0.74rem', color: 'var(--text-secondary)' }}>
            Diesel: ₹8,420 · Plant: ₹1,704 · Mandi: ₹3,724 · Driver: ₹2,100
          </div>

          <div style={{ fontSize: '0.73rem', color: 'var(--text-dim)' }}>
            Separated from non-business family drawings
          </div>
        </div>

        {/* Visual 4: Available Liquidity */}
        <div className="fresh-metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              {t('exec.total_liquidity', lang)}
            </span>
            <span className="status-pill status-pill-neutral">
              3 Accounts
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'baseline', gap: '0.5rem', margin: '0.2rem 0' }}>
            <span className="font-mono" style={{ fontSize: '2.2rem', fontWeight: 800, color: 'var(--text-primary)' }}>
              {formatINR(totalLiquidity)}
            </span>
          </div>

          <div style={{ display: 'flex', gap: '0.4rem', flexWrap: 'wrap' }}>
            <span style={{ fontSize: '0.72rem', background: 'var(--bg-surface-subtle)', padding: '0.15rem 0.45rem', borderRadius: '4px', border: '1px solid var(--border-subtle)' }}>
              Canara: {formatINR(bankAccounts.canara)}
            </span>
            <span style={{ fontSize: '0.72rem', background: 'var(--bg-surface-subtle)', padding: '0.15rem 0.45rem', borderRadius: '4px', border: '1px solid var(--border-subtle)' }}>
              Axis: {formatINR(bankAccounts.gpayAxis)}
            </span>
          </div>

          <div style={{ fontSize: '0.73rem', color: 'var(--text-dim)' }}>
            Safe Drawer Cash: {formatINR(bankAccounts.cashSafe)}
          </div>
        </div>
      </div>

      {/* 3. Performance by Business Division (Modular Drilldowns) */}
      <div className="fresh-card" style={{ padding: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <div>
            <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
              {t('exec.division_title', lang)}
            </span>
            <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
              Each vertical runs independently with its own dedicated dashboard and operational portal
            </p>
          </div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '1rem' }}>
          {divisions.map(div => (
            <div
              key={div.id}
              style={{
                background: 'var(--bg-surface-subtle)',
                borderRadius: '12px',
                padding: '1.25rem',
                border: '1px solid var(--border-subtle)',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'space-between',
                gap: '1rem'
              }}
            >
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span style={{ fontSize: '1.4rem' }}>{div.icon}</span>
                    <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
                      {t(div.nameKey, lang)}
                    </span>
                  </div>
                  <span
                    style={{
                      fontSize: '0.75rem',
                      fontWeight: 800,
                      padding: '0.2rem 0.55rem',
                      borderRadius: '6px',
                      background: 'var(--bg-surface)',
                      color: div.accent,
                      border: '1px solid var(--border-subtle)'
                    }}
                  >
                    Net {formatINR(div.net)}
                  </span>
                </div>

                <div style={{ marginTop: '0.75rem', fontSize: '0.78rem', color: 'var(--text-secondary)' }}>
                  {div.metric}
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '0.65rem', fontSize: '0.8rem', color: 'var(--text-muted)' }}>
                  <span>Revenue: <strong>{formatINR(div.revenue)}</strong></span>
                  <span>Expenses: <strong>{formatINR(div.expenses)}</strong></span>
                </div>
              </div>

              <button
                onClick={() => onNavigateToVertical(div.id)}
                className="btn-fresh btn-fresh-outline"
                style={{ width: '100%', justifyContent: 'space-between', fontSize: '0.82rem', padding: '0.5rem 0.85rem' }}
              >
                <span>Open Dedicated {t(div.nameKey, lang)} Portal</span>
                <ArrowRight size={14} />
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* 4. Corporate B2B Receivables & 60+ Days Credit Aging */}
      <div className="fresh-card" style={{ padding: '1.25rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem', flexWrap: 'wrap', gap: '0.5rem' }}>
          <div>
            <span style={{ fontWeight: 800, fontSize: '1.05rem' }}>
              {t('exec.corporate_receivables', lang)}
            </span>
            <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)' }}>
              Resolving ₹4–₹5 Lakhs stalled client credit via automated 15-day / monthly aging alerts
            </p>
          </div>

          <div style={{ display: 'flex', gap: '0.5rem' }}>
            <span className="status-pill status-pill-neutral">
              Total Outstanding: {formatINR(totalOutstandingCredit)}
            </span>
            <span className="status-pill status-pill-amber">
              Critical &gt;60d: {formatINR(criticalOverdueCredit)}
            </span>
          </div>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table className="fresh-table">
            <thead>
              <tr>
                <th>Corporate Client</th>
                <th>Billing Cycle</th>
                <th>Current Balance</th>
                <th>{t('exec.aging_0_15', lang)}</th>
                <th>{t('exec.aging_16_30', lang)}</th>
                <th>{t('exec.aging_31_60', lang)}</th>
                <th>{t('exec.aging_60_plus', lang)}</th>
                <th>Follow-up Action</th>
              </tr>
            </thead>
            <tbody>
              {creditAccounts.map(account => (
                <tr key={account.id}>
                  <td style={{ fontWeight: 700 }}>{account.company_name}</td>
                  <td>
                    <span className="status-pill status-pill-neutral">
                      {account.billing_cycle}
                    </span>
                  </td>
                  <td className="font-mono" style={{ fontWeight: 800, color: 'var(--text-primary)' }}>
                    {formatINR(account.current_balance)}
                  </td>
                  <td className="font-mono">{formatINR(account.aging.days_0_15)}</td>
                  <td className="font-mono">{formatINR(account.aging.days_16_30)}</td>
                  <td className="font-mono" style={{ color: account.aging.days_31_60 > 0 ? '#D97706' : 'var(--text-dim)' }}>
                    {formatINR(account.aging.days_31_60)}
                  </td>
                  <td className="font-mono" style={{ fontWeight: 800, color: account.aging.days_60_plus > 0 ? '#DC2626' : 'var(--text-dim)' }}>
                    {formatINR(account.aging.days_60_plus)}
                    {account.aging.days_60_plus > 0 && ' ⚠️'}
                  </td>
                  <td style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>
                    {account.follow_up_note}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* 5. 1-Click IT Tax Audit Export Modal */}
      {showTaxModal && (
        <div className="fresh-modal-backdrop" onClick={() => setShowTaxModal(false)}>
          <div className="fresh-modal-dialog" onClick={e => e.stopPropagation()}>
            <div style={{ padding: '1.25rem 1.5rem', borderBottom: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <FileSpreadsheet size={20} color="#059669" />
                <span style={{ fontWeight: 800, fontSize: '1.15rem' }}>
                  {t('exec.tax_export_title', lang)}
                </span>
              </div>
              <button
                onClick={() => setShowTaxModal(false)}
                style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-muted)' }}
              >
                <X size={20} />
              </button>
            </div>

            <div style={{ padding: '1.5rem', display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div style={{ background: 'var(--bg-surface-subtle)', padding: '0.85rem', borderRadius: '8px', fontSize: '0.82rem', color: 'var(--text-secondary)' }}>
                {t('exec.tax_export_subtitle', lang)}
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.45rem 0', borderBottom: '1px solid var(--border-subtle)', fontSize: '0.88rem' }}>
                  <span>Financial Assessment Year:</span>
                  <span className="font-mono" style={{ fontWeight: 700 }}>2026-2027</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.45rem 0', borderBottom: '1px solid var(--border-subtle)', fontSize: '0.88rem' }}>
                  <span>Entity Classification:</span>
                  <span style={{ fontWeight: 600 }}>DK Enterprises (Partnership Firm)</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.45rem 0', borderBottom: '1px solid var(--border-subtle)', fontSize: '0.88rem' }}>
                  <span>Drinking Water Supply (0% GST Exemption):</span>
                  <span className="font-mono" style={{ fontWeight: 700, color: '#059669' }}>₹ 43,50,000</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.45rem 0', borderBottom: '1px solid var(--border-subtle)', fontSize: '0.88rem' }}>
                  <span>Commercial Vehicle Rental (18% GST Applicable):</span>
                  <span className="font-mono" style={{ fontWeight: 700, color: '#0284C7' }}>₹ 12,50,000</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.45rem 0', borderBottom: '1px solid var(--border-subtle)', fontSize: '0.88rem' }}>
                  <span>Allowable Diesel & Fleet Maintenance Deductions:</span>
                  <span className="font-mono" style={{ fontWeight: 700, color: '#D97706' }}>- ₹ 16,65,000</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0.65rem 0', fontSize: '1rem', fontWeight: 800 }}>
                  <span>Auditable Operating Profit:</span>
                  <span className="font-mono" style={{ color: '#059669' }}>₹ 11,15,000</span>
                </div>
              </div>
            </div>

            <div style={{ padding: '1rem 1.5rem', borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
              <button
                onClick={() => setShowTaxModal(false)}
                className="btn-fresh btn-fresh-outline"
              >
                {t('common.close', lang)}
              </button>
              <button
                onClick={() => {
                  alert('Auditor Tax Excel schedule exported successfully.');
                  setShowTaxModal(false);
                }}
                className="btn-fresh btn-fresh-emerald"
              >
                Download Excel (.xlsx)
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
